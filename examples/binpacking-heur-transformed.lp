placed(I) :- place(I,_).

fill(B,S) :- S = #sum { W,I : place(I,B), item(I,W) }, bin(B).

heuristic(place(I,B),S+I,0,true) :- bin(B), item(I,W), capacity(C), fill(B,S), C >= S + W.
