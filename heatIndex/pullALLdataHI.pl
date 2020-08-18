#!/bin/env perl

use JSON;

use POSIX;

$endYEAR=$ARGV[0];
$callsign=$ARGV[1];

	$website="https://cli-dap.mrcc.illinois.edu/station/$callsign/";

	$json = `curl -k $website`;

	print $website;
	print "\n$callsign \n\n";

	#Decodes the JSON output from the call

	$data = decode_json($json);
	
	$state = $$data{"statename"};
	$county = $$data{"county"};
	$stn = $$data{"stationname"};
	$lat = $$data{"stationlatitude"};
	$lon = $$data{"stationlongitude"};
	$porStart = $$data{"porstartdate"};
	$porEnd = $$data{"porenddate"};
	$fips = $$data{"fips"};


	@porSDate=split(/-/,$porStart);
	@porEDate=split(/-/,$porEnd);

	if($porEDate[0] == 9999)
        {$porEDate[0]=$endYEAR;}

	if($porSDate[0] < 1973)
	{$porSDate[0]=1973;$porSDate[1]="01";$porSDate[2]="01";}

	$startDat="$porSDate[0]$porSDate[1]$porSDate[2]";
	$endDat="$porEDate[0]$porEDate[1]$porEDate[2]";	

	$startYr=$porSDate[0];
	$endYr=$porEDate[0];
	
	print "$endDat,$startDat\n\n";

	print "$stn in $state is located at Latitude $lat Longitude $lon in the county of $county and began observing data on $porStart\n";
	
	$rawFile="$callsign-raw.csv";

	$qcFile="$callsign-QC.csv";

	open(OUT, ">$rawFile") or die "Can't open";	
	open(QC, ">$qcFile") or die "Can't open";

		$websiteData="https://cli-dap.mrcc.illinois.edu/station/$callsign/data?start=$startDat&end=$endDat&elem=AVA&elem=DEW&elem=MWS";
		print "\n\n$websiteData\n\n";	

		$jsonData = `curl -k "$websiteData"`;
		#print $jsonData;	
		$dataVals=decode_json($jsonData);

		for($yr=$startYr;$yr<=$endYr;$yr++)
		{
			print $yr;
			for($mo=1;$mo<=12;$mo++)
			{
				if($mo<10){$mon="0$mo";}
				else{$mon=$mo;}			
	
				$monLen=lengthOfMonth($mo,$yr);
	
				for($dy=1;$dy<=$moLen;$dy++)
				{
					if($dy<10){$day="0$dy";}
					else{$day=$dy;}
	
					for($hr=0;$hr<2400;$hr=$hr+100)
					{
	
						if($hr==0){$hour="0000";}
						elsif($hr>0 && $hr<1000){$hour="0$hr";}
						else{$hour=$hr;}					
	
	
						$hash="$yr$mon$day$hour";
						#$hash="20170101$hour";
						$obs=$$dataVals{"$hash"};
						$wind=$$obs{"MWS"};
						$temp=$$obs{"AVA"};
						$dewp=$$obs{"DEW"};
						
						#Tests for Extremes & Errors
						($temp,$dewp,$wind)=grossError($temp,$dewp,$wind);

						disContT($temp,$temp1,$temp2,$yr,$mon,$day,$hour,$yr1,$mo1,$dy1,$hr1,$yr2,$mo2,$dy2,$hr2);
						disContD($dewp,$dewp1,$dewp2,$yr,$mon,$day,$hour,$yr1,$mo1,$dy1,$hr1,$yr2,$mo2,$dy2,$hr2);

						if($temp ne ""){print OUT "$yr,$mon,$day,$hour,$wind,$dewp,$temp\n";}

						

						$temp2=$temp1;
						$wind2=$wind1;
						$dewp2=$dewp1;
						
						($yr2,$mo2,$dy2,$hr2)=($yr1,$mo1,$dy1,$hr1);

						$temp1=$temp;
						$wind1=$wind;
						$dewp1=$dewp;
				
						($yr1,$mo1,$dy1,$hr1)=($yr,$mon,$day,$hour);
		

					}
				}
			}
		}
	close(OUT);

	$i++;


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

sub grossError
{
	($inT,$inD,$inW)=@_;

	if($inT > 120 || $inT < -70){print "BAD TEMP $inT\n";$inT="M";}
	if($inD > 120 || $inD < -99 || ($inD > $inT and $inT ne "M" and $inD ne "M")){print "BAD DEWP $inD,$inT\n";$inD="M";}
	if($inW > 100 || $inW < 0){print "BAD WIND $inW\n";$inW="M";}

	return ($inT,$inD,$inW);

}


sub disContT
{
	($inT,$inT1,$inT2,$y,$m,$d,$h,$y1,$m1,$d1,$h1,$y2,$m2,$d2,$h2)=@_;

	if(($inT1-$inT2 >= 30 || $inT1-$inT2 <= -30) and $inT1 ne "M" and $inT2 ne "M" and $inT1 ne "" and $inT2 ne "")
	{
		print "Bad Temp?, $inT2,$inT1,$inT\n";
		print QC "temp,$inT2,$y2$m2$d2,$hr2,$inT1,$y1$m1$d1,$hr1,$inT,$y$m$d,$h\n";
	}
}


sub disContD
{
        ($inD,$inD1,$inD2,$y,$m,$d,$h,$y1,$m1,$d1,$h1,$y2,$m2,$d2,$h2)=@_;

        if(($inD1-$inD2 >= 30 || $inD1-$inD2 <= -30) and $inD1 ne "M" and $inD2 ne "M" and $inD1 ne "" and $inD2 ne "")
        {
		print "Bad Dewp?, $inD2,$inD1,$inD\n";
                print QC "dewp,$inD2,$y2$m2$d2,$hr2,$inD1,$y1$m1$d1,$hr1,$inD,$y$m$d,$h\n";
        }
}
