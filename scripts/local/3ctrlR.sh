#!/bin/bash

mkdir -p logs/3ctrlR

for i in {1..5}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 1 \
        --game continuous_prediction_game \
        --topology three_control \
        --report deploy \
        --reproducer roulette \
        --n_generations 1000 \
        --n_nodes_per_output 1 \
        --modes_interval 50 \
        > logs/3ctrlR/$i.log 2>&1 &
done
