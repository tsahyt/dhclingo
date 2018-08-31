#program base.
unit(1..3).
elem(1..5).

{ a(X,U) } :- elem(X), unit(U), unit(U1), U1=U+1.
:- a(X,U), 1 < U, not a(X,U-1).

b(1,Z)   :- elem(Z), unit(1), not a(Z,1).
b(U+1,Z) :- a(Z,U), not a(U+1).

:- unit(U), #count{ Z : b(U,Z) } > 2.
:- b(U1,Z), b(U2,Z), U1 != U2.

#program dynamic_heuristic.
#heuristic b(U,Z) : unit(U), elem(Z). [-Z@-U, true]
