# Benchmark Week 29 no2, 2018/

Compare external VSIDS passthrough heuristic in Python to native VSIDS in
Clingo. Both versions run through a Python main loop. This happens because the
configuration of the heuristic is affected otherwise.

## Setup

+ Gitlab Commit clingo-benchmark-docker:650655badb66a3bd925497c83eb73a229561313b
+ ASP Competition 2015, 5 random instances per domain (same as last
  benchmark!). Excluded are:
    * CQA for directory structure (not captured by `setup-benchmarks.sh`)
    * Instances > 10 MB, most notably Reachability.
* 900s time limit
* 12GB memory limit
* Run in Docker container
* Simple JSON based answer set comparison written in Python

## Run

Finished

## Findings

* 123 benchmarks have been performed
    * 70 answer sets matched
    * 53 answer did "not match" (according to script)
        * 52 of these resulted in a timeout for both solvers
        * 1 resulted in an OOM
* We find that similar results have therefore been achieved in both cases!

### Absolute

Graphs have been produced for finished instances over and under 30 seconds. The
cutoff here is arbitrary and only serves to create a better illustration, since
very short running instances would otherwise get drowned out by the scale in
the graph.

![Sub 30s](img/20180723-sub30.pdf)
![Over 30s](img/20180723-over30.pdf)

### Relative

The Python/Native ratio (for the finished instances only!) has the following statistical key figures
```R
> summary(ratio)
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
 0.6906  0.9997  1.0118  1.0209  1.0449  1.2162 
> sd(ratio)
[1] 0.06008548
```

For only "long" instances, i.e. with a running time of over 10s (in either heuristic)
```R
> summary(ratiolong)
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
 0.9636  1.0178  1.0348  1.0357  1.0496  1.1347 
> sd(ratiolong)
[1] 0.03545501
```

### Memory

Memory usage has been plotted for instances that have finished *and* used more than 128M of RAM

![Memory](img/20180723-mem.pdf)

Relative Numbers (Python/Native) are

```R
> summary(memratio)
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
 0.6558  0.9988  1.0004  0.9987  1.0054  1.0621 
> sd(memratio)
[1] 0.04473417
```
