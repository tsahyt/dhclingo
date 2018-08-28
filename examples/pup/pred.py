#!/usr/bin/env python
# -*- coding: utf-8 -*-

import clingo
import networkx as nx

class Pred(object):
    def __init__(self):
        super(Pred, self).__init__()
        self.__source = None
        self.__instance = None
        
    def init(self, init):
        for a in init.symbolic_atoms:
            if str(a.symbol).startswith("zone2sensor("):
                zone = int(str(a.symbol.arguments[0]))
                sensor = int(str(a.symbol.arguments[1]))
                print(zone, sensor)
                pass

    def propagate(self, ctl, changes):
        pass

    def decide(self, vsids):
        for node in nx.bfs_successors(self.__instance, self.__source):
            pass

    def undo(self, thread_id, assign, changes):
        pass
