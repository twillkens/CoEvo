#!/bin/bash

#SBATCH --job-name=3mixDE
#SBATCH --partition=guest-compute
#SBATCH --account=guest
#SBATCH --qos=low
#SBATCH --array=1-30%30
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/3mixDE/%a.out
#SBATCH --error=logs/3mixDE/%a.err

# Load Julia module or set up the environment
module purge
module load gnu7/7.3.0 anaconda/5.2_py2 openmpi3/3.1.0
source /home/twillkens/.bashrc
conda activate "/home/twillkens/.conda/envs/coevo"

srun julia --project -e 'push!(LOAD_PATH, "@CoEvo"); using PkgLock; PkgLock.instantiate_precompile()'

# Run script
srun julia --project=. run/prediction_game/run.jl \
        --trial $SLURM_ARRAY_TASK_ID \
        --n_workers $SLURM_CPUS_PER_TASK \
        --game continuous_prediction_game \
        --topology three_mixed \
        --reproduction disco \
        --n_generations 30000 \
        --n_nodes_per_output 1 \
        --archive_interval 50 \
        --function_set simple \
        --mutation shrink_volatile \
        --noise_std high \
        --n_population 50 \
        --n_children 50 \
        --n_elites 50 \
        --episode_length 16 \
