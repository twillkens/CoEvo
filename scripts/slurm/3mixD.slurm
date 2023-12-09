#!/bin/bash

#SBATCH --job-name=3mixD
#SBATCH --partition=guest-compute
#SBATCH --account=guest
#SBATCH --qos=low
#SBATCH --array=1-30%30
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/3mixD/%a.out
#SBATCH --error=logs/3mixD/%a.err

# Create log directory if it doesn't exist
if [ ! -d "logs/3mixD" ]; then
    mkdir -p "logs/3mixD"
fi

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
        --report deploy \
        --reproducer disco \
        --n_generations 30000 \
        --n_nodes_per_output 1 \
        --modes_interval 50 \
