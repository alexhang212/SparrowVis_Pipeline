#!/usr/bin/env python3
"""Extracts Frames from videos for further segmentation on HPC"""

import subprocess
import os 
import csv
import moviepy
import numpy as np
import math
import moviepy.editor as mpy
import pandas as pd


iter = os.getenv("PBS_ARRAY_INDEX")#get index from cluster
iter = int(iter) - 1
maxiter = 500 #the number of subjobs called from HPC
Homedir = os.getenv("HOME")
Ephdir = os.getenv("EPHEMERAL")

#function from online to split vector into equal chunks:
def split(a, n):
    k, m = divmod(len(a), n)
    return (a[i*k+min(i, m):(i+1)*k+min(i+1, m)] for i in range(n))


#get dir names of meerkat output
DirNames = []
for root, dirs, files in os.walk("../MeerkatOutput", topdown=False):
    DirNames += dirs

#split dirnames into equal chunks:
chunks = list(split(DirNames, maxiter))

##Process videos:
for Vid in chunks[iter]:
    #extracting frames
    df = pd.read_csv("../MeerkatOutput/{Vid}/FramesShort.csv".format(Vid=Vid))

    #Find the raw video file
    VidFile = []
    for file in os.listdir("{Eph}/RawVideos2/".format(Eph=Ephdir)):
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
    RawVid = mpy.VideoFileClip("{Eph}/RawVideos/{File}".format(Eph=Ephdir, File=VidFile[0]))


    #make direectory for clips
    if not os.path.exists("{Eph}/Clips/{Vid}/".format(Vid=Vid, Eph=Ephdir)):
            os.mkdir("{Eph}/Clips/{Vid}/".format(Vid=Vid, Eph = Ephdir))
    
    for i in range(len(df.index)): #for each row of dataframe
        Start = df.iloc[i,df.columns.get_loc("StartFrame")]
        StartTime = math.floor((Start/25))
        Event = df.iloc[i,df.columns.get_loc("Event")]
        TimeSeq= np.linspace(StartTime,StartTime+7,22) #get vector for time frames


        #Extract Clips
        Clip = RawVid.subclip(StartTime-1, StartTime+6) #7 seconds clip, starting from start time -1
        Clip.write_videofile("{Eph}/Clips/{Vid}/Event{Event}.mp4".format(Vid=Vid, Event=Event, Eph=Ephdir),audio=False)

        


