% bin/1
% item/2    item-id, size
% capacity/1

after(I,J) :- item(I,_), item(J,_), J = I + 1.

place(1,1,S) :- item(1,S).
place(J,B,F + S) :- place(I,B,F), after(I,J), item(J,S), capacity(C), C > F + S.
place(J,B1,S) :- place(I,B,_), not place(J,B,_), after(I,J), item(J,S), bin(B1), B1 = B + 1.

place(I,B) :- place(I,B,X).

#show item/2.
#show bin/1.
#show capacity/1.
#show place/2.
