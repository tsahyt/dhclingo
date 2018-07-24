% bin/1
% item/2    item-id, size
% capacity/1

1 { place(I,B) : bin(B) } 1 :- item(I,_).
:- bin(B), capacity(C), F > C, F = #sum { S,I : item(I,S), place(I,B) }.
