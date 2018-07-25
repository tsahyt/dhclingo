#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo

class Declarative(object):
    def __init__(self, hfile, ifile):
        super(Declarative, self).__init__()
        self.solver = clingo.Control()

        # load heuristic and instance
        heuristic_program = open(hfile).read()
        instance_program = open(ifile).read()
        self.solver.add("base", [], heuristic_program)
        self.solver.add("base", [], instance_program)
        self.solver.ground([("base",[])])
    
    def decide(self,vsids):
        return vsids

    def init(self, init):
        pass
