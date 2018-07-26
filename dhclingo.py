#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo
import logging

hlog = logging.getLogger("heuristic")
logging.basicConfig(level=logging.DEBUG)

class Declarative(object):
    def __init__(self, hfile, ifile):
        super(Declarative, self).__init__()

        initsolver = clingo.Control()

        # load heuristic and instance
        heuristic_program = open(hfile).read()
        instance_program = open(ifile).read()

        self.__program = []
        self.__external_sigs = []
        self.__result_sigs = []
        self.__some_location = None

        clingo.parse_program(heuristic_program, self.__process_hprog)
        clingo.parse_program(instance_program, lambda a:
                self.__program.append(a))

        # define mappings
        self.__externals = dict()
        self.__ext_lits = dict()
        self.__lit_exts = dict()
        self.__lit_ress = dict()
        self.__impossible = set()

    def __process_hprog(self, a):
        self.__collect_watches(self, a)

        if a.type == clingo.ast.ASTType.Heuristic:
            l = a.location
            mod = a.modifier
            bias = a.bias
            priority = a.priority
            
            hargs = [a.atom.term, bias, priority, mod]
            hatom = clingo.ast.SymbolicAtom(clingo.ast.Function(location=l, 
                name="heuristic", arguments=hargs, external=False))
            head = clingo.ast.Literal(location=l, sign=clingo.ast.Sign.NoSign, 
                    atom=hatom)
            rule = clingo.ast.Rule(location=l, head=head, body=a.body)

            self.__program.append(rule)
        elif a.type != clingo.ast.ASTType.External:
            self.__program.append(a)

        self.__some_location = a.location

    def __collect_watches(self, builder, a):
        if a.type == clingo.ast.ASTType.External:
            name = a.atom.term.name
            arity = len(a.atom.term.arguments)
            self.__external_sigs.append((name, arity))
        elif a.type == clingo.ast.ASTType.Heuristic:
            name = a.atom.term.name
            arity = len(a.atom.term.arguments)
            self.__result_sigs.append((name,arity))

    def __make_step_solver(self):
        stepsolver = clingo.Control()
        with stepsolver.builder() as b:
            for stmt in self.__program:
                b.add(stmt)
            for e in self.__externals:
                if self.__externals[e] == True: 
                    clingo.parse_program("{}.".format(e), lambda a: b.add(a))
        stepsolver.ground([("base",[])])
        return stepsolver
    
    def decide(self,vsids):
        stepsolver = self.__make_step_solver()
        with stepsolver.solve(yield_=True) as handle:
            try:
                model = handle.next()
                # hlog.debug("model: {}".format(model))
                decision = self.__find_heuristic_atom(model)
                if decision:
                    decision = decision.arguments
                    atom = decision[0]
                    lit = self.__ext_lits[atom]
                    hlog.debug("choice: {} {} ({})".format(atom, decision[3], lit))
                    if str(decision[3]) == "true":
                        return lit
                    elif str(decision[3]) == "false":
                        return -lit
                    else:
                        hlog.warning(
                                "Invalid modifier {}! Defaulting to true".format(
                                    decision[3]))
                    return lit
                else:
                    hlog.warning("No decision made by heuristic, falling back")
                    return vsids
            except StopIteration:
                hlog.warning("found no model!")
        return vsids

    def __level_weight(self, a, b):
        level_a = int(str(a.arguments[1]))
        level_b = int(str(b.arguments[1]))
        weight_a = int(str(a.arguments[2]))
        weight_b = int(str(b.arguments[2]))

        if level_a != level_b:
            if level_a > level_b:
                return 1
            else:
                return -1
        else:
            if weight_a > weight_b:
                return 1
            elif weight_b < weight_a:
                return -1
            else:
                return 0

    def __find_heuristic_atom(self, model):
        """
        Pick some heuristic atom.

        :type model: clingo.Model
        """
        syms = [x for x in model.symbols(atoms=True) if x.name == "heuristic"
                and len(x.arguments) == 4
                and str(x.arguments[0]) not in self.__impossible]
        syms_s = sorted(syms,cmp=self.__level_weight)
        if syms_s:
            return syms_s[0]
        else:
            return None

    def init(self, init):
        for a in init.symbolic_atoms:
            name = a.symbol.name
            alen = len(a.symbol.arguments)
            lit = init.solver_literal(a.literal)
            if (name, alen) in self.__external_sigs:
                # watch in main
                init.add_watch(lit)
                init.add_watch(-lit)

                # store as external
                f = clingo.Function(name, a.symbol.arguments)
                alit = abs(lit)
                self.__externals[f] = a.is_fact
                self.__ext_lits[f] = alit
                try:
                    self.__lit_exts[alit].add(f)
                except KeyError:
                    self.__lit_exts[alit] = set([f])
            if (name, alen) in self.__result_sigs:
                init.add_watch(lit)
                init.add_watch(-lit)

                alit = abs(lit)
                f = str(clingo.Function(name, a.symbol.arguments))
                try:
                    self.__lit_ress[alit].add(f)
                except KeyError:
                    self.__lit_ress[alit] = set([f])

        hlog.debug("ext_lits: {}".format(self.__ext_lits))
        self.__make_step_solver()

    def propagate(self, ctl, changes):
        hlog.debug("propagate {}".format(changes))
        for l in changes:
            for e in self.__lit_exts[abs(l)]:
                self.__externals[e] = ctl.assignment.is_true(abs(l))
            try:
                for a in self.__lit_ress[abs(l)]:
                    self.__impossible.add(a)
            except KeyError:
                pass

    def undo(self, thread_id, assign, changes):
        hlog.debug("undo {}".format(changes))
        for l in changes:
            for e in self.__lit_exts[abs(l)]:
                self.__externals[e] = assign.is_true(abs(l))
            try:
                for a in self.__lit_ress[abs(l)]:
                    self.__impossible.remove(a)
            except KeyError:
                pass
