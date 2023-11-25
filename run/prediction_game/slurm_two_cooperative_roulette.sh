#!/usr/bin/bash

#!/bin/bash

#SBATCH --job-name=two_cooperative_roulette
#SBATCH --partition=guest-compute
#SBATCH --account=guest
#SBATCH --qos=low
#SBATCH --array=1-5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=11
#SBATCH --output=two_cooperative_roulette_trial_%A_%a.out
#SBATCH --error=two_cooperative_roulette_trial_%A_%a.err

# Load Julia module or set up the environment
module purge
module load gnu7/7.3.0 anaconda/5.2_py2 openmpi3/3.1.0
source /home/twillkens/.bashrc
conda activate "/home/twillkens/.conda/envs/coevo"

# You can adjust the number of workers (--n_workers) as needed
srun julia --project -e 'push!(LOAD_PATH, "@CoEvo"); using PkgLock; PkgLock.instantiate_precompile()'

srun julia --project=. run/prediction_game/run.jl \
        --trial $SLURM_ARRAY_TASK_ID \
        --n_workers $SLURM_CPUS_PER_TASK \
        --game continuous_prediction_game \
        --topology two_cooperative \
        --report deploy \
        --reproducer roulette \
        --n_generations 100