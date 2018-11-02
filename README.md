dhclingo
========

`dhclingo` is a Python wrapper around clingo extended with external heuristics
for using declarative heuristics.

Requirements
------------

The special clingo build supporting external heuristics must be in PATH as
`hclingo`. It should be built against Python 2.7, which is the default setting
when both Python 2.7 and Python 3 are available on the build system.

Usage
-----

To be executed from the same directory as the dhclingo files, e.g.

```
./dhclingo examples/pup/pup-combined.lp examples/pup/pup-02.lp
```

`dhclingo` supports the following arguments

* `-o`. This enables offline mode. In offline mode, the heuristic mediator will
  cache decisions, reducing the number of heuristic solver runs. Note that this
  lowers the "responsiveness" of the heuristic, as cached decisions will be
  used even if they are no longer "valid" after previous changes to the partial
  assignment.
* `-c`. Enables posting of conflicts whenever the heuristic does not make
  a decision. The nogood to be posted is the set of previously made decisions.
* `-r`. Restart heuristic on one-step backtracking.
* `-h`. Post help

For debug output, the `LOG` environment variable can be used. It supports three
levels, `LOG=0` (default), `LOG=1` (information output), `LOG=2` (full debug
output). A fourth level can be accessed with `LOG=3`, which dumps heuristic
programs to `/tmp` whenever no decision is made by the heuristic.

Caveat
------

`dhclingo` is tested with Clingo linked against Python 2.7. It may or may not
work when Clingo links against Python 3.
