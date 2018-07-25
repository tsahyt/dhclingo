#external place(I,B) : item(I,_), bin(B).

placed_item(I) :- place(I,_).
_heuristic(place(I,B)) :- not place(I,B), not placed_item(I), item(I,_), bin(B).
