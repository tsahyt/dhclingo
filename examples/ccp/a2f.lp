vtx(V) :- edge(V,_).
vtx(V) :- edge(_,V).

% Determine which vertex is reachable from what other vertex.
reachable(V,W) :- vtx(V), edge(V,W).
reachable(V,W) :- vtx(V), vtx(X), vtx(W), reachable(V,X), reachable(X,W).

% Find some starting vertices from which to "flood" the graph with some colour.
color(1..N) :- nrofcolors(N).
1 { cgroup(V,C) : vtx(V) } 1 :- color(C).
colorWith(V,C) :- cgroup(V,C).
colorWith(W,C) :- colorWith(V,C), reachable(V,W).
colored(V) :- colorWith(V,_).

% Make sure everything has been assigned some colour.
:- vtx(V), not colored(V).

% Determine bins
bin(1..N,C) :- nrofbins(N), color(C).

% Greedy Bin-Packing, some vertices might be left over. This does not
% necessarily correspond to first-fit or best-fit. We only make sure that no
% bin exceeds its capacity, and that if something could still be placed, it
% will be placed.
{ place(V,B,C) : bin(B,C) } 1 :- colorWith(V,C), vtx(V).
:- bin(B,C), maxbinsize(MaxS), MaxS < #sum{ S,V : place(V,B,C), size(V,S) }.
:- vtx(V), colorWith(V,C), bin(B,C), not place(V,B,C), 
    maxbinsize(MaxS), F = #sum { X,Z : place(Z,B,C), size(Z,X) },
    size(V,S), F + S < MaxS.

% Transfer greedy solution first.
#heuristic bin(C,B,V) : place(V,B,C). [0@1, true]

% Ultimately resign
#heuristic resign. [0@0, true]
