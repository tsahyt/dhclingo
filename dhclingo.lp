#script (python)

import dhclingo
import os

def main(prg):
    m = os.environ['MFILE']
    o = os.environ['OFFLINE']
    prg.set_heuristic(dhclingo.Declarative(m,o == '1'))
    prg.ground([("base", [])])
    prg.solve()

#end.
