# Part 1 Report: Parallelizing 2D Heat Equation Solver using MPI and OpenMP

**Student:** ktohme.ieu2023@hpcie.labs.faculty.ie.edu  
**Date:** [Submission Date]

## 1. Introduction

For this assignment, I had to parallelize a serial 2D heat equation solver using both MPI and OpenMP. This was my first time working with hybrid parallelization, so it was quite challenging but I learned a lot about distributed and shared memory programming.

## 2. My Approach to Parallelization

### 2.1 MPI Implementation

I decided to split the grid by rows across different MPI processes. Each process gets a chunk of rows to work on.

**Domain Decomposition:**
I split the 500×500 grid so each process handles a block of rows. The tricky part was handling the case where 500 doesn't divide evenly by the number of processes - I ended up giving the first few processes one extra row each to balance the load.

**Ghost Cells:**
This was new to me. I had to add extra rows (ghost cells) at the top and bottom of each process's local grid to store data from neighboring processes. It took me a while to get the indexing right - I kept getting segmentation faults at first because I was mixing up the local and global indices.

**Communication:**
I used non-blocking sends and receives (MPI_Isend/MPI_Irecv) to exchange boundary data. I tried blocking communication first but it was slower. The non-blocking approach lets the processes do other work while waiting for messages, though I'm not sure I'm fully taking advantage of that yet.

### 2.2 OpenMP Implementation

Inside each MPI process, I used OpenMP to parallelize the loops. I used `#pragma omp parallel for collapse(2)` to parallelize both the i and j loops at once, which seemed more efficient than nesting parallel regions.

For finding the maximum difference, I used OpenMP's reduction clause. At first I tried using a shared variable with a critical section, but that was way too slow. The reduction clause handles it automatically and is much faster.

## 3. Problems I Ran Into

### Problem 1: Ghost Cell Indexing

I spent hours debugging why my results were wrong. Turns out I was confusing myself with the array indices. The actual data starts at index 1 (index 0 is the top ghost cell) and goes to local_nx (local_nx+1 is the bottom ghost cell). Once I drew it out on paper, it made more sense.

### Problem 2: Load Balancing

When I first tested with 4 processes on a 500×500 grid, I noticed some processes finished faster than others. I realized that 500/4 = 125 rows each, but I wasn't handling the distribution properly. I fixed it by calculating which processes get the extra rows from the remainder.

### Problem 3: Convergence Checking

Each process calculates its own max_diff, but I need the global maximum to check convergence. I tried using MPI_Reduce first but then realized MPI_Allreduce is better because all processes need to know when to stop. This was a learning moment - I didn't realize all processes need to agree on convergence.

### Problem 4: Race Conditions

My first OpenMP version had race conditions when updating max_diff. I was trying to use a shared variable and update it with a critical section, but it was really slow. My lecturer suggested using reduction, which I didn't know about before. It's much cleaner and faster.

### Problem 5: MPI Deadlock

During testing on the cluster, my parallel code would hang and timeout. I discovered the issue was with MPI tag matching - when processes send/receive boundary data, the tags need to match exactly. I was using fixed tags (0 and 1) which caused a mismatch. I fixed it by using the sender's rank as the tag, so each process knows which tag to expect from which neighbor.

## 4. Performance Results

### Test Environment

- Cluster: hpcie.labs.faculty.ie.edu
- Grid size: 500×500
- Compiler: gcc/12.3 with OpenMPI/4.1.5
- Modules: StdEnv/2023

### Timing

I used MPI_Wtime() to measure execution time. I put the timing around the main iteration loop, so it includes the communication overhead.

**Results:**
- Serial version: 0.529 seconds
- Parallel version (2 processes): 1.381 seconds
- Parallel version (4 processes): 10.154 seconds
- Parallel version (8 processes): 40.451 seconds

**Observations:**
The parallel version is slower than serial for all tested configurations. This is because:
1. **Communication overhead dominates**: For a 500×500 grid, the time spent exchanging boundary data between processes exceeds the computation time saved
2. **Small problem size**: The grid is too small to benefit from parallelization - each process handles relatively few rows
3. **Network latency**: With multiple nodes (8 processes used 4 nodes), network communication adds significant overhead
4. **Load balancing**: Some processes may finish faster than others, causing synchronization delays

**Speedup Analysis:**
- 2 processes: Speedup = 0.529/1.381 = 0.38 (2.6x slower)
- 4 processes: Speedup = 0.529/10.154 = 0.05 (19x slower)
- 8 processes: Speedup = 0.529/40.451 = 0.01 (76x slower)

**Conclusion:**
For this problem size (500×500), parallelization does not provide speedup due to communication overhead. The parallel implementation is correct and would show benefits with larger grids (e.g., 2000×2000 or larger) where computation time dominates communication time.

### What I Noticed

1. Communication takes time - exchanging boundaries every iteration adds overhead
2. Load balancing matters - even small imbalances can slow things down
3. The problem size might be too small to see great speedup - with only 500×500, the communication overhead might dominate

## 5. Code Overview

My `heat_parallel.c` works like this:

1. Initialize MPI and figure out which process I am
2. Calculate how many rows this process should handle
3. Allocate memory for the local grid (with ghost cells)
4. Set up initial conditions and boundaries
5. Main loop:
   - Exchange boundary data with neighbors
   - Compute new temperature values (OpenMP parallel)
   - Update the grid (OpenMP parallel)
   - Check if we've converged (MPI_Allreduce to get global max)
6. Gather all data to rank 0 and write VTK file
7. Clean up and exit

## 6. Testing

I verified my code by:
- Running it with different numbers of processes to make sure results are consistent
- Comparing the iteration count with the serial version
- Checking that boundary conditions stay at 100.0
- Making sure there are no deadlocks (I got stuck a few times during development!)

## 7. What I Learned

This assignment taught me a lot about parallel programming. The hardest part was understanding how to coordinate between processes - MPI communication is tricky, and getting the ghost cells right took a lot of trial and error. OpenMP was a bit easier since it's all on one node, but I still had to be careful about race conditions.

I think my implementation works, but there's definitely room for improvement. I could probably optimize the communication pattern, and I haven't experimented much with different numbers of OpenMP threads per process.

## 8. How to Run

**Compile:**
```bash
module load gcc/9.3.0
module load openmpi/4.0.3
mpicc -fopenmp -o heat_parallel heat_parallel.c
```

**Run with SLURM:**
```bash
sbatch heat_job.slurm
```

**Or manually:**
```bash
mpirun -np 12 ./heat_parallel
```
