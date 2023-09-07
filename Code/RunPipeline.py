"""Run full sparrow vis pipeline, replaces bash script"""

import sys
import subprocess
import argparse
import os
import glob
import shutil

def RunPipeline(VideoPath):
    #Deep Meerkat:
    print("#####Deep Meerkat:#####")

    print("Processing %s"%VideoPath)
    BaseName = os.path.basename(VideoPath).split(".")[0]
    result = subprocess.run(["python", 
                             "../DeepMeerkat/DeepMeerkat/Meerkat.py",
                             "--input",VideoPath,
                             "--path_to_model",
                             "../DeepMeerkat/DeepMeerkat/model/",
                             "--output","../Output/"])

    ##Remove files
    for f in glob.glob(os.path.join("..","Output",BaseName,"*.jpg")):
        os.remove(f)
    # shutil.move(VideoPath, "../RawVideos/")

    ###R script for processing:
    print("#####Process Output:#####")

    result = subprocess.run(["Rscript","ProcessFrameInfo.R",BaseName ])

    ###Get Clips:
    print("#####Get Clips:#####")
    result = subprocess.run(["python","ExtractFrames.py",BaseName ])

    print("#####  FINISH  #####")

    return True

if __name__ == "__main__":

    ###parse arguments:
    parser = argparse.ArgumentParser()

    parser.add_argument("--path",
                        type=str,
                        required=True,
                        # default='./experiments/muppet_600.yaml',
                        help="Input: Specify the path to video or directory (for loop mode)")
    parser.add_argument("--loop",
                        action='store_true',
                        help="Activate Loop mode, loops through specified directory")

    arg = parser.parse_args()

    ##start:
    print("Here are the input arguments:")
    print("Input Path: %s" %arg.path)
    print("Loop Mode is set as: %s" %str(arg.loop))

    if arg.loop == True:
        if os.path.isdir(arg.path):
            ##loop through
            for vid in os.listdir(arg.path):
                RunPipeline(vid)
        else:
            raise Exception("Loop mode is used, but path is not a directory")
    else: #single video mode
        if os.path.exists(arg.path):
            ##Run 1 vid
            RunPipeline(arg.path)
        else:
            raise Exception("Video File not found, check path")
        


