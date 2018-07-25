#external place(I,B) : item(I,_), bin(B).
heuristic(place(I,B)) :- not place(I,_), item(I,_), bin(B).
