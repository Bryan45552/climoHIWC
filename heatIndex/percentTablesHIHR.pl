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
		$actHr[$i][$Hr]=$values[$Hr+1];
		$actClimTotHr[$Hr]=$actClimTotHr[$Hr]+$actHr[$i][$Hr];
	}

	$actYr[$i]=$values[25];

	$yrObsTot=$yrObsTot+$actYr[$i];

        $i++;
}

$i=0;$j=0;

#Goes through HI thresholds and reads in data to be manipulated
#Calculates percentages of hours and months with obs for thresholds
#Also tracks totals for the full POR climatology

$ClimFileAvg="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgHIObsHr.csv";
$ClimFilePerc="/home/bpeake/chillHeatClimo/$folder/$station/$station-AvgHIPercHr.csv";

open(CLIM, ">$ClimFileAvg") or die "Can't open";
open(CLIMP, ">$ClimFilePerc") or die "Can't open";


print CLIM "Threshold,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,All Hours\n";
print CLIMP "Threshold,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,All Hours\n";

for($HIthr=$minHIthresh;$HIthr<=$maxHIthresh;$HIthr=$HIthr+5)
{

	$HIfileHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-$HIthr-threshHIHr.csv";
	open(my $fhX, "<",$HIfileHr);

	$OutHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-$HIthr-threshHIHr-perc.csv";

	open(OUTHR, ">$OutHr") or die "Can't open";
	print OUTHR "Year,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,All Hours";

	while (my $lineX = <$fhX>)
	{
		chomp $lineX;
		@values=split(/,/, $lineX);

		print OUTHR "\n$year[$i]";

		for($Hr=1;$Hr<=24;$Hr++)
		{
			$heatIndexObsHr[$i][$Hr][$HIthr]=$values[$Hr];#Number of Obs for that month at thresh
			$heatIndexClimTotHr[$Hr][$HIthr]=$heatIndexClimTotHr[$Hr][$HIthr]+$heatIndexObsHr[$i][$Hr][$HIthr];#POR number of obs for that month at thresh
			$heatIndexYr[$i][$HIthr]=$heatIndexYr[$i][$HIthr]+$heatIndexObsHr[$i][$Hr][$HIthr];#Number of obs for that year at thresh

			if($actHr[$i][$Hr] != 0){$PercentObsHIHr[$i][$Hr][$HIthr]=sprintf("%.1f",100*($heatIndexObsHr[$i][$Hr][$HIthr]/$actHr[$i][$Hr]));}#Percent of Obs for that month at thresh
			else{$PercentObsHIHr[$i][$Hr][$HIthr]="M";}

			print OUTHR ",$PercentObsHIHr[$i][$Hr][$HIthr]";
		}
			$heatIndexYrTot[$HIthr]=$heatIndexYrTot[$HIthr]+$heatIndexYr[$i][$HIthr];#POR number of obs at thresh
			if($actYr[$i] != 0){$percentYr[$i][$HIthr]=sprintf("%.1f",100*($heatIndexYr[$i][$HIthr]/$actYr[$i]));}#Percent of obs for that year at thresh
			else{$percentYr[$i][$HIthr]="M";}
			print OUTHR ",$percentYr[$i][$HIthr]";


		$i++;
	}
	#Avg Obs POR
	print OUTHR "\nAvg Obs";
	
	print CLIM "$HIthr";
	print CLIMP "$HIthr";
	
	for($Hr=1;$Hr<=24;$Hr++)
	{
		$avgObsHr[$Hr][$HIthr]=sprintf("%.1f",$heatIndexClimTotHr[$Hr][$HIthr]/$PORlen);
		print OUTHR ",$avgObsHr[$Hr][$HIthr]";
		print CLIM ",$avgObsHr[$Hr][$HIthr]";
	}

	$avgObsYr[$HIthr]=sprintf("%.1f",$heatIndexYrTot[$HIthr]/$PORlen);
	print OUTHR ",$avgObsYr[$HIthr]";
	print CLIM ",$avgObsYr[$HIthr]\n";

	# % Obs POR
	
	print OUTHR "\nAnnual";

        for($Hr=1;$Hr<=24;$Hr++)
        {
                if($actClimTotHr[$Hr] != 0){$percObsHr[$Hr][$HIthr]=sprintf("%.1f",100*($heatIndexClimTotHr[$Hr][$HIthr]/$actClimTotHr[$Hr]));}
		else{$percObsHr[$Hr][$HIthr]="M";}
                print OUTHR ",$percObsHr[$Hr][$HIthr]";
		print CLIMP ",$percObsHr[$Hr][$HIthr]";
        }

        if($yrObsTot != 0){$percObsYr[$HIthr]=sprintf("%.1f",100*($heatIndexYrTot[$HIthr]/$yrObsTot));}
	else{$percObsYr[$HIthr]="M";}

        print OUTHR ",$percObsYr[$HIthr]";
	print CLIMP ",$percObsYr[$HIthr]\n";

	close(OUTHR);









	$HIfileHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-$HIthr-threshHIHr.csv";
        open(my $fhY, "<",$HIfileHr);

	while (my $lineY = <$fhY>)
	{
	        chomp $lineY;
	        @values=split(/,/, $lineY);
	        for($hr=1;$hr<=24;$hr++)
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
