export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Slicer-5.2
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/UKFTractography/lib/Slicer-5.2/qt-loadable-modules
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Teem-1.12.0


UKFTractography=/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/UKFTractography/lib/Slicer-5.2/cli-modules/UKFTractography

subject_list=./subj_list.txt


while read caseid ; 
do
	echo $caseid
	
	data_dwi_space_folder=./dwi/${caseid}.dti

	DWIQCed_nrrd=${data_dwi_space_folder}/${caseid}_QCed.nrrd
	
	#DWIQCed_nrrd=${data_dwi_space_folder}/${caseid}.nhdr
	
	#RGVP_mask=$data_dwi_space_folder/${caseid}_QCed_RGVP_mask-edit.nrrd
	RGVP_mask=$data_dwi_space_folder/${caseid}_QCed_RGVP_mask.nrrd

	outputdir=$data_dwi_space_folder/${caseid}_UKF
	mkdir -p $outputdir

	qms=(0.001 0.003 0.005 0.007)
	qls=(50 100 150 200 250 300)

	for qm in ${qms[@]}
	do
		for ql in ${qls[@]}
		do
			if [ ! -f $outputdir/ql${ql}_qm${qm}.vtk ]
			then
				$1 $UKFTractography --dwiFile $DWIQCed_nrrd --maskFile $RGVP_mask --seedsFile $RGVP_mask --numTensor 2 --seedsPerVoxel 20 --stoppingThreshold 0.06 --stoppingFA 0.01 --seedingThreshold 0.02 --Qm ${qm} --Ql ${ql} --tracts $outputdir/ql${ql}_qm${qm}.vtk --recordFA
			fi
		done
	done

	#exit
done <$subject_list


