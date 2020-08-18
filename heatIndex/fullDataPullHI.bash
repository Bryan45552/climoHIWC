#!/bin/bash
source /home/bpeake/.bashrc

cd /home/bpeake/chillHeatClimo/heatIndex

file=$1

startyr=1973
endyr=$2

echo $file;
echo $endyr;

while IFS= read -r line
do
        # display $line or do somthing with $line
	wban=$line
	
	perl pullALLdataHI.pl $endyr $wban

	mkdir /home/bpeake/chillHeatClimo/Data/$wban/

	mv $wban-raw.csv $wban-QC.csv /home/bpeake/chillHeatClimo/Data/$wban/

	#cp /home/bpeake/chillHeatClimo/Data/$wban/$wban-raw.csv /home/bpeake/chillHeatClimo/Data/$wban/$wban-QC.csv /home/bpeake/chillHeatClimo/Data30yr90prct/$wban/

	echo $wban

	perl tablesHI.pl $wban Data $startyr $endyr
	echo Done

	#perl tablesHIHR.pl $wban Data $startyr $endyr
	#echo Done

	perl percentTablesHI.pl $wban Data $startyr $endyr
	echo percentTables.pl Done

	perl percentTablesHIHR.pl $wban Data $startyr $endyr
	echo percentTablesHIHR.pl Done

	perl HIDays.pl $wban Data $startyr $endyr 1
	echo WCDays.pl Done

	Station=$wban

done <"$file"
