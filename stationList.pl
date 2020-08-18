#!/bin/env perl

use JSON;

use POSIX;

$state=$ARGV[0];


        $website="cli-dap.mrcc.illinois.edu/state/$state/";

        @json = `curl $website`;

        $data = $json[0];

        @decode=decode_json($data);

        $hash=$decode[0][$i];

        $wban = $$hash{"weabaseid"};

$rawFile="$state-metaList.csv";

open(OUT, ">$rawFile") or die "Can't open";

print OUT "Station,State,County,ClimDiv,WBAN,FIPS,Lat,Lon,Elev(ft),PORstart,PORend\n";

while ($hash ne "")
{

	$wban = $$hash{"weabaseid"};

	$website="cli-dap.mrcc.illinois.edu/station/$wban/";

	$json = `curl $website`;


	print "$wban $i\n";

	#Decodes the JSON output from the call

	$data = decode_json($json);

	$state = $$hash{"statename"};
	$ST = $$hash{"statecode"};
	$county = $$hash{"county"};
	$stn = $$hash{"stationname"};
	$lat = $$hash{"stationlatitude"};
	$lon = $$hash{"stationlongitude"};
	$elev= $$hash{"stationelevation"};
	$CD = $$hash{"climatedivisionnumber"};
	$porStart = $$hash{"porstartdate"};
	$porEnd = $$hash{"porenddate"};
	$fips = $$hash{"fips"};

	print OUT "$stn,$ST,$county,$CD,$wban,$fips,$lat,$lon,$elev,$porStart,$porEnd\n";


	$i++;
	$hash=$decode[0][$i];

}

close(OUT);

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
