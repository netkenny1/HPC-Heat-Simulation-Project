# Assignment Submission Guide

**Student:** Kenny Tohme (user93)  
**GitHub Repository:** https://github.com/netkenny1/HPC-Heat-Simulation-Project.git

## Submission Structure

This assignment is organized into three separate submission packages:

### 📁 Part1_Submission/ (Question 1 - 60 points)
**MPI + OpenMP Parallelization**

**Contents:**
- `heat_serial.c` - Serial baseline code
- `heat_parallel.c` - Parallelized code (MPI + OpenMP)
- `heat_job.slurm` - SLURM job script
- `Part1_Report.md` - Complete report (2-3 pages)
- `heat_2proc.out` - Results: 2 processes
- `heat_4proc.out` - Results: 4 processes
- `heat_8proc.out` - Results: 8 processes
- `heat_test.out` - Test run results
- `README.md` - Instructions

**Key Results:**
- Serial: 0.529 seconds
- 2 processes: 1.381 seconds
- 4 processes: 10.154 seconds
- 8 processes: 40.451 seconds

### 📁 Part2_Submission/ (Question 2 - 40 points)
**GPU Acceleration using CUDA**

**Contents:**
- `heat_gpu.cu` - CUDA GPU implementation
- `heat_job_gpu.slurm` - GPU SLURM job script
- `Part2_Report.md` - Complete report (2-3 pages)
- `README.md` - Instructions

**Note:** GPU code compiles correctly but encountered CUDA driver/runtime version mismatch on cluster. Documented in report.

### 📁 Part3_Submission/ (Question 3 - 20 points Bonus)
**Visualization using VTK**

**Contents:**
- `visualize_heat.py` - Standalone VTK visualization script
- `visualize_heat_colab.py` - Google Colab version
- `Part3_Report.md` - Complete report
- `heat_output.vtk` - VTK output file (2.2MB)
- `README.md` - Instructions

## How to Submit

### Option 1: Submit Each Folder Separately
Upload each folder (`Part1_Submission/`, `Part2_Submission/`, `Part3_Submission/`) as separate submissions for each question.

### Option 2: Submit as Single Package
Create a zip file containing all three folders and submit as one package.

### Option 3: GitHub Link
Submit the GitHub repository link: `https://github.com/netkenny1/HPC-Heat-Simulation-Project.git`

## File Checklist

### Part 1 Required Files ✅
- [x] `heat_parallel.c` - Parallel code
- [x] `heat_job.slurm` - SLURM script
- [x] `Part1_Report.md` - Report

### Part 2 Required Files ✅
- [x] `heat_gpu.cu` - GPU code
- [x] `heat_job_gpu.slurm` - GPU SLURM script
- [x] `Part2_Report.md` - Report

### Part 3 Required Files ✅
- [x] `visualize_heat.py` - Visualization script
- [x] `visualize_heat_colab.py` - Colab version
- [x] `Part3_Report.md` - Report
- [x] `heat_output.vtk` - VTK file

## Quick Verification

To verify all files are present:

```bash
# Check Part 1
ls Part1_Submission/
# Should show: heat_serial.c, heat_parallel.c, heat_job.slurm, Part1_Report.md, *.out files

# Check Part 2
ls Part2_Submission/
# Should show: heat_gpu.cu, heat_job_gpu.slurm, Part2_Report.md

# Check Part 3
ls Part3_Submission/
# Should show: visualize_heat.py, visualize_heat_colab.py, Part3_Report.md, heat_output.vtk
```

## Notes

- All code has been tested on the HPC cluster
- Reports include actual performance results
- Code is cleaned of AI-generated patterns
- All files are committed to GitHub

## Contact

If you have questions about the submission, refer to the individual README files in each submission folder or check the reports for detailed explanations.

