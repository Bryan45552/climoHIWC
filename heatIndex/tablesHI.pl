#!/bin/env perl

$station=$ARGV[0];
$folder=$ARGV[1];


$rawfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-raw.csv";
$startYr=$ARGV[2];
$endYr=$ARGV[3];

$minHIthresh=80;
$maxHIthresh=115;

$maxHI=0;

$z=0;

#Initialize Variable Arrays

for ($year=$startYr;$year<=$endYr;$year++)
        {
                for($hr=0;$hr<2400;$hr=$hr+100)
                {
 	                $numHrs[$hr][$year]=0;
						#HRS where HI could be calculated because data are not missing
                        $hrsHI[$hr][$year]=0;

			for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
			{
				$hrsThrHI[$threshHI][$hr][$year]=0;
			}
                }
                for($mo=1;$mo<=12;$mo++)
                {
 	               $numMo[$mo][$year]=0;
					#Months where HI could be calculated because data are not missing
                       $moHI[$mo][$year]=0;

                       for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
                       {
                               $moThrHI[$threshHI][$mo][$year]=0;
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
        $RH[$z]=relHumid($T[$z],$Td[$z]);

	#Heat Index Calcs
	#Calculated only if data are not missing
	#M's were originally being calculated for wind chill
	
        if($T[$z] >= 80 and $T[$z] ne "M" and $Td[$z] ne "M"){$HI[$z]=heatIndex($T[$z],$RH[$z]);$HIcalc=1;}
	else {$HIcalc=0;}

	#Maximum Value Calcs

	if($HI[$z] >= $maxHI)
	{
		$maxHI=$HI[$z];
		$maxHIdate="$Y[$z]-$M[$z]-$D[$z]";
		$maxHIhr=$obsHour[$z];
	}

	#Hour/Observation Counters
	#Done for Hours 0-23 and Months 1-12
	#Includes Total Possible Hours
	#Hours where HI and WC Are Calculated
	#Hours Certain Thresholds of HI and WC Are Met

	for ($year=$startYr;$year<=$endYr;$year++)
	{
	        for($hr=0;$hr<2400;$hr=$hr+100)
        	{
			if($obsHour[$z]==$hr && $Y[$z]==$year)
			{
				if($T[$z] ne "M"){$numHrs[$hr][$year]++;}
				if($T[$z] ne "M" and $Td[$z] ne "M"){$hrsHI[$hr][$year]++;}
				if($T[$z] ne "M" and $wind[$z] ne "M"){$hrsWC[$hr][$year]++;}
				#Heat Index
				if($HIcalc==1 and $T[$z] ne "M" and $Td[$z] ne "M")
				{
                           		for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
                           		{
                               			if($HI[$z] >= $threshHI){$hrsThrHI[$threshHI][$hr][$year]++;}
                           		}
				}
			}
                }

		for($mo=1;$mo<=12;$mo++)
		{
			if($M[$z]==$mo && $Y[$z]==$year)
			{
				if($T[$z] ne "M"){$numMo[$mo][$year]++;$numYr[$year]++;}
				if($T[$z] ne "M" and $Td[$z] ne "M"){$moHI[$mo][$year]++;}
				if($T[$z] ne "M" and $wind[$z] ne "M"){$moWC[$mo][$year]++;}
				
				if($HIcalc==1)
				{
					for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
                                        {
                                                if($HI[$z] >= $threshHI){$moThrHI[$threshHI][$mo][$year]++;$moThrHIyr[$threshHI][$year]++;}
                                        }
				}
			}
		}
	}

	$z++;
}

print "Highest Heat Index was $maxHI on $maxHIdate at $maxHIhr Local Standard Time\n";

#Table Printing Section
#Naming convention station-datatype.csv

$actObs="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsHr.csv";
$actObsMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-actObsMo.csv";
$obsHIMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-obsHIMo.csv";
$obsHIHr="/home/bpeake/chillHeatClimo/$folder/$station/$station-obsHIHr.csv";

open(OUT, ">$actObs") or die "Can't open";
open(OUT1, ">$actObsMo") or die "Can't open";
open(OUT2, ">$obsHIMo") or die "Can't open";
open(OUT5, ">$obsHIHr") or die "Can't open";

for($yr=$startYr;$yr<=$endYr;$yr++)
{
	print OUT "$yr";
        print OUT1 "$yr";
        print OUT2 "$yr";
        print OUT5 "$yr";

	for($hour=0;$hour<2400;$hour=$hour+100)
	{
		print OUT ",$numHrs[$hour][$yr]";
		print OUT5 ",$hrsHI[$hour][$yr]";
		
	}

        for($mon=1;$mon<=12;$mon++)
        {
                print OUT1 ",$numMo[$mon][$yr]";
		print OUT2 ",$moHI[$mon][$yr]";
        }

	print OUT ",$numYr[$yr]\n";
        print OUT1 ",$numYr[$yr]\n";
	print OUT2 "\n";
	print OUT5 "\n";
}

#Threshold Heat Index Files

for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
{
	$threshHRHIfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-$threshHI-threshHIHr.csv";
        $threshMoHIfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-$threshHI-threshHIMo.csv";

	open(OUT6, ">$threshHRHIfile") or die "Can't open";
	open(OUT7, ">$threshMoHIfile") or die "Can't open";

	for($yr=$startYr;$yr<=$endYr;$yr++)
	{
	        print OUT6 "$yr";
		print OUT7 "$yr";

	        for($hour=0;$hour<2400;$hour=$hour+100)
	        {
	                print OUT6 ",$hrsThrHI[$threshHI][$hour][$yr]";
	        }

		for($month=1;$month<=12;$month++)
                {
                        print OUT7 ",$moThrHI[$threshHI][$month][$yr]";
                }

        print OUT6 ",$moThrHIyr[$threshHI][$yr]\n";
	print OUT7 ",$moThrHIyr[$threshHI][$yr]\n";


	}
	close(OUT6);
        close(OUT7);
}


#Subroutines: Include Heat Index, Wind Chill, Relative Humidity and Temperature Conversion

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
