#!/bin/bash
source /home/bpeake/.bashrc

cd /home/bpeake/chillHeatClimo/windChill

file=$1

startyr=1973
endyr=$2

while IFS= read -r line
do
        # display $line or do somthing with $line
	wban=$line
	
	perl pullALLdataWC.pl $endyr $wban

	mkdir /home/bpeake/chillHeatClimo/Data/$wban/

	mv $wban-raw.csv $wban-QC.csv /home/bpeake/chillHeatClimo/Data/$wban/

	#cp /home/bpeake/chillHeatClimo/Data/$wban/$wban-raw.csv /home/bpeake/chillHeatClimo/Data/$wban/$wban-QC.csv /home/bpeake/chillHeatClimo/Data30yr90prct/$wban/

	echo $wban

	perl tablesWCMon.pl $wban Data $startyr $endyr
	echo Done

	#perl tablesWChr.pl $wban Data $startyr $endyr
	#echo Done

	perl percentTablesWC.pl $wban Data $startyr $endyr
	echo percentTables.pl Done

	#perl percentTablesWCHR.pl $wban Data $startyr $endyr
	#echo percentTablesHR.pl Done

	perl WCDays.pl $wban Data $startyr $endyr
	echo WCDays.pl Done

	Station=$wban

done <"$file"
