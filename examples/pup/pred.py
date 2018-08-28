#!/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import deque
from operator import itemgetter
import clingo
import networkx as nx

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

    def bf_ordering(self, start):
        G = self.__instance
        visited = {start}
        queue = deque([start])
        while queue:
            parent = queue.popleft()
            yield parent
            nd = sorted(G.degree(set(G[parent]) - visited).items(),
                        key=itemgetter(1))
            children = [n for n, d in nd]
            visited.update(children)
            queue.extend(children)

    def propagate(self, ctl, changes):
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

    def decide(self, vsids):
        for elem in self.bf_ordering(self.__source):
            print elem
        return vsids

    def undo(self, thread_id, assign, changes):
        self.__decisions = []
        for l in changes:
            for e in self.__lit_watches[abs(l)]:
                self.__externals[e] = assign.is_true(abs(l))
            try:
                for a in self.__lit_ress[abs(l)]:
                    self.__impossible.remove(a)
            except KeyError:
                pass
