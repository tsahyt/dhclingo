% Main ---------------------------------------------------------------------------
#program base.

zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).
unit(U) :- comUnit(U).

1 { unit2zone(U,Z) : unit(U) } 1 :- zone(Z).
1 { unit2sensor(U,S) : unit(U) } 1 :- sensor(S).
:- unit(U), 3 { unit2zone(U,Z) : zone(Z) }.
:- unit(U), 3 { unit2sensor(U,S) : sensor(S) }.

% does not work:
% partnerunits(U,P) :- unit2zone(U,Z), zone2sensor(Z,S), unit2sensor(P,S), U != P.

% does work:
{ partnerunits(U,P) } :- unit(U), unit(P), U != P.
:- not partnerunits(U,P), unit2zone(U,Z), unit2sensor(P,S), zone2sensor(Z,S), U != P.

% symmetry and interunit cap
partnerunits(U,P) :- partnerunits(P,U), unit(U), unit(P).
:- unit(U), maxPU(M), M+1 { partnerunits(U,P) : unit(P) }.

% partial assignment:
% unit2zone(1,1). unit2zone(1,11). unit2zone(2,2). unit2zone(3,3). unit2zone(3,12).
% unit2sensor(1,1). unit2sensor(1,2). unit2sensor(2,20). unit2sensor(2,3). unit2sensor(3,4).
% partnerunits(U,P) :- comUnit(U), comUnit(P), P = U + 1.

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

maxLevel(X) :- #max { L : visitedAt(_,_,L) } = X.

% Heuristic Dynamic --------------------------------------------------------------
#program dynamic_heuristic.
#external source(Z).
#external unit2zone(U,Z).
#external unit2sensor(U,S).
#external visitedAt(A,X,O).
#external maxLevel(X).

unit(U) :- comUnit(U).
zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

% New Unit
maxUnit(U) :- #max { X : unit2zone(X,_) ; X : unit2sensor(X,_); 0 } = U.
nextUnit(U+1) :- maxUnit(U), comUnit(U+1).

#heuristic unit2zone(U,Z) : visitedAt(z,Z,L), nextUnit(U), maxLevel(M). [L@M+1, true]
#heuristic unit2sensor(U,S) : visitedAt(s,S,L), nextUnit(U), maxLevel(M). [L@M+1, true]

% Pred prefers units that are already connected to elements close in the input
% graph. If no such preferred unit can be found, we use a new unit (see above)
preferredUnit(z,Z,U,0) :- unit2sensor(U,S), zone2sensor(Z,S).
preferredUnit(s,S,U,0) :- unit2zone(U,Z), zone2sensor(Z,S).
preferredUnit(z,Z,U,1) :- unit2zone(U,Z2), zone2sensor(Z,S), zone2sensor(Z2,S).
preferredUnit(s,S,U,1) :- unit2sensor(U,S2), zone2sensor(Z,S), zone2sensor(Z,S2).

minPreferredUnit(U) :- #min { X : preferredUnit(_,_,X,_); 1 } = U, comUnit(U).

#heuristic unit2zone(U,Z) : 
    visitedAt(z,Z,L), preferredUnit(z,Z,U,W). [W-U@L, true]
#heuristic unit2sensor(U,S) : 
    visitedAt(s,S,L), preferredUnit(s,S,U,W). [W-U@L, true]

#heuristic unit2zone(U,Z) : visitedAt(z,Z,L), minPreferredUnit(Min), maxUnit(Max), Min <= U, U <= Max, comUnit(U). [-U@L+1, true]
#heuristic unit2sensor(U,S) : visitedAt(s,S,L), minPreferredUnit(Min), maxUnit(Max), Min <= U, U <= Max, comUnit(U). [-U@L+1, true]

% if no source is known, pick the lexicographically smallest possible
sourced :- source(X).
_persist(usedSource(X)) :- source(X).
usedAllSources :- N = #count { X : usedSource(X) }, M = #count { Z : zone(Z) }, N = M.

#heuristic source(Z) : zone(Z), not sourced, not usedSource(Z). [Z@0, true]

#heuristic _resign : usedAllSources, not sourced. [0@0, true]

#heuristic partnerunits(U,U+1) : comUnit(U), comUnit(U+1). [0@-1, true]
