#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo
import logging
import time
import copy

hlog = logging.getLogger("heuristic")
logging.basicConfig(level=logging.DEBUG)

class Declarative(object):
    def __init__(self, mfile, offline):
        super(Declarative, self).__init__()

        initsolver = clingo.Control()

        # load heuristic and instance
        self.__program = []
        self.__external_sigs = []
        self.__result_sigs = []
        self.__some_location = None

        # define containers
        self.__heads = set()
        self.__bodies = set()

        clingo.parse_program(mfile, self.__process_hprog)

        # define mappings
        self.__externals = dict()
        self.__lit_watches = dict()
        self.__lit_ress = dict()
        self.__res_lits = dict()
        self.__impossible = set()

        if offline:
            self.decide = self.__decide_offline
            self.__offline_decisions = []
        else:
            self.decide = self.__decide_online

        self.__last_decision = None

    def __remember_watch(self, alit, f):
        self.__res_lits[str(f)] = alit
        try:
            self.__lit_watches[alit].add(f)
        except KeyError:
            self.__lit_watches[alit] = set([f])

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
        hlog.debug("building heuristic program")
        with stepsolver.builder() as b:
            for stmt in self.__program:
                b.add(stmt)
            for e in self.__externals:
                if self.__externals[e] == True: 
                    clingo.parse_program("{}.".format(e), lambda a: b.add(a))
        hlog.debug("grounding heuristic program")
        stepsolver.ground([("base",[])])
        return stepsolver

    def __resigned(self, vsids):
        return vsids
    
    def __decide_offline(self, vsids):
        self.__last_decision = None
        self.__offline_decisions = filter(lambda x: str(x.arguments[0]) not in self.__impossible, self.__offline_decisions)
        if not self.__offline_decisions:
            stepsolver = self.__make_step_solver()
            with stepsolver.solve(yield_=True) as handle:
                try:
                    hlog.debug("solving for heuristic")
                    model = handle.next()
                    hlog.debug("solving done")
                    xs = [x for x in model.symbols(atoms=True) 
                            if x.name == "heuristic" 
                            and len(x.arguments) == 4]
                    xs_s = sorted(sorted(xs), key=self.__level_weight)
                    self.__offline_decisions = xs_s
                except StopIteration:
                    hlog.warning("found no model!")

        while self.__offline_decisions:
            d = self.__offline_decisions.pop()
            if str(d.arguments[0]) not in self.__impossible:
                return self.__make_decision(vsids, d)

        hlog.warning("offline heuristic ran out of decisions, using vsids literal {}".format(vsids))
        return vsids

    def __decide_online(self,vsids):
        hlog.debug("decide called")
        t0 = time.time()
        stepsolver = self.__make_step_solver()
        self.__last_decision = None
        with stepsolver.solve(yield_=True) as handle:
            try:
                model = handle.next()
                t1 = time.time()
                # hlog.debug("step solver created and solved in {} s".format(t1 - t0))
                # hlog.debug("model: {}".format(model))
                decision = self.__find_heuristic_atom(model)
                if decision:
                    return self.__make_decision(vsids, decision)
                else:
                    hlog.warning("No decision made by heuristic, falling back")
                    return vsids
            except StopIteration:
                hlog.warning("found no model!")
        return vsids

    def __make_decision(self, vsids, decision):
        decision = decision.arguments
        atom = decision[0]
        if str(atom) == "vsids":
            hlog.debug("heuristic request fallback")
            return vsids
        if str(atom) == "resign":
            hlog.debug("heuristic resigned, using vsids forever")
            self.decide = self.__resigned
            return vsids
        lit = self.__res_lits[str(atom)]
        hlog.debug("choice: {} {} ({})".format(atom, decision[3], lit))
        if str(decision[3]) == "true":
            self.__last_decision = lit
            return lit
        elif str(decision[3]) == "false":
            self.__last_decision = -lit
            return -lit
        else:
            hlog.warning(
                    "Invalid modifier {}! Defaulting to true".format(
                        decision[3]))
            self.__last_decision = None
            return vsids

    def __level_weight(self, a):
        weight = int(str(a.arguments[1]))
        level = int(str(a.arguments[2]))
        return (level, weight)

    def __find_heuristic_atom(self, model):
        """
        Pick some heuristic atom.

        :type model: clingo.Model
        """
        syms = [x for x in model.symbols(atoms=True) if x.name == "heuristic"
                and len(x.arguments) == 4
                and str(x.arguments[0]) not in self.__impossible]
        syms = sorted(syms)
        syms_s = sorted(syms,key=self.__level_weight)
        if syms_s:
            return syms_s[-1]
        else:
            return None

    def init(self, init):
        for a in init.symbolic_atoms:
            name = a.symbol.name
            alen = len(a.symbol.arguments)
            lit = init.solver_literal(a.literal)
            # hlog.debug("symbol {}: {}".format(a.symbol, lit))
            if (name, alen) in self.__external_sigs:
                # watch in main
                init.add_watch(lit)
                init.add_watch(-lit)

                # store as external
                f = clingo.Function(name, a.symbol.arguments)
                alit = abs(lit)
                self.__externals[f] = a.is_fact
                self.__remember_watch(alit, f)
            if (name, alen) in self.__result_sigs:
                init.add_watch(lit)
                init.add_watch(-lit)

                alit = abs(lit)
                f = str(clingo.Function(name, a.symbol.arguments))
                try:
                    self.__lit_ress[alit].add(f)
                except KeyError:
                    self.__lit_ress[alit] = set([f])
                self.__remember_watch(alit, f)
            if a.is_fact:
                self.__add_fact(a.symbol)

    def __add_fact(self, symbol):
        l = self.__some_location
        args = [ clingo.ast.Symbol(location=l, symbol=s) for s in
                symbol.arguments ]
        func = clingo.ast.Function(location=l, name=symbol.name,
                arguments=args, external=False)
        atom = clingo.ast.SymbolicAtom(func)
        head = clingo.ast.Literal(location=l, sign=clingo.ast.Sign.NoSign,
                atom=atom)
        rule = clingo.ast.Rule(location=l, head=head, body=[])
        self.__program.append(rule)

    def propagate(self, ctl, changes):
        hlog.debug("propagate {}".format(changes))
        if self.__last_decision and -self.__last_decision in changes:
            hlog.debug("one-step backtracking detected, erasing cached decisions")
        #     self.__offline_decisions = []
        for l in changes:
            for e in self.__lit_watches[abs(l)]:
                self.__externals[e] = ctl.assignment.is_true(abs(l))
            try:
                for a in self.__lit_ress[abs(l)]:
                    if l < 0:
                        hlog.debug("propagate -{} ({})".format(a,l))
                    else:
                        hlog.debug("propagate {} ({})".format(a,l))
                    self.__impossible.add(a)
            except KeyError:
                pass

    def undo(self, thread_id, assign, changes):
        hlog.debug("undo {}".format(changes))
        self.__offline_decisions = []
        for l in changes:
            for e in self.__lit_watches[abs(l)]:
                self.__externals[e] = assign.is_true(abs(l))
            try:
                for a in self.__lit_ress[abs(l)]:
                    self.__impossible.remove(a)
            except KeyError:
                pass

class HeuristicSplitter(object):
    def __init__(self, mfile):
        super(HeuristicSplitter, self).__init__()
        prog = open(mfile).read()
        
        self.base_program = []
        self.heuristic_program = []
        self.last_p = "base"
        clingo.parse_program(prog, self.__split)

    def get_heuristic_str(self):
        return "\n".join(self.heuristic_program)

    def __split(self, a):
        if a.type == clingo.ast.ASTType.Program:
            self.last_p = str(a.name)
        else:
            if self.last_p == "dynamic_heuristic":
                self.heuristic_program.append(str(a))
            else:
                self.base_program.append(a)
