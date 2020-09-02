import sys
import pandas as pd
import numpy as np
import math
import os
import datetime as dt

##FUNCTION TO CONVERT FAHRENHEIT TO KELVIN:
def f2k(tempF):
        tempC = ((float(tempF)) - 32.) * (5./9.)
        tempK = float(tempC) + 273.15
        return(tempK)

##FUNCTION TO CONVERT DEW POINT (KELVIN) AND TEMP (KELVIN) TO RELATIVE HUMIDITY:
def dp2rh(dptK,tempK):
	dptK = float(dptK)
	tempK = float(tempK)
        #L = 2.453 * (10.**6.)
        L = 2453000
        Rv = 461.
        satVapPres = 6.11 * math.exp((L/Rv)*((1./273)-(1./tempK)))
        vapPres = 6.11 * math.exp((L/Rv)*((1./273)-(1./dptK)))
        RH = 100. * (vapPres/satVapPres)
        return(RH)

##FUNCTION TO GET HEAT INDEX (FAHRENHEIT):
def getHeatIndex(temp,RH):
        temp = float(temp)
        RH = float(RH)
        if (temp == np.nan) or (RH == np.nan):
                heatIndex = np.nan
        elif temp > 65:
                c1 = float(-42.379)
                c2 = float(2.04901523)
                c3 = float(10.14333127)
                c4 = float(-0.22475541)
                c5 = float(-0.00683783)
                c6 = float(-0.05481717)
                c7 = float(0.00122874)
                c8 = float(0.00085282)
                c9 = float(-0.00000199)
                heatIndex = c1 + (c2*temp) + (c3*RH) + (c4*temp*RH) + (c5*(temp**2.)) + (c6*(RH**2.)) + (c7*(temp**2.)*RH) + (c8*temp*(RH**2.)) + (c9*(temp**2.)*(RH**2.))
                if (RH < 13) and (temp >= 80) and (temp <= 112):
                        adjust = ((13.-RH)/4.)*(((17.-abs(temp-95.))/17.)**(1./2.))
                        heatIndex -= adjust
                elif (RH > 85) and (temp >= 80) and (temp <= 87):
                        adjust = ((RH-85.)/10.)*((87.-temp)/5.)
                        heatIndex += adjust
                heatIndex = round(heatIndex,1)
                if (float(heatIndex) < 80.):
                        heatIndex = "NC"
        else:
                heatIndex = "NC"
        return(heatIndex)

def isFloat(val):
	try:
		float(val)
		return(True)
	except:
		return(False)

def probOfHIX(df,temp):
	temp = float(temp)
	cDF = df.loc[:,["%04d" %(i) for i in range(1973,2019)]]
	outList = []
	outListBefore = []
	outListAfter = []
	for row in cDF.index.values:
		probTemp = (float(sum([1 for i in cDF.loc[row,:] if (isFloat(i)) and (float(i) >= temp) and not (np.isnan(i))]))/(cDF.loc[row,:].count()))
		nTempBefore = 0.
		nTempAfter = 0.
		nGoodYears = 0.
		for col in cDF.columns.tolist()[:47]:
			nMissing = cDF.shape[0] - cDF[col].count()
			#print("%s - %s - %.02f%%" %(col,nMissing,(float(nMissing)/(float(cDF.shape[0])))*100.)) ##
			if ((float(cDF[col].count())/float(cDF.shape[0])) >= 0.9):
				nGoodYears += 1.
				if (any(cDF.loc[:row,col] >= temp)):
					nTempBefore += 1
				if (any(cDF.loc[row:,col] >= temp)):
					nTempAfter += 1
		#print("%d Good Years of Data    |    %d Days Exceeding %d Before    |    %d Days Exceeding %d After" %(nGoodYears,nTempBefore,temp,nTempAfter,temp)) ##
		probTempBefore = nTempBefore/nGoodYears
		probTempAfter = nTempAfter/nGoodYears
		#probTempBefore = (float(sum([1 for col in cDF.columns.tolist()[:47] if any(cDF.loc[:row,col] >= temp) and ((cDF[col].count())/(cDF.shape[0]) >= 0.9)]))/(df.loc[row,'GoodYears']))
		#probTempAfter = (float(sum([1 for col in cDF.columns.tolist()[:47] if any(cDF.loc[(row+1):,col] >= temp) and ((cDF[col].count())/(cDF.shape[0]) >= 0.9)]))/(df.loc[row,'GoodYears']))
		outList.append(probTemp)
		outListBefore.append(probTempBefore)
		outListAfter.append(probTempAfter)
	df["Prob%d" %(temp)] = outList
	df["ProbBefore%d" %(temp)] = outListBefore
	df["ProbAfter%d" %(temp)] = outListAfter
	return(df)

