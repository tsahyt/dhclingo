#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo

class Declarative(object):
    def __init__(self, hfile):
        super(Declarative, self).__init__()
        heuristic_program = open(hfile).read()
        self.solver = clingo.Control()
        self.solver.add("base", [], heuristic_program)
        self.solver.ground([("base",[])])
    
    def decide(self,vsids):
        return vsids

    def init(self, init):
        pass
