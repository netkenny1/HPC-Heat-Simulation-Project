# Part 2 Report: GPU Acceleration using CUDA

**Student:** ktohme.ieu2023@hpcie.labs.faculty.ie.edu  
**Date:** [Submission Date]

## 1. Introduction

For Part 2, I had to accelerate the heat equation solver using CUDA. I've never worked with GPUs before, so this was completely new to me. I chose CUDA over OpenACC because I wanted to learn how GPU programming actually works at a lower level.

## 2. My CUDA Implementation

### 2.1 Learning About GPU Architecture

I had to learn a lot about how GPUs work. The main thing I learned is that GPUs have thousands of cores that can run threads in parallel, but they're organized into blocks. I decided to use 16×16 thread blocks (256 threads each) because that seemed like a reasonable size - not too big, not too small.

### 2.2 Writing the Kernels

I wrote two CUDA kernels:

**compute_heat_kernel:** This does the actual computation. Each thread handles one grid point and calculates the new temperature using the stencil. I also tried to do a reduction in shared memory to find the max difference, but that part was really tricky.

**update_heat_kernel:** This just copies the new values back to the old array. It's simple but necessary.

### 2.3 Memory Management

This was confusing at first. I had to allocate memory on both the host (CPU) and device (GPU), then copy data back and forth. I tried to minimize transfers by keeping everything on the GPU during computation and only copying back at the end.

I used:
- `cudaMalloc` for device memory
- `cudaMemcpy` to transfer data
- Regular `malloc` for host memory

### 2.4 The Reduction Problem

Finding the maximum difference across all threads was hard. I tried to do a full GPU reduction but it was too complicated. In the end, I did a per-block reduction on the GPU (using shared memory) and then find the global max on the CPU. It's not perfect, but it works and the code is readable.

## 3. Problems I Had

### Problem 1: Understanding Shared Memory

I didn't understand shared memory at first. I kept getting errors because I wasn't declaring it correctly. The `extern __shared__` syntax was new to me. Also, I had to calculate how much shared memory I needed and pass it when launching the kernel.

### Problem 2: Memory Access Patterns

My first version was really slow. I realized I wasn't accessing memory efficiently - the threads in a warp need to access consecutive memory locations for best performance. I restructured my array indexing to use row-major order (i * NY + j) which helped a lot.

### Problem 3: Boundary Checks

I had to add checks in the kernel to make sure threads don't try to access out-of-bounds memory. This adds some overhead, but it's necessary. I set boundary values on the host before copying to device, so they stay constant.

### Problem 4: Convergence Checking

Every iteration, I need to check if we've converged. This means I have to transfer data from GPU to CPU to find the global maximum. I tried to minimize this by only transferring the block maxima (not the whole grid), but it's still overhead. I'm not sure if there's a better way without making the code way more complex.

## 4. Performance

### Test Setup

I tested on Google Colab because the HPC cluster GPU nodes weren't available when I was working on this. Colab gives you a free GPU which is handy.

- Platform: Google Colab GPU (T4 I think)
- CUDA Version: 11.0
- Grid size: 500×500
- Thread blocks: 16×16

### Timing

I used CUDA events to measure time, which is more accurate than regular timing for GPU code. The timing includes the kernel execution but not the initial memory transfers.

**Results:**
- CPU parallel version: [To be filled]
- GPU version: [To be filled]
- Speedup: [To be calculated]

I'm curious to see if the GPU is actually faster for this problem size. With only 500×500 grid points, the GPU might not be fully utilized, and the memory transfer overhead might hurt performance.

### What I Noticed

1. Memory transfers are expensive - copying data to/from GPU takes time
2. The problem might be too small - GPUs work better with bigger problems
3. My reduction implementation might not be optimal - there's probably a better way

## 5. Code Structure

My `heat_gpu.cu` works like this:

1. Allocate memory on host and device
2. Set initial conditions (boundaries at 100.0)
3. Copy data to GPU
4. Main loop:
   - Launch compute kernel
   - Copy block maxima back to host
   - Find global maximum on CPU
   - Launch update kernel
   - Check convergence
5. Copy final results back to host
6. Write VTK file
7. Free all memory

## 6. Testing

I verified the GPU version by:
- Comparing iteration count with CPU versions (should be the same)
- Checking that results look reasonable
- Making sure boundaries stay at 100.0
- Checking for CUDA errors (I got a lot of "invalid argument" errors during development!)

## 7. What I Learned

CUDA is really different from CPU programming. The hardest part was understanding the memory model - host vs device, global vs shared memory. Also, debugging GPU code is harder because you can't just print statements everywhere.

I think my implementation works, but I'm sure there are optimizations I'm missing. I didn't use shared memory for caching, which might help. Also, my reduction is probably not optimal. But for a first CUDA program, I'm happy with it.

## 8. Comparison with CPU Version

**Advantages:**
- Thousands of threads can run at once
- No MPI communication needed
- Simpler code structure (no domain decomposition)

**Disadvantages:**
- Memory transfer overhead
- Problem might be too small to see benefits
- Need CUDA-capable hardware

## 9. How to Run

**On HPC Cluster (if GPU available):**
```bash
module load cuda/11.0
module load gcc/9.3.0
nvcc -o heat_gpu heat_gpu.cu
sbatch heat_job_gpu.slurm
```

**On Google Colab:**
1. Upload `heat_gpu.cu` to Colab
2. Set runtime to GPU (Runtime → Change runtime type → GPU)
3. Run:
```python
!nvcc -o heat_gpu heat_gpu.cu
!./heat_gpu
```

**Manual:**
```bash
./heat_gpu
```
