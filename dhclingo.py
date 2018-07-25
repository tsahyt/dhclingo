#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo
import logging

hlog = logging.getLogger("heuristic")
logging.basicConfig(level=logging.DEBUG)

class Declarative(object):
    def __init__(self, hfile, ifile):
        super(Declarative, self).__init__()
        self.solver = clingo.Control()

        # load heuristic and instance
        heuristic_program = open(hfile).read()
        instance_program = open(ifile).read()
        self.solver.add("base", [], instance_program)

        self.__external_sigs = []
        with self.solver.builder() as b:
            clingo.parse_program(heuristic_program, 
                    lambda a: self.__collect_externals(b, a))
        self.solver.ground([("base",[])])

        # define mappings
        self.__externals = dict()
        self.__ext_lits = dict()
        self.__lit_exts = dict()

    def __collect_externals(self, builder, a):
        if a.type == clingo.ast.ASTType.External:
            name = a.atom.term.name
            arity = len(a.atom.term.arguments)
            self.__external_sigs.append((name, arity))
        builder.add(a)
    
    def decide(self,vsids):
        for e in self.__externals:
            self.solver.assign_external(e,self.__externals[e])
        with self.solver.solve(yield_=True) as handle:
            try:
                model = handle.next()
                atom = self.__find_heuristic_atom(model).arguments[0]
                lit = self.__ext_lits[atom]
                hlog.debug("choice: {} ({})".format(atom, lit))
                return lit
            except StopIteration:
                hlog.warning("found no model!")
        return vsids

    def __find_heuristic_atom(self, model):
        """
        Pick some heuristic atom.

        :type model: clingo.Model
        """
        hlog.debug("model: {}".format(model))
        syms = (x for x in model.symbols(atoms=True) if x.name == "heuristic")
        return syms.next()

    def init(self, init):
        for a in init.symbolic_atoms:
            name = a.symbol.name
            alen = len(a.symbol.arguments)
            if (name, alen) in self.__external_sigs:
                # watch in main
                lit = init.solver_literal(a.literal)
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

        hlog.debug("ext_lits: {}".format(self.__ext_lits))

    def propagate(self, ctl, changes):
        hlog.debug("propagate {}".format(changes))
        for l in changes:
            for e in self.__lit_exts[abs(l)]:
                self.__externals[e] = ctl.assignment.is_true(abs(l))

    def undo(self, thread_id, assign, changes):
        hlog.debug("undo {}".format(changes))
        for l in changes:
            for e in self.__lit_exts[abs(l)]:
                self.__externals[e] = assign.is_true(abs(l))
