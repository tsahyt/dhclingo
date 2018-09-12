dhclingo
========

dhclingo is a Python wrapper around clingo extended with external heuristics
for using declarative heuristics.

Requirements
------------

The special clingo build supporting external heuristics must be in PATH as
`hclingo`. It should be built against Python 2.7, which is the default setting
when both Python 2.7 and Python 3 are available on the build system.

Usage
-----

To be executed from the same directory as the dhclingo files

```
./dhclingo -o examples/pup/pup-combined.lp examples/pup/pup-02.lp
```

The `-o` flag stands for "offline", which is the recommended mode. In offline
mode, the heuristic mediator will cache decisions, reducing the number of
heuristic solver runs.

For debug output, the `LOG` environment variable can be used. It supports three
levels, `LOG=0` (default), `LOG=1` (information output), `LOG=2` (full debug
output).
