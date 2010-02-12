#!/usr/local/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

use strict;
use warnings;
use utf8;


use Data::Dumper;
# attention, besoin d'avoir dans le path (au hasard le directory bin de perl:
# zlib1.dll, libxml2_.dll, libiconv2.dll
use XML::Compile::Schema;
use WWW::Mechanize;

my $xsdfile = 'J:/documents/Projects/workspace/mda-tools/XSD/musicbrainz mmd-1.3.xsd';
my $schema = XML::Compile::Schema->new($xsdfile);
my $reader = $schema->compile(READER => '{http://musicbrainz.org/ns/mmd-1.0#}metadata');



my $xmlurl = "http://musicbrainz.org/ws/1/artist/?type=xml&name=George+Michael";
my $browser = WWW::Mechanize->new();
$browser->get($xmlurl);
my $xmlmsg = $browser->content();


my $hash   = $reader->($xmlmsg);
print Dumper $hash;






#my $xmlmsgOld = <<__TOP;
#<?xml version="1.0" encoding="UTF-8"?>
#<metadata xmlns="http://musicbrainz.org/ns/mmd-1.0#" xmlns:ext="http://musicbrainz.org/ns/ext-1.0#">
#	<artist-list offset="0" count="57">
#		<artist type="Person" id="c0b2500e-0cef-4130-869d-732b23ed9df5" ext:score="100">
#			<name>Tori Amos</name>
#			<sort-name>Tori Amos</sort-name>
#			<life-span begin="1963-08-22"/>
#		</artist>
#		<artist type="Person" id="9973d77e-bbcd-4977-86ad-8c300417aa00" ext:score="42">
#			<name>Tori</name>
#			<sort-name>Tori</sort-name>
#		</artist>
#		<artist type="Person" id="43256173-a132-42df-86cf-9b1d62fb448d" ext:score="42">
#			<name>Tori</name>
#			<sort-name>Tori</sort-name>
#			<disambiguation>Spanish MC</disambiguation>
#		</artist>
#		<artist type="Group" id="5bcd4eaa-fae7-465f-9f03-d005b959ed02" ext:score="41">
#			<name>The Da Capo Players</name>
#			<sort-name>The Da Capo Players</sort-name>
#		</artist>
#		<artist type="Group" id="5cc22c2d-4e5f-40e3-b959-e41e1e1870b5" ext:score="37">
#			<name>Amos</name>
#			<sort-name>Amos</sort-name>
#			<disambiguation>Brazilian Metal band</disambiguation>
#		</artist>
#		<artist type="Person" id="5841e893-52e7-4e45-82d3-6001d37dad4f" ext:score="37">
#			<name>Amos</name>
#			<sort-name>Amos</sort-name>
#			<disambiguation>Rapper from Louisville, KY, USA</disambiguation>
#		</artist>
#		<artist type="Person" id="d664c56f-cee4-49b4-9e09-099ba0178462" ext:score="37">
#			<name>Amos</name>
#			<sort-name>Amos</sort-name>
#			<disambiguation>UK techno producer Amos Pizzey</disambiguation>
#		</artist>
#		<artist type="Person" id="048db7e7-7186-4bdc-8a1c-abf5d69cb007" ext:score="37">
#			<name>Amos</name>
#			<sort-name>Amos</sort-name>
#			<disambiguation>Swedish producer Amos Jansson</disambiguation>
#		</artist>
#		<artist type="Person" id="6296af33-fd99-49d6-bfa9-60883a4c8faa" ext:score="37">
#			<name>Amos</name>
#			<sort-name>Amos</sort-name>
#			<disambiguation>Gianluca Marcelli</disambiguation>
#		</artist>
#		<artist type="Person" id="896998e8-1f1f-4add-93ed-c8a951d0d4a1" ext:score="26">
#			<name>Tori Spelling</name>
#			<sort-name>Tori Spelling</sort-name>
#		</artist>
#		<artist type="Unknown" id="ca862bfd-3e27-4758-838c-5112e3c3c56b" ext:score="26">
#			<name>Tori Crimes</name>
#			<sort-name>Tori Crimes</sort-name>
#		</artist>
#		<artist type="Person" id="69178de5-27e1-4580-af9a-2408aa05bb51" ext:score="26">
#			<name>Tori Thompson</name>
#			<sort-name>Tori Thompson</sort-name>
#			<life-span begin="1993-10-25"/>
#		</artist>
#		<artist type="Person" id="71551055-d0d5-4ffc-a33e-9e7840585a5f" ext:score="26">
#			<name>Tori Alamaze</name>
#			<sort-name>Tori Alamaze</sort-name>
#		</artist>
#		<artist type="Person" id="8ba603d8-61b2-4175-9820-065ee079cb52" ext:score="26">
#			<name>Tori Baxley</name>
#			<sort-name>Tori Baxley</sort-name>
#		</artist>
#		<artist type="Person" id="af1a9ea1-0863-4fda-b81a-bf6e65813ea6" ext:score="26">
#			<name>Tori Fuson</name>
#			<sort-name>Tori Fuson</sort-name>
#		</artist>
#		<artist type="Person" id="ac6ca6e5-1e64-414d-b3bc-0cdf7611232b" ext:score="26">
#			<name>Tori Sparks</name>
#			<sort-name>Tori Sparks</sort-name>
#		</artist>
#		<artist type="Person" id="2342f9f1-60dc-4156-a688-efc036842844" ext:score="26">
#			<name>Tori London</name>
#			<sort-name>Tori London</sort-name>
#		</artist>
#		<artist type="Person" id="372a24d2-4585-4eb3-88db-e6b7bd7e1c23" ext:score="26">
#			<name>Tori Kudo</name>
#			<sort-name>Tori Kudo</sort-name>
#		</artist>
#		<artist type="Person" id="f55fccba-908e-4ebc-a1ce-1e31191e52ca" ext:score="26">
#			<name>Fulvio Tori</name>
#			<sort-name>Fulvio Tori</sort-name>
#		</artist>
#		<artist type="Group" id="c2841b26-0c35-4524-98a7-d71b43a9a60d" ext:score="23">
#			<name>Daniel Amos</name>
#			<sort-name>Daniel Amos</sort-name>
#			<life-span begin="1976"/>
#		</artist>
#		<artist type="Person" id="dfa41f72-2f98-4f16-95ea-440cad19db77" ext:score="23">
#			<name>Amos Milburn</name>
#			<sort-name>Amos Milburn</sort-name>
#			<life-span end="1980-01-03" begin="1927-04-01"/>
#		</artist>
#		<artist type="Unknown" id="eef2006e-4f04-4138-bf11-54d92ba08613" ext:score="23">
#			<name>Amos Clarke</name>
#			<sort-name>Amos Clarke</sort-name>
#		</artist>
#		<artist type="Unknown" id="c59dbeff-2fed-4289-a74d-3bbe9416c969" ext:score="23">
#			<name>Amos Milbourne</name>
#			<sort-name>Amos Milbourne</sort-name>
#		</artist>
#		<artist type="Person" id="cd344a48-e3cf-4fd2-b4de-bb7375a06247" ext:score="23">
#			<name>Amos Garrett</name>
#			<sort-name>Amos Garrett</sort-name>
#		</artist>
#		<artist type="Unknown" id="e92c996a-513f-4b50-b616-b9583d41cd6d" ext:score="23">
#			<name>Amos Easton</name>
#			<sort-name>Amos Easton</sort-name>
#		</artist>
#	</artist-list>
#</metadata>
#__TOP



#my ($json_url) =
#"http://www.librarything.com/api_getdata.php?userid=Kalimko&key=958343592&max=100";
## "http://ws.geonames.org/citiesJSON?north=44.1&south=-9.9&east=-22.4&west=55.2&lang=de";
## "http://www.southparkstudios.com/includes/utils/proxy_feed.php?html=season_json.jhtml%3fseason=1";
#my $browser = WWW::Mechanize->new();
#print "Getting json $json_url\n";
#$browser->get($json_url);
#my $content = $browser->content();
#my $json    = new JSON;
## these are some nice json options to relax restrictions a bit:
##my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
#$content =~ s/^var widgetResults = //g;
## ;LibraryThing.bookAPI.displayWidgetContents(widgetResults, "LT_Content");
#$content =~ s/;[^;]+;$//g;
##print("\n$content\n");
#my $json_text = $json->filter_json_object->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->allow_unknown->decode($content);
#sub kiki {
#	}
#	
##print Dumper($json_text);
#foreach my $bookId (keys(%{$json_text->{books}}))
#{
#	utf8::encode($json_text->{books}->{$bookId}->{title});
#	print( "titre: ".$json_text->{books}->{$bookId}->{title}."\n");
#}
#
