#!/bin/bash
#SBATCH --job-name=process-configs
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=01:00:00
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

# Load Julia module or set up the environment
module load julia

# Set the root directory for the configurations
export COEVO_TRIAL_DIR="/path/to/your/configuration/directory"

# Define the Julia script path
JULIA_SCRIPT_PATH="/path/to/your/julia/script.jl"

# Function to submit a job for a specific configuration
submit_job() {
    game=$1
    topology=$2
    substrate=$3
    reproducer=$4

    # Submit a job to Slurm
    sbatch --wrap="julia $JULIA_SCRIPT_PATH $game $topology $substrate $reproducer"
}

# Iterate over configurations and submit jobs
while read line; do
    IFS=' ' read -ra CONFIG <<< "$line"
    if [[ ${#CONFIG[@]} -eq 4 ]]; then
        submit_job ${CONFIG[0]} ${CONFIG[1]} ${CONFIG[2]} ${CONFIG[3]}
    fi
done < <(julia -e 'include("'"$JULIA_SCRIPT_PATH"'"); print_configurations("'$COEVO_TRIAL_DIR'")')

echo "All configurations submitted to Slurm."
