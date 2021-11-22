#!/bin/bash
#Runs pipeline, loops through all videos in Meerkat Input

#Get all video files from MeerkatInput

VidArr=()
for entry in "../MeerkatInput"/*
do
VidArr+=($entry)
# echo $entry
# echo $VidArr
done

# echo ${VidArr[@]}


for vid in ${VidArr[@]}
do
echo "Processing " $vid
vidName=$(basename -- "$vid"| cut -f 1 -d '.') #gets base name of video without extension

##1.run meerkat:
python ../DeepMeerkat/DeepMeerkat/Meerkat.py --input $vid --path_to_model ../DeepMeerkat/DeepMeerkat/model/ --output ../Output/

#Remove all images and move video to raw videos
rm ../Output/$vidName/*.jpg
mv $vid ../RawVideos/

##2.Define events from R
Rscript ProcessFrameInfo.R $vidName

##3.Get Clips
python ExtractFrames.py $vidName

done