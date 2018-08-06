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

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ORDERING FOR HEURISTIC
%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Breadth First Order (by Level)
maxOrdinal(X) :- X = Z + S, Z = #max { A : zone(A) }, S = #max { A : sensor(A) }.
orderStep(1..X) :- maxOrdinal(X).

1 { source(Z) : zone(Z) } 1.

visitedAt(z,Z,1) :- source(Z).
visitedAt(s,S,O) :- visitedAt(z,Z,O-1), orderStep(O), zone2sensor(Z,S), not visitedBefore(s,S,O).
visitedAt(z,Z,O) :- visitedAt(s,S,O-1), orderStep(O), zone2sensor(Z,S), not visitedBefore(z,Z,O).

visitedBefore(A,Z,O) :- orderStep(O), visitedAt(A,Z,P), O > P.
