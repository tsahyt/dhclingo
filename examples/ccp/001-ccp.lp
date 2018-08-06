nrofcolors(4).
nrofbins(3).
maxbinsize(5).
maxborder(2).

edge("b1","s1").
edge("s1","p1").
edge("p1","b2").
edge("b2","p2").
edge("p2","b3").
edge("b3","p3").
edge("p3","s2").
edge("s2","b4").

edge("b7","s3").
edge("s3","p4").
edge("p4","b8").
edge("b8","p5").
edge("p5","b9").
edge("b9","p6").
edge("p6","s4").
edge("s4","b10").

edge("p1","b5").
edge("b5","e1").
edge("e1","b6").
edge("b6","p3").

edge("p4","b11").
edge("b11","e2").
edge("e2","b12").
edge("b12","p6").

size("b1",1).
size("b2",1).
size("b3",1).
size("b4",1).
size("b5",1).
size("b6",1).
size("b7",1).
size("b8",1).
size("b9",1).
size("b10",1).
size("b11",1).
size("b12",1).
size("e1",2).
size("e2",2).
size("s1",3).
size("s2",3).
size("s3",3).
size("s4",3).
size("p1",4).
size("p2",4).
size("p3",4).
size("p4",4).
size("p5",4).
size("p6",4).

path1("b1"; "s1"; "p1"; "b2"; "p2"; "b3"; "p3"; "s2"; "b4").
path2("b7"; "s3"; "p4"; "b8"; "p5"; "b9"; "p6"; "s4"; "b10").

edge_matching("a1", "b1").
edge_matching("a1", "b2").
edge_matching("a1", "b5").
edge_matching("a2", "b5").
edge_matching("a2", "b6").
edge_matching("a3", "b6").
edge_matching("a3", "b4").
edge_matching("a3", "b3").
edge_matching("a4", "b2").
edge_matching("a4", "b3").
edge_matching("a4", "b8").
edge_matching("a4", "b9").
edge_matching("a5", "b8").
edge_matching("a5", "b7").
edge_matching("a5", "b11").
edge_matching("a6", "b9").
edge_matching("a6", "b10").
edge_matching("a6", "b12").
edge_matching("a7", "b11").
edge_matching("a7", "b12").
