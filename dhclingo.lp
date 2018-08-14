#script (python)

import dhclingo
import os

def main(prg):
    m = os.environ['MFILE']
    o = os.environ['OFFLINE']
    splitter = dhclingo.HeuristicSplitter(m)

    with prg.builder() as b:
        for a in splitter.base_program:
            b.add(a)

    prg.set_heuristic(dhclingo.Declarative(splitter.get_heuristic_str(),o == '1'))

    prg.ground([("base", [])])
    prg.solve()

#end.
