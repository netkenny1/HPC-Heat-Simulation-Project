#!/usr/bin/env python3
# VTK visualization for Google Colab

try:
    import vtk
    from vtk.util import numpy_support
    import numpy as np
    import matplotlib.pyplot as plt
    from matplotlib.colors import LinearSegmentedColormap
except ImportError as e:
    print(f"Error importing required libraries: {e}")
    print("Please install required packages:")
    print("!pip install vtk matplotlib numpy")
    raise

def visualize_heat_colab(vtk_file='heat_output.vtk', save_image='heat_visualization.png'):
    # Visualizes heat distribution from VTK file in Colab
    
    reader = vtk.vtkStructuredPointsReader()
    reader.SetFileName(vtk_file)
    reader.Update()
    
    data = reader.GetOutput()
    dims = data.GetDimensions()
    nx, ny = dims[0], dims[1]
    
    scalars = data.GetPointData().GetScalars()
    temp_array = numpy_support.vtk_to_numpy(scalars)
    temp_2d = temp_array.reshape((ny, nx))
    
    plt.figure(figsize=(10, 8))
    im = plt.imshow(temp_2d, cmap='hot', origin='lower', interpolation='bilinear')
    cbar = plt.colorbar(im, label='Temperature')
    cbar.set_label('Temperature', rotation=270, labelpad=20)
    
    plt.title('2D Heat Equation - Temperature Distribution', fontsize=14, fontweight='bold')
    plt.xlabel('X Position', fontsize=12)
    plt.ylabel('Y Position', fontsize=12)
    
    plt.tight_layout()
    plt.savefig(save_image, dpi=150, bbox_inches='tight')
    print(f"Visualization saved to {save_image}")
    plt.show()
    
    print(f"\nTemperature Statistics:")
    print(f"  Min: {temp_2d.min():.2f}")
    print(f"  Max: {temp_2d.max():.2f}")
    print(f"  Mean: {temp_2d.mean():.2f}")
    print(f"  Std: {temp_2d.std():.2f}")

if __name__ == "__main__":
    import sys
    
    vtk_file = 'heat_output.vtk'
    save_image = 'heat_visualization.png'
    
    if len(sys.argv) > 1:
        vtk_file = sys.argv[1]
    if len(sys.argv) > 2:
        save_image = sys.argv[2]
    
    visualize_heat_colab(vtk_file, save_image)

