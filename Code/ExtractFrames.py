#!/usr/bin/env python3
"""Extract 7 second event clips from Meerkat Output and Raw Videos"""

import subprocess
import os 
import csv
import moviepy
import numpy as np
import math
import moviepy.editor as mpy
import pandas as pd
import sys



#function from online to split vector into equal chunks:
def split(a, n):
    k, m = divmod(len(a), n)
    return (a[i*k+min(i, m):(i+1)*k+min(i+1, m)] for i in range(n))


def main(argv):
    Vid = argv[1] 
    df = pd.read_csv("../Output/{Vid}/FramesShort.csv".format(Vid=Vid))

    #Find the raw video file
    VidFile = []
    for file in os.listdir("../RawVideos/"):
        if file.startswith(Vid):
            VidFile.append(file)
    
    #quick checks:
    if len(VidFile) == 0:
        print("No Raw Video found for video {Vid}".format(Vid=Vid))
    elif len(VidFile) > 1:
        print("multiple Videos fouund, somethings wrong :o")
    else:
        print("all good")

    #read in video:
    RawVid = mpy.VideoFileClip("../RawVideos/{File}".format(File=VidFile[0]))


    #make direectory for clips
    if not os.path.exists("../Output/{Vid}/".format(Vid=Vid)):
            os.mkdir("../Output/{Vid}/".format(Vid=Vid ))
    
    for i in range(len(df.index)): #for each row of dataframe
        Start = df.iloc[i,df.columns.get_loc("StartFrame")]
        StartTime = math.floor((Start/25))
        Event = df.iloc[i,df.columns.get_loc("Event")]
        TimeSeq= np.linspace(StartTime,StartTime+7,22) #get vector for time frames

        #Extract Clips
        Clip = RawVid.subclip(StartTime-1, StartTime+6) #7 seconds clip, starting from start time -1
        Clip.write_videofile("../Output/{Vid}/Event{Event}.mp4".format(Vid=Vid, Event=Event),audio=False)

if __name__ == "__main__": 
    """Makes sure the "main" function is called from command line"""  
    status = main(sys.argv)
    sys.exit(status)

