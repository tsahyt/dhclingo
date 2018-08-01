zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

usedUnit(U) :- unit2zone(U,_).
usedUnit(U) :- unit2sensor(U,_).
availableUnit(U) :- not usedUnit(U), unit(U).

usedElem(z,Z) :- unit2zone(_,Z).
usedElem(s,S) :- unit2sensor(_,S).
availableElem(z,Z) :- not usedElem(z,Z), zone(Z).
availableElem(s,S) :- not usedElem(s,S), sensor(S).

canAssign(A,E,U) :- availableElem(A,E), availableUnit(U).

% heuristic(unit2zone(U,Z),-U,-L,true) :- visitedAt(z,Z,L), canAssign(z,Z,U).
#heuristic unit2zone(U,Z) : visitedAt(z,Z,L), canAssign(z,Z,U). [-U@-L, true]
% heuristic(unit2sensor(U,S),-U,-L,true) :- visitedAt(s,S,L), canAssign(s,S,U).
#heuristic unit2sensor(U,S) : visitedAt(s,S,L), canAssign(s,S,U). [-U@-L, true]

% if no source is known, pick the lexicographically smallest possible
sourced :- source(X).
% heuristic(source(Z),-Z,0,true) :- zone(Z), not sourced.
#heuristic source(Z) : zone(Z), not sourced. [-Z@0, true]
