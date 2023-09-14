import argparse
import math
import os.path
import os
import numpy as np
import vtk


def write_vtk(fibers_list, cell_nums, vtk_filename):
    outpd = vtk.vtkPolyData()
    outpoints = vtk.vtkPoints()
    outlines = vtk.vtkCellArray()

    outlines.InitTraversal()

    for lidx in range(0, len(fibers_list)):
        cellptids = vtk.vtkIdList()

        for pidx in range(0, cell_nums[lidx]):
            idx = outpoints.InsertNextPoint(fibers_list[lidx][pidx][0],
                                            fibers_list[lidx][pidx][1],
                                            fibers_list[lidx][pidx][2])

            cellptids.InsertNextId(idx)

        outlines.InsertNextCell(cellptids)

    # put data into output polydata
    outpd.SetLines(outlines)
    outpd.SetPoints(outpoints)

    writer = vtk.vtkDataSetWriter()
    writer.SetFileName(vtk_filename)
    writer.SetInputData(outpd)
    writer.Write()


def compute_length(mode, fiber):
    # 1: distance for head to end
    # 2: distance for all fiber
    if mode == 1:
        length = math.sqrt(abs(fiber[-1, 0] - fiber[0, 0]) ** 2 + abs(fiber[-1, 1] - fiber[0, 1]) ** 2 + abs(
            fiber[-1, 2] - fiber[0, 2]) ** 2)
    elif mode == 2:
        length = 0
        for i in range(0, len(fiber) - 1):
            length = length + math.sqrt(
                abs(fiber[i + 1, 0] - fiber[i, 0]) ** 2 + abs(fiber[i + 1, 1] - fiber[i, 1]) ** 2 + abs(
                    fiber[i + 1, 2] - fiber[i, 2]) ** 2)
    return length


def load_filter_fiber_vtk(fiber_vtk_name):
    basename, extension = os.path.splitext(fiber_vtk_name)
    if extension == '.vtk':
        reader = vtk.vtkPolyDataReader()
        reader.SetFileName(fiber_vtk_name)
        reader.Update()
        vtkdata = reader.GetOutput()
    else:
        reader = vtk.vtkXMLPolyDataReader()
        reader.SetFileName(fiber_vtk_name)
        reader.Update()
        vtkdata = reader.GetOutput()

    # get point data from vtk polydata cell
    # one cell is one fiber
    cell_nums = []
    point_list = []
    for i in range(vtkdata.GetNumberOfCells()):
        pts = vtkdata.GetCell(i).GetPoints()
        num = pts.GetNumberOfPoints()

        fiber_point_np = np.array([np.array(pts.GetPoint(i_point)) for i_point in range(pts.GetNumberOfPoints())])

        # filter length
        length = compute_length(1, fiber_point_np)
        if length >= int(args.filter_length):
            cell_nums.append(num)
            point_list.append(fiber_point_np)

    return point_list, cell_nums


# ------------------
# Parse arguments
# ------------------
parser = argparse.ArgumentParser(description="Filter the fiber tract of vtk file by length.",
                                 epilog='Written by Wei Zhang')
parser.add_argument('inputVTK', help='input VTK')
parser.add_argument('outputVTK', help='output vtk')
parser.add_argument('filter_length', help='min length to filter fibers')
args = parser.parse_args()

# load input vtk and filter them
point_list, cell_nums = load_filter_fiber_vtk(args.inputVTK)

# save new vtk after filter
write_vtk(point_list, cell_nums, args.outputVTK)

print('<length_filter>' + '  ' + args.outputVTK)
