export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/SlicerDMRI/lib/Slicer-5.2/qt-loadable-modules
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Slicer-5.2
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Teem-1.12.0

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Python/lib

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Slicer-5.2
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/UKFTractography/lib/Slicer-5.2/qt-loadable-modules
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Teem-1.12.0
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/SlicerDMRI/lib/Slicer-5.2/cli-modules/



UKFTractography=/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/UKFTractography/lib/Slicer-5.2/cli-modules/UKFTractography
SlicerDMRICLI=/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/SlicerDMRI/lib/Slicer-5.2/cli-modules

subject_list=./subj_list.txt


while read caseid ; 
do
	echo $caseid
	
	data_dwi_space_folder=./dwi/${caseid}.dti

	#DWIQCed_nrrd=${data_dwi_space_folder}/${caseid}.nhdr
	DWIQCed_nrrd=${data_dwi_space_folder}/${caseid}_QCed.nrrd
	
#	RGVP_mask=$data_dwi_space_folder/${caseid}_QCed_RGVP_mask-edit.nrrd
	RGVP_mask=$data_dwi_space_folder/${caseid}_QCed_RGVP_mask.nrrd
	RGVP_ROI=$data_dwi_space_folder/${caseid}_QCed_b0-label.nrrd

	outputdir=$data_dwi_space_folder/${caseid}_UKF/
	filteredir=$outputdir/filterd
	selecteddir=$outputdir/selected
	mkdir -p $filteredir
	mkdir -p $selecteddir
	mkdir -p $selecteddir/LL
	mkdir -p $selecteddir/RR
	mkdir -p $selecteddir/LR
	mkdir -p $selecteddir/RL
	
	fiber_length=80


	#qms=(0.001 0.003 0.005 0.007)
	qms=(0.001)
	qls=(50 100 150 200 250 300)

	for qm in ${qms[@]}
	do
		for ql in ${qls[@]}
		do

			# filtering by length
			fulltract=$outputdir/ql${ql}_qm${qm}.vtk
			filteredtract=$filteredir/ql${ql}_qm${qm}_filtered.vtk	
			if [ ! -f $filteredtract ]
			then
				$1 python wm_pre_full_endpoint_length.py $fulltract $filteredtract -l $fiber_length
			fi
			# test single ql qm vtk
			#python ./length_filter.py $fulltract $outputdir/ql${ql}_qm${qm}_filter.vtk $fiber_length


			# ON-L: 2, ON-R: 1, OT-L: 5, OT-R: 4. 
			LLtract=$selecteddir/LL/ql${ql}_qm${qm}_filtered_LL.vtk
			RRtract=$selecteddir/RR/ql${ql}_qm${qm}_filtered_RR.vtk
			LRtract=$selecteddir/LR/ql${ql}_qm${qm}_filtered_LR.vtk
			RLtract=$selecteddir/RL/ql${ql}_qm${qm}_filtered_RL.vtk

			if [ ! -f $RLtract ]
			then
				$1 $SlicerDMRICLI/FiberBundleLabelSelect $RGVP_ROI $filteredtract $LLtract -i AND -p 2,5
				$1 $SlicerDMRICLI/FiberBundleLabelSelect $RGVP_ROI $filteredtract $RRtract -i AND -p 1,4
				$1 $SlicerDMRICLI/FiberBundleLabelSelect $RGVP_ROI $filteredtract $LRtract -i AND -p 2,4
				$1 $SlicerDMRICLI/FiberBundleLabelSelect $RGVP_ROI $filteredtract $RLtract -i AND -p 1,5

			fi

			#appendLL=$selecteddir/LL.vtk
			#appendRR=$selecteddir/RR.vtk
			#appendLR=$selecteddir/RL.vtk
			#appendRL=$selecteddir/RL.vtk



			#exit

		done
	done
	
	
	# append RGVP fiber
	$1 wm_append_clusters.py $selecteddir/LL/ $selecteddir/  -appendedTractName LL
	$1 wm_append_clusters.py $selecteddir/RR/ $selecteddir/  -appendedTractName RR
	$1 wm_append_clusters.py $selecteddir/LR/ $selecteddir/  -appendedTractName LR
	$1 wm_append_clusters.py $selecteddir/RL/ $selecteddir/  -appendedTractName RL
	
	# append all fiber
	mkdir -p $filterdir/all
	#$1 wm_append_clusters.py $filteredir/ $filteredir/all/  -appendedTractName all
	$1 wm_append_clusters.py $filteredir/ $selecteddir/  -appendedTractName all
	
	# filter all fiber and RGVP fiber
	python ./filter_fiber.py $selecteddir/LL.vtp $selecteddir/LL_filter.vtk $fiber_length
	python ./filter_fiber.py $selecteddir/LR.vtp $selecteddir/LR_filter.vtk $fiber_length
	python ./filter_fiber.py $selecteddir/RL.vtp $selecteddir/RL_filter.vtk $fiber_length
	python ./filter_fiber.py $selecteddir/RR.vtp $selecteddir/RR_filter.vtk $fiber_length
	python ./filter_fiber.py $selecteddir/all.vtp $selecteddir/all_filter.vtk $fiber_length
	
	
	#exit
done <$subject_list


