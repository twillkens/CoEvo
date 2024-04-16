# QueMEU
This is the anonymous partial repository for the paper "Coevolutionary Heuristics for Maximization of Expected Utility." It contains excerpts relevant for running trials and plotting/analyzing data. The full codebase with utilities will be released in the event of acceptance for publication.

Please see test/quemeu/run.jl for an entry point for running trials.
src/concrete/configurations/quemeu contains organizing configuration code
src/concrete/ecosystems/quemeu contains most of the code for executing the various conditions.
test/quemeu/plot.jl contains plotting code for generating figures,
test/quemeu/analyze.jl contains code for statistical analysis.

Other files in src/concrete support the core evolutionary algorithm.
