#!/bin/env perl

$station=$ARGV[0];
$folder=$ARGV[1];

$rawfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-raw.csv";

$startYr=$ARGV[2];
$endYr=$ARGV[3];

$gdDyThr=$ARGV[4];

$minHIthresh=80;
$maxHIthresh=115;

$minWCthresh=-40;
$maxWCthresh=50;

$hrCnt=0;
$goodDays=0;

$maxHI=0;
$minWC=99;

$z=0;

for ($year=$startYr;$year<=$endYr;$year++)
{
	for($mo=1;$mo<=12;$mo++)
	{
		$numdyMo[$mo][$year]=0;
		$modyHI[$mo][$year]=0;
		$modyWC[$mo][$year]=0;

		for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
		{
			for ($cnt=1;$cnt<=8;$cnt++)
			{ 
				$dayThrHI[$mo][$year][$threshHI][$cnt]=0;
				$dayThrHIyr[$year][$threshHI][$cnt]=0;
			}
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
 
		#Day Counters
        #Done for and Months 1-12 and 1-8 hours in a day
        #Hours where HI are Calculated
        #Hours Certain Thresholds of HI Are Met
		if($D[$z] != $D[$z-1] && $z > 0) #if it's a new day, let's see how many hours of HI there were in the day prior
		{
			if($hrCnt>=22){$goodDays[$M[$z-1]][$D[$z-1]]++;}

			$hrCnt=0;
			for ($year=$startYr;$year<=$endYr;$year++)
			{
				for($mo=1;$mo<=12;$mo++)
				{
					$lenMo=lengthOfMonth($mo,$year);
					for($dy=1;$dy<=$lenMo;$dy++)
					{
						if($M[$z-1]==$mo && $Y[$z-1]==$year && $D[$z-1]==$dy)
						{		
						
							for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
							{
								for ($cnt=1;$cnt<=8;$cnt++) #allows for counts of hours in each day up to 8 hours
								{
									if ($dayCount[$threshHI] >= $cnt) 
									{
										$dayThrHI[$mo][$year][$threshHI][$cnt]++;
										$dayThrHIyr[$year][$threshHI][$cnt]++;
										$singleDayHI[$mo][$dy][$threshHI][$cnt]++;
									}
								}
							}
						}
					}
				}
			}
			for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5){$dayCount[$threshHI]=0;}
		}
        #Heat Index Calcs
        #Calculated only if data are not missing
        #M's were originally being calculated for wind chill

        if($T[$z] >= 80 and $T[$z] ne "M" and $Td[$z] ne "M"){$HI[$z]=heatIndex($T[$z],$RH[$z]);$HIcalc=1;}
        else {$HIcalc=0;}

		if ($HIcalc==1)
		{
			for($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
			{
				if($HI[$z] >= $threshHI){$dayCount[$threshHI]++;}
			}
		}
	
		if($T[$z] ne "M"){$hrCnt++;}
		
        $z++;
}
		
##AVERAGES AS SUM OF INDIVIDUAL DAYS##

for ($mo=1;$mo<=12;$mo++)
{
	$lenMo=lengthOfMonth($mo,2016);#2016 used as a leap year to get Feb 29 averages
	for($dy=1;$dy<=$lenMo;$dy++)
	{
		for ($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
		{
			for($cnt=1;$cnt<=8;$cnt++)
			{
				$dyAvgHI[$mo][$dy][$threshHI][$cnt]=$singleDayHI[$mo][$dy][$threshHI][$cnt]/$goodDays[$mo][$dy];
				$monAvgHI[$mo][$threshHI][$cnt]=$monAvgHI[$mo][$threshHI][$cnt]+$dyAvgHI[$mo][$dy][$threshHI][$cnt];
				$annAvgHI[$threshHI][$cnt]=$annAvgHI[$threshHI][$cnt]+$dyAvgHI[$mo][$dy][$threshHI][$cnt];
			}
		}
	}
}

#print "$monAvgHI[6][95][1],$monAvgHI[7][95][1],$monAvgHI[8][95][1],$annAvgHI[95][1]\n";
#print "$monAvgHI[6][95][2],$monAvgHI[7][95][2],$monAvgHI[8][95][2],$annAvgHI[95][2]\n";
#print "$monAvgHI[6][95][4],$monAvgHI[7][95][4],$monAvgHI[8][95][4],$annAvgHI[95][4]\n";


for ($threshHI=$minHIthresh;$threshHI<=$maxHIthresh;$threshHI=$threshHI+5)
{
	for ($cnt=1;$cnt<=8;$cnt++)
	{
		$outfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-HIDays-$threshHI-$cnt.csv";
		open(OUT, ">$outfile") or die "Can't open";
	
		#Print out individual year values
		for ($year=$startYr;$year<=$endYr;$year++)
		{
			print OUT "$year";
			for($mo=1;$mo<=12;$mo++)
			{
				print OUT ",$dayThrHI[$mo][$year][$threshHI][$cnt]";
	
				$porTotHI[$mo][$threshHI][$cnt]=$porTotHI[$mo][$threshHI][$cnt]+$dayThrHI[$mo][$year][$threshHI][$cnt];
				$porTotHIyr[$threshHI][$cnt]=$porTotHIyr[$threshHI][$cnt]+$dayThrHI[$mo][$year][$threshHI][$cnt];
			}
			print OUT ",$dayThrHIyr[$year][$threshHI][$cnt]\n";
		}
		#Print Out the long term monthly averages based on daily averages
		print OUT "Avg";
		for($mo=1;$mo<=12;$mo++)
		{
			$monAvgHI[$mo][$threshHI][$cnt]=sprintf("%.1f",$monAvgHI[$mo][$threshHI][$cnt]);
			print OUT ",$monAvgHI[$mo][$threshHI][$cnt]";
		}
		#Print out the long term annual average
		$annAvgHI[$threshHI][$cnt]=sprintf("%.1f",$annAvgHI[$threshHI][$cnt]);
		print OUT ",$annAvgHI[$threshHI][$cnt]\n";

		#Print out the total number of days in the POR
		print OUT "Total";
		for($mo=1;$mo<=12;$mo++)
		{
			print OUT ",$porTotHI[$mo][$threshHI][$cnt]";
		}
		print OUT ",$porTotHIyr[$threshHI][$cnt]\n";
		
		close (OUT);
	}
	
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

sub lengthOfMonth
{
        ($inmonth,$inYear)=@_;

        $leaptest=$inYear/4;

        if($inmonth==1 || $inmonth==3 || $inmonth==5 || $inmonth==7 || $inmonth==8 || $inmonth==10 || $inmonth==12){$moLen=31;}
        elsif($inmonth==4 || $inmonth==6 || $inmonth ==9 || $inmonth==11){$moLen=30}
        elsif($inmonth==2)
        {
                if($leaptest != int($leaptest)){$moLen=28;}
                elsif($inyear/400 != int($inyear/400) && $inyear/100 == int($inyear/100)){$moLen=28;}
                else{$moLen=29;}
        }

        return $moLen;
}
