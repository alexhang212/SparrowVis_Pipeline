#!/bin/bash
#Runs pipeline, takes 1 video as input

echo "Processing " $1
vidName=$(basename -- "$1"| cut -f 1 -d '.') #gets base name of video without extension

##1.run meerkat:
python ../DeepMeerkat/DeepMeerkat/Meerkat.py --input $1 --path_to_model ../DeepMeerkat/DeepMeerkat/model/ --output ../Output/

#Remove all images and move video to raw videos
rm ../Output/$vidName/*.jpg
mv $1 ../RawVideos/

##2.Define events from R
Rscript ProcessFrameInfo.R $vidName

##3.Get Clips
python ExtractFrames.py $vidName

