use strict;
use utf8;

use Data::Dumper;

use XML::Compile::Schema;

my $xsdfile = "J:/documents/Projects/workspace/mda-tools/XSD/mda-management-interface.xsd";
my $mmiNs = "http://medee.dyndns.org/MDA/20100131/mda-management-interface";

my $schema = XML::Compile::Schema->new($xsdfile);
my $writer = $schema->compile(
		WRITER => "{$mmiNs}DataSourcesDescriptionsList");
 $schema->printIndex;

my $hash;
$hash->{DataSourceDescription}->[0]->{code}="AZE";
die Dumper $hash;
my $doc    = XML::LibXML::Document->new('1.0','UTF-8');
my $xml    = $writer->($doc, $hash);  # partial doc
print $xml->toString;
