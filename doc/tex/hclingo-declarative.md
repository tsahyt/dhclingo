Declarative Heuristics with HClingo

# HClingo

HClingo is a fork of the Clingo Answer Set Solver which allows using *external
decision heuristics* to steer the search process. To achieve this, it exposes
a function via its C and Python APIs which registers a callback with the
solver. The callback function is expected to return some literal when called.
This literal is then used to make the next non-deterministic decision.

The callback function can share data with a standard Clingo propagator. As
a result, users have access to the entire propagator API when implementing
their decision heuristics. This means that a heuristic can get notified about
changes in literals through watches.

# Declarative Heuristics

DHClingo is a frontend to HClingo providing a way to implement decision
heuristics *declaratively* using ASP itself as a language. To this end we
require three ASP programs in total. The first is the *main program*, which
constitutes the encoding of the problem we want to solve, *without* any
instance specific data. The second is the *instance file*, providing the
instance specific data omitted from the main program. The last is the
*heuristic program*, which declares the heuristic to be used during solving. We
repurpose two syntactic constructs already available in Clingo for use in the
heuristic program, i.e. they receive special semantics.

External atoms are defined in Clingo using the `#external` directive. DHClingo
uses `#external` to gain access to atoms in the main program. They can be
thought of as "inputs" to the heuristic. Consider the following line from a Bin
Packing heuristic:

    ```asp
    #external place(I,B) : item(I,_), bin(B).
    ```

Clingo also provides a way to define domain specific heuristics declaratively,
albeit with a different semantics than DHClingo. We repurpose the available
`#heuristic` directive in DHClingo. Atoms found in the head of such a directive
can be thought of as "outputs" of the heuristic. A heuristic directive in
Clingo comes with a *bias*, a *priority*, and a *modifier*. Our version comes
with a *weight*, a *level*, and a *sign* instead. Consider the following line
from a Partner Units heuristic.

    ```asp
    #heuristic unit2zone(U,Z) : visitedAt(z,Z,L), canAssign(z,Z,U). [-U@-L, true]
    ```

This line states that `unit2zone(U,Z)` shall be made `true` with weight $-U$ on
level $-L$ when the given body has been derived. The weight and level
annotation is analogous to weak constraints. When two heuristic decisions have
been derived, one of which has a higher level than the other, the one with the
higher level is always preferred. If both have the same level, the one with the
higher weight is preferred. If both have the same level *and* weight, DHClingo
makes no guarantees as to which of the two literals will be picked for the
current non-deterministic decision.

There are two special atoms which can be picked with a heuristic directive. The
`vsids` atom will defer the *current* decision to the VSIDS fallback heuristic.
This can be useful for heuristics that can only make decisions in some
situations and want to refer back to a general purpose decision heuristic
otherwise. The `resign` atom will *permanently* disable the custom decision
heuristic. After resigning, the solver falls back to VSIDS for every future
decision. This is useful for heuristics which can generate some approximate
solution upfront and then expect the solver to repair any remaining problems.

The usage of these special atoms is the same as for any other atom that can be
decided on by the heuristic. For example, consider

    ```asp
    #heuristic vsids. [0@0, true]
    ```

The primitives introduced so far support the encoding of *stateless* heuristics,
that is heuristics which depend only on the current assignment. Sometimes it is
necessary to keep track of past decisions in the heuristic to inform the current
decision. To facilitate this, we introduce a `persist` primitive. It takes the
shape of a special directive `#persist a : b.` which states that `a` follows
*persistently* from `b`. Once `a` has been derived persistently it will be added
as a fact to the knowledge base of the heuristic, i.e. it will be true in all
future invocations of the heuristic. We show a real world example of this
mechanism in our case study on the Partner Units Problem below.

Finally, we provide two modes of operation. The default mode is for the
heuristic to operate as an *online* heuristic. This means that the heuristic is
recalculated on every decision made by the solver. In contrast an *offline*
heuristic calculates a full list of future decisions and then passes them to
the solver one after the other. Only when those decisions have been exhausted
is the heuristic run again. Offline heuristics can be combined with the
`resign` atom.

## Basic Implementation

DHClingo is implemented on top of HClingo in Python. It works by running two
instances of Clingo. One instance represents the main program, whereas the
other is used to calculate the heuristic. It dynamically creates a *heuristic
program* from its inputs and the current assignment in the main solver. All
`#heuristic` directives in the input heuristic program are rewritten to
heuristic rules of the form `_heuristic(head, W, L, S) :- body` where `W` is the
weight, `L` the level, and `S` the sign as given by a heuristic directive
`#heuristic head : body. [W@L,S]`.

DHClingo registers a propagator and a heuristic with the main solver. All
inputs (defined using `#external`) and outputs (defined using `#heuristic`) are
registered as watches with the solver, such that the heuristic is notified of
changes to those atoms.

On every non-deterministic decision, DHClingo computes a model of the heuristic
program with respect to the current assignment of the main program and extracts
all `heuristic/4` atoms. When running in offline mode, this is only done on
demand, and the complete results are cached. The atoms are sorted in accordance
with their weight and level and the maximal atom w.r.t this ordering which is
also compatible with the current assignment is returned to the main solver.

Persistent derivations, defined via the `#persist` directive, are also
transformed into normal rules. `#persist a : b.` is translated to `_persist(a)
:- b.`. When a `_persist/1` predicate occurs in the heuristic model, the
contained symbol will be added to a set from which facts will be drawn for
future heuristic programs.

# Case Studies

## Bin Packing

Consider a simple bin packing encoding with instance predicates `bin/1`,
`item/2`, and `capacity/1`.

```asp
1 { place(I,B) : bin(B) } 1 :- item(I,_).
:- bin(B), capacity(C), F > C, F = #sum { S,I : item(I,S), place(I,B) }.
```

We can define a heuristic program as follows

    ```asp
    #external place(I,B) : item(I,_), bin(B).

    placed(I) :- place(I,_).

    #heuristic place(I,B) : 
        bin(B), item(I,W), capacity(C), not placed(I),
        S = #sum { X,I1 : place(I1,B), item(I1,X) }, 
        C >= S + W. [-S-I@0, true]
    ```

This corresponds to a Best-Fit heuristic. Best-Fit places a previously unplaced
item in the bin into which it fits best, i.e. the bin in which the *least*
amount of space is *left over* after placement. To achieve this the heuristic
requires all current placements, which is declared in the first line using
`#external`. It derives whether an item is placed. When an item is not placed,
it can still be placed by the heuristic. The level and weight are set such that
the item/bin pair with the least amount of leftover space after placement is
preferred.

## Partner Units Problem

## Combined Configuration
