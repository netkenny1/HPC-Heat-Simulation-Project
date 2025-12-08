#!/bin/bash
#SBATCH --job-name=heat_gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --output=heat_gpu.out

# GPU driver supports CUDA 12.4, use CUDA 12.2
# Recompile on GPU node to match driver version
module --force purge
module load StdEnv/2023
module load gcc/12.3
module load cuda/12.2

# Recompile with CUDA 12.2 for Tesla T4 (compute capability 7.5)
nvcc -O2 -arch=sm_75 -o heat_gpu heat_gpu.cu

# Run the GPU code
./heat_gpu

