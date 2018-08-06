#script (python)

import dhclingo
import os

def main(prg):
    f = os.environ['HFILE']
    i = os.environ['IFILE']
    o = os.environ['OFFLINE']
    prg.set_heuristic(dhclingo.Declarative(f,i,o == '1'))
    prg.ground([("base", [])])
    prg.solve()

#end.
