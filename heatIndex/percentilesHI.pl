#!/bin/env perl

use JSON;

use POSIX;

$folder=$ARGV[0];

$startYr=$ARGV[1];
$endYr=$ARGV[2];

$minHIthresh=80;
$maxHIthresh=115;

$minWCthresh=-40;
$maxWCthresh=50;

$maxHI=0;
$minWC=99;

$z=0;
$i=0;

$outFile="HIpercentiles.csv";

open(OUT, ">$outFile") or die "Can't open";

print OUT "FIPS,stnName,state,stnCallSgn,lat,lon,record,perc999,perc99,perc95,perc90,perc999All,perc99All,perc95All,perc90All\n";

$stnfile="stations-QC.txt";

open(my $fh, "<",$stnfile);

while (my $line = <$fh>)
{

        chomp $line;
        $station=$line;

        $website="https://cli-dap.mrcc.illinois.edu/station/$station/";

        $json = `curl -k $website`;

        $data = decode_json($json);

        $state = $$data{"statecode"};
        $county = $$data{"county"};
        $stn = $$data{"stationname"};
        $lat = $$data{"stationlatitude"};
        $lon = $$data{"stationlongitude"};
        $porStart = $$data{"porstartdate"};
        $porEnd = $$data{"porenddate"};
        $fips = $$data{"fips"};

	#print "$state,$stn,$lat,$lon\n";
	#Open the datafile for manipulation

	$rawfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-raw.csv";

	$maxHI[$r]=0;
	
	open(my $fh1, "<",$rawfile);

	while (my $line1 = <$fh1>)
	{
		#Obs Times
		
		chomp $line1;
		@values=split(/,/, $line1);
		@day=split(/\//,$values[0]);
		$Y[$z]=$values[0];
		$M[$z]=$values[1];
		$D[$z]=$values[2];
		@Obshr=split(//,$values[3]);
		$obsHour[$z]=$values[3];

		#Obs Variables

		$T[$z]=$values[6];
		$Td[$z]=$values[5];
       		$wind[$z]=$values[4];
		$RH[$z]=relHumid($T[$z],$Td[$z]);

		#Wind Chill & Heat Index Calcs
		#Calculated only if data are not missing
		#M's were originally being calculated for wind chill
	
        if($T[$z] >= 80 and $T[$z] ne "M" and $Td[$z] ne "M"){$HI[$z]=heatIndex($T[$z],$RH[$z]);$HIcalc=1;}
		else {$HIcalc=0;}

		#Maximum Value Calcs

		if($HI[$z] >= $maxHI[$r])
		{
			$maxHI[$r]=$HI[$z];
			$maxHIdate[$r]="$Y[$z]-$M[$z]-$D[$z]";
			$maxHIhr[$r]=$obsHour[$z];
		}	
	
		#print "Lowest Wind Chill was $minWC on $minWCdate at $minWChr Local Standard Time, current date is $Y[$z]-$M[$z]-$D[$z]\n";
	
		#Hour/Observation Counters
		#Done for Hours 0-23 and Months 1-12
		#Includes Total Possible Hours
		#Hours where WC Are Calculated
		#Hours Certain Thresholds of WC Are Met
	
		if($HIcalc==1 and $T[$z] ne "M" and $wind[$z] ne "M")
		{
		$cHI[$i]=$HI[$z];
		$cY[$i]=$Y[$z];
		$cM[$i]=$M[$z];
		$cD[$i]=$D[$z];
		$cObsHr[$i]=$obsHour[$z];
		$hrsCalcd++;
		
		$i++;
		}
	
		if($T[$z] ne "M" and $wind[$z] ne "M"){$hrsTot++;}
		
		$z++;
	}

	$onePercCalcd=sprintf("%.0f",$hrsCalcd/100);
	$onePercTot=sprintf("%.0f",$hrsTot/100);


	print "1% of calculated heat index is $onePercCalcd ($hrsCalcd) and 1% of all available hours is $onePercTot ($hrsTot)\n";

	@sortedHI= sort { $b <=> $a } @cHI;

	$percCalc999=sprintf("%.1f",$sortedHI[($onePercCalcd/10)-1]);
	$percCalc99=sprintf("%.1f",$sortedHI[$onePercCalcd-1]);
	$percCalc95=sprintf("%.1f",$sortedHI[($onePercCalcd*5)-1]);
	$percCalc90=sprintf("%.1f",$sortedHI[($onePercCalcd*10)-1]);

	$percTot999=sprintf("%.1f",$sortedHI[($onePercTot/10)-1]);
	$percTot99=sprintf("%.1f",$sortedHI[$onePercTot-1]);
	$percTot95=sprintf("%.1f",$sortedHI[($onePercTot*5)-1]);
	$percTot90=sprintf("%.1f",$sortedHI[($onePercTot*10)-1]);

	print "$station,$percCalc99,$percCalc999\n";

	$record=sprintf("%.1f",$sortedHI[0]);

	print OUT "$fips,$stn,$state,$lat,$lon,$station,$record,$percCalc999,$percCalc99,$percCalc95,$percCalc90,$percTot999,$percTot99,$percTot95,$percTot90\n";

	$i=0;$z=0;
	$hrsCalcd=0;$hrsTot=0;
	$onePercCalcd=0;$onePercTot=0;
	@cHI=();
	$r++;
}

#Subroutines

sub heatIndex
{
	($TempF,$RH)=@_;
	if($TempF >= 80){
	$heatI=-42.379+(2.04901523*$TempF)+(10.14333127*$RH)-(0.22475541*$TempF*$RH)-(0.00683783*$TempF*$TempF)-(0.05481717*$RH*$RH)+(0.00122874*$RH*$TempF*$TempF)+(0.00085282*$TempF*$RH*$RH)-(0.00000199*$TempF*$TempF*$RH*$RH);
	}

	return $heatI;
}

sub relHumid
{
	($TempF,$DewpF)=@_;

	$TempC=degreesC($TempF);
	$DewpC=degreesC($DewpF);

	$e=6.11*(10**((7.5*$DewpC)/(237.3+$DewpC)));

	$es=6.11*(10**((7.5*$TempC)/(237.3+$TempC)));

	$RH=($e/$es)*100;

	return $RH;
}

sub degreesC
{
	$inTemp=$_[0];

	$TC=($inTemp-32)*(5/9);

	return $TC;
}
