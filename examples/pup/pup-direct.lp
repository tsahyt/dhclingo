% Main ---------------------------------------------------------------------------
#program base.

zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

1 { unit2zone(U,Z) : comUnit(U) } 1 :- zone(Z).
1 { unit2sensor(U,S) : comUnit(U) } 1 :- sensor(S).
:- comUnit(U), 3 { unit2zone(U,Z) : zone(Z) }.
:- comUnit(U), 3 { unit2sensor(U,S) : sensor(S) }.

{ partnerunits(U,P) } :- comUnit(U), comUnit(P), U != P.
:- not partnerunits(U,P), unit2zone(U,Z), unit2sensor(P,S), zone2sensor(Z,S), U != P.

partnerunits(U,P) :- partnerunits(P,U), comUnit(U), comUnit(P).
:- comUnit(U), maxPU(M), M+1 { partnerunits(U,P) : comUnit(P) }.

% Heuristic Base -----------------------------------------------------------------
#program base_heuristic.
maxOrdinal(X) :- X = Z + S, Z = #max { A : zone(A) }, 
    S = #max { A : sensor(A) }.
step(0..M) :- maxOrdinal(M).

% 1 { source(Z) : zone(Z) } 1.
source(1).

visitedAt(z,Z,1) :- source(Z).
visitedAt(s,Y,N+1) :- visitedAt(z,X,N), zone2sensor(X,Y), maxOrdinal(M), N<M, not step(K) : visitedAt(s,Y,K), K<N.
visitedAt(z,Y,N+1) :- visitedAt(s,X,N), zone2sensor(Y,X), maxOrdinal(M), N<M, not step(K) : visitedAt(z,Y,K), K<N.

maxLevel(X) :- #max { L : visitedAt(_,_,L) } = X.

% Heuristic Dynamic --------------------------------------------------------------
#program dynamic_heuristic.
#external unit2zone(U,Z).
#external unit2sensor(U,S).
#external visitedAt(A,X,O).
#external maxLevel(X).

% zone(Z) :- zone2sensor(Z,S).
% sensor(S) :- zone2sensor(Z,S).

lastUnit(U) :- U = #max { X : unit2zone(X,_) ; X : unit2sensor(X,_); 0 }.
freshUnit(U+1) :- lastUnit(U), comUnit(U+1).

full(U,z) :- comUnit(U), 2 = #count { Z : unit2zone(U,Z) }.
full(U,s) :- comUnit(U), 2 = #count { S : unit2sensor(U,S) }.

% Current level of the ordering
unusedOn(N) :- visitedAt(A,X,N), not usedElem(A,X).
currentLevel(N) :- N = #min { X : unusedOn(X) }.

% Current element, lexicographically smallest in current level
usedElem(z,X) :- unit2zone(_,X).
usedElem(s,X) :- unit2sensor(_,X).
currentElem(A,X) :- currentLevel(L), (X,A) = #min { (X1,A1) : visitedAt(A1,X1,L), not usedElem(A1,X1) }.

% Preferred Units
preferredUnit(z,Z,U) :- unit2sensor(U,S), zone2sensor(Z,S).
preferredUnit(s,S,U) :- unit2zone(U,Z), zone2sensor(Z,S).
preferredUnit(z,Z,U) :- unit2zone(U,Z2), zone2sensor(Z,S), zone2sensor(Z2,S).
preferredUnit(s,S,U) :- unit2sensor(U,S2), zone2sensor(Z,S), zone2sensor(Z,S2).

% First, try to place the current element at a preferred unit
rule1(U,A,X) :- preferredUnit(A,X,U), currentElem(A,X), not full(U,A).
rule1 :- rule1(_,_,_).
#heuristic unit2sensor(U,S) : rule1(U,s,S). [0@0, true]
#heuristic unit2zone(U,Z) : rule1(U,z,Z). [0@0, true]

% Second, try to place it on a new unit
rule2(U,A,X) :- not rule1, freshUnit(U), currentElem(A,X).
#heuristic unit2sensor(U,S) : rule2(U,s,S). [0@0, true]
#heuristic unit2zone(U,Z) : rule2(U,z,Z). [0@0, true]

#heuristic _resign : maxLevel(M). [0@M+2, true]
#heuristic partnerunits(U,U+1) : comUnit(U), comUnit(U+1). [0@-1, true]
