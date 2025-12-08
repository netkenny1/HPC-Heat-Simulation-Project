# Makefile for HPC Heat Simulation Project
# Student: ktohme.ieu2023@hpcie.labs.faculty.ie.edu

CC = gcc
MPICC = mpicc
NVCC = nvcc

CFLAGS = -Wall -O2
MPI_FLAGS = -fopenmp
CUDA_FLAGS = -O2

# Default target
all: serial parallel gpu

# Serial version
serial: heat_serial.c
	$(CC) $(CFLAGS) -o heat_serial heat_serial.c -lm

# MPI + OpenMP parallel version
parallel: heat_parallel.c
	$(MPICC) $(MPI_FLAGS) -o heat_parallel heat_parallel.c

# CUDA GPU version
gpu: heat_gpu.cu
	$(NVCC) $(CUDA_FLAGS) -o heat_gpu heat_gpu.cu

# Clean compiled files
clean:
	rm -f heat_serial heat_parallel heat_gpu
	rm -f *.o *.out
	rm -f heat_output.vtk

# Clean everything including output files
cleanall: clean
	rm -f *.png *.jpg

# Help target
help:
	@echo "Available targets:"
	@echo "  make serial    - Compile serial version"
	@echo "  make parallel  - Compile MPI+OpenMP version"
	@echo "  make gpu       - Compile CUDA version"
	@echo "  make all       - Compile all versions"
	@echo "  make clean     - Remove compiled binaries"
	@echo "  make cleanall  - Remove all generated files"
	@echo "  make help      - Show this help message"

.PHONY: all serial parallel gpu clean cleanall help

