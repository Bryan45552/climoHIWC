#!/bin/env perl

$station=$ARGV[0];
$folder=$ARGV[1];


$rawfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-raw.csv";
$startYr=$ARGV[2];
$endYr=$ARGV[3];

$minHIthresh=80;
$maxHIthresh=115;

$minWCthresh=-40;
$maxWCthresh=50;

$maxHI=0;
$minWC=99;

$z=0;

#Initialize Variable Arrays
#Due to inhomogeneous missing data, full arrays
#of the entire POR must be made to account for
#missing data fully omitted from the record.

for ($year=$startYr;$year<=$endYr;$year++)
{

	#Months of year because of use of snow year 
    for($mo=1;$mo<=12;$mo++)
    {

        $numMo[$mo][$year]=0;
		#Months where WC could be calculated because data are not missing
        $moWC[$mo][$year]=0;
		#Since only positive numbers can be counters, a 100-threshold is used
		#for wind chill to eliminate issues with below zero threshold data

		for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
        {
            $moThrWC[100-$threshWC][$mo][$year]=0;
        }

    }
}

#Open the datafile for manipulation

open(my $fh, "<",$rawfile);

while (my $line = <$fh>)
{
	#Obs Times
	
	chomp $line;
	@values=split(/,/, $line);
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

	if($WC[$z] <= $minWC)
	{
		$minWC=$WC[$z];
		$minWCdate="$Y[$z]-$M[$z]-$D[$z]";
		$minWChr=$obsHour[$z];
	}


	#Hour/Observation Counters
	#Done for Hours 0-23 and Months 1-12
	#Includes Total Possible Hours
	#Hours where WC Are Calculated
	#Hours Certain Thresholds of WC Are Met
	
	for ($year=$startYr;$year<=$endYr;$year++)
	{	
		for($mo=1;$mo<=12;$mo++)
		{
			#Months of the year calculation 
			if($M[$z]==$mo && $Y[$z]==$year)
			{
					if($T[$z] ne "M"){$numMo[$mo][$year]++;$numYr[$year]++;}
					if($T[$z] ne "M" and $wind[$z] ne "M"){$moWC[$mo][$year]++;}

					if($WCcalc==1)
					{
						for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
						{
							if($WC[$z] <= $threshWC){$moThrWC[100-$threshWC][$mo][$year]++;}
						}
					}
			}	
		}

	}
	
	$z++;
}

print "Lowest Wind Chill was $minWC on $minWCdate at $minWChr Local Standard Time\n";

#Table Printing Section
#Naming convention station-datatype.csv

$actObsMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsMo.csv";
$obsWCMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-obsWCMo.csv";

open(OUT, ">$actObsMo") or die "Can't open";
open(OUT1, ">$obsWCMo") or die "Can't open";

for($yr=$startYr+1;$yr<=$endYr;$yr++)
{
	print OUT "$yr";
    print OUT1 "$yr";

	#print July-December first and begin calculating the snow year total
	for ($mon=7;$mon<=12;$mon++)
	{
		print OUT ",$numMo[$mon][$yr-1]";$numYr=$numYr+$numMo[$mon][$yr-1];
		print OUT1 ",$moWC[$mon][$yr-1]";$numWCYr=$numWCYr+$numMo[$mon][$yr-1];
	}
	
	for ($mon=1;$mon<=6;$mon++)
	{
		print OUT ",$numMo[$mon][$yr]";$numYr=$numYr+$numMo[$mon][$yr];
		print OUT1 ",$moWC[$mon][$yr]";$numWCYr=$numWCYr+$numMo[$mon][$yr];
	}
	
	print OUT ",$numYr\n";
	print OUT1 ",$numWCYr\n";

	$numYr=0;$numWCYr=0;
}

#Threshold Wind Chill Files

for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
{
	$threshMoWCfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-$threshWC-threshWCMo.csv";
	
	open(OUT2, ">$threshMoWCfile") or die "Can't open";

	for($yr=$startYr+1;$yr<=$endYr;$yr++)
	{	
		print OUT2 "$yr";
	
		for ($month=7;$month<=12;$month++)
		{
			print OUT2 ",$moThrWC[100-$threshWC][$month][$yr-1]";$numThrWC=$numThrWC+$moThrWC[100-$threshWC][$month][$yr-1];
		}
	
		for ($month=1;$month<=6;$month++)
		{
			print OUT2 ",$moThrWC[100-$threshWC][$month][$yr]";$numThrWC=$numThrWC+$moThrWC[100-$threshWC][$month][$yr];
		}
		
		print OUT2 ",$numThrWC\n";
		
		$numThrWC=0;
	}
	
	close(OUT2);
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
