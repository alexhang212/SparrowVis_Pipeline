## Organize all meerkat output files into csv with Meerkat frequency and video naem
rm(list=ls())

# Video <- "V0115_LM28_V6I_20180520"

Videos <- list.files("../Output/")
VideoCode <- sapply(Videos, function(x) substr(x, 1,6)) ##get first 6 letters of video

##for non duplicated videos
GetMeerkatFreq <- function(Video){
  Short <- read.csv(paste("../Output/",Video,"/FramesShort.csv", sep=""))
  Sub90 <- subset(Short,Short$MeanTime<90)
  Freq <- nrow(Sub90)
  Time <- 90 - Sub90$MeanTime[1]
  return(c(Video,Freq,Time))
}

FreqList <- lapply(Videos, GetMeerkatFreq)
FreqDF <- data.frame(matrix(unlist(FreqList), ncol=3, byrow=T))
names(FreqDF) <- c("Video","PipelineVisits","PipelineEffTime" )

write.csv(FreqDF, "../AutoVisitRate.csv")
