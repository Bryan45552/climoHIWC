#!/bin/env perl

use JSON;

use POSIX;

@state=(WA,OR,CA,NV,AZ,UT,ID,MT,WY,CO,NM,TX,ND,SD,NE,KS,OK,MN,IA,MO,LA,WI,MI,IL,IN,OH,KY,TN,AR,MS,AL,GA,FL,WV,NC,SC,VA,MD,DE,PA,NY,CT,RI,MA,VT,NH,ME,NY,CT,RI,MA,VT,NH,ME);

$i=0;

$outfile=$ARGV[0];

open(OUT, ">$outfile") or die "Can't open";

for($j=0;$j<50;$j++)
{

        $website="https://cli-dap.mrcc.illinois.edu/state/$state[$j]/";

        @json = `curl -k $website`;

        $data = $json[0];

        @decode=decode_json($data);

        $hash=$decode[0][$i];

        $wban = $$hash{"weabaseid"};

	while ($hash ne "")
	{

		$wban = $$hash{"weabaseid"};


		print OUT "$wban\n";

		$i++;
		$hash=$decode[0][$i];

	}
$i=0;
}
