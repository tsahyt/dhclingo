#external source(Z).
#external unit2zone(U,Z).
#external unit2sensor(U,S).
#external visitedAt(A,X,O).

% from instance file
unit(U) :- comUnit(U).
zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

unitUsedAllZones(U) :- unitCap { unit2zone(U,_) }, unit(U).
unitUsedAllSensors(U) :- unitCap { unit2sensor(U,_) }, unit(U).
usedUnit(U) :- unitUsedAllZones(U), unitUsedAllSensors(U).
availableUnit(U) :- not usedUnit(U), unit(U).

usedElem(z,Z) :- unit2zone(_,Z).
usedElem(s,S) :- unit2sensor(_,S).
availableElem(z,Z) :- not usedElem(z,Z), zone(Z).
availableElem(s,S) :- not usedElem(s,S), sensor(S).

canAssign(A,E,U) :- availableElem(A,E), availableUnit(U).

#heuristic unit2zone(U,Z) : visitedAt(z,Z,L), canAssign(z,Z,U). [-U@-L, true]
#heuristic unit2sensor(U,S) : visitedAt(s,S,L), canAssign(s,S,U). [-U@-L, true]

% if no source is known, pick the lexicographically smallest possible
sourced :- source(X).
#heuristic source(Z) : zone(Z), not sourced. [-Z@0, true]
