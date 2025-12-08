#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <mpi.h>
#include <omp.h>

#define NX 500
#define NY 500
#define MAX_ITER 1000
#define TOLERANCE 1e-6

int main(int argc, char *argv[]) {
    int rank, size;
    int i, j, iter;
    double diff, max_diff, global_max_diff;
    double start_time, end_time;
    
    // MPI initialization
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Calculate local grid dimensions
    int rows_per_process = NX / size;
    int remainder = NX % size;
    
    // Distribute remainder rows to first few processes
    int local_start_row = rank * rows_per_process;
    if (rank < remainder) {
        local_start_row += rank;
        rows_per_process += 1;
    } else {
        local_start_row += remainder;
    }
    
    int local_nx = rows_per_process;
    int local_start = local_start_row;
    int local_end = local_start + local_nx;
    
    // Allocate local arrays with ghost cells (2 extra rows for boundaries)
    double (*u)[NY] = malloc((local_nx + 2) * sizeof(double[NY]));
    double (*u_new)[NY] = malloc((local_nx + 2) * sizeof(double[NY]));
    
    if (u == NULL || u_new == NULL) {
        fprintf(stderr, "Memory allocation failed on rank %d\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    
    // Initialize local grid
    #pragma omp parallel for collapse(2)
    for (i = 0; i < local_nx + 2; i++) {
        for (j = 0; j < NY; j++) {
            u[i][j] = 0.0;
            u_new[i][j] = 0.0;
        }
    }
    
    // Set boundary conditions
    #pragma omp parallel for
    for (j = 0; j < NY; j++) {
        if (local_start == 0) {
            u[1][j] = 100.0;
        }
        if (local_end == NX) {
            u[local_nx][j] = 100.0;
        }
        if (j == 0 || j == NY - 1) {
            for (i = 1; i <= local_nx; i++) {
                u[i][j] = 100.0;
            }
        }
    }
    
    // Synchronize before starting iterations
    MPI_Barrier(MPI_COMM_WORLD);
    
    if (rank == 0) {
        start_time = MPI_Wtime();
    }
    
    // Iterative solver
    for (iter = 0; iter < MAX_ITER; iter++) {
        max_diff = 0.0;
        
        // Exchange boundary data with neighbors
        MPI_Request send_req[2], recv_req[2];
        
        // Send top row to previous process (if not first process)
        if (rank > 0) {
            MPI_Isend(&u[1][0], NY, MPI_DOUBLE, rank - 1, 0, MPI_COMM_WORLD, &send_req[0]);
            MPI_Irecv(&u[0][0], NY, MPI_DOUBLE, rank - 1, 0, MPI_COMM_WORLD, &recv_req[0]);
        }
        
        // Send bottom row to next process (if not last process)
        if (rank < size - 1) {
            MPI_Isend(&u[local_nx][0], NY, MPI_DOUBLE, rank + 1, 1, MPI_COMM_WORLD, &send_req[1]);
            MPI_Irecv(&u[local_nx + 1][0], NY, MPI_DOUBLE, rank + 1, 1, MPI_COMM_WORLD, &recv_req[1]);
        }
        
        // Wait for boundary exchanges to complete
        if (rank > 0) {
            MPI_Wait(&send_req[0], MPI_STATUS_IGNORE);
            MPI_Wait(&recv_req[0], MPI_STATUS_IGNORE);
        }
        if (rank < size - 1) {
            MPI_Wait(&send_req[1], MPI_STATUS_IGNORE);
            MPI_Wait(&recv_req[1], MPI_STATUS_IGNORE);
        }
        
        // Compute new values using OpenMP
        #pragma omp parallel for collapse(2) reduction(max:max_diff)
        for (i = 1; i <= local_nx; i++) {
            for (j = 1; j < NY - 1; j++) {
                u_new[i][j] = 0.25 * (u[i+1][j] + u[i-1][j]
                                     + u[i][j+1] + u[i][j-1]);
                diff = fabs(u_new[i][j] - u[i][j]);
                if (diff > max_diff) {
                    max_diff = diff;
                }
            }
        }
        
        // Update u
        #pragma omp parallel for collapse(2)
        for (i = 1; i <= local_nx; i++) {
            for (j = 1; j < NY - 1; j++) {
                u[i][j] = u_new[i][j];
            }
        }
        
        // Find global maximum difference
        MPI_Allreduce(&max_diff, &global_max_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);
        
        // Check for convergence
        if (global_max_diff < TOLERANCE) {
            if (rank == 0) {
                printf("Converged after %d iterations.\n", iter + 1);
            }
            break;
        }
    }
    
    if (rank == 0) {
        end_time = MPI_Wtime();
        printf("Parallel execution time: %f seconds\n", end_time - start_time);
        printf("Final max difference: %e\n", global_max_diff);
    }
    
    // Gather data to rank 0 for VTK output
    if (rank == 0) {
        double *full_grid = (double *)malloc(NX * NY * sizeof(double));
        
        // Copy rank 0's data
        for (i = 1; i <= local_nx; i++) {
            for (j = 0; j < NY; j++) {
                full_grid[(local_start + i - 1) * NY + j] = u[i][j];
            }
        }
        
        // Receive data from other processes
        for (int proc = 1; proc < size; proc++) {
            int proc_rows = NX / size;
            int proc_remainder = NX % size;
            int proc_start = proc * proc_rows;
            if (proc < proc_remainder) {
                proc_start += proc;
                proc_rows += 1;
            } else {
                proc_start += proc_remainder;
            }
            
            double *recv_buffer = (double *)malloc(proc_rows * NY * sizeof(double));
            MPI_Recv(recv_buffer, proc_rows * NY, MPI_DOUBLE, proc, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            
            for (i = 0; i < proc_rows; i++) {
                for (j = 0; j < NY; j++) {
                    full_grid[(proc_start + i) * NY + j] = recv_buffer[i * NY + j];
                }
            }
            free(recv_buffer);
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
            
            for (j = 0; j < NY; j++) {
                for (i = 0; i < NX; i++) {
                    fprintf(fp, "%f\n", full_grid[i * NY + j]);
                }
            }
            
            fclose(fp);
            printf("VTK output written to heat_output.vtk\n");
        }
        
        free(full_grid);
    } else {
        // Send local data to rank 0
        double *send_buffer = (double *)malloc(local_nx * NY * sizeof(double));
        for (i = 1; i <= local_nx; i++) {
            for (j = 0; j < NY; j++) {
                send_buffer[(i - 1) * NY + j] = u[i][j];
            }
        }
        MPI_Send(send_buffer, local_nx * NY, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
        free(send_buffer);
    }
    
    // Clean up
    free(u);
    free(u_new);
    
    MPI_Finalize();
    return 0;
}

