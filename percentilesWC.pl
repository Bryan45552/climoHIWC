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

$outFile="WCpercentiles.csv";

open(OUT, ">$outFile") or die "Can't open";

print OUT "FIPS,stnName,state,stnCallSgn,lat,lon,record,perc99,perc95,perc90,perc99All,perc95All,perc90All\n";

$stnfile="stations-QC2019.txt";

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

	$minWC[$r]=99;
	
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

		#Wind Chill & Heat Index Calcs
		#Calculated only if data are not missing
		#M's were originally being calculated for wind chill
	
		if($T[$z] <=50 && $wind[$z] >= 3 and $T[$z] ne "M" and $wind[$z] ne "M"){$WC[$z]=windChill($T[$z],$wind[$z]);$WCcalc=1;}
		else {$WCcalc=0;}

		#Minimum Value Calcs

		if($WC[$z] <= $minWC[$r])
		{
			$minWC[$r]=$WC[$z];
			$minWCdate[$r]="$Y[$z]-$M[$z]-$D[$z]";
			$minWChr[$r]=$obsHour[$z];
		}	
	
		#print "Lowest Wind Chill was $minWC on $minWCdate at $minWChr Local Standard Time, current date is $Y[$z]-$M[$z]-$D[$z]\n";
	
		#Hour/Observation Counters
		#Done for Hours 0-23 and Months 1-12
		#Includes Total Possible Hours
		#Hours where WC Are Calculated
		#Hours Certain Thresholds of WC Are Met
	
		if($WCcalc==1 and $T[$z] ne "M" and $wind[$z] ne "M")
		{
		$cWC[$i]=$WC[$z];
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



	#print "Lowest Wind Chill was $minWC on $minWCdate at $minWChr Local Standard Time\n";

	print "1% of calculated wind chills is $onePercCalcd ($hrsCalcd) and 1% of all available hours is $onePercTot ($hrsTot)\n";

	@sortedWC= sort { $a <=> $b } @cWC;
	
	$percCalc99=sprintf("%.1f",$sortedWC[$onePercCalcd-1]);
	$percCalc95=sprintf("%.1f",$sortedWC[($onePercCalcd*5)-1]);
	$percCalc90=sprintf("%.1f",$sortedWC[($onePercCalcd*10)-1]);

	$percTot99=sprintf("%.1f",$sortedWC[$onePercTot-1]);
	$percTot95=sprintf("%.1f",$sortedWC[($onePercTot*5)-1]);
	$percTot90=sprintf("%.1f",$sortedWC[($onePercTot*10)-1]);



	$record=sprintf("%.1f",$sortedWC[0]);

	print OUT "$fips,$stn,$state,$lat,$lon,$station,$record,$percCalc99,$percCalc95,$percCalc90,$percTot99,$percTot95,$percTot90\n";

	$i=0;$z=0;
	$hrsCalcd=0;$hrsTot=0;
	$onePercCalcd=0;$onePercTot=0;
	@cWC=();
	$r++;
}

#Subroutines

sub windChill
{
	($cTemp,$windMPH)=@_;
	if($windMPH >= 3 && $cTemp <= 50){$wChill=35.74+(0.6215*$cTemp)-(35.75*$windMPH**0.16)+(0.4275*$cTemp*$windMPH**0.16);}

	return $wChill;

}

sub degreesC
{
	$inTemp=$_[0];

	$TC=($inTemp-32)*(5/9);

	return $TC;
}
