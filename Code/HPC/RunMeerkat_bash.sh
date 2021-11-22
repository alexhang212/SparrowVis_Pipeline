#!/bin/bash
#PBS -l walltime=20:00:00
#PBS -l select=1:ncpus=2:mem=1gb

module load anaconda3/personal
source activate SparrowVis

work_dir=$EPHEMERAL/MeerkatDir/$PBS_ARRAY_INDEX #create new directory for each sub run
mkdir $work_dir
cd $work_dir

#initialize array to store vid names:
VidArr=()

#Get all video files from MeerkatInput
for entry in "$EPHEMERAL/MeerkatInput"/*
do
VidArr+=("$entry")
#echo $entry

done

#get index of video to run
Index=$PBS_ARRAY_INDEX
let Index-=1
echo $Index

vid=${VidArr[$Index]} # path to video to run
vidBase=$(basename -- "$vid") #vid with extension
vidName=$(basename -- "$vid"| cut -f 1 -d '.') # get name of video without extension or path
echo $vidBase
echo $vidName

#copy model and video to working directory:
cp $vid ./
#cp -r ../../DeepMeerkat/DeepMeerkat/model/ ./

#running meerkat:
echo "Meerkat is about to run"
python $HOME/ModelTraining/DeepMeerkat/DeepMeerkat/Meerkat.py --input $vidBase --path_to_model $HOME/ModelTraining/DeepMeerkat/DeepMeerkat/model/ --output ./
err=$? #save success of previous step($?) as err
echo "Meerkat is finished running"

if [[ $err -eq 0 ]]
then
    #run successful, move folder to output, delete video
    echo "script succeeded!"
    rm $vidName/*.jpg #remove all images
    mv $vidName $HOME/Pipeline/MeerkatOutput
    rm -r $work_dir
    mv $vid $EPHEMERAL/RawVideos #remove source vid
else
    #run not successful
    echo "script failed!"
    rm -r $work_dir

fi


#end of file
