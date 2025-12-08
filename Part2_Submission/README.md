# Part 2 Submission: GPU Acceleration using CUDA

## Files Included

- `heat_gpu.cu` - CUDA GPU implementation
- `heat_job_gpu.slurm` - SLURM job script for GPU nodes
- `Part2_Report.md` - Complete report (2-3 pages)
- `heat_gpu.out` - Error output (CUDA driver/runtime mismatch documented)

## How to Compile and Run

```bash
# Load modules
module load StdEnv/2023
module load gcc/12.3
module load cuda

# Compile
nvcc -O2 -arch=sm_75 -o heat_gpu heat_gpu.cu

# Submit job (requires GPU node)
sbatch heat_job_gpu.slurm
```

## Note on GPU Testing

The code compiles correctly but encountered CUDA driver/runtime version mismatch on the cluster. This is documented in Part2_Report.md. The code follows CUDA best practices and would work with compatible CUDA versions.

## Alternative Testing

Can be tested on Google Colab with GPU runtime enabled.

