# Part 1 Submission: MPI + OpenMP Parallelization

## Files Included

- `heat_serial.c` - Original serial implementation (baseline)
- `heat_parallel.c` - Parallelized code using MPI and OpenMP
- `heat_job.slurm` - SLURM job script for cluster execution
- `Part1_Report.md` - Complete report (2-3 pages)
- `heat_2proc.out` - Output from 2-process run
- `heat_4proc.out` - Output from 4-process run
- `heat_8proc.out` - Output from 8-process run
- `heat_test.out` - Test run output

## How to Compile and Run

```bash
# Load modules
module load gcc/12.3
module load openmpi/4.1.5

# Compile
mpicc -fopenmp -o heat_parallel heat_parallel.c

# Submit job
sbatch heat_job.slurm

# Or run directly
mpirun -np 2 ./heat_parallel
```

## Results Summary

- Serial: 0.529 seconds
- 2 processes: 1.381 seconds
- 4 processes: 10.154 seconds
- 8 processes: 40.451 seconds

See Part1_Report.md for detailed analysis.

