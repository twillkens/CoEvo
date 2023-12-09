#!/bin/bash

mkdir -p logs/2compD

for i in {1..1}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 5 \
        --game continuous_prediction_game \
        --topology two_competitive \
        --report deploy \
        --reproducer disco \
        --n_generations 10000 \
        --n_nodes_per_output 1 \
        --modes_interval 50 \
        --function_set all \
        --mutation shrink_volatile \
        --noise_std high \
        > logs/2compD/$i.log 2>&1 &
done
