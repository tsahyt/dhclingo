---
title: Declarative Heuristics for ASP
author: Dipl.-Ing. Paul Ogris, AAU Klagenfurt
date: 2018-09-11
bibliography: slides.bib
link-citations: true
---

Answer Set Programming (*ASP*) 

* is a declarative programming paradigm
* provides a means to easily model hard combinatorial search problems
* can perform well [see @aschinger_optimization_2011] compared to other general purpose approaches.

------

No silver bullet, complex instances can still be prohibitively slow

. . .

Domain-specific heuristics can help!

------

* Specialized solvers outperform ASP.
* The QuickPup solver [see @teppan_quickpup:_2012] was able to solve all instances it was benchmarked on, ASP at the time was not.
* Clingo 5.3 still only solves around 70% of the PUP instances in the ASP competition set in our benchmarks.
* Equipped with a domain-specific heuristic written directly into the solver, ASP still shows great promise [@musitsch_improving_2016]

------

How to teach an ASP a new heuristic?

------

Modern ASP solvers use some variation of the CDCL algorithm

```
if (unitPropagation(φ,ν) == conflict):
    return UNSAT
while not all variables assigned:
    (x, v) ← decide(φ,ν)
    dl ← dl + 1
    ν ← ν ∪ {(x,v)}
    if (unitPropagation(φ,ν) == conflict):
        β ← conflictAnalysis(φ,ν)
        if (β < 0):
            return UNSAT
        else:
            backtrack(φ,ν,β)
            dl ← β
return SAT
```

. . .

A non-deterministic decision happens in `decide`!

-------

`decide` can be anything that returns a literal!

* General purpose heuristics like *VSIDS* or *BerkMin*
* Also *domain-specific* heuristics

# History

Domain-specific heuristics in ASP are not new

## Clingo Domain Heuristics

Domain heuristics for Clingo introduced in @gebser_domain-specific_2013

------

Allows influencing the VSIDS heuristic via modifiers

* sign (true, false)
* level 
* factor
* init

------

A simple planning heuristic

```
#heuristic holds(F, T-1) : holds(F,T). [l-T+1@0, true]
#heuristic holds(F, T-1) : fluent(F), time(T), not holds(F,T). [l-T+1@0, false]
```

. . .

Facts that hold are assumed to have held in the past. Falsehoods are believed to have been false before.

## HWasp

# Procedural Heuristics with Clingo

# Declarative Heuristics
