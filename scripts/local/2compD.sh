#!/bin/bash

mkdir -p logs/2compD

for i in {1..5}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 1 \
        --game continuous_prediction_game \
        --episode_length 16 \
        --topology two_competitive \
        --report deploy \
        --reproducer disco \
        --n_generations 500 \
        --n_nodes_per_output 1 \
        --modes_interval 50 \
        --function_set all \
        --mutation shrink_volatile \
        --noise_std high \
        --adaptive_archive_max_size 50 \
        --n_adaptive_archive_samples 50 \
        > logs/2compD/$i.log 2>&1 &
done
