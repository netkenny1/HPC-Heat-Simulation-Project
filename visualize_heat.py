#!/usr/bin/env python3
# VTK visualization script for heat equation results

import vtk
import sys
import os

def visualize_heat_distribution(vtk_file='heat_output.vtk', output_image=None):
    # Reads VTK file and shows temperature distribution
    
    if not os.path.exists(vtk_file):
        print(f"Error: File {vtk_file} not found!")
        return
    
    reader = vtk.vtkStructuredPointsReader()
    reader.SetFileName(vtk_file)
    reader.Update()
    
    data = reader.GetOutput()
    
    mapper = vtk.vtkDataSetMapper()
    mapper.SetInputConnection(reader.GetOutputPort())
    mapper.SetScalarRange(data.GetPointData().GetScalars().GetRange())
    
    actor = vtk.vtkActor()
    actor.SetMapper(mapper)
    
    renderer = vtk.vtkRenderer()
    renderer.AddActor(actor)
    renderer.SetBackground(0.1, 0.1, 0.1)
    
    scalar_bar = vtk.vtkScalarBarActor()
    scalar_bar.SetLookupTable(mapper.GetLookupTable())
    scalar_bar.SetTitle("Temperature")
    scalar_bar.SetNumberOfLabels(5)
    renderer.AddActor2D(scalar_bar)
    
    render_window = vtk.vtkRenderWindow()
    render_window.AddRenderer(renderer)
    render_window.SetSize(800, 600)
    render_window.SetWindowName("2D Heat Equation Visualization")
    
    if output_image:
        window_to_image = vtk.vtkWindowToImageFilter()
        window_to_image.SetInput(render_window)
        window_to_image.Update()
        
        writer = vtk.vtkPNGWriter()
        writer.SetFileName(output_image)
        writer.SetInputConnection(window_to_image.GetOutputPort())
        render_window.Render()
        writer.Write()
        print(f"Visualization saved to {output_image}")
    
    interactor = vtk.vtkRenderWindowInteractor()
    interactor.SetRenderWindow(render_window)
    style = vtk.vtkInteractorStyleImage()
    interactor.SetInteractorStyle(style)
    
    print("Visualization window opened. Close the window to exit.")
    render_window.Render()
    interactor.Start()

if __name__ == "__main__":
    vtk_file = 'heat_output.vtk'
    output_image = None
    
    if len(sys.argv) > 1:
        vtk_file = sys.argv[1]
    if len(sys.argv) > 2:
        output_image = sys.argv[2]
    
    visualize_heat_distribution(vtk_file, output_image)

