#script (python)

import dhclingo
import os

def main(prg):
    f = os.environ['HFILE']
    prg.set_heuristic(dhclingo.Declarative(f))
    prg.ground([("base", [])])
    prg.solve()

#end.
