% bin/1
% item/2    item-id, size
% capacity/1

% { place(I,B) : bin(B) } 1 :- item(I,_).
:- bin(B), capacity(C), F > C, F = #sum { S,I : item(I,S), place(I,B) }.

after(I,J) :- item(I,_), item(J,_), J = I + 1.
placed(I) :- place(I,_).

spaceAfter(I,B,X) :- bin(B), item(I,_), capacity(C), F = #sum { S,I1 : item(I1,S), place(I1,B), I1 < I }, X = C - F, X > 0.

place(1,1).
place(J,B) :- place(I,B), after(I,J), item(J,S), spaceAfter(J,B,X), X >= S.
place(J,B1) :- place(I,B), not place(J,B), after(I,J), bin(B1), B1 = B + 1.

#show place/2.
