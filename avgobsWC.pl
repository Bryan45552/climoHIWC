#!/bin/env perl

use JSON;

use POSIX;

$folder=$ARGV[0];

$startyr=1973;
$endYr=$ARGV[1];

$outFile="avgWCObs$endYr.csv";

open(OUT, ">$outFile") or die "Can't open";

print OUT "FIPS,stnName,state,stnCallSgn,lat,lon,ann40,ann35,ann30,ann25,ann20,ann15,ann10,ann5,ann0,annM5,annM10,annM15,annM20,annM25,annM30,annM35,annM40";

print OUT ",jul40,jul35,jul30,jul25,jul20,jul15,jul10,jul5,jul0,julM5,julM10,julM15,julM20,julM25,julM30,julM35,julM40";
print OUT ",aug40,aug35,aug30,aug25,aug20,aug15,aug10,aug5,aug0,augM5,augM10,augM15,augM20,augM25,augM30,augM35,augM40";
print OUT ",sep40,sep35,sep30,sep25,sep20,sep15,sep10,sep5,sep0,sepM5,sepM10,sepM15,sepM20,sepM25,sepM30,sepM35,sepM40";
print OUT ",oct40,oct35,oct30,oct25,oct20,oct15,oct10,oct5,oct0,octM5,octM10,octM15,octM20,octM25,octM30,octM35,octM40";
print OUT ",nov40,nov35,nov30,nov25,nov20,nov15,nov10,nov5,nov0,novM5,novM10,novM15,novM20,novM25,novM30,novM35,novM40";
print OUT ",dec40,dec35,dec30,dec25,dec20,dec15,dec10,dec5,dec0,decM5,decM10,decM15,decM20,decM25,decM30,decM35,decM40";
print OUT ",jan40,jan35,jan30,jan25,jan20,jan15,jan10,jan5,jan0,janM5,janM10,janM15,janM20,janM25,janM30,janM35,janM40";
print OUT ",feb40,feb35,feb30,feb25,feb20,feb15,feb10,feb5,feb0,febM5,febM10,febM15,febM20,febM25,febM30,febM35,febM40";
print OUT ",mar40,mar35,mar30,mar25,mar20,mar15,mar10,mar5,mar0,marM5,marM10,marM15,marM20,marM25,marM30,marM35,marM40";
print OUT ",apr40,apr35,apr30,apr25,apr20,apr15,apr10,apr5,apr0,aprM5,aprM10,aprM15,aprM20,aprM25,aprM30,aprM35,aprM40";
print OUT ",may40,may35,may30,may25,may20,may15,may10,may5,may0,mayM5,mayM10,mayM15,mayM20,mayM25,mayM30,mayM35,mayM40";
print OUT ",jun40,jun35,jun30,jun25,jun20,jun15,jun10,jun5,jun0,junM5,junM10,junM15,junM20,junM25,junM30,junM35,junM40\n";

$stnfile="stations-QC$endYr.txt";

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


	for($thresh=40;$thresh>=-40;$thresh=$thresh-5)
	{
		$avgObsFileMo="/home/bpeake/chillHeatClimo/$folder/$station/$station-$thresh-threshWCMo-perc.csv";
	
		open(my $fh1, "<",$avgObsFileMo);
	
		while (my $line1 = <$fh1>)
		{
		        chomp $line1;
		        @values=split(/,/, $line1);
	
			for($val=0;$val<14;$val++)
			{
			        $dataln[$i][$val]=$values[$val]
			}

		        $i++;
		}
	
		for($mo=1;$mo<=13;$mo++)
		{
			$avgObs[100-$thresh][$mo]=$dataln[$i-2][$mo]
		}
		
		$i=0;
		
	}


	print OUT "$fips,$stn,$state,$station,$lat,$lon";
	
        for ($thresh=40;$thresh>=-40;$thresh=$thresh-5)
	{
		print OUT ",$avgObs[100-$thresh][13]";
	}

	for($mo=1;$mo<=12;$mo++)
	{
		for ($thresh=40;$thresh>=-40;$thresh=$thresh-5)
		{
			print OUT ",$avgObs[100-$thresh][$mo]";
		}
	}
	print OUT "\n";

}
