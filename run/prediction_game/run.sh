#!/bin/bash

# for i in {1..5}
# do
#    echo "Running trial $i"
#    julia --project=. run/prediction_game/run.jl \
#         --trial $i \
#         --n_workers 1 \
#         --game continuous_prediction_game \
#         --topology two_competitive \
#         --report deploy \
#         --reproducer roulette \
#         --n_generations 500 &
# done

julia --project=. run/prediction_game/run.jl \
      --trial 1 \
      --n_workers 1 \
      --game continuous_prediction_game \
      --topology two_competitive \
      --report verbose_test \
      --reproducer disco \
      --n_generations 100 \
      --n_nodes_per_output 2 \
      --seed 42