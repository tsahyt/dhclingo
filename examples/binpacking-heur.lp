#external place(I,B) : item(I,_), bin(B).

placed(I) :- place(I,_).

score(I,B,S) :- 
    F = #sum { X,I1 : place(I1,B), item(I1,X), bin(B) }, 
    item(I,W), bin(B), capacity(C), not placed(I),
    S = C - (F + W), S >= 0.

best(I,B) :- score(I,B,X), X = #min { Z : score(_,_,Z) }.

#heuristic place(I,B) : best(I,B). [0@0, true]
