#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo
import logging
import time
import copy
import os

hlog = logging.getLogger("heuristic")
if "LOG" in list(os.environ.keys()):
    loglevel = int(os.environ["LOG"])
else:
    loglevel = 0

if loglevel == 1:
    logging.basicConfig(level=logging.INFO)
elif loglevel >= 2:
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.ERROR)

class Declarative(object):
    def __init__(self, mfile, offline, btrack):
        super(Declarative, self).__init__()

        self.__dumpcount = 0
        self.__stats = Statistics()

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
        self.__res_lits = dict()
        self.__impossible = set()
        self.__persisted = set()

        if offline:
            self.decide = self.__decide_offline
            self.__offline_decisions = []
        else:
            self.decide = self.__decide_online

        self.__btrack = btrack

        self.__last_decision = None

    def __remember_watch(self, lit, f):
        self.__res_lits[str(f)] = lit
        try:
            self.__lit_watches[lit].add(f)
        except KeyError:
            self.__lit_watches[lit] = set([f])

    def __process_hprog(self, a):
        self.__collect_watches(self, a)

        if a.type == clingo.ast.ASTType.Heuristic:
            l = a.location
            mod = a.modifier
            bias = a.bias
            priority = a.priority
            
            hargs = [a.atom.term, bias, priority, mod]
            hatom = clingo.ast.SymbolicAtom(clingo.ast.Function(location=l, 
                name="_heuristic", arguments=hargs, external=False))
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
        facts = 0
        if loglevel == 3:
            self.__lastprog = []
        with stepsolver.builder() as b:
            for stmt in self.__program:
                b.add(stmt)
                if loglevel == 3: self.__lastprog.append(str(stmt))
            for e in self.__externals:
                if self.__externals[e] == True: 
                    stmt = "{}.".format(e)
                    clingo.parse_program(stmt, lambda a: b.add(a))
                    if loglevel == 3: self.__lastprog.append(stmt)
                    facts += 1
            for p in self.__persisted:
                stmt = "{}.".format(p)
                clingo.parse_program(stmt, lambda a: b.add(a))
                if loglevel == 3: self.__lastprog.append(stmt)
                facts += 1
        hlog.info("heuristic program with {} added facts".format(facts))
        hlog.debug("grounding heuristic program")
        stepsolver.ground([("base",[])])
        return stepsolver

    def __resigned(self, vsids):
        return vsids

    def __persist(self, model):
        xs = [x.arguments[0] 
                for x in model.symbols(atoms=True)
                if x.name == "_persist"
                and len(x.arguments) == 1]
        self.__persisted |= set(map(str, xs))
    
    def __decide_offline(self, vsids):
        self.__last_decision = None
        self.__offline_decisions = [x for x in self.__offline_decisions if str(x.arguments[0]) not in self.__impossible]
        if not self.__offline_decisions:
            t0 = time.time()
            stepsolver = self.__make_step_solver()
            with stepsolver.solve(yield_=True) as handle:
                try:
                    hlog.debug("solving for heuristic")
                    model = next(handle)
                    self.__persist(model)
                    hlog.debug("solving done")
                    xs = [x for x in model.symbols(atoms=True) 
                            if x.name == "_heuristic" 
                            and len(x.arguments) == 4]
                    xs_s = sorted(sorted(xs), key=self.__level_weight)
                    t1 = time.time()
                    hlog.info("{} offline decisions took {}s".format(len(xs_s), t1 - t0))
                    self.__offline_decisions = xs_s
                except StopIteration:
                    hlog.warning("found no model!")

        while self.__offline_decisions:
            d = self.__offline_decisions.pop()
            if str(d.arguments[0]) not in self.__impossible:
                return self.__make_decision(vsids, d)

        hlog.warning("ran out of decisions, using vsids {}".format(vsids))
        return vsids

    def __decide_online(self,vsids):
        t0 = time.time()
        stepsolver = self.__make_step_solver()
        self.__last_decision = None
        with stepsolver.solve(yield_=True) as handle:
            try:
                model = next(handle)
                self.__persist(model)
                decision = self.__find_heuristic_atom(model)
                t1 = time.time()
                hlog.info("online decision took {}s".format(t1 - t0))
                if decision:
                    return self.__make_decision(vsids, decision)
                else:
                    self.__dumpcount += 1
                    if loglevel == 3:
                        hlog.warning("No decision made by heuristic, falling back, dumping program to /tmp/dump-{}.lp".format(self.__dumpcount))
                        with open("/tmp/dump-{}.lp".format(self.__dumpcount), 'w') as f:
                            f.write("\n".join(self.__lastprog))
                    else:
                        hlog.warning("No decision made by heuristic, falling back")
                    return vsids
            except StopIteration:
                hlog.warning("found no model!")
        return vsids

    def __make_decision(self, vsids, decision):
        decision = decision.arguments
        atom = decision[0]
        if str(atom) == "_vsids":
            hlog.debug("heuristic request fallback")
            return vsids
        if str(atom) == "_resign":
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
        syms = [x for x in model.symbols(atoms=True) if x.name == "_heuristic"
                and len(x.arguments) == 4
                and str(x.arguments[0]) not in self.__impossible]
        
        syms_s = sorted(sorted(syms, key=lambda x: str(x.arguments[0])),key=self.__level_weight)
        hlog.debug("decisions: {}".format(syms_s))
        if syms_s:
            return syms_s[0]
        else:
            return None

    def init(self, init):
        for a in init.symbolic_atoms:
            name = a.symbol.name
            alen = len(a.symbol.arguments)
            lit = init.solver_literal(a.literal)
            if (name, alen) in self.__external_sigs or (name, alen) in self.__result_sigs:
                # watch in main
                init.add_watch(lit)
                init.add_watch(-lit)

                # store as external
                f = clingo.Function(name, a.symbol.arguments)
                self.__externals[f] = a.is_fact
                self.__remember_watch(lit, f)
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
        if self.__last_decision and -self.__last_decision in changes:
            self.__stats.onestep()
            if self.__btrack:
                hlog.debug("clearing cache after one-step backtracking")
                self.__offline_decisions = []
        for l in changes:
            try:
                for e in self.__lit_watches[l]:
                    hlog.debug("propagate {} ({})".format(e,l))
                    self.__externals[e] = True
                    self.__impossible.add(str(e))
            except KeyError:
                pass
            try:
                for e in self.__lit_watches[-l]:
                    hlog.debug("propagate -{} ({})".format(e,l))
                    self.__externals[e] = False
                    self.__impossible.add(str(e))
            except KeyError:
                pass

    def undo(self, thread_id, assign, changes):
        self.__offline_decisions = []
        hlog.debug("undo set: {}".format(changes))
        for l in changes:
            try:
                for e in self.__lit_watches[l]:
                    hlog.debug("undo {} ({})".format(e,l))
                    self.__externals[e] = False
                    self.__impossible.remove(e)
            except KeyError:
                pass
            try:
                for e in self.__lit_watches[-l]:
                    hlog.debug("undo {} ({})".format(e,l))
                    self.__externals[e] = False
                    self.__impossible.remove(e)
            except KeyError:
                pass

    def check(self, a):
        hlog.debug("model found")
        hlog.info("statistics: one step backtrackings: {}".format(
            self.__stats.get_onestep()))

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

class Statistics(object):
    def __init__(self):
        self.__onestep = 0

    def clean(self):
        self.__onestep = 0
        
    def onestep(self):
        self.__onestep += 1

    def get_onestep(self):
        return self.__onestep
