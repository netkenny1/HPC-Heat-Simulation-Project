# Part 3 Report: Visualization Using VTK (Bonus)

**Student:** ktohme.ieu2023@hpcie.labs.faculty.ie.edu  
**Date:** [Submission Date]

## 1. Introduction

For the bonus part, I decided to add visualization using VTK. I've never used VTK before, so I had to learn it from scratch. It was actually pretty interesting - being able to see the results visually helped me understand what the code was doing and catch some bugs.

## 2. Writing VTK Files

### 2.1 Learning the VTK Format

I chose the legacy VTK format because it's simple - just a text file with a specific structure. The format has:
- A header with version info
- Dataset type (STRUCTURED_POINTS for regular grids)
- Grid dimensions
- The actual data values

I found some examples online and adapted them for my code.

### 2.2 Adding VTK Output to Parallel Code

This was tricky because the data is split across multiple MPI processes. I had to:
1. Have each process send its local data to rank 0
2. Rank 0 collects all the data and reconstructs the full grid
3. Rank 0 writes the VTK file

The hardest part was making sure the data ordering was correct. VTK expects data in a specific order (j-loop outer, i-loop inner), which is different from how I store it in C arrays. I got it wrong the first time and the visualization looked weird.

### 2.3 Adding VTK Output to GPU Code

This was easier because there's only one process. I just copy the data back from GPU to CPU at the end, then write the file. Same VTK format as the parallel version.

## 3. Visualization Scripts

### 3.1 Standalone Script (`visualize_heat.py`)

I wrote a Python script that uses VTK to read and display the data. It creates a color-mapped visualization with a color bar. You can zoom and pan around, which is nice.

I had to install VTK first: `pip install vtk`

**Usage:**
```bash
python visualize_heat.py
# Or save to image:
python visualize_heat.py heat_output.vtk output.png
```

### 3.2 Colab Version (`visualize_heat_colab.py`)

The standalone VTK visualization doesn't work well in Colab notebooks (the interactive window doesn't show up). So I made a Colab-specific version that:
- Uses VTK to read the data
- Converts it to NumPy arrays
- Uses Matplotlib to plot it (which works in Colab)
- Shows some statistics about the temperature

This was useful when I was testing the GPU version on Colab.

## 4. What the Visualization Shows

When I first ran the visualization, I was surprised - it actually looks like what I expected! The boundaries are bright (hot, 100°C) and the center is darker (cooler). There's a smooth gradient from the edges to the center, which makes sense physically.

The visualization helped me verify:
- Boundary conditions are correct (bright edges)
- The solution converged properly (smooth gradient, no weird patterns)
- My parallel code is working (no visible seams between process boundaries)

## 5. Problems I Had

### Problem 1: Data Ordering

My first VTK file had the data in the wrong order. The visualization looked rotated or mirrored. I had to swap the loop order when writing the file - VTK wants j-outer, i-inner, but I was doing i-outer, j-inner.

### Problem 2: Gathering Data in MPI

In the parallel version, I had to gather all the data to rank 0. I had to figure out which rows each process handles and reconstruct the full grid. I got the indexing wrong a few times and ended up with gaps or overlaps in the visualization.

### Problem 3: Colab Visualization

The standard VTK visualization doesn't work in Colab. I tried a few things before realizing I should just use Matplotlib instead. It's not as fancy, but it works and shows the data clearly.

### Problem 4: File Format

I had some issues with the VTK file format at first - missing headers, wrong dimensions, etc. I had to carefully check the format specification and make sure I was writing everything correctly.

## 6. How to Use

### Step 1: Run the simulation
```bash
# MPI version
sbatch heat_job.slurm

# GPU version
./heat_gpu
```

### Step 2: Check the VTK file was created
```bash
ls -lh heat_output.vtk
```

### Step 3: Visualize
```bash
# Standalone
python visualize_heat.py

# Or in Colab
!pip install vtk matplotlib numpy
from visualize_heat_colab import visualize_heat_colab
visualize_heat_colab('heat_output.vtk', 'heat_visualization.png')
```

## 7. What I Learned

VTK is pretty powerful but also complex. For this assignment, I only scratched the surface. The visualization really helped me understand what my code was doing and catch some bugs. It's satisfying to see the results visually instead of just numbers.

I think the visualization turned out well. It's not super fancy, but it shows the temperature distribution clearly and helps verify that the code is working correctly.

## 8. Observations

Looking at the visualization:
- The boundaries are clearly hot (bright colors)
- There's a smooth gradient to the center (cooler)
- The solution looks symmetric (which makes sense for a square with uniform boundaries)
- No weird artifacts or discontinuities, which suggests the parallel code is working correctly

## 9. Files

- `heat_output.vtk` - Generated by both parallel and GPU versions
- `visualize_heat.py` - Standalone visualization script
- `visualize_heat_colab.py` - Colab version

## 10. Conclusion

Adding visualization was a good learning experience. It helped me understand VTK and also helped debug my code. The visualization confirms that the numerical solution is working correctly and shows the expected physical behavior.
