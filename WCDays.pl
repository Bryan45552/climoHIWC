#!/bin/env perl

$station=$ARGV[0];
$folder=$ARGV[1];

$rawfile="/home/bpeake/chillHeatClimo/$folder/$station/$station-raw.csv";

$startYr=$ARGV[2];
$endYr=$ARGV[3];

$gdDyThr=$ARGV[4];

$minWCthresh=-40;
$maxWCthresh=50;

$hrCnt=0;
$goodDays=0;

$maxHI=0;
$minWC=99;

$z=0;

#Initialization of variable arrays

for ($year=$startYr;$year<=$endYr;$year++)
{
	for($mo=1;$mo<=12;$mo++)
	{
		$numdyMo[$mo][$year]=0;
		$modyWC[$mo][$year]=0;

		for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
		{
			for ($cnt=1;$cnt<=8;$cnt++)
			{
				$dayThrWC[$mo][$year][100-$threshWC][$cnt]=0;
				$dayThrWCyr[$year][100-$threshWC][$cnt]=0;
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
    $wind[$z]=$values[4];
 
	#Day Counters
    #Done for and Months 1-12 and 1-8 hours in a day
    #Hours where HI and WC Are Calculated
    #Hours Certain Thresholds of HI and WC Are Met
	#Counters are done prior to calculation as counting
	#is done after the previous day has completed

	if($D[$z] != $D[$z-1] && $z > 0) #if it's a new day, let's see how many hours of HI there were in the day prior
	{
		#Statement constitues that a day had at least 
		#22 of 24 hours, thus considered a quality "good" day 
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
						for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
						{
							for ($cnt=1;$cnt<=8;$cnt++) #allows for counts of hours in each day up to 8 hours
							{
								if ($dayCountWC[100-$threshWC] >= $cnt) 
								{
									$dayThrWC[$mo][$year][100-$threshWC][$cnt]++;
									$dayThrWCyr[$year][100-$threshWC][$cnt]++;
									$singleDayWC[$mo][$dy][100-$threshWC][$cnt]++;
								}
							}
						}	
					}	
				}
			}
		}
		for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5){$dayCountWC[100-$threshWC]=0;}
	}	
	
    #Wind Chill & Heat Index Calcs
    #Calculated only if data are not missing
    #M's were originally being calculated for wind chill
    if($T[$z] <=50 && $wind[$z] >= 3 and $T[$z] ne "M" and $wind[$z] ne "M"){$WC[$z]=windChill($T[$z],$wind[$z]);$WCcalc=1;}
    else {$WCcalc=0;}

	if($T[$z] ne "M"){$hrCnt++;}

	if ($WCcalc==1)
	{
		for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
		{
			if($WC[$z] <= $threshWC) {$dayCountWC[100-$threshWC]++;}
		}
	}

    $z++;
}

##AVERAGES AS SUM OF INDIVIDUAL DAYS##

for ($mo=1;$mo<=12;$mo++)
{
	$lenMo=lengthOfMonth($mo,2016);#2016 used as a leap year to get Feb 29 averages
	for($dy=1;$dy<=$lenMo;$dy++)
	{
		for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
		{
			for($cnt=1;$cnt<=8;$cnt++)
			{
				$dyAvgWC[$mo][$dy][100-$threshWC][$cnt]=$singleDayWC[$mo][$dy][100-$threshWC][$cnt]/$goodDays[$mo][$dy];
				$monAvgWC[$mo][100-$threshWC][$cnt]=$monAvgWC[$mo][100-$threshWC][$cnt]+$dyAvgWC[$mo][$dy][100-$threshWC][$cnt];
				#$annAvgWC[100-$threshWC][$cnt]=$annAvgWC[100-$threshWC][$cnt]+$dyAvgWC[$mo][$dy][100-$threshWC][$cnt];
			}			
		}
	}
}

$sumFile="/home/bpeake/chillHeatClimo/$folder/$station/$station-WCDaysSum.csv";
open(SUM, ">$sumFile") or die "Can't open";
print SUM "Thresh,Num Hrs,7,8,9,10,11,12,1,2,3,4,5,6,Annual\n";

