export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/SlicerDMRI/lib/Slicer-5.2/qt-loadable-modules
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Slicer-5.2
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Teem-1.12.0

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Python/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Slicer-5.2/cli-modules
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/weizhang/Desktop/Slicer-4.8.1-linux-amd64/lib/Slicer-4.8


SlicerDMRICLI=/home/weizhang/Slicer-5.2.2-linux-amd64/NA-MIC/Extensions-31382/SlicerDMRI/lib/Slicer-5.2/cli-modules
DTIPrep=/home/weizhang/DTIPrep1.2/DTIPrep
BRAINSFit=//home/weizhang/Slicer-5.2.2-linux-amd64/lib/Slicer-5.2/cli-modules/BRAINSFit
ResampleScalarVectorDWIVolume=/home/weizhang/Slicer-5.2.2-linux-amd64/lib/Slicer-5.2/cli-modules/ResampleScalarVectorDWIVolume 


subject_list=./subj_list.txt


while read caseid ; 
do
	echo $caseid
	
	data_dwi_space_folder=./dwi/${caseid}.dti
	
	DWI=${data_dwi_space_folder}/${caseid}.nhdr

	# Motion correction
	DWIQCed_nrrd=${data_dwi_space_folder}/${caseid}_QCed.nrrd
	if [ ! -f $DWIQCed_nrrd ]; then 
	    $1 $DTIPrep --DWINrrdFile $DWI --check  --xmlProtocol ./dtiprepprotocalonlyeddy.xml
	fi

	# extract b0 and dti
	b0=${data_dwi_space_folder}/${caseid}_QCed_b0.nrrd
	dti=${data_dwi_space_folder}/${caseid}_QCed_dti.nrrd
	if [ ! -f ${b0} ]; then
		$1 $SlicerDMRICLI/DWIToDTIEstimation $DWIQCed_nrrd ${dti} ${b0} --enumeration WLS
	fi

	# register input data to template
	atlas_T2=./average_T2w_wholehead.nii.gz
	tfm=${data_dwi_space_folder}/${caseid}_b0_to_atlasT2.tfm
	if [ ! -f $tfm ]; then
	    $1 $BRAINSFit --fixedVolume $atlas_T2 --movingVolume $b0 --linearTransform $tfm --useRigid --useAffine
	fi

	# align atlas RGVP mask to DWI
	tfm_Inverse=${data_dwi_space_folder}/${caseid}_b0_to_atlasT2_Inverse.h5
	atlas_T2_mask=ORG_ON-mask-draw.nii.gz
    RGVP_mask=$data_dwi_space_folder/${caseid}_QCed_RGVP_mask.nrrd
    interpolation=nn
    if [ ! -f ${RGVP_mask} ]; then
        $1 $ResampleScalarVectorDWIVolume --Reference $b0 --transformationFile $tfm_Inverse --hfieldtype h-Field \
            --interpolation $interpolation --transform_order output-to-input --image_center input --transform a ${atlas_T2_mask} $RGVP_mask
    fi
	
done <$subject_list
