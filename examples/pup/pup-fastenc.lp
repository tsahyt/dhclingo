% Main ---------------------------------------------------------------------------
#program base.

elem(z,Z) :- zone2sensor(Z,D).
elem(d,D) :- zone2sensor(Z,D).

numb(A,N) :- elem(A,N), not elem(A,N+1).

zone :- numb(z,N), numb(d,M), N > M.

rule(z) :- zone.
rule(d) :- not zone.

{ gt(A,X,U) } :- elem(A,X), comUnit(U), comUnit(U1), U1=U+1.

:- gt(A,X,U), 1 < U, not gt(A,X,U-1).

unit2zone(1,Z)   :- elem(z,Z), comUnit(1), not gt(z,Z,1).
unit2zone(U+1,Z) :- gt(z,Z,U), not gt(z,Z,U+1).

:- comUnit(U), #count{ Z : unit2zone(U,Z) } > 2.
:- elem(z,Z), unit2zone(U1,Z), unit2zone(U2,Z), U1 != U2.

unit2sensor(1,D)   :- elem(d,D), comUnit(1), not gt(d,D,1).
unit2sensor(U+1,D) :- gt(d,D,U), not gt(d,D,U+1).

:- comUnit(U), #count{ D : unit2sensor(U,D) } > 2.
:- elem(d,D), unit2sensor(U1,D), unit2sensor(U2,D), U1 != U2.

partner(d,D,U) :- unit2zone(U,Z), rule(d), zone2sensor(Z,D).
partner(z,Z,U) :- unit2sensor(U,D), rule(z), zone2sensor(Z,D).

partnerunits(U,P) :- partner(d,D,U), unit2sensor(P,D), U < P.
partnerunits(P,U) :- partner(d,D,U), unit2sensor(P,D), P < U.
partnerunits(U,P) :- partner(z,Z,U), unit2zone(P,Z), U < P.
partnerunits(P,U) :- partner(z,Z,U), unit2zone(P,Z), P < U.
partnerunits(U,P) :- partnerunits(P,U), P < U.

:- comUnit(U), maxPU(M), #count{ P : partnerunits(U,P) } > M.

% Heuristic Base -----------------------------------------------------------------
#program base_heuristic.
maxOrdinal(X) :- numb(z,N), numb(d,M), X = N + M.
step(0..M) :- maxOrdinal(M).

1 { source(Z) : elem(z,Z) } 1.
%source(1).

visitedAt(z,Z,1) :- source(Z).
visitedAt(d,Y,N+1) :- visitedAt(z,X,N), zone2sensor(X,Y), maxOrdinal(M), N<M, not step(K) : visitedAt(d,Y,K), K<N.
visitedAt(z,Y,N+1) :- visitedAt(d,X,N), zone2sensor(Y,X), maxOrdinal(M), N<M, not step(K) : visitedAt(z,Y,K), K<N.

% Heuristic Dynamic --------------------------------------------------------------
#program dynamic_heuristic.
#external source(Z).
#external unit2zone(U,Z).
#external unit2sensor(U,S).
#external visitedAt(A,X,O).

usedUnit(U) :- unit2zone(U,Z).
usedUnit(U) :- unit2sensor(U,S).
freeUnit(U) :- not usedUnit(U), comUnit(U).

% New Unit
#heuristic unit2zone(U,Z) : visitedAt(z,Z,L), freeUnit(U). [-U@-L, true]
#heuristic unit2sensor(U,S) : visitedAt(s,S,L), freeUnit(U). [-U@-L, true]

% Pred prefers units that are already connected to elements close in the input
% graph. If no such preferred unit can be found, we use a new unit (see above)
preferredUnit(z,Z,U,1) :- unit2sensor(U,S), zone2sensor(Z,S).
preferredUnit(s,S,U,1) :- unit2zone(U,Z), zone2sensor(Z,S).
preferredUnit(z,Z,U,0) :- unit2zone(U,Z2), zone2sensor(Z,S), zone2sensor(Z2,S).
preferredUnit(s,S,U,0) :- unit2sensor(U,S2), zone2sensor(Z,S), zone2sensor(Z,S2).

#heuristic unit2zone(U,Z) : 
    visitedAt(z,Z,L), usedUnit(U), preferredUnit(z,Z,U,W). [W@-L, true]
#heuristic unit2sensor(U,S) : 
    visitedAt(s,S,L), usedUnit(U), preferredUnit(s,S,U,W). [W@-L, true]

% if no source is known, pick the lexicographically smallest possible
sourced :- source(X).
#heuristic source(Z) : elem(z,Z), not sourced. [-Z@0, true]
