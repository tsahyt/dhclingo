vtx(V) :- edge(V,_).
vtx(V) :- edge(_,V).

% number vertices arbitrarily for ordering purposes.
vtxNo(1..N) :- N = #count { X : vtx(X) }.
1 { vtxNo(V,N) : vtxNo(N) } 1 :- vtx(V).
:- vtxNo(V,N), vtxNo(W,N), V != W.

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

% Greedy Bin-Packing, some vertices might be left over. This implements a
% next-fit strategy.

first(V,C) :- vtx(V), colorWith(V,C), vtxNo(V,N), N = #min { X : vtxNo(V1,X), colorWith(V1,C) }.
after(V,W,C) :- colorWith(V,C), colorWith(W,C), vtxNo(V,N), vtxNo(W,M), M > N.

place(V,1,C,S) :- vtx(V), size(V,S), colorWith(V,C), first(V,C).
place(W,B,C,F + S) :- place(V,B,C,F), after(V,W,C), size(W,S), maxbinsize(C), C > F + S.
place(W,B1,C,S) :- place(V,B,C,_), not place(W,B,C,_), after(V,W,C), size(W,S), maxbinsize(C), bin(B1,C), B1 = B + 1.

place(V,B,C) :- place(V,B,C,_).

% Transfer greedy solution first.
#heuristic bin(C,B,V) : place(V,B,C). [0@1, true]

% Ultimately resign
#heuristic resign. [0@0, true]

