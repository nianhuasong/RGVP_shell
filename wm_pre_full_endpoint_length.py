def compute_lengths(inpd):
    """Compute length of each fiber in polydata. Returns lengths and step size.
    Step size is estimated using points in the middle of a fiber with over 15 points.
    """

    # Make sure we have lines and points.
    if (inpd.GetNumberOfLines() == 0) or (inpd.GetNumberOfPoints() == 0):
        print("<filter.py> No fibers found in input polydata.")
        return 0, 0
    
    # measure step size (using first line that has >=5 points)
    cell_idx = 0
    ptids = vtk.vtkIdList()
    inpoints = inpd.GetPoints()
    inpd.GetLines().InitTraversal()
    while (ptids.GetNumberOfIds() < 5) & (cell_idx < inpd.GetNumberOfLines()):
        inpd.GetLines().GetNextCell(ptids)
        ##    inpd.GetLines().GetCell(cell_idx, ptids)
        ## the GetCell function is not wrapped in Canopy python-vtk
        cell_idx += 1
    # make sure we have some points along this fiber
    # In case all fibers in the brain are really short, treat it the same as no fibers.
    if ptids.GetNumberOfIds() < 5:
        return 0, 0
    
    # Use points from the middle of the fiber to estimate step length.
    # This is because the step size may vary near endpoints (in order to include
    # endpoints when downsampling the fiber to reduce file size).
    step_size = 0.0
    count = 0.0
    for ptidx in range(1, ptids.GetNumberOfIds()-1):
        point0 = inpoints.GetPoint(ptids.GetId(ptidx))
        point1 = inpoints.GetPoint(ptids.GetId(ptidx + 1))
        step_size += numpy.sqrt(numpy.sum(numpy.power(numpy.subtract(point0, point1), 2)))
        count += 1
    step_size = step_size / count

    fiber_lengths = list()
    # loop over lines
    inpd.GetLines().InitTraversal()
    num_lines = inpd.GetNumberOfLines()
    for lidx in range(0, num_lines):
        inpd.GetLines().GetNextCell(ptids)
        # save length
        fiber_lengths.append(ptids.GetNumberOfIds() * step_size)

    return numpy.array(fiber_lengths), step_size

def preprocess(inpd):
    """Remove fibers below a length threshold and using other criteria (optional).
    Based on fiber length, and optionally on distance between
    endpoints (u-shape has low distance), and inferior location
    (likely in brainstem).
    """

    fiber_lengths, step_size = compute_lengths(inpd)

    # set up processing and output objects
    ptids = vtk.vtkIdList()
    inpoints = inpd.GetPoints()
    ednpoint_dists = [];

    # loop over lines
    inpd.GetLines().InitTraversal()
    num_lines = inpd.GetNumberOfLines()

    for lidx in range(0, num_lines):
        inpd.GetLines().GetNextCell(ptids)

        ptid = ptids.GetId(0)
        point0 = inpoints.GetPoint(ptid)
        ptid = ptids.GetId(ptids.GetNumberOfIds() - 1)
        point1 = inpoints.GetPoint(ptid)

        endpoint_dist = numpy.sqrt(numpy.sum(numpy.power(numpy.subtract(point0, point1), 2)))
        ednpoint_dists.append(endpoint_dist)

        
    return (fiber_lengths, numpy.array(ednpoint_dists))

import argparse
import os
import nibabel
import vtk
import numpy

try:
    import whitematteranalysis as wma
except:
    print("Error importing white matter analysis package\n")
    raise

#-----------------
# Parse arguments
#-----------------
parser = argparse.ArgumentParser(
    description="Convert a fiber tract or cluster (vtk) to a voxel-wise fiber density image (nii.gz). ",
    epilog="Written by Fan Zhang")

parser.add_argument("-v", "--version",
    action="version", default=argparse.SUPPRESS,
    version='1.0',
    help="Show program's version number and exit")

parser.add_argument(
    'inputVTK',
    help='Input VTK/VTP file that is going to be converted.')
parser.add_argument(
    'outputVTK',
    help='Output volume image, where the value of each voxel represents the number of fibers passing though the voxel.')
parser.add_argument(
    '-l', action="store", dest="fiberLength", type=int,
    help='Minimum length (in mm) of fibers to keep.')
# parser.add_argument(
#     '-gt', action="store", dest="GroundTruth", type=str,
#     help='GroundTruth label')

args = parser.parse_args()

inpd = wma.io.read_polydata(args.inputVTK)

fiber_lengths, ednpoint_dists = preprocess(inpd)

# print(fiber_lengths)
# print(ednpoint_dists)

mask = (fiber_lengths > args.fiberLength ) #& (ednpoint_dists > args.fiberLength)


pd_ds = wma.filter.mask(inpd, mask,  preserve_point_data=True, preserve_cell_data=True, verbose=False)

wma.io.write_polydata(pd_ds, args.outputVTK)
numpy.save(args.outputVTK.replace('.vtk', '.npy').replace('.vtp', '.npy'), mask)

# if args.GroundTruth is not None:
#     GT = numpy.load(args.GroundTruth)
#     print GT.shape

#     GT_masked = GT[mask]

#     print GT_masked.shape

#     numpy.save(args.outputVTK.replace('.vtk', '.npy').replace('.vtp', '.npy').replace('.npy', '_GT.npy'), GT_masked)









    