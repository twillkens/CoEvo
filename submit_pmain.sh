#!/usr/bin/bash

#SBATCH --output=3ctrl.log
#SBATCH --error=3ctrl.err
#SBATCH --job-name=3ctrl
#SBATCH --partition=guest-compute
#SBATCH --cpus-per-task=41
#SBATCH --tasks=1
#SBATCH --qos=low
#SBATCH --account=guest

module purge
module load gnu7/7.3.0 anaconda/5.2_py2 openmpi3/3.1.0
source /home/twillkens/.bashrc
conda activate "/home/twillkens/.conda/envs/coevo"

#julia --project -e 'push!(LOAD_PATH, "@CoEvo"); using PkgLock; PkgLock.instantiate_precompile()'
julia --project=. -p 40 pmain.jl