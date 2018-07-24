#!/usr/bin/env python
# -*- coding: utf-8 -*-

class Declarative(object):
    """docstring for Declarative"""
    def __init__(self, hfile):
        super(Declarative, self).__init__()
        self.hfile = hfile
    
    def decide(self,vsids):
        return vsids

    def init(self, init):
        pass
