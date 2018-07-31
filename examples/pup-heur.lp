zone(Z) :- zone2sensor(Z,S).
sensor(S) :- zone2sensor(Z,S).

maxOrdinal(X) :- X = Z + S, Z = #max { A : zone(A) }, S = #max { A : sensor(A) }.
ordinal(1..X) :- maxOrdinal(X).
orderStep(1..X) :- maxOrdinal(X).

1 { source(Z) : zone(Z) } 1.

visitedAt(z,Z,1) :- source(Z).
visitedAt(s,S,O) :- visitedAt(z,Z,O-1), orderStep(O), zone2sensor(Z,S), not visitedBefore(s,S,O).
visitedAt(z,Z,O) :- visitedAt(s,S,O-1), orderStep(O), zone2sensor(Z,S), not visitedBefore(z,Z,O).

visitedBefore(A,Z,O) :- orderStep(O), visitedAt(A,Z,P), O > P.
