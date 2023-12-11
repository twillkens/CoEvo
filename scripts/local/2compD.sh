#!/bin/bash

mkdir -p logs/2compD

for i in {1..1}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --seed 2046455945345878094 \
        --n_workers 5 \
        --game continuous_prediction_game \
        --topology two_competitive \
        --report deploy \
        --reproducer disco \
        --n_generations 30000 \
        --n_nodes_per_output 1 \
        --n_population 100 \
        --n_children 100 \
        --modes_interval 100 \
        --adaptive_archive_max_size 1000 \
        --n_adaptive_archive_samples 50 \
        --function_set all \
        --mutation shrink_volatile \
        --noise_std high \
        > logs/2compD/$i.log 2>&1 &
done
