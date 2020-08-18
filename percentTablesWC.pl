#!/bin/env perl

$station=$ARGV[0];
$folder=$ARGV[1];

$startyr=$ARGV[2];
$endyr=$ARV[3];

$PORlen=$endyr-$startyr+1;

$minWCthresh=-40;
$maxWCthresh=50;

$maxHI=0;
$minWC=99;

#Read in Actual Obs files
#Actual Obs files will be used to determine more accurate
#percentage and average observation values.

$obsFileMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsMo.csv";

open(my $fh1, "<",$obsFileMo);

while (my $line = <$fh1>)
{
    chomp $line;
    @values=split(/,/, $line);
	$year[$i]=$values[0];
	#Note that while values 1-12 are used, the order in the actObsMo file
	#is 7-12, 1-6.  Since they are all on one line, need to do in actual
	#month order is not necessary.
	for($mo=1;$mo<=12;$mo++)
	{
		$actMo[$i][$mo]=$values[$mo];
		$actClimTotMo[$mo]=$actClimTotMo[$mo]+$actMo[$i][$mo];
		$actYr[$i]=$actYr[$i]+$actMo[$i][$mo];
	}

	$yrObsTot=$yrObsTot+$actYr[$i];

	$i++;
}


$i=0;$j=0;

#Goes through WC thresholds and reads in data to be manipulated
#Calculates percentages of hours and months with obs for thresholds
#Also tracks totals for the full POR climatology

$ClimFileAvg="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgWCObsMo.csv";
$ClimFilePerc="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgWCPercMo.csv";

open(CLIM, ">$ClimFileAvg") or die "Can't open";
open(CLIMP, ">$ClimFilePerc") or die "Can't open";


print CLIM "Threshold,7,8,9,10,11,12,1,2,3,4,5,6,Annual\n";
print CLIMP "Threshold,7,8,9,10,11,12,1,2,3,4,5,6,Annual\n";

for($WCthr=$maxWCthresh;$WCthr>=$minWCthresh;$WCthr=$WCthr-5)
{

	$WCfileMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-$WCthr-threshWCMo.csv";
	open(my $fhX, "<",$WCfileMo);

	$OutMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-$WCthr-threshWCMo-perc.csv";

	open(OUTMO, ">$OutMo") or die "Can't open";
	print OUTMO "StartYear,7,8,9,10,11,12,1,2,3,4,5,6,All Months";

	while (my $lineX = <$fhX>)
	{
		chomp $lineX;
		@values=split(/,/, $lineX);

		print OUTMO "\n$year[$i]";

		for($mo=1;$mo<=12;$mo++)
		{
			$windChillObsMo[$i][$mo][100-$WCthr]=$values[$mo];#Number of Obs for that month at thresh
			$windChillClimTotMo[$mo][100-$WCthr]=$windChillClimTotMo[$mo][100-$WCthr]+$windChillObsMo[$i][$mo][100-$WCthr];#POR number of obs for that month at thresh
			$windChillYr[$i][100-$WCthr]=$windChillYr[$i][100-$WCthr]+$windChillObsMo[$i][$mo][100-$WCthr];#Number of obs for that year at thresh

			if($actMo[$i][$mo] != 0){$PercentObsWCMo[$i][$mo][100-$WCthr]=sprintf("%.1f",100*($windChillObsMo[$i][$mo][100-$WCthr]/$actMo[$i][$mo]));}#Percent of Obs for that month at thresh
			else{$PercentObsWCMo[$i][$mo][100-$WCthr]="M";}			

			print OUTMO ",$PercentObsWCMo[$i][$mo][100-$WCthr]";
		}
			$windChillYrTot[100-$WCthr]=$windChillYrTot[100-$WCthr]+$windChillYr[$i][100-$WCthr];#POR number of obs at thresh
			if($actYr[$i] != 0){$percentWCYr[$i][100-$WCthr]=sprintf("%.1f",100*($windChillYr[$i][100-$WCthr]/$actYr[$i]));}#Percent of obs for that year at thresh
			else{$percentWCYr[$i][100-$WCthr]="M";}

			print OUTMO ",$percentWCYr[$i][100-$WCthr]";


		$i++;
	}
	#Avg Obs POR
	print OUTMO "\nAvg Obs";
	
	print CLIM "$WCthr";
	print CLIMP "$WCthr";
	
	#array used to find what the actual month 
	#is for the subroutine length of month 
	@snyr=(0,7,8,9,10,11,12,1,2,3,4,5,6);	

	for($mo=1;$mo<=12;$mo++)
	{
		$moLenAvg=lengthOfMonthInHrs($snyr[$mo]);
		$avgObsMo[$mo][100-$WCthr]=sprintf("%.1f",($windChillClimTotMo[$mo][100-$WCthr]/$actClimTotMo[$mo])*$moLenAvg);
		print OUTMO ",$avgObsMo[$mo][100-$WCthr]";
		print CLIM ",$avgObsMo[$mo][100-$WCthr]";
		
		$avgObsYr[100-$WCthr]=$avgObsYr[100-$WCthr]+$avgObsMo[$mo][100-$WCthr];
	}

	$avgObsYr[100-$WCthr]=sprintf("%.1f",$avgObsYr[100-$WCthr]);
	print OUTMO ",$avgObsYr[100-$WCthr]";
	print CLIM ",$avgObsYr[100-$WCthr]\n";

	# % Obs POR
	
	print OUTMO "\nAnnual";

        for($mo=1;$mo<=12;$mo++)
        {
                if($actClimTotMo[$mo] != 0){$percObsMo[$mo][100-$WCthr]=sprintf("%.1f",100*($windChillClimTotMo[$mo][100-$WCthr]/$actClimTotMo[$mo]));}
		else{$percObsMo[$mo][100-$WCthr]="M";}
                print OUTMO ",$percObsMo[$mo][100-$WCthr]";
		print CLIMP ",$percObsMo[$mo][100-$WCthr]";
        }

        if($yrObsTot != 0){$percObsYr[100-$WCthr]=sprintf("%.1f",100*($windChillYrTot[100-$WCthr]/$yrObsTot));}
	else{$percObsYr[100-$WCthr]="M";}

        print OUTMO ",$percObsYr[100-$WCthr]";
	print CLIMP ",$percObsYr[100-$WCthr]\n";

	close(OUTMO);

	$i=0;$j=0;

}

sub lengthOfMonthInHrs
{
        ($inmonth)=@_;

        if($inmonth==1 || $inmonth==3 || $inmonth==5 || $inmonth==7 || $inmonth==8 || $inmonth==10 || $inmonth==12){$moLen=744;}
        elsif($inmonth==4 || $inmonth==6 || $inmonth ==9 || $inmonth==11){$moLen=720}
        elsif($inmonth==2){$moLen=678;}

        return $moLen;

}

