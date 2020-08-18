#!/bin/env perl

$station=$ARGV[0];
$folder=$ARGV[1];

$startyr=$ARGV[2];
$endyr=$ARV[3];

$PORlen=$endyr-$startyr+1;

$minHIthresh=80;
$maxHIthresh=115;

$maxHI=0;

#Read in Actual Obs files

$obsFileMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsMo.csv";

open(my $fh1, "<",$obsFileMo);

while (my $line = <$fh1>)
{
        chomp $line;
        @values=split(/,/, $line);
	$year[$i]=$values[0];
	for($mo=1;$mo<=12;$mo++)
	{
		$actMo[$i][$mo]=$values[$mo];
		$actClimTotMo[$mo]=$actClimTotMo[$mo]+$actMo[$i][$mo];
		$actYr[$i]=$actYr[$i]+$actMo[$i][$mo];
	}

	$yrObsTot=$yrObsTot+$actYr[$i];

	$i++;
}


$obsFileHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsHr.csv";

open(my $fh2, "<",$obsFileHr);

while (my $line1 = <$fh2>)
{
        chomp $line;
        @values=split(/,/, $line1);
        for($hr=0;$hr<=23;$hr++)
	{
		$actHr[$j][$hr]=$values[$hr+1];
		$actClimTotHr[$hr]=$actClimTotHr[$hr]+$actHr[$j][$hr];
	}

        $j++;
}

$i=0;$j=0;

#Goes through HI thresholds and reads in data to be manipulated
#Calculates percentages of hours and months with obs for thresholds
#Also tracks totals for the full POR climatology

$ClimFileAvg="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgHIObsMo.csv";
$ClimFilePerc="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgHIPercMo.csv";

open(CLIM, ">$ClimFileAvg") or die "Can't open";
open(CLIMP, ">$ClimFilePerc") or die "Can't open";


print CLIM "Threshold,1,2,3,4,5,6,7,8,9,10,11,12,Annual\n";
print CLIMP "Threshold,1,2,3,4,5,6,7,8,9,10,11,12,Annual\n";

for($HIthr=$minHIthresh;$HIthr<=$maxHIthresh;$HIthr=$HIthr+5)
{

	$HIfileMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-$HIthr-threshHIMo.csv";
	open(my $fhX, "<",$HIfileMo);

	$OutMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-$HIthr-threshHIMo-perc.csv";

	open(OUTMO, ">$OutMo") or die "Can't open";
	print OUTMO "Year,1,2,3,4,5,6,7,8,9,10,11,12,All Months";

	while (my $lineX = <$fhX>)
	{
		chomp $lineX;
		@values=split(/,/, $lineX);

		print OUTMO "\n$year[$i]";

		for($mo=1;$mo<=12;$mo++)
		{
			$heatIndexObsMo[$i][$mo][$HIthr]=$values[$mo];#Number of Obs for that month at thresh
			$heatIndexClimTotMo[$mo][$HIthr]=$heatIndexClimTotMo[$mo][$HIthr]+$heatIndexObsMo[$i][$mo][$HIthr];#POR number of obs for that month at thresh
			$heatIndexYr[$i][$HIthr]=$heatIndexYr[$i][$HIthr]+$heatIndexObsMo[$i][$mo][$HIthr];#Number of obs for that year at thresh

			if($actMo[$i][$mo] != 0){$PercentObsHIMo[$i][$mo][$HIthr]=sprintf("%.1f",100*($heatIndexObsMo[$i][$mo][$HIthr]/$actMo[$i][$mo]));}#Percent of Obs for that month at thresh
			else{$PercentObsHIMo[$i][$mo][$HIthr]="M";}

			print OUTMO ",$PercentObsHIMo[$i][$mo][$HIthr]";
		}
			$heatIndexYrTot[$HIthr]=$heatIndexYrTot[$HIthr]+$heatIndexYr[$i][$HIthr];#POR number of obs at thresh
			if($actYr[$i] != 0){$percentYr[$i][$HIthr]=sprintf("%.1f",100*($heatIndexYr[$i][$HIthr]/$actYr[$i]));}#Percent of obs for that year at thresh
			else{$percentYr[$i][$HIthr]="M";}
			print OUTMO ",$percentYr[$i][$HIthr]";


		$i++;
	}
	#Avg Obs POR
	print OUTMO "\nAvg Obs";
	
	print CLIM "$HIthr";
	print CLIMP "$HIthr";
	
	for($mo=1;$mo<=12;$mo++)
	{
		$moLenAvg=lengthOfMonthInHrs($mo);
		$avgObsMo[$mo][$HIthr]=sprintf("%.1f",($heatIndexClimTotMo[$mo][$HIthr]/$actClimTotMo[$mo])*$moLenAvg);
		print OUTMO ",$avgObsMo[$mo][$HIthr]";
		print CLIM ",$avgObsMo[$mo][$HIthr]";
	}

	$avgObsYr[$HIthr]=sprintf("%.1f",($heatIndexYrTot[$HIthr]/$yrObsTot)*8766);
	print OUTMO ",$avgObsYr[$HIthr]";
	print CLIM ",$avgObsYr[$HIthr]\n";

	# % Obs POR
	
	print OUTMO "\nAnnual";

        for($mo=1;$mo<=12;$mo++)
        {
                if($actClimTotMo[$mo] != 0){$percObsMo[$mo][$HIthr]=sprintf("%.1f",100*($heatIndexClimTotMo[$mo][$HIthr]/$actClimTotMo[$mo]));}
		else{$percObsMo[$mo][$HIthr]="M";}
                print OUTMO ",$percObsMo[$mo][$HIthr]";
		print CLIMP ",$percObsMo[$mo][$HIthr]";
        }

        if($yrObsTot != 0){$percObsYr[$HIthr]=sprintf("%.1f",100*($heatIndexYrTot[$HIthr]/$yrObsTot));}
	else{$percObsYr[$HIthr]="M";}

        print OUTMO ",$percObsYr[$HIthr]";
	print CLIMP ",$percObsYr[$HIthr]\n";

	close(OUTMO);









	$HIfileHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-$HIthr-threshHIHr.csv";
        open(my $fhY, "<",$HIfileHr);

	while (my $lineY = <$fhY>)
	{
	        chomp $lineY;
	        @values=split(/,/, $lineY);
	        for($hr=0;$hr<=23;$hr++)
		{
			$heatIndexObsHr[$j][$hr][$HIthr]=$values[$hr+1];
			$heatIndexClimTotHr[$hr][$HIthr]=$heatIndexClimTotHr[$hr][$HIthr]+$heatIndexObsHr[$j][$hr][$HIthr];
			if($actHr[$j][$hr] != 0){$PercentObsHr[$j][$hr][$HIthr]=sprintf("%.1f",100*($heatIndexObsHr[$j][$hr][$HIthr]/$actHr[$j][$hr]));}
			else{$PercentObsHr[$j][$hr][$HIthr]="M";}
		
		}
	        $j++;


	}



	$i=0;
	$j=0;
}

close(CLIM);
close(CLIMP);
			
sub lengthOfMonthInHrs
{
        ($inmonth)=@_;

        if($inmonth==1 || $inmonth==3 || $inmonth==5 || $inmonth==7 || $inmonth==8 || $inmonth==10 || $inmonth==12){$moLen=744;}
        elsif($inmonth==4 || $inmonth==6 || $inmonth ==9 || $inmonth==11){$moLen=720}
        elsif($inmonth==2){$moLen=678;}

        return $moLen;

}

