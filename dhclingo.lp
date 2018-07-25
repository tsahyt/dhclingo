#script (python)

import dhclingo
import os

def main(prg):
    f = os.environ['HFILE']
    i = os.environ['IFILE']
    prg.set_heuristic(dhclingo.Declarative(f,i))
    prg.ground([("base", [])])
    prg.solve()

#end.
