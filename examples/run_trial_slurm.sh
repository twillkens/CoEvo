#!/bin/bash
#SBATCH --job-name=trial_job
#SBATCH --output=logs/output_%A_%a.txt
#SBATCH --error=logs/error_%A_%a.txt
#SBATCH --array=1-30
#SBATCH --nodes=1
#SBATCH --ntasks=5 # 5 workers
#SBATCH --time=02:00:00
#SBATCH --partition=your_partition_name

module load julia

SEED=$(head /dev/urandom | tr -dc 0-9 | head -c 10)
julia trial.jl $SLURM_ARRAY_TASK_ID $SEED
