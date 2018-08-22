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
#external partnerunits(U,P).

#heuristic partnerunits(U,P) : partnerunits(U,P). [-1000@-1000, true]

unit(U) :- comUnit(U).
zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

unitUsedAllZones(U) :- 2 { unit2zone(U,Z) : zone(Z) }, unit(U).
unitUsedAllSensors(U) :- 2 { unit2sensor(U,S) : sensor(S) }, unit(U).
usedUnit(U) :- unitUsedAllZones(U), unitUsedAllSensors(U).
availableUnit(U) :- not usedUnit(U), unit(U).

usedElem(z,Z) :- unit2zone(_,Z).
usedElem(s,S) :- unit2sensor(_,S).
availableElem(z,Z) :- not usedElem(z,Z), zone(Z).
availableElem(s,S) :- not usedElem(s,S), sensor(S).

canAssign(A,E,U) :- availableElem(A,E), availableUnit(U).

% QuickPup*
#heuristic unit2zone(U,Z) : visitedAt(z,Z,L), canAssign(z,Z,U). [-U@-L, true]
#heuristic unit2sensor(U,S) : visitedAt(s,S,L), canAssign(s,S,U). [-U@-L, true]

% Pred prefers units that are already connected to elements close in the input
% graph. If no such preferred unit can be found, we fall back to QuickPup*.
preferredUnit1(z,Z,U) :- canAssign(z,Z,U), unit2sensor(U,S), zone2sensor(Z,S).
preferredUnit1(s,S,U) :- canAssign(s,S,U), unit2zone(U,Z), zone2sensor(Z,S).
preferredUnit2(z,Z,U) :- 
    canAssign(z,Z,U), unit2zone(U,Z2), zone2sensor(Z,S), zone2sensor(Z2,S).
preferredUnit2(s,S,U) :- 
    canAssign(z,Z,U), unit2sensor(U,S2), zone2sensor(Z,S), zone2sensor(Z,S2).

#heuristic unit2zone(U,Z) : 
    visitedAt(z,Z,L), canAssign(z,Z,U), preferredUnit2(z,Z,U). [0@-L, true]
#heuristic unit2sensor(U,S) : 
    visitedAt(s,S,L), canAssign(s,S,U), preferredUnit2(s,S,U). [0@-L, true]
#heuristic unit2zone(U,Z) : 
    visitedAt(z,Z,L), canAssign(z,Z,U), preferredUnit1(z,Z,U). [1@-L, true]
#heuristic unit2sensor(U,S) : 
    visitedAt(s,S,L), canAssign(s,S,U), preferredUnit1(s,S,U). [1@-L, true]

% if no source is known, pick the lexicographically smallest possible
sourced :- source(X).
#heuristic source(Z) : zone(Z), not sourced. [-Z@0, true]
