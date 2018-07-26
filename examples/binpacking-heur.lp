#external place(I,B) : item(I,_), bin(B).

placed(I) :- place(I,_).

fill(B,S) :- S = #sum { W,I : place(I,B), item(I,W) }, bin(B).

#heuristic place(I,B) : 
    bin(B), item(I,W), capacity(C), fill(B,S), C >= S + W. [S+I@0, true]
