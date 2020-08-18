#!/bin/env perl

$station=$ARGV[0];
$folder=$ARGV[1];

$startyr=$ARGV[2];
$endyr=$ARGV[3];

$PORlen=$endyr-$startyr+1;

$minHIthresh=80;
$maxHIthresh=115;

$minWCthresh=-40;
$maxWCthresh=50;

$maxHI=0;
$minWC=99;

#Read in Actual Obs files

$obsFileHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsHr.csv";

open(my $fh2, "<",$obsFileHr);

while (my $line1 = <$fh2>)
{
        chomp $line;
        @values=split(/,/, $line1);
	$year[$i]=$values[0];
        for($Hr=1;$Hr<=24;$Hr++)
	{
		$actHr[$i][$Hr]=$values[$Hr];
		$actClimTotHr[$Hr]=$actClimTotHr[$Hr]+$actHr[$i][$Hr];
	}

	$actYr[$i]=$values[25];

	$yrObsTot=$yrObsTot+$actYr[$i];

        $i++;
}

$i=0;$j=0;


#Goes through WC thresholds and reads in data to be manipulated
#Calculates percentages of hours and months with obs for thresholds
#Also tracks totals for the full POR climatology

$ClimFileAvg="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgWCObsHr.csv";
$ClimFilePerc="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgWCPercHr.csv";

open(CLIM, ">$ClimFileAvg") or die "Can't open";
open(CLIMP, ">$ClimFilePerc") or die "Can't open";


print CLIM "Threshold,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,Annual\n";
print CLIMP "Threshold,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,Annual\n";

for($WCthr=$maxWCthresh;$WCthr>=$minWCthresh;$WCthr=$WCthr-5)
{

	$WCfileHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-$WCthr-threshWCHr.csv";
	open(my $fhX, "<",$WCfileHr);

	$OutHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-$WCthr-threshWCHr-perc.csv";

	open(OUTHR, ">$OutHr") or die "Can't open";
	print OUTHR "Year,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,All Months";

	while (my $lineX = <$fhX>)
	{
		chomp $lineX;
		@values=split(/,/, $lineX);

		print OUTHR "\n$year[$i]";

		for($Hr=1;$Hr<=24;$Hr++)
		{
			$windChillObsHr[$i][$Hr][100-$WCthr]=$values[$Hr];#Number of Obs for that hour at thresh
			$windChillClimTotHr[$Hr][100-$WCthr]=$windChillClimTotHr[$Hr][100-$WCthr]+$windChillObsHr[$i][$Hr][100-$WCthr];#POR number of obs for that month at thresh
			$windChillYr[$i][100-$WCthr]=$windChillYr[$i][100-$WCthr]+$windChillObsHr[$i][$Hr][100-$WCthr];#Number of obs for that year at thresh

			if($actHr[$i][$Hr] != 0){$PercentObsWCHr[$i][$Hr][100-$WCthr]=sprintf("%.1f",100*($windChillObsHr[$i][$Hr][100-$WCthr]/$actHr[$i][$Hr]));}#Percent of Obs for that month at thresh
			else{$PercentObsWCHr[$i][$Hr][100-$WCthr]="M";}			

			print OUTHR ",$PercentObsWCHr[$i][$Hr][100-$WCthr]";
		}
			$windChillYrTot[100-$WCthr]=$windChillYrTot[100-$WCthr]+$windChillYr[$i][100-$WCthr];#POR number of obs at thresh
			if($actYr[$i] != 0){$percentWCYr[$i][100-$WCthr]=sprintf("%.1f",100*($windChillYr[$i][100-$WCthr]/$actYr[$i]));}#Percent of obs for that year at thresh
			else{$percentWCYr[$i][100-$WCthr]="M";}

			print OUTHR ",$percentWCYr[$i][100-$WCthr]";


		$i++;
	}
	#Avg Obs POR
	print OUTHR "\nAvg Obs";
	
	print CLIM "$WCthr";
	print CLIMP "$WCthr";
	
	for($Hr=1;$Hr<=24;$Hr++)
	{
		$avgObsHr[$Hr][100-$WCthr]=sprintf("%.1f",$windChillClimTotHr[$Hr][100-$WCthr]/$PORlen);
		print OUTHR ",$avgObsHr[$Hr][100-$WCthr]";
		print CLIM ",$avgObsHr[$Hr][100-$WCthr]";
	}

	$avgObsYr[100-$WCthr]=sprintf("%.1f",$windChillYrTot[100-$WCthr]/$PORlen);
	print OUTHR ",$avgObsYr[100-$WCthr]";
	print CLIM ",$avgObsYr[100-$WCthr]\n";

	# % Obs POR
	
	print OUTHR "\nAnnual";

        for($Hr=1;$Hr<=24;$Hr++)
        {
                if($actClimTotHr[$Hr] != 0){$percObsHr[$Hr][100-$WCthr]=sprintf("%.1f",100*($windChillClimTotHr[$Hr][100-$WCthr]/$actClimTotHr[$Hr]));}
		else{$percObsHr[$Hr][100-$WCthr]="M";}
                print OUTHR ",$percObsHr[$Hr][100-$WCthr]";
		print CLIMP ",$percObsHr[$Hr][100-$WCthr]";
        }

        if($yrObsTot != 0){$percObsYr[100-$WCthr]=sprintf("%.1f",100*($windChillYrTot[100-$WCthr]/$yrObsTot));}
	else{$percObsYr[100-$WCthr]="M";}

        print OUTHR ",$percObsYr[100-$WCthr]";
	print CLIMP ",$percObsYr[100-$WCthr]\n";

	close(OUTHR);

	$i=0;$j=0;

}
