#!/usr/bin/bash

#SBATCH --output=mismatch_match.log
#SBATCH --error=mismatch_match.err
#SBATCH --job-name=mismatch_match
#SBATCH --partition=guest-compute
#SBATCH --cpus-per-task=21
#SBATCH --tasks=1
#SBATCH --qos=low
#SBATCH --account=guest

module purge
module load gnu7/7.3.0 anaconda/5.2_py2 openmpi3/3.1.0
source /home/twillkens/.bashrc
conda activate "/home/twillkens/.conda/envs/coevo"

#julia --project -e 'push!(LOAD_PATH, "@CoEvo"); using PkgLock; PkgLock.instantiate_precompile()'
julia --project=. -p 20 run_mismatch_match.jl