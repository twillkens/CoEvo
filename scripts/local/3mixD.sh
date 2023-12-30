#!/bin/bash

mkdir -p logs/3mixD

for i in {1..30}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 1 \
        --game continuous_prediction_game \
        --topology three_mixed \
        --reproduction disco \
        --n_generations 30000 \
        --n_nodes_per_output 1 \
        --archive_interval 200 \
        --function_set simple \
        --mutation shrink_small \
        --noise_std high \
        --n_population 100\
        --n_children 100\
        --n_elites 0 \
        --episode_length 16 \
        > logs/3mixD/$i.log 2>&1 &
done
