library(ggplot2)
library(reshape2)
library(jsonlite)

files <- dir(path='Data/testdata',pattern="*.csv")

getMetaData <- function(stnId){
	url <- sprintf('https://cli-dap.mrcc.illinois.edu/station/%s/',stnId)
	stnMetaData <- try(fromJSON(txt = url),silent=TRUE)
	if (class(stnMetaData) == "try-error"){
		stnMetaData <- fromJSON(txt = url)
	}
	return(stnMetaData)
}

#f <- 1
outMat <- numeric(3)
for (f in 1:length(files)){
	filename <- sprintf('Data/testdata/%s',files[f],full.name=FALSE)

	stnId <- substr(files[f],1,4)

	stnMetaData <- getMetaData(stnId)
	stnName <- stnMetaData$stationname
	stnState <- stnMetaData$statecode

	outMat <- rbind(outMat,c(stnId,stnName,stnState))

	print(sprintf('%d / %d - %s',f,length(files),stnId))

	df <- read.csv(filename,header=TRUE,colClasses=c("MonthDay"="character"))

	df$MonthDay <- sapply(df$MonthDay,function(x) sprintf("2000%s",x))

	df <- df[,-which(colnames(df) %in% sapply(seq(1973,2019),function(x) sprintf("X%04d",x)))]

	df.bkp <- df

	df <- df[,-grep("Before",colnames(df))]
	df <- df[,-grep("After",colnames(df))]

	##FUNCTION TO CALCULATE MOVING AVERAGE:
	movingAvg <- function(dates,vals){
	  cDF <- data.frame(cbind(dates,vals))
	  colnames(cDF) <- c("Date","Val")
	  avgVals <- c()
	  for (row in 1:nrow(cDF)){
	    cDate <- as.Date(cDF[row,'Date'],'%Y%m%d')
	    startDate <- cDate - 15
	    endDate <- cDate + 15
	    dateList <- seq(startDate,endDate,by="days")
	    dateList <- sapply(dateList,function(x) sprintf("2000%s",format(x,'%m%d')))
	    goodDF <- subset(cDF,Date %in% dateList)
	    avgVal <- mean(as.numeric(as.character(goodDF$Val)))
	    avgVals <- c(avgVals,avgVal)
	  }
	  return(avgVals)
	}

	df$"80 F" <- movingAvg(df$MonthDay,df$Prob80)
	df$"85 F" <- movingAvg(df$MonthDay,df$Prob85)
	df$"90 F" <- movingAvg(df$MonthDay,df$Prob90)
	df$"95 F" <- movingAvg(df$MonthDay,df$Prob95)
	df$"100 F" <- movingAvg(df$MonthDay,df$Prob100)
	df$"105 F" <- movingAvg(df$MonthDay,df$Prob105)
	df$"110 F" <- movingAvg(df$MonthDay,df$Prob110)
	df$"115 F" <- movingAvg(df$MonthDay,df$Prob115)

	df$MonthDay <- as.Date(df$MonthDay,'%Y%m%d')

	df <- melt(df,id=colnames(df)[1:9])

	##ESTABLISH THEME:
	theme_weaver <- function(){
	  theme(
	    plot.title = element_text(hjust=0.5,face='bold',size=(15)),
	    plot.subtitle = element_text(hjust=0.5,face='bold.italic',size=(12)),
	    strip.text = element_text(face='bold'),
	    axis.title = element_text(face='bold'),
	    axis.text.x = element_text(angle=0,hjust=0.5,vjust=0),
	    #panel.grid.major.x = element_blank(),
	    panel.grid.minor.x = element_blank()#,
	    #legend.position='none'
	  )
	}

	g1 <- ggplot(data=df,aes(x=MonthDay)) +
	  geom_line(aes(y=value,color=variable),size=1) +
	  scale_x_date(date_breaks="1 month",date_labels="%b") +
	  scale_y_continuous(labels=scales::percent) +
	  scale_color_manual(name="Heat Index \U2265",values=c("#00CC00","#9FEE00","#FFD300","#FFAA00","#FF7400","#FF4900","#FF0000","#CD0074","#C600CD")) +
	  labs(x="Date",y="Probability",title="Heat Index Probability",subtitle=sprintf("%s - %s, %s",stnId,stnName,stnState)) +
	  theme_bw() +
	  theme_weaver()

	#print(g1)

	ggsave(sprintf('Graphs/Prob/HIXprob%s.png',stnId),g1,device='png',height=6,width=8,units='in',dpi=100)

	df <- df.bkp

	df <- df[,c("MonthDay",colnames(df)[grep("Before",colnames(df))])]

	##FUNCTION TO CALCULATE MOVING AVERAGE:
	movingAvg2 <- function(dates,vals){
	  cDF <- data.frame(cbind(dates,vals))
	  colnames(cDF) <- c("Date","Val")
	  avgVals <- c()
	  for (row in 1:nrow(cDF)){
	    cDate <- as.Date(cDF[row,'Date'],'%Y%m%d')
	    startDate <- cDate - 15
	    endDate <- cDate + 15
	    if (startDate < as.Date("2000-01-01",'%Y-%m-%d')){
	      startDate <- as.Date("2000-01-01",'%Y-%m-%d')
	    }
	    if (endDate > as.Date("2000-12-31",'%Y-%m-%d')){
	      endDate <- as.Date("2000-12-31",'%Y-%m-%d')
	    }
	    dateList <- seq(startDate,endDate,by="days")
	    dateList <- sapply(dateList,function(x) sprintf("2000%s",format(x,'%m%d')))
	    goodDF <- subset(cDF,Date %in% dateList)
	    avgVal <- mean(as.numeric(as.character(goodDF$Val)))
	    avgVals <- c(avgVals,avgVal)
	  }
	  return(avgVals)
	}

	df$"80 F" <- movingAvg2(df$MonthDay,df$ProbBefore80)
	df$"85 F" <- movingAvg2(df$MonthDay,df$ProbBefore85)
	df$"90 F" <- movingAvg2(df$MonthDay,df$ProbBefore90)
	df$"95 F" <- movingAvg2(df$MonthDay,df$ProbBefore95)
	df$"100 F" <- movingAvg2(df$MonthDay,df$ProbBefore100)
	df$"105 F" <- movingAvg2(df$MonthDay,df$ProbBefore105)
	df$"110 F" <- movingAvg2(df$MonthDay,df$ProbBefore110)
	df$"115 F" <- movingAvg2(df$MonthDay,df$ProbBefore115)

	df$MonthDay <- as.Date(df$MonthDay,'%Y%m%d')

	df <- melt(df,id=colnames(df)[1:9])

	g2 <- ggplot(data=df,aes(x=MonthDay)) +
	  geom_line(aes(y=value,color=variable),size=1) +
	  scale_x_date(date_breaks="1 month",date_labels="%b") +
	  scale_y_continuous(labels=scales::percent) +
	  scale_color_manual(name="Heat Index \U2265",values=c("#00CC00","#9FEE00","#FFD300","#FFAA00","#FF7400","#FF4900","#FF0000","#CD0074","#C600CD")) +
	  labs(x="Date",y="Probability",title="Heat Index Probability Before Date",subtitle=sprintf("%s - %s, %s",stnId,stnName,stnState)) +
	  theme_bw() +
	  theme_weaver()

	#print(g2)

	ggsave(sprintf('Graphs/ProbBefore/HIXprobBefore%s.png',stnId),g2,device='png',height=6,width=8,units='in',dpi=100)

	df <- df.bkp

	df <- df[,c("MonthDay",colnames(df)[grep("After",colnames(df))])]

	##FUNCTION TO CALCULATE MOVING AVERAGE:
	movingAvg2 <- function(dates,vals){
	  cDF <- data.frame(cbind(dates,vals))
	  colnames(cDF) <- c("Date","Val")
	  avgVals <- c()
	  for (row in 1:nrow(cDF)){
	    cDate <- as.Date(cDF[row,'Date'],'%Y%m%d')
	    startDate <- cDate - 15
	    endDate <- cDate + 15
	    if (startDate < as.Date("2000-01-01",'%Y-%m-%d')){
	      startDate <- as.Date("2000-01-01",'%Y-%m-%d')
	    }
	    if (endDate > as.Date("2000-12-31",'%Y-%m-%d')){
	      endDate <- as.Date("2000-12-31",'%Y-%m-%d')
	    }
	    dateList <- seq(startDate,endDate,by="days")
	    dateList <- sapply(dateList,function(x) sprintf("2000%s",format(x,'%m%d')))
	    goodDF <- subset(cDF,Date %in% dateList)
	    avgVal <- mean(as.numeric(as.character(goodDF$Val)))
	    avgVals <- c(avgVals,avgVal)
	  }
	  return(avgVals)
	}

	df$"80 F" <- movingAvg2(df$MonthDay,df$ProbAfter80)
	df$"85 F" <- movingAvg2(df$MonthDay,df$ProbAfter85)
	df$"90 F" <- movingAvg2(df$MonthDay,df$ProbAfter90)
	df$"95 F" <- movingAvg2(df$MonthDay,df$ProbAfter95)
	df$"100 F" <- movingAvg2(df$MonthDay,df$ProbAfter100)
	df$"105 F" <- movingAvg2(df$MonthDay,df$ProbAfter105)
	df$"110 F" <- movingAvg2(df$MonthDay,df$ProbAfter110)
	df$"115 F" <- movingAvg2(df$MonthDay,df$ProbAfter115)

	df$MonthDay <- as.Date(df$MonthDay,'%Y%m%d')

	df <- melt(df,id=colnames(df)[1:9])

	g3 <- ggplot(data=df,aes(x=MonthDay)) +
	  geom_line(aes(y=value,color=variable),size=1) +
	  scale_x_date(date_breaks="1 month",date_labels="%b") +
	  scale_y_continuous(labels=scales::percent) +
	  scale_color_manual(name="Heat Index \U2265",values=c("#00CC00","#9FEE00","#FFD300","#FFAA00","#FF7400","#FF4900","#FF0000","#CD0074","#C600CD")) +
	  labs(x="Date",y="Probability",title="Heat Index Probability After Date",subtitle=sprintf("%s - %s, %s",stnId,stnName,stnState)) +
	  theme_bw() +
	  theme_weaver()

	#print(g3)

	ggsave(sprintf('Graphs/ProbAfter/HIXprobAfter%s.png',stnId),g3,device='png',height=6,width=8,units='in',dpi=100)
}
outMat <- outMat[-1,]
outDF <- as.data.frame(outMat)
colnames(outDF) <- c("StnID","StnName","StnState")
write.csv(outDF,file='stationData.csv',row.names=FALSE,quote=FALSE)
