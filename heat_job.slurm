#!/bin/bash
#SBATCH --job-name=heat_parallel
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=2
#SBATCH --time=00:30:00
#SBATCH --output=heat_parallel.out

# Modules are already loaded, but ensure they're available
# gcc/12.3 and openmpi/4.1.5 are already loaded

mpirun -np 4 ./heat_parallel

