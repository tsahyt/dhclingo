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
