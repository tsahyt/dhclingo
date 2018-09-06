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
* can perform well compared to other general purpose approaches, e.g. for configuration problems [see @aschinger_optimization_2011]

------

No silver bullet, complex instances can still be prohibitively slow

. . .

Domain-specific heuristics may help!

------

## Why Heuristics?

* Specialized solvers outperform ASP.
* The QuickPup solver [see @teppan_quickpup:_2012] was able to solve all instances it was benchmarked on, ASP at the time was not.
* Clingo 5.3 still only solves around 70% of the PUP instances in the ASP competition set in our benchmarks.
* Equipped with a domain-specific heuristic written directly into the solver, @musitsch_improving_2016 was able to solve 100% of tested PUP instances.

------

## PUP with HWASP {data-background-color="#fff"}

![](figures/pup-hwasp.svg){width=70%}

------

How to teach an ASP solver a new heuristic?

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
* or *domain-specific* heuristics

# History {data-background-color="#a30"}

Domain-specific heuristics in ASP are not new

## Clingo Domain Heuristics

Domain heuristics for Clingo introduced in @gebser_domain-specific_2013

. . .

Allows influencing the general purpose heuristic via modifiers

------

It is declarative, e.g.

```
#heuristic holds(F, T-1) : holds(F,T). [l-T+1@0, true]
#heuristic holds(F, T-1) : fluent(F), time(T), not holds(F,T). [l-T+1@0, false]
```

. . .

Facts that hold are assumed to have held in the past. Falsehoods are believed to have been false before.

------

@calimeri_combining_2015 used this interface to attack the Combined Configuration Problem.

1. A greedy algorithm is presented to calculate an approximate solution first
2. The "solution" is handed to the solver by giving the solution atoms a higher heuristic value
3. The solver is then expected to sort out any remaining problems

------

## CCP Evaluation {data-background-color="#fff"}
![](figures/ccp-exp2.svg){width=60%}

The combined Greedy & ASP approach was able to solve all 100 instances, versus 54 plain.

------

However, **expressivity** is limited due to evaluation semantics.

. . .

e.g. a simple bin packing heuristic already requires *fixing an ordering upfront*.


## HWasp

@dodaro_driving_2016 present a low-level interface to the WASP solver, allowing the implementation of domain specific heuristics.

------

@musitsch_improving_2016 demonstrates great improvements over general purpose heuristics on industrial problems.

 Problem   Clasp  Best Heuristic
--------- ------ ---------------
PUP         23              36
CCP          3              36
SMP          4              30

------

Purely procedural interface, requiring knowledge of solver internals, as well as rebuilding the solver.

::: notes
A Python interface exists, but still requires knowledge of the solver internals
:::

# Declarative Heuristics {data-background-color="#582"}

## Overview { data-background-color="#fff" }

![](figures/sequence-diagram.svg){width=60%}

## Low-Level
Can we keep changes to the solver minimal while exhibiting a uniform and stable interface?

. . .

**Idea**: Allow implementation of `decide` externally and let it manage its own state.

------

No knowledge of solver internals required. Only literals need to be known for decisions.

------

But it is still procedural

## Declarativity

We want to use ASP to describe heuristics for ASP.

→ Use a second solver!

------

### How it works

+ User defines two programs
    1. *Main* program
    2. *Heuristic* program
* The heuristic is computed separately *as needed* to make decisions in the *main* solver.
* Main solver tells the heuristic about changes, so it can adapt.
* Repeat until a solution is found.

## Example

Bin-Packing

```
1 { place(I,B) : bin(B) } 1 :- item(I,_).
:- bin(B), capacity(C), F > C, 
    F = #sum { S,I : item(I,S), place(I,B) }.

#program dynamic_heuristic.
#watch place/2.

placed(I) :- place(I,_).

#heuristic place(I,B) : 
    bin(B), item(I,W), capacity(C), not placed(I),
    S = #sum { X,I1 : place(I1,B), item(I1,X) }, 
    C >= S + W. [-S-I@0, true]
```

------

### Observations

+ No ordering required upfront!
+ Fully declarative
+ Negation behaves as ASP users expect
* Aggregates can *always* get evaluated

# References

------
