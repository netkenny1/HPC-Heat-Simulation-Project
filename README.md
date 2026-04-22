# HPC Heat Simulation

Parallel **2D heat-equation solver** implemented in C. Starts from a serial reference, scales out across nodes with **MPI**, multi-threads on each node with **OpenMP**, and accelerates the inner loop on the GPU with **CUDA** (with an OpenACC path). Includes SLURM job scripts, sample outputs, and performance analysis across CPU and GPU configurations.

## What it does

Solves the 2D transient heat equation

```
∂u/∂t = α ( ∂²u/∂x² + ∂²u/∂y² )
```

on a rectangular grid using a standard finite-difference scheme, writing VTK fields for visualization.

## Implementations

| File | Description |
|---|---|
| `heat_serial.c` | Reference single-thread implementation. |
| `heat_parallel.c` | MPI + OpenMP hybrid — halo-exchange across ranks, threading inside each rank. |
| `heat_gpu.cu` | CUDA kernel for the interior-point update. |
| `heat_job.slurm` | SLURM submission script for the CPU (MPI + OpenMP) run. |
| `heat_job_gpu.slurm` | SLURM submission script for the GPU run. |
| `heat_output.vtk` | Sample output field (openable in ParaView / VisIt). |
| `heat_*proc.out` | Captured stdout from 2 / 4 / 8-rank runs for scaling analysis. |

## Build

```bash
# Serial
gcc -O3 -o heat_serial heat_serial.c -lm

# MPI + OpenMP
mpicc -O3 -fopenmp -o heat_parallel heat_parallel.c -lm

# CUDA
nvcc -O3 -o heat_gpu heat_gpu.cu
```

## Run

```bash
# Local OpenMP run
OMP_NUM_THREADS=4 ./heat_parallel

# Multi-rank MPI
mpirun -np 8 ./heat_parallel

# Cluster
sbatch heat_job.slurm
sbatch heat_job_gpu.slurm
```

## Results

Performance is compared across CPU (serial, OpenMP-only, MPI+OpenMP) and GPU (CUDA) runs, with scaling data captured in the `heat_*proc.out` logs. See the performance write-up for the speed-up curves and discussion.

## Stack

**C**, **MPI**, **OpenMP**, **CUDA** (optional **OpenACC** path), **SLURM**, **VTK** for output.
