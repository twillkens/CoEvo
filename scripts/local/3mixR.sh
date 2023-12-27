#!/bin/bash

mkdir -p logs/3mixR

for i in {1..1}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 1 \
        --game continuous_prediction_game \
        --topology three_mixed \
        --reproduction roulette \
        --n_generations 30000 \
        --n_nodes_per_output 1 \
        --archive_interval 50 \
        --function_set simple \
        --mutation shrink_volatile \
        --noise_std high \
        --n_population 50 \
        --n_children 50 \
        --n_elites 0 \
        --episode_length 16 \
        > logs/3mixR/$i.log 2>&1 &
done