for($threshWC=$maxWCthresh;$threshWC>=$minWCthresh;$threshWC=$threshWC-5)
{

	
	for ($cnt=1;$cnt<=8;$cnt++)
	{
		$outfileWC="/home/bpeake/chillHeatClimo/$folder/$station/$station-WCDays-$threshWC-$cnt.csv";
		open(OUT1, ">$outfileWC") or die "Can't open";
		for ($year=$startYr+1;$year<=$endYr;$year++)
		{
			print OUT1 "$year";
			for($mo=7;$mo<=12;$mo++)
			{		
				print OUT1 ",$dayThrWC[$mo][$year-1][100-$threshWC][$cnt]";
				#Counts totals for long-term average later	
				
				$porTotWC[$mo][100-$threshWC][$cnt]=$porTotWC[$mo][100-$threshWC][$cnt]+$dayThrWC[$mo][$year-1][100-$threshWC][$cnt];
				$porTotWCyr[100-$threshWC][$cnt]=$porTotWCyr[100-$threshWC][$cnt]+$dayThrWC[$mo][$year-1][100-$threshWC][$cnt];
			
				$annTot[$year][100-$threshWC][$cnt]=$annTot[$year][100-$threshWC][$cnt]+$dayThrWC[$mo][$year-1][100-$threshWC][$cnt];
			}
			
			for($mo=1;$mo<=6;$mo++)
			{		
				print OUT1 ",$dayThrWC[$mo][$year][100-$threshWC][$cnt]";
				
				$porTotWC[$mo][100-$threshWC][$cnt]=$porTotWC[$mo][100-$threshWC][$cnt]+$dayThrWC[$mo][$year][100-$threshWC][$cnt];
				$porTotWCyr[100-$threshWC][$cnt]=$porTotWCyr[100-$threshWC][$cnt]+$dayThrWC[$mo][$year][100-$threshWC][$cnt];

				$annTot[$year][100-$threshWC][$cnt]=$annTot[$year][100-$threshWC][$cnt]+$dayThrWC[$mo][$year][100-$threshWC][$cnt];
			}			
			
			print OUT1 ",$annTot[$year][100-$threshWC][$cnt]\n";
		}
		#Long-term average output & summary file
		print OUT1 "Avg";
		print SUM "$threshWC,$cnt";
		for($mo=7;$mo<=12;$mo++)
		{
			$monAvgWC[$mo][100-$threshWC][$cnt]=sprintf("%.1f",$monAvgWC[$mo][100-$threshWC][$cnt]);
			print OUT1 ",$monAvgWC[$mo][100-$threshWC][$cnt]";
			print SUM ",$monAvgWC[$mo][100-$threshWC][$cnt]";
			$annAvgWC[100-$threshWC][$cnt]=$annAvgWC[100-$threshWC][$cnt]+$monAvgWC[$mo][100-$threshWC][$cnt];
		}

                for($mo=1;$mo<=6;$mo++)
                {
                        $monAvgWC[$mo][100-$threshWC][$cnt]=sprintf("%.1f",$monAvgWC[$mo][100-$threshWC][$cnt]);
                        print OUT1 ",$monAvgWC[$mo][100-$threshWC][$cnt]";
						print SUM ",$monAvgWC[$mo][100-$threshWC][$cnt]";
                        $annAvgWC[100-$threshWC][$cnt]=$annAvgWC[100-$threshWC][$cnt]+$monAvgWC[$mo][100-$threshWC][$cnt];
                }

		#$annAvgWC[100-$threshWC][$cnt]=sprintf("%.1f",$annAvgWC[100-$threshWC][$cnt]);
		print OUT1 ",$annAvgWC[100-$threshWC][$cnt]\n";
		print SUM ",$annAvgWC[100-$threshWC][$cnt]\n";
		#Total days output for lower frequency data 

		print OUT1 "Total";
		for($mo=7;$mo<=12;$mo++)
		{
			print OUT1 ",$porTotWC[$mo][100-$threshWC][$cnt]";
		}

                for($mo=1;$mo<=6;$mo++)
                {
                        print OUT1 ",$porTotWC[$mo][100-$threshWC][$cnt]";
                }

		print OUT1 ",$porTotWCyr[100-$threshWC][$cnt]\n";

		close (OUT1);
	}

}

close (SUM);
	
	
	
	
#Subroutines: Include Heat Index, Wind Chill, Relative Humidity and Temperature Conversion

sub heatIndex
{
	($TempF,$RH)=@_;
	if($TempF >= 80){
	$heatI=-42.379+(2.04901523*$TempF)+(10.14333127*$RH)-(0.22475541*$TempF*$RH)-(0.00683783*$TempF*$TempF)-(0.05481717*$RH*$RH)+(0.00122874*$RH*$TempF*$TempF)+(0.00085282*$TempF*$RH*$RH)-(0.00000199*$TempF*$TempF*$RH*$RH);
	}

	return $heatI;
}

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
