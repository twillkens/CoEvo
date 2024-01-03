#!/bin/bash

mkdir -p logs/2compDE
n_trials=4
#for i in {1..$n_trials}
for ((i=1; i<=n_trials; i++))
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 1 \
        --n_trials $n_trials \
        --game continuous_prediction_game \
        --topology two_competitive \
        --reproduction disco \
        --n_generations 30000 \
        --n_nodes_per_output 1 \
        --archive_interval 100 \
        --function_set all \
        --mutation shrink_modest \
        --noise_std low \
        --n_population 50 \
        --n_children 50 \
        --n_elites 0 \
        --episode_length 16 \
        > logs/2compDE/$i.log 2>&1 &
done
