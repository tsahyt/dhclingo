% Declarative Heuristics for ASP
% Dipl.-Ing. Paul Ogris
% Alpen-Adria Universität Klagenfurt

Answer Set Programming (*ASP*) has been used successfully to solve hard combinatorial search problems in industrial domains

------

No silver bullet, large instances can still be prohibitively slow

. . .

**Use Heuristics!**

------

Modern ASP solvers use some variation of the CDCL algorithm

```
if (unitPropagation(φ,ν) == conflict):
    return UNSAT
while not all variables assigned:
    (x, v) ← decide(φ,ν)
    dl ← dl + 1
    nu ← nu ∪ {(x,v)}
    if (unitPropagation(φ,ν) == conflict):
        β ← conflictAnalysis(φ,ν)
        if (β < 0):
            return UNSAT
        else:
            backtrack(φ,ν,β)
            dl ← β
return SAT
```

-------

`decide` can be anything that returns a literal!

. . .

General purpose heuristics are available

* VSIDS
* VMTF
* BerkMin
* ...

------

General purpose heuristics do not always perform well

→ Use *domain specific heuristics* instead

. . .

The ASP solver needs to support the use of special heuristics

------

# Related Work

## HWasp

::: incremental

+ foo
+ bar

:::

## Clingo Domain Heuristics

quux

------

bar

# Procedural Heuristics with Clingo

# Declarative Heuristics


