zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

maxOrdinal(X) :- X = Z + S, Z = #max { A : zone(A) }, S = #max { A : sensor(A) }.
orderStep(1..X) :- maxOrdinal(X).

%%% Breadth First Order (by Level)
% 1 { source(Z) : zone(Z) } 1.
% 
% visitedAt(z,Z,1) :- source(Z).
% visitedAt(s,S,O) :- visitedAt(z,Z,O-1), orderStep(O), zone2sensor(Z,S), not visitedBefore(s,S,O).
% visitedAt(z,Z,O) :- visitedAt(s,S,O-1), orderStep(O), zone2sensor(Z,S), not visitedBefore(z,Z,O).
% 
% visitedBefore(A,Z,O) :- orderStep(O), visitedAt(A,Z,P), O > P.

%%% Any Topological Order
ordinal(1..X) :- maxOrdinal(X).

elem(z,Z) :- zone(Z).
elem(s,S) :- sensor(S).

1 { order(A,X,O) : ordinal(O) } 1 :- elem(A,X).

:- order(A,X,O), order(B,Y,O), A != B, X != Y.
:- order(z,Z,O1), order(s,S,O2), zone2sensor(Z,S), O2 <= O1.
