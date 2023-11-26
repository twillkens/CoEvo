#!/bin/bash

for i in {1..20}
do
   echo "Running trial $i"
   julia --project=. run/prediction_game/run.jl \
        --trial $i \
        --n_workers 1 \
        --game continuous_prediction_game \
        --topology two_competitive \
        --report deploy \
        --reproducer roulette \
        --n_generations 10000 &
done
