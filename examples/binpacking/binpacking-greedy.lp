% bin/1
% item/2    item-id, size
% capacity/1

{ place(I,B) : bin(B) } 1 :- item(I,_).
placed(I) :- place(I,_).
:- bin(B), capacity(C), F > C, F = #sum { S,I : item(I,S), place(I,B) }.
:- item(I,S), bin(B), capacity(C), F = #sum { S1,I1 : item(I1,S1), place(I1,B) },
   not placed(I), F + S < C.
