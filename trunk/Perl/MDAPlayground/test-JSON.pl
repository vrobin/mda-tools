#!/usr/local/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

use strict;
use warnings;
use Data::Dumper;
use WWW::Mechanize;
use utf8;
use JSON -support_by_pp;

my ($json_url) =
"http://www.librarything.com/api_getdata.php?userid=Kalimko&key=958343592&max=100";
# "http://ws.geonames.org/citiesJSON?north=44.1&south=-9.9&east=-22.4&west=55.2&lang=de";
# "http://www.southparkstudios.com/includes/utils/proxy_feed.php?html=season_json.jhtml%3fseason=1";
my $browser = WWW::Mechanize->new();
print "Getting json $json_url\n";
$browser->get($json_url);
my $content = $browser->content();
my $json    = new JSON;
# these are some nice json options to relax restrictions a bit:
#my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
$content =~ s/^var widgetResults = //g;
# ;LibraryThing.bookAPI.displayWidgetContents(widgetResults, "LT_Content");
$content =~ s/;[^;]+;$//g;
#print("\n$content\n");
my $json_text = $json->filter_json_object->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->allow_unknown->decode($content);
sub kiki {
	}
	
#print Dumper($json_text);
foreach my $bookId (keys(%{$json_text->{books}}))
{
	utf8::encode($json_text->{books}->{$bookId}->{title});
	print( "titre: ".$json_text->{books}->{$bookId}->{title}."\n");
}

