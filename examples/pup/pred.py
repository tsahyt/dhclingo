#!/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import deque
from operator import itemgetter
import clingo
import networkx as nx

class Unit(object):
    def __init__(self, num):
        self.num = num
        self.zones = 0
        self.sensors = 0

    def assign(self, elem):
        if elem.startswith("z"):
            self.zones += 1
        elif elem.startswith("s"):
            self.sensors += 1
        else:
            raise ValueError("invalid element")

    def can_take(self, elem):
        if elem.startswith("z"):
            return self.zones < 2
        elif elem.startswith("s"):
            return self.sensors < 2
        else:
            raise ValueError("invalid element")

class Pred(object):
    def __init__(self):
        super(Pred, self).__init__()
        self.__source = "z1"
        self.__instance = nx.Graph()
        self.__impossible = set()
        self.__lit_ress = dict()
        
    def init(self, init):
        for a in init.symbolic_atoms:
            if str(a.symbol).startswith("zone2sensor("):
                zone = "z{}".format(a.symbol.arguments[0])
                sensor = "s{}".format(str(a.symbol.arguments[1]))
                self.__instance.add_edge(zone, sensor)
            if (str(a.symbol).startswith("unit2zone(")
                or str(a.symbol).startswith("unit2sensor(")):
                l = init.solver_literal(a.literal)
                try:
                    self.__lit_ress[abs(l)].add(str(a.symbol))
                except KeyError:
                    self.__lit_ress[abs(l)] = set([str(a.symbol)])
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

    def make_decisions(self):
        self.__decisions = []
        assigned_unit = dict()
        last_unit = Unit(1)

        for elem in self.bf_ordering(self.__source): 
            one_hop = self.__instance.neighbors(elem)
            two_hop = [ x for ns in [ self.__instance.neighbors(y) for y in one_hop ] for x in ns ]
            preferred1 = [ x for x in one_hop if x in assigned_unit ]
            preferred2 = [ x for x in two_hop if x in assigned_unit ]

            preferred = None
            if preferred is not None:
                assigned_unit[elem] = preferred
                preferred.assign(elem)
                self.__decisions.append((elem, preferred))
            else:
                assigned_unit[elem] = last_unit
                last_unit.assign(elem)
                self.__decisions.append((elem, last_unit))
                last_unit = Unit(last_unit.num + 1)

    def propagate(self, ctl, changes):
        for l in changes:
            try:
                for a in self.__lit_ress[abs(l)]:
                    self.__impossible.add(a)
            except KeyError:
                pass

    def decide(self, vsids):
        self.make_decisions()
        return vsids

    def undo(self, thread_id, assign, changes):
        self.__decisions = []
        for l in changes:
            try:
                for a in self.__lit_ress[abs(l)]:
                    self.__impossible.remove(a)
            except KeyError:
                pass