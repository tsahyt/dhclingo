# Benchmark Week 29, 2018

Compare external VSIDS passthrough heuristic in Python to native VSIDS in
Clingo. Both versions run through a Python main loop. This happens because the
configuration of the heuristic is affected otherwise.

## Setup

+ Gitlab Commit clingo-benchmark-docker:0e912e2123bb1cee7b20017e8f47ffadfa960f9e
+ ASP Competition 2015, 5 random instances per domain. Excluded are:
    * CQA for directory structure (not captured by `setup-benchmarks.sh`)
    * Instances > 10 MB, most notably Reachability.
* 900s time limit
* 12GB memory limit
* Run in Docker container
* Simple JSON based answer set comparison written in Python

## Run

Aborted after roughly a day to check why some answer sets do not match in the logs.

## Findings

* 54 benchmarks have been performed.
    * 22 answer sets matched
    * 32 answer sets did not match (according to comparison)

### Non-Matching Answer Sets

Out of 32 "Answer Sets do not match" answers,

* 25 were preceded by the script throwing a JSON decoder error, which causes
  a bad exit code and triggers the "Answer Sets do not match" answer. In all 25
  cases this happened because of timeouts leaving incomplete answer sets/solver
  output.

  --> Fix comparison script!

* The other 7 cases reported "complete" in pyrunlim!

    1. CombinedConfiguration/000154_combined_configuration_problem-0-0.asp 
    2. CombinedConfiguration/000237_combined_configuration_problem-0-0.asp 
    3. Labyrinth/0059-labyrinth-13-0.asp
    4. Labyrinth/0080-labyrinth-19-0.asp
    5. Labyrinth/0095-labyrinth-15-0.asp
    6. Labyrinth/0097-labyrinth-12-0.asp
    7. Labyrinth/0192-labyrinth-18-0.asp

### Ratio

The following boxplot illustrates the ratio between the Python variant and the
native variant. Only completed benchmarks *with matching answer sets* have been
considered so far!

![Boxplot](img/20180718-ratio.pdf)

### Absolute Times

![Finished](img/20180718-absolute.pdf)
![Non-Matching](img/20180718-nonmatch.pdf)
