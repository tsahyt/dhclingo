{ b }.

1 { a(N) : N = 1..5 } 1.

% ------------------------------------------------------------------------------
#program dynamic_heuristic.

#external a(X).

hasA :- a(X).

_persist(used(X)) :- a(X).

#heuristic b : hasA. [0@0, true]
#heuristic a(X) : not hasA, not used(X), X = 1..5. [-X@1, true]
