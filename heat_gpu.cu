#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>

#define NX 500
#define NY 500
#define MAX_ITER 1000
#define TOLERANCE 1e-6

__global__ void compute_heat_kernel(double *u, double *u_new, int nx, int ny, double *max_diff) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    
    // Shared memory for reduction
    extern __shared__ double sdata[];
    int tid = threadIdx.y * blockDim.x + threadIdx.x;
    
    if (i > 0 && i < nx - 1 && j > 0 && j < ny - 1) {
        int idx = i * ny + j;
        u_new[idx] = 0.25 * (u[(i+1)*ny + j] + u[(i-1)*ny + j]
                            + u[i*ny + (j+1)] + u[i*ny + (j-1)]);
        
        double diff = fabs(u_new[idx] - u[idx]);
        sdata[tid] = diff;
    } else {
        sdata[tid] = 0.0;
    }
    
    __syncthreads();
    
    // Reduction in shared memory
    for (int s = blockDim.x * blockDim.y / 2; s > 0; s >>= 1) {
        if (tid < s) {
            if (sdata[tid] < sdata[tid + s]) {
                sdata[tid] = sdata[tid + s];
            }
        }
        __syncthreads();
    }
    
    if (tid == 0) {
        max_diff[blockIdx.y * gridDim.x + blockIdx.x] = sdata[0];
    }
}

__global__ void update_heat_kernel(double *u, double *u_new, int nx, int ny) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (i > 0 && i < nx - 1 && j > 0 && j < ny - 1) {
        int idx = i * ny + j;
        u[idx] = u_new[idx];
    }
}

double find_max_diff(double *d_max_diff, int num_blocks) {
    double *h_max_diff = (double *)malloc(num_blocks * sizeof(double));
    cudaMemcpy(h_max_diff, d_max_diff, num_blocks * sizeof(double), cudaMemcpyDeviceToHost);
    
    double max_val = 0.0;
    for (int i = 0; i < num_blocks; i++) {
        if (h_max_diff[i] > max_val) {
            max_val = h_max_diff[i];
        }
    }
    
    free(h_max_diff);
    return max_val;
}

int main() {
    double *h_u, *h_u_new;
    double *d_u, *d_u_new, *d_max_diff;
    int iter;
    double max_diff;
    cudaEvent_t start, stop;
    float elapsed_time;
    
    // Allocate host memory
    size_t size = NX * NY * sizeof(double);
    h_u = (double *)malloc(size);
    h_u_new = (double *)malloc(size);
    
    if (h_u == NULL || h_u_new == NULL) {
        fprintf(stderr, "Host memory allocation failed\n");
        return 1;
    }
    
    // Initialize the grid
    for (int i = 0; i < NX; i++) {
        for (int j = 0; j < NY; j++) {
            h_u[i * NY + j] = 0.0;
            if (i == 0 || i == NX - 1 || j == 0 || j == NY - 1) {
                h_u[i * NY + j] = 100.0; // Boundary conditions
            }
        }
    }
    
    // Allocate device memory
    cudaError_t err;
    err = cudaMalloc((void **)&d_u, size);
    if (err != cudaSuccess) {
        fprintf(stderr, "CUDA malloc failed for d_u: %s\n", cudaGetErrorString(err));
        free(h_u);
        free(h_u_new);
        return 1;
    }
    err = cudaMalloc((void **)&d_u_new, size);
    if (err != cudaSuccess) {
        fprintf(stderr, "CUDA malloc failed for d_u_new: %s\n", cudaGetErrorString(err));
        cudaFree(d_u);
        free(h_u);
        free(h_u_new);
        return 1;
    }
    
    // Calculate number of blocks for reduction
    dim3 blockSize(16, 16);
    dim3 gridSize((NX + blockSize.x - 1) / blockSize.x, 
                  (NY + blockSize.y - 1) / blockSize.y);
    int num_blocks = gridSize.x * gridSize.y;
    err = cudaMalloc((void **)&d_max_diff, num_blocks * sizeof(double));
    if (err != cudaSuccess) {
        fprintf(stderr, "CUDA malloc failed for d_max_diff: %s\n", cudaGetErrorString(err));
        cudaFree(d_u);
        cudaFree(d_u_new);
        free(h_u);
        free(h_u_new);
        return 1;
    }
    
    // Copy initial data to device
    err = cudaMemcpy(d_u, h_u, size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr, "CUDA memcpy failed: %s\n", cudaGetErrorString(err));
        cudaFree(d_u);
        cudaFree(d_u_new);
        cudaFree(d_max_diff);
        free(h_u);
        free(h_u_new);
        return 1;
    }
    
    // Create CUDA events for timing
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);
    
    // Iterative solver
    for (iter = 0; iter < MAX_ITER; iter++) {
        // Compute new values
        size_t shared_mem_size = blockSize.x * blockSize.y * sizeof(double);
        compute_heat_kernel<<<gridSize, blockSize, shared_mem_size>>>(
            d_u, d_u_new, NX, NY, d_max_diff);
        err = cudaGetLastError();
        if (err != cudaSuccess) {
            fprintf(stderr, "Kernel launch failed: %s\n", cudaGetErrorString(err));
            break;
        }
        cudaDeviceSynchronize();
        
        // Find maximum difference
        max_diff = find_max_diff(d_max_diff, num_blocks);
        
        // Update u
        update_heat_kernel<<<gridSize, blockSize>>>(d_u, d_u_new, NX, NY);
        err = cudaGetLastError();
        if (err != cudaSuccess) {
            fprintf(stderr, "Kernel launch failed: %s\n", cudaGetErrorString(err));
            break;
        }
        cudaDeviceSynchronize();
        
        // Check for convergence
        if (max_diff < TOLERANCE) {
            printf("Converged after %d iterations.\n", iter + 1);
            break;
        }
    }
    
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsed_time, start, stop);
    
    printf("GPU execution time: %f seconds\n", elapsed_time / 1000.0);
    printf("Final max difference: %e\n", max_diff);
    
    // Copy result back to host (for VTK output)
    err = cudaMemcpy(h_u, d_u, size, cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) {
        fprintf(stderr, "CUDA memcpy failed: %s\n", cudaGetErrorString(err));
    }
    
    // Write VTK file
    FILE *fp = fopen("heat_output.vtk", "w");
    if (fp != NULL) {
        fprintf(fp, "# vtk DataFile Version 2.0\n");
        fprintf(fp, "2D Heat Equation Data\n");
        fprintf(fp, "ASCII\n");
        fprintf(fp, "DATASET STRUCTURED_POINTS\n");
        fprintf(fp, "DIMENSIONS %d %d 1\n", NX, NY);
        fprintf(fp, "ORIGIN 0 0 0\n");
        fprintf(fp, "SPACING 1 1 1\n");
        fprintf(fp, "POINT_DATA %d\n", NX * NY);
        fprintf(fp, "SCALARS temperature float 1\n");
        fprintf(fp, "LOOKUP_TABLE default\n");
        
        for (int j = 0; j < NY; j++) {
            for (int i = 0; i < NX; i++) {
                fprintf(fp, "%f\n", h_u[i * NY + j]);
            }
        }
        
        fclose(fp);
        printf("VTK output written to heat_output.vtk\n");
    }
    
    // Clean up
    free(h_u);
    free(h_u_new);
    cudaFree(d_u);
    cudaFree(d_u_new);
    cudaFree(d_max_diff);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    
    return 0;
}

