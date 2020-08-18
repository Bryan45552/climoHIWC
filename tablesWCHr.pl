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

for ($year=$startYr;$year<=$endYr;$year++)
{
        for($hr=0;$hr<2400;$hr=$hr+100)
	{
			$numHrs[$hr][$year]=0;
			#HRS where HI or WC could be calculated because data are not missing
            $hrsWC[$hr][$year]=0;
            for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
			{
               	$hrsThrWC[100-$threshWC][$hr][$year]=0;
            }
	}
}
print "Vars Done\n";
#Open the datafile for manipulation

open(my $fh, "<",$rawfile);

print "$rawfile\n";

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
        $RH[$z]=relHumid($T[$z],$Td[$z]);

	#Wind Chill & Heat Index Calcs
	#Calculated only if data are not missing
	#M's were originally being calculated for wind chill

    if($T[$z] <=50 && $wind[$z] >= 3 and $T[$z] ne "M" and $wind[$z] ne "M"){$WC[$z]=windChill($T[$z],$wind[$z]);$WCcalc=1;}
	else {$WCcalc=0;}


	#Hour/Observation Counters
	#Done for Hours 0-23 and Months 1-12
	#Includes Total Possible Hours
	#Hours where HI and WC Are Calculated
	#Hours Certain Thresholds of WC Are Met
	#if statements used to sort into snow year by taking previous year data into 
	#the snow year starting July 1

	for ($year=$startYr;$year<=$endYr;$year++)
	{
	        for($hr=0;$hr<2400;$hr=$hr+100)
        	{
			if($obsHour[$z]==$hr && $Y[$z]==$year)
			{
				if($T[$z] ne "M" and $M[$z] <= 6){$snYr=$year; $numHrs[$hr][$snYr]++;}
				if($T[$z] ne "M" and $M[$z] >= 7){$snYr=$year+1; $numHrs[$hr][$snYr]++;}
					
				if($T[$z] ne "M" and $wind[$z] ne "M" and $M[$z] <= 6){$snYr=$year; $hrsWC[$hr][$snYr]++;}
				if($T[$z] ne "M" and $wind[$z] ne "M" and $M[$z] >= 7){$snYr=$year+1; $hrsWC[$hr][$snYr]++;}
					

				#Wind Chill
				if($WCcalc==1 and $T[$z] ne "M" and $wind[$z] ne "M")
				{
					for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
					{
						if($WC[$z] <= $threshWC && $M[$z] <= 6){$snYr=$year; $hrsThrWC[100-$threshWC][$hr][$snYr]++;}
						if($WC[$z] <= $threshWC && $M[$z] >= 7){$snYr=$year+1; $hrsThrWC[100-$threshWC][$hr][$snYr]++;}
					}
				}
			}
		}
	}

	$z++;
	
	
}

#Table Printing Section
#Naming convention station-datatype.csv

$actObs="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsHr.csv";
$obsWCHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-obsWCHr.csv";

open(OUT, ">$actObs") or die "Can't open";
open(OUT4, ">$obsWCHr") or die "Can't open";

for($yr=$startYr+1;$yr<=$endYr;$yr++)
{
	print OUT "$yr";
    print OUT4 "$yr";

	for($hour=0;$hour<2400;$hour=$hour+100)
	{
		print OUT ",$numHrs[$hour][$yr]";
		print OUT4 ",$hrsWC[$hour][$yr]";
	}

	print OUT ",$numYr[$yr]\n";
	print OUT4 "\n";
}

#Threshold Wind Chill Files

for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
{
        $threshHRWCfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-$threshWC-threshWCHr.csv";

        open(OUT8, ">$threshHRWCfile") or die "Can't open";

        for($yr=$startYr+1;$yr<=$endYr;$yr++)
        {
            print OUT8 "$yr";

            for($hour=0;$hour<2400;$hour=$hour+100)
            {
                print OUT8 ",$hrsThrWC[100-$threshWC][$hour][$yr]";
		$hrsThrWCyr[100-$threshWC][$yr]=$hrsThrWCyr[100-$threshWC][$yr]+$hrsThrWC[100-$threshWC][$hour][$yr];
            }
        
			print OUT8 ",$hrsThrWCyr[100-$threshWC][$yr]\n";
        }
        close(OUT8);
}

#Subroutines: Include Heat Index, Wind Chill, Relative Humidity and Temperature Conversion

sub windChill
{
	($cTemp,$windMPH)=@_;
	if($windMPH >= 3 && $cTemp <= 50){$wChill=35.74+(0.6215*$cTemp)-(35.75*$windMPH**0.16)+(0.4275*$cTemp*$windMPH**0.16);}

	return $wChill;

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
