#!/bin/bash

mkdir -p logs/3mixD

for i in {1..1}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 5 \
        --game continuous_prediction_game \
        --topology three_mixed \
        --report verbose_test \
        --reproducer disco \
        --n_generations 10000 \
        --n_nodes_per_output 1 \
        --modes_interval 50 \
        > logs/3mixD/$i.log 2>&1 &
done
