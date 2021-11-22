# Processes output info of frames from deep meerkat and define it as events
# rm(list=ls())

library(dplyr)

# #testing
# FileName <- "VK0024"
# Process_framecsv(FileName)

Process_framecsv <- function(FileName){
  #processes raw data from meerkat, outputs long and short format of events
  print(FileName)
  data <- read.csv(paste("../Output/",FileName,"/annotations.csv", sep="" ), stringsAsFactors=F)
  #case where meerkat detected nothing
  if(nrow(data)==0){
    data <- data.frame(matrix(data=NA, nrow=0, ncol=11))
    names(data) <-c("Frame","Clock","x","y","h","w","label","score","FileName","diff","Event")
    write.csv(data, file=paste("../Output/",FileName,"/FramesLong.csv", sep=""))
    DataShort <- data.frame(matrix(data=NA, nrow=0, ncol=4))
    names(DataShort) <-c("Event","MeanTime","StartFrame", "EndFrame")
    write.csv(DataShort, file=paste("../Output/",FileName,"/FramesShort.csv", sep=""))
    return(NULL) # to break out of function
    
  }
  
  data$FileName <- FileName #Add file name column
  
  ##Newly Added: Solve duplication problem
  
  DupVals <- unique(data$Frame[duplicated(data$Frame)]) # get frame values that are duplicated
  
  #only keeping the row (box) with the largest confidence score
  for(i in 1: length(DupVals)){
    sub <- subset(data,data$Frame==DupVals[i])
    sub <- sub[-which.max(sub$score),] #leave the other rows
    data <- anti_join(data,sub) #dyplr function to exlude the other unwanted rows
    
  }
  
  
  #defining events:
  data$diff <- c(0,diff(data$Frame))
  
  #group stuff that is lower than 40 diff frames sequentially,remove 2 frames or less
  counter <- 1 #counter for event num
  EventNumCounter <- 0 # counter for number of frames in each evnt
  EventVect <- rep(NA,nrow(data))
  for(i in 1:nrow(data)){
    #browser()
    if(data$diff[i]>40){
      if(EventNumCounter <2){
        #if previous 'event' has 2 or less frames
        EventVect[(i-EventNumCounter):(i-1)] <- NA
        counter <- counter-1}
      #larger than 40, new event
      counter <- counter+1
      EventVect[i] <- counter
      EventNumCounter <- 1 #counts number of frames in the event
    }else{
      #smaller than 40, continue same event
      EventVect[i] <- counter
      EventNumCounter <- EventNumCounter +1 
    }
  }
  
  #if final 'event' has 2 or less frames
  if(EventNumCounter <2){
    #if previous 'event' has 2 or less frames
    EventVect[(i-EventNumCounter):i] <- NA
  }
  
  data$Event <- EventVect
  # write.csv(data, file=paste("../MeerkatOutput/",FileName,"/FramesLong.csv", sep=""))
  
  
  ###Part 2: Get short format:###
  
  #convert time to decimals:
  data$Time.dec <-sapply(strsplit(data$Clock, ":"), 
                         function(x){
                           x <- as.numeric(x)
                           x[1]*60 + x[2]+x[3]/60
                         })
  
  #convert long to short format:
  UnqEvents <- na.omit(unique(data$Event))
  if(length(UnqEvents)==0){ # to solve bug where no events can be defined
    DataShort <- data.frame(matrix(data=NA, nrow=length(UnqEvents), ncol=4))
    names(DataShort) <-c("Event","MeanTime","StartFrame", "EndFrame")
    write.csv(DataShort, file=paste("../Output/",FileName,"/FramesShort.csv", sep=""))
    return(NULL) # to break out of function
  }
  
  DataShort <- data.frame(matrix(data=NA, nrow=length(UnqEvents), ncol=4))
  names(DataShort) <-c("Event","MeanTime","StartFrame", "EndFrame")
  
  ###Doing further event manip: if start time of events within 7 seconds, group as same event
  for(i in 1:length(UnqEvents)){
    sub <- subset(data,data$Event==UnqEvents[i])
    DataShort[i,] <- c(UnqEvents[i], mean(sub$Time.dec), sub[1,names(sub)=="Frame"],sub[nrow(sub),names(sub)=="Frame"])
  }
  
  DataShort2 <- data.frame(matrix(data=NA, nrow=0, ncol=4))
  names(DataShort2) <-c("Event","MeanTime","StartFrame", "EndFrame")
  Evntcounter <- 1
  Mergecounter <- 1
  
  while(nrow(DataShort)>0){
    # browser()
    if(nrow(DataShort)==1){
      #last row left, nothing to compare
      TempShort <- data.frame(Event=Evntcounter, MeanTime=mean(DataShort[1:Mergecounter,"MeanTime"]), 
                              StartFrame=DataShort[1,"StartFrame"], EndFrame=DataShort[Mergecounter,"EndFrame"])
      DataShort2 <- rbind(DataShort2, TempShort)
      DataShort <- DataShort[-c(1:Mergecounter),]
      break
    }
    
    if((DataShort[(1+Mergecounter),"EndFrame"]-DataShort[1,"StartFrame"])<(25*6)){
      #next one is within 7 sec
      Mergecounter <- Mergecounter +1
      
      if(Mergecounter==nrow(DataShort)){ #exception where the final few events should be merged
        TempShort <- data.frame(Event=Evntcounter, MeanTime=mean(DataShort[1:Mergecounter,"MeanTime"]), 
                                StartFrame=DataShort[1,"StartFrame"], EndFrame=DataShort[Mergecounter,"EndFrame"])
        DataShort2 <- rbind(DataShort2, TempShort)
        DataShort <- DataShort[-c(1:Mergecounter),]
      }
      
    }else{
      #next one is not within 7 sec, log event
      TempShort <- data.frame(Event=Evntcounter, MeanTime=mean(DataShort[1:Mergecounter,"MeanTime"]), 
                              StartFrame=DataShort[1,"StartFrame"], EndFrame=DataShort[Mergecounter,"EndFrame"])
      DataShort2 <- rbind(DataShort2, TempShort)
      DataShort <- DataShort[-c(1:Mergecounter),]
      Mergecounter <- 1
      Evntcounter <- Evntcounter + 1
      
    }
  }
  
  DataShort2$Diff <- (DataShort2$EndFrame-DataShort2$StartFrame)/25
  write.csv(DataShort2, file=paste("../Output/",FileName,"/FramesShort.csv", sep=""))
  
  
}



#Process File
args = commandArgs(trailingOnly=TRUE)
FileName = args[1]
print(paste("Processing", FileName))
Process_framecsv(FileName)