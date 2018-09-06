---
title: Declarative Heuristics for ASP
author: Dipl.-Ing. Paul Ogris
institute: AAU Klagenfurt
date: 2018-09-11
bibliography: slides.bib
link-citations: true
---

Answer Set Programming (*ASP*) 

* is a declarative programming paradigm
* provides a means to easily model hard combinatorial search problems
* can perform well compared to other general purpose approaches, e.g. for configuration problems [see @aschinger_optimization_2011]

TODO: details of configuration problem

------

No silver bullet, complex instances can still be prohibitively slow

. . .

Domain-specific heuristics may help!

------

## Why Heuristics?

* Specialized solvers outperform ASP
* The QuickPup solver [see @teppan_quickpup:_2012] was able to solve all instances it was benchmarked on, ASP at the time was not
* Clingo 5.3 still only solves around 70% of the PUP instances in the ASP competition set in our benchmarks

------

## PUP with HWASP {data-background-color="#fff"}

![](figures/pup-hwasp.svg){width=60%}

Equipped with a domain-specific heuristic written directly into the solver, @musitsch_improving_2016 was able to solve 100% of tested PUP instances

------

How to teach an ASP solver a new heuristic?

------

Modern ASP solvers use some variation of the CDCL algorithm

TODO: clearer explanation

```
if (unitPropagation(φ,ν) == conflict):
    return UNSAT
while not all variables assigned:
    literal ← decide(φ,ν)
    ν ← ν ∪ {literal}
    if (unitPropagation(φ,ν) == conflict):
        β ← conflictAnalysis(φ,ν)
        if (β < 0):
            return UNSAT
        else:
            backtrack(φ,ν,β)
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

* Allows influencing the general purpose heuristic via modifiers
* It is fully declarative

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

------

```
1 { place(I,B) : bin(B) } 1 :- item(I,_).
:- bin(B), capacity(C), F > C, 
    F = #sum { S,I : item(I,S), place(I,B) }.

#heuristic place(I,B) : 
    bin(B), item(I,W), capacity(C),
    S = #sum { X,I1 : place(I1,B), item(I1,X), I1 < I }, 
    C >= S + W. [S+I, true]
```

------


## HWasp

@dodaro_driving_2016 present a low-level interface to the WASP solver, allowing the implementation of domain specific heuristics.

------

@musitsch_improving_2016 demonstrates great improvements over general purpose heuristics on industrial problems.

 Problem   Clasp  Best Heuristic
--------- ------ ---------------
PUP         23              36
CCP          3              36

------

Purely procedural interface, requiring knowledge of solver internals, as well as rebuilding the solver.

::: notes
A Python interface exists, but still requires knowledge of the solver internals
:::

# Declarative Heuristics {data-background-color="#582"}

-------

We want to use ASP to describe heuristics for ASP.

. . .

→ Use a second solver!

## How it works

+ User defines two programs
    1. *Main* program
    2. *Heuristic* program
* The heuristic is computed separately *as needed* to make decisions in the *main* solver.
* Main solver tells the heuristic about changes, so it can adapt.
* Repeat until a solution is found.

## Overview { data-background-color="#fff" }

![](figures/sequence-diagram.svg){width=60%}

TODO: example for fallback in second solver call

## Observations

+ Fully declarative
+ Negation behaves as ASP users expect
* Aggregates can *always* get evaluated

## Proof Of Concept

* We expose `decide` from Clasp for external implementation (C or Python)
* The external heuristic keeps its own state, does not care about solver internals
* Can also register as a propagator to receive updates on watched literals
* Our Proof-of-Concept is an external heuristic written in Python handling a second heuristic solver
* Registers and manages watched literals as required
* Handles caching of decisions

## Language

Special Atoms
: `vsids` and `resign`

Persistence
: `#persist` can be used to remember decisions between invocations

Watching
: Inputs are set with `#watch`

Decisions
: `#heuristic` marks heuristic rules.

TODO: explain base_heuristic

:::notes
`vsids` switches to VSIDS for *one* decision, `resign` is permanent.
:::

## Example

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
    C >= S + W. [S+I@0, true]
```

::: notes
Note that there is no ordering required in the aggregate, and that there is a negative literal in the body
:::


# References

------
