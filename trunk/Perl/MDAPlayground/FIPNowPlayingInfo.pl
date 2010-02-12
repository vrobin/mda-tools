#!/usr/bin/perl -w
use strict;

# the url of the player from which information is displayed:
# http://players.tv-radio.com/radiofrance/playerfip.php

# The url of the iframe containing song information
# http://players.tv-radio.com/radiofrance/metadatas/fip_direct_alantenne_arthur.php
# Its content:
# <META HTTP-EQUIV="Refresh" CONTENT="30">
#<body bgcolor="#000000">
#<center><font face="arial" size="2" color="#ffffff"><b>A l'antenne</b></font><br><br>
#<MARQUEE DIRECTION="left" BGCOLOR="#000000" SCROLLAMOUNT="2" SCROLLDELAY="3">
#
#<!-- FIP a l'antenne -->
#<font face="arial" size="2" color="#ffffff"><b>NO QUIERO NADA</b></font><br><font face="arial" size="1" color="#ffffff"><b>ROY PACI&amp;ARETUSKA - SUONOGLOBAL 2007</b></font>
#</MARQUEE></b></font></center>

# The url of the iframe containing image link (if present)
# http://players.tv-radio.com/radiofrance/pochettes/fipRSS.html
# Its content:
# <META HTTP-EQUIV=Refresh CONTENT="60"><body STYLE="background-color: transparent"><a target="_blank" href="http://www.amazon.fr/gp/redirect.html%3FASIN=B00003Q4FM%26tag=tvradicom-21%26lcode=xm2%26cID=2025%26ccmID=165953%26location=/o/ASIN/B00003Q4FM%253FSubscriptionId=0Z3DNPF5HJ6K8N1675R2"><img border="0" src="http://ecx.images-amazon.com/images/I/31HQJTFE16L._SL500_.jpg" alt="pochette" width="100" height="100"></a></body>

#!/usr/bin/perl -w

use LWP::UserAgent;
use Data::Dumper;

my $playerURL = 'http://players.tv-radio.com/radiofrance/playerfip.php';
my $artworkPageURL = 'http://players.tv-radio.com/radiofrance/pochettes/fipRSS.html';
my $songInfoURL = 'http://players.tv-radio.com/radiofrance/metadatas/fip_direct_alantenne_arthur.php';

# Create a user agent object
my $ua = LWP::UserAgent->new;
#$ua->agent("$0/0.1 " . $ua->agent);
$ua->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 1.1.4322)'); # pretend we are very capable browser :)

# Initialize proxy settings from environment variables
$ua->env_proxy;

# Create a request
my $req = HTTP::Request->new(GET => $songInfoURL);
$req->header('Accept' => '*/*');
$req->referer($playerURL);

#===========================
# old stuff, I need no fomrs, nor post
#my %form;
#$form{eo_cb_id} = 'cbAjax';
#$form{eo_cb_param} = '{"c": 1, "m": "", "d": "48.598862787704625|47.4633605822591|2.6645278930664062|2.3891830444335937"}';
# Pass request to the user agent and get a response back
#
#my $res = $ua->request($req,0,0,4096);
#my $res = $ua->post('http://www.geocaching.com/seek/gmnearest.aspx?lat=49.11298409078267&lng=1.7873382568359375&zm=12&mt=m', \%form);
#===========================

my $metadata;

my $content = $ua->request($req);

# Check the outcome of the response
if ($content->is_success) {
	my $test = $content->content;
	if( $test =~ m!<b>([^<]*)</b></font><br><font face="arial" size="1" color="#ffffff"><b>([^<]*?)(?: - )?([^-<]*?)( [0-9]*)?</b>!mi ) {
	#die "track: $1 - artist: $2 - album: $3 - year: $4";
		$metadata = {
			artist   =>  $2,
			album    =>  $3,
			title    =>  $1, 
			year     =>  $4,
			type     =>  'FIP Radio'
#		duration =>  int($cdInfo->{PlayingLengths})/75,
#		type     =>  'CD',
#		icon     =>  $icon ,
#		cover    =>  $icon,
		};
	}
    #print $content->content;
}
else {
    print "Error: " . $content->status_line . "\n";
}


$req = HTTP::Request->new(GET => $artworkPageURL);
$req->header('Accept' => '*/*');
$req->referer($playerURL);

	
$content = $ua->request($req);
if ($content->is_success) {
	my $test = $content->content;
	if( $test =~ m!<img border="0" src="([^"]*)" alt="pochette"!mi ) {
	#die "coverurl: $1 ";
		$metadata->{cover} = $1 || 'http://image.radio-france.fr/chaines/fip/commun/img/logo2005.gif'
	}
    #print $content->content;
}
else {
    print "Error: " . $content->status_line . "\n";
}
die Dumper \$metadata;
die $content->content;