#!/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import deque
from operator import itemgetter
from functools import total_ordering
import re
import clingo
import networkx as nx

@total_ordering
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

    def unassign(self, elem):
        if elem.startswith("z"):
            self.zones -= 1
        elif elem.startswith("s"):
            self.sensors -= 1
        else:
            raise ValueError("invalid element")

    def can_take(self, elem):
        if elem.startswith("z"):
            return self.zones < 2
        elif elem.startswith("s"):
            return self.sensors < 2
        else:
            raise ValueError("invalid element")

    def __lt__(self, other):
        return self.num < other.num

    def __str__(self):
        return str(self.num)

class Pred(object):
    def __init__(self):
        super(Pred, self).__init__()
        self.__decisions = []
        self.__source = []
        self.__instance = nx.Graph()
        self.__impossible = set()
        self.__lit_ress = dict()
        self.__res_lits = dict()
        self.__assigned_unit = dict()
        self.__zoneRE = re.compile(r"unit2zone\((\d+),(\d+)\)")
        self.__sensorRE = re.compile(r"unit2sensor\((\d+),(\d+)\)")
        self.__units = dict()

    def init(self, init):
        units = set()
        source = set()
        for a in init.symbolic_atoms:
            if str(a.symbol).startswith("zone2sensor("):
                zone = "z{}".format(a.symbol.arguments[0])
                sensor = "s{}".format(str(a.symbol.arguments[1]))
                source.add(zone)
                self.__instance.add_edge(zone, sensor)
            if str(a.symbol).startswith("unit2zone(") or str(
                a.symbol
            ).startswith("unit2sensor("):
                l = init.solver_literal(a.literal)
                try:
                    self.__lit_ress[l].add(str(a.symbol))
                except KeyError:
                    self.__lit_ress[l] = set([str(a.symbol)])
                self.__res_lits[str(a.symbol)] = l
                init.add_watch(l)
                init.add_watch(-l)
            if str(a.symbol).startswith("comUnit("):
                units.add(Unit(int(str(a.symbol.arguments[0]))))
        self.__source = sorted(list(source))
        for u in units:
            self.__units[u.num] = u
        print self.__units

    def bf_ordering(self, start):
        G = self.__instance
        visited = {start}
        queue = deque([start])
        while queue:
            parent = queue.popleft()
            yield parent
            nd = sorted(
                G.degree(set(G[parent]) - visited).items(), key=itemgetter(1)
            )
            children = [n for n, d in nd]
            visited.update(children)
            queue.extend(children)

    def make_decisions(self):
        assigned_unit = self.__assigned_unit
        last_unit = self.__units[1]

        if not self.__source:
            self.__decisions = []
            return

        for elem in self.bf_ordering(self.__source[0]):
            one_hop = self.__instance.neighbors(elem)
            two_hop = [
                x
                for ns in [self.__instance.neighbors(y) for y in one_hop]
                for x in ns
            ]
            preferred1 = [
                assigned_unit[x]
                for x in one_hop
                if x in assigned_unit and assigned_unit[x].can_take(elem)
            ]
            preferred2 = [
                assigned_unit[x]
                for x in two_hop
                if x in assigned_unit and assigned_unit[x].can_take(elem)
            ]

            preferred = None
            if preferred1:
                preferred = max(preferred1)
            elif preferred2:
                preferred = max(preferred2)

            if preferred is not None:
                assigned_unit[elem] = preferred
                preferred.assign(elem)
                self.__decisions.append((elem, preferred))
            elif last_unit.can_take(elem):
                assigned_unit[elem] = last_unit
                last_unit.assign(elem)
                self.__decisions.append((elem, last_unit))
            else:
                try:
                    last_unit = self.__units[last_unit.num + 1]
                except KeyError:
                    print "ran out of units"
                assigned_unit[elem] = last_unit
                last_unit.assign(elem)
                self.__decisions.append((elem, last_unit))

    def __assign(self, a):
        z = self.__zoneRE.match(a)
        if z:
            (u,e) = z.groups()
            unit = self.__units[int(u)]
            elem = "z" + e
            self.__assigned_unit[elem].unassign(elem)
            unit.assign(elem)
            return
        s = self.__sensorRE.match(a)
        if s:
            (u,e) = s.groups()
            unit = self.__units[int(u)]
            elem = "s" + e
            self.__assigned_unit[elem].unassign(elem)
            unit.assign(elem)

    def __unassign(self, a):
        z = self.__zoneRE.match(a)
        if z:
            (u,e) = z.groups()
            unit = self.__units[int(u)]
            elem = "z" + e
            self.__assigned_unit[elem].unassign(elem)
            return
        s = self.__sensorRE.match(a)
        if s:
            (u,e) = s.groups()
            unit = self.__units[int(u)]
            elem = "s" + e
            self.__assigned_unit[elem].unassign(elem)

    def propagate(self, ctl, changes):
        for l in changes:
            try:
                for a in self.__lit_ress[l]:
                    self.__assign(a)
                    self.__impossible.add(a)
            except KeyError:
                pass
            try:
                for a in self.__lit_ress[-l]:
                    # if self.__zoneRE.match(a):
                        # print (a, "zone neg!")
                    self.__impossible.add(a)
            except KeyError:
                pass

    def decide(self, vsids):
        if not self.__decisions: 
            self.make_decisions()
            self.__decisions.reverse()
        while self.__decisions:
            (elem, unit) = self.__decisions.pop()
            predicate = "{}({},{})".format(
                    "unit2zone" if elem[0] == 'z' else "unit2sensor", 
                    unit.num, elem[1:])
            try:
                lit = self.__res_lits[predicate]
                if predicate in self.__impossible:
                    continue
                return lit
            except KeyError:
                print "unknown unit"
                return vsids
        return vsids

    def undo(self, thread_id, assign, changes):
        self.__decisions = []
        source_switched = False
        if self.__source:
            if self.__source[0].startswith("z"):
                rs = r"unit2zone\((\d+),{}\)".format(self.__source[0][1:])
            else:
                rs = r"unit2sensor\((\d+),{}\)".format(self.__source[0][1:])
            r = re.compile(rs)
            for l in changes:
                try:
                    for a in self.__lit_ress[abs(l)]:
                        if not source_switched and self.__source and r.match(a):
                            self.__source = self.__source[1:]
                            source_switched = True
                        self.__unassign(a)
                        self.__impossible.remove(a)
                except KeyError:
                    pass
