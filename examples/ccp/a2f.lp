#external vertex_color(V,C).
#external vertex_bin(V,C).

% #heuristic bin(C,B,V). [0@0, true]
vtx(V) :- edge(V,_).
vtx(V) :- edge(_,V).

usedVtx(V) :- vertex_color(V,_).
usedVtx(V) :- vertex_bin(V,_).

% resign when no other choices can be made
#heuristic resign. [0@0, true]
