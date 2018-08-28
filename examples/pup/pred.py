#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo
import networkx as nx
import matplotlib.pyplot as plt

class Pred(object):
    def __init__(self):
        super(Pred, self).__init__()
        self.__source = "z1"
        self.__instance = nx.Graph()
        
    def init(self, init):
        for a in init.symbolic_atoms:
            if str(a.symbol).startswith("zone2sensor("):
                zone = "z{}".format(a.symbol.arguments[0])
                sensor = "s{}".format(str(a.symbol.arguments[1]))
                self.__instance.add_edge(zone, sensor)
            if (str(a.symbol).startswith("unit2zone(")
                or str(a.symbol).startswith("unit2sensor(")):
                l = init.solver_literal(a.literal)
                init.add_watch(l)
        print map(str,self.__instance.nodes())
        order = [x for x in nx.traversal.bfs_successors(self.__instance, "z1")]
        print order

    def propagate(self, ctl, changes):
        pass

    def decide(self, vsids):
        return vsids

    def undo(self, thread_id, assign, changes):
        pass
