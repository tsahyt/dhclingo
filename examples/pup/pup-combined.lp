% Main ---------------------------------------------------------------------------
#program base.

zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).
unit(U) :- comUnit(U).

1 { unit2zone(U,Z) : unit(U) } 1 :- zone(Z).
1 { unit2sensor(U,S) : unit(U) } 1 :- sensor(S).
:- unit(U), 3 { unit2zone(U,Z) : zone(Z) }.
:- unit(U), 3 { unit2sensor(U,S) : sensor(S) }.

partnerunits(U,P) :- unit2zone(U,Z), zone2sensor(Z,S), unit2sensor(P,S), U != P.
partnerunits(U,P) :- partnerunits(P,U), unit(U), unit(P).
:- unit(U), maxPU(M), M+1 { partnerunits(U,P) : unit(P) }.

% Heuristic Base -----------------------------------------------------------------
#program base_heuristic.
maxOrdinal(X) :- X = Z + S, Z = #max { A : zone(A) }, 
    S = #max { A : sensor(A) }.
step(0..M) :- maxOrdinal(M).

1 { source(Z) : zone(Z) } 1.
%source(1).

visitedAt(z,Z,1) :- source(Z).
visitedAt(s,Y,N+1) :- visitedAt(z,X,N), zone2sensor(X,Y), maxOrdinal(M), N<M, not step(K) : visitedAt(s,Y,K), K<N.
visitedAt(z,Y,N+1) :- visitedAt(s,X,N), zone2sensor(Y,X), maxOrdinal(M), N<M, not step(K) : visitedAt(z,Y,K), K<N.

% Heuristic Dynamic --------------------------------------------------------------
#program dynamic_heuristic.
#external source(Z).
#external unit2zone(U,Z).
#external unit2sensor(U,S).
#external visitedAt(A,X,O).

unit(U) :- comUnit(U).
zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

usedUnit(U) :- unit2zone(U,Z).
usedUnit(U) :- unit2sensor(U,S).
freeUnit(U) :- not usedUnit(U), unit(U).

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
_persist(usedSource(X)) :- source(X).

#heuristic source(Z) : zone(Z), not sourced, not usedSource(Z). [-Z@0, true]
