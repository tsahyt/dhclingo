#external place(I,B) : item(I,_), bin(B).

placed(I) :- place(I,_).

#heuristic place(I,B) : 
    bin(B), item(I,W), capacity(C), not placed(I),
    S = #sum { X,I1 : place(I1,B), item(I1,X) }, 
    C >= S + W. [S+I@0, true]