##COLLECT DATA FROM FILES:
stnCount = 1
for file in os.listdir('./Data/OriginalData'):
	cStn = str(file)[0:4]
	cStnDF = pd.read_csv('./Data/OriginalData/%s-raw.csv' %(cStn),names=['Year','Month','Day','Time','Wind','Dwpt','Temp'],dtype=str)
	cStnDF['Date'] = ["%s-%s-%s" %(cStnDF.loc[row,'Year'],cStnDF.loc[row,'Month'],cStnDF.loc[row,'Day']) for row in cStnDF.index.values]
	#CALCULATE HEAT INDEX:
	cStnDF.loc[cStnDF['Dwpt'] == "M",'Dwpt'] = np.nan
	cStnDF.loc[cStnDF['Temp'] == "M",'Temp'] = np.nan
	cStnDF['RH'] = [dp2rh(f2k(cStnDF.loc[row,'Dwpt']),f2k(cStnDF.loc[row,'Temp'])) for row in cStnDF.index.values]
	cStnDF['HIX'] = [getHeatIndex(cStnDF.loc[row,'Temp'],cStnDF.loc[row,'RH']) for row in cStnDF.index.values]
	cStnDF.loc[cStnDF['HIX'] == "NC",'HIX'] = 0.
	#GET MAX HEAT INDEX FOR EACH DATE:
	cStnDataNew = []
	dateCount = 1
	nDates = len(np.unique(cStnDF['Date'].values.tolist()))
	for d in np.unique(cStnDF['Date']):
		print("%d | %d/%d - %.02f" %(stnCount,dateCount,nDates,(float(dateCount)/float(nDates))*100.))
		dateDF = cStnDF.loc[cStnDF['Date'] == d,:]
		maxHIX = np.amax(dateDF['HIX'])
		outList = dateDF.loc[dateDF.index.tolist()[0],['Year','Month','Day','Date']].values.tolist()
		outList.append(maxHIX)
		cStnDataNew.append(outList)
		dateCount += 1
	cStnDFnew = pd.DataFrame(cStnDataNew)
	cStnDFnew.columns = ['Year','Month','Day','Date','MaxHIX']
	#CALCULATE PROBABILITY OF HEAT INDEX EXCEEDING A THRESHOLD:
	cStnDFnew['MonthDay'] = [cStnDFnew.loc[row,'Month'] + cStnDFnew.loc[row,'Day'] for row in cStnDFnew.index.values]
	cStnDFnew = cStnDFnew.pivot(index='MonthDay',columns='Year',values='MaxHIX')
	cStnDFnew = cStnDFnew.reset_index()

	outDF = probOfHIX(cStnDFnew,80)
	outDF = probOfHIX(outDF,85)
	outDF = probOfHIX(outDF,90)
	outDF = probOfHIX(outDF,95)
	outDF = probOfHIX(outDF,100)
	outDF = probOfHIX(outDF,105)
	outDF = probOfHIX(outDF,110)
	outDF = probOfHIX(outDF,115)

	stnCount += 1

	outDF.to_csv('./Data/ProcessedData/%s_probs.csv' %(cStn),index=False)
	#outDF.to_csv('%s_probs.csv' %(cStn),index=False) ##
