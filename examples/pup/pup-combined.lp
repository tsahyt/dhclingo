#include <dhclingo>.

% Main ---------------------------------------------------------------------------
#program base.
#const unitCap = 2.
#const interUnitCap = 2.

zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).
unit(U) :- comUnit(U).

1 { unit2zone(U,Z) : unit(U) } 1 :- zone(Z).
1 { unit2sensor(U,S) : unit(U) } 1 :- sensor(S).
:- unit(U), unitCap+1 { unit2zone(U,Z) : zone(Z) }.
:- unit(U), unitCap+1 { unit2sensor(U,S) : sensor(S) }.

partnerunits(U,P) :- unit2zone(U,Z), zone2sensor(Z,S), unit2sensor(P,S), U != P.
partnerunits(U,P) :- partnerunits(P,U), unit(U), unit(P).
:- unit(U), interUnitCap+1 { partnerunits(U,P) : unit(P) }.

% Heuristic Base -----------------------------------------------------------------
#program base_heuristic.
maxOrdinal(X) :- X = Z + S, Z = #max { A : zone(A) }, 
    S = #max { A : sensor(A) }.
orderStep(1..X) :- maxOrdinal(X).

1 { source(Z) : zone(Z) } 1.

visitedAt(z,Z,1) :- source(Z).
visitedAt(s,S,O) :- visitedAt(z,Z,O-1), orderStep(O), 
    zone2sensor(Z,S), not visitedBefore(s,S,O).
visitedAt(z,Z,O) :- visitedAt(s,S,O-1), orderStep(O), 
    zone2sensor(Z,S), not visitedBefore(z,Z,O).

visitedBefore(A,Z,O) :- orderStep(O), visitedAt(A,Z,P), O > P.

% Heuristic Dynamic --------------------------------------------------------------
#program dynamic_heuristic.
#external source(Z).
#external unit2zone(U,Z).
#external unit2sensor(U,S).
#external visitedAt(A,X,O).

#const unitCap = 2.
#const interUnitCap = 2.

unit(U) :- comUnit(U).
zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

unitUsedAllZones(U) :- unitCap { unit2zone(U,Z) : zone(Z) }, unit(U).
unitUsedAllSensors(U) :- unitCap { unit2sensor(U,S) : sensor(S) }, unit(U).
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
