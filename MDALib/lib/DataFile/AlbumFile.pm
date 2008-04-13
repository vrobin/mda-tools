#!/usr/bin/perl -w
package DataFile::AlbumFile;

use strict;
use utf8;

use DataFile::Date;
use DataFile::DataSource;
use DataFile::Composer;
use DataFile::Picture;
use Tools;

use Log::Log4perl qw(:easy);
use Data::Dumper;
use XML::Simple;


sub new {
	my $class = shift;
	my $albumFile = { };
	bless ($albumFile, $class);
	return $albumFile;
}

sub dataSources  {
	my $self = shift;
	my $dataSources = shift;
	# if no performances array ref is sent
	if(!$dataSources) {
		# if no performances array exists
		if(ref($self->{dataSources}{dataSource}) ne 'ARRAY') {
			#create it
			$self->{dataSources}{dataSource}=[];
			DEBUG 'Initializing normalized date array'
		} # returning existing or initialized
		return ($self->{dataSources}{dataSource});
	}
	if($#$dataSources == -1) {
		DEBUG "called disc->dataSources with an empty array, truncating!";
	}
	$self->{dataSources}{dataSource} = $dataSources;
}

# Write the file to disk, input: filename

sub serialize {
	my $self = shift or return undef;
	my $outputFile = shift or return undef;
	#print Dumper(\$self);
	$self->{xmlns}="http://medee.dyndns.org/MDA/20080308/collection";
	$self->{'xmlns:xsi'}="http://www.w3.org/2001/XMLSchema-instance";
	$self->{'xmlns:xlink'}="http://www.w3.org/1999/xlink";
	$self->{'xsi:schemaLocation'}="http://medee.dyndns.org/MDA/20080308/collection collection.xsd ";
	my $xmlparser = XML::Simple->new();
	$xmlparser->XMLout(
		$self,
		RootName      => 'albumFile',
		AttrIndent    => 0,
		NoIndent    => 1,
		SuppressEmpty => 1,
		KeyAttr       => [],
		OutputFile    =>$outputFile,
		ContentKey    => 'content',
		XMLDecl       => "<?xml version='1.0'?>",
	);
}

sub deserialize {
	my $self = shift or return undef;
	my $inputFile = shift or return undef;
	my $xmlparser = XML::Simple->new();
	my $toto = $xmlparser->XMLin($inputFile, 
#		$self,
#		RootName      => 'albumFile',
#		AttrIndent    => 1,
#		SuppressEmpty => 1,
		KeyAttr       => [],
		ForceArray => ['XXaward', 'XXcomposer', 'XXcredit', 'XXdataSource', 'XXdisc', 'XXnormalized', 'XXnote', 'XXpart', 'XXperformance', 'XXpicture', 'XXplace', 'XXrating', 'XXrelease', 'XXtag', 'XXtrack', 'XXwork','XXdiscId' ],
#		OutputFile    =>$inputFile,
		ForceContent => 1,
		ContentKey    => 'content'
#		XMLDecl       => "<?xml version='1.0'?>",
	);

	$self->{lookupData} = $toto->{lookupData} ;

	if(exists($toto->{dataSources}) and exists($toto->{dataSources}{dataSource}) ) {
		unless(ref($toto->{dataSources}{dataSource}) eq 'ARRAY') {
			my $dataSource=$toto->{dataSources}{dataSource};
			push @{$toto->{dataSources}{dataSource}=[]}, $dataSource;
		}
	}

	$self->dataSources($toto->{dataSources}{dataSource});
	
	foreach my $dataSource (@{$self->dataSources()}) {
		#Tools::blessObject('DataFile::DataSource', $dataSource);
		# to deserialize, this module must know the reader class
		print("DATASOURCE: ",$dataSource->{class}, "\n");
		eval("use  ".$dataSource->{class});
		Tools::blessObject($dataSource->{class}, $dataSource);
		$dataSource->albumFile($self);
	}
}

sub dataSource {
	my $self = shift or return undef;
	my $dataSourceName = shift or return undef; 

	# DataSource must have it's providerName filled for coherency check
	unless( $self and $dataSourceName ) { 
		ERROR("Missing source name"); 
		return undef; 
	}
	
	# foreach dataSource in this albumfile, look for an already existing dataSource with the same name
	foreach my $existingDataSource ( @{$self->{dataSources}{dataSource}} ) {
		if($existingDataSource->name() eq $dataSourceName) {
			return $existingDataSource;
		}
	}

	# A try to ease the access to dataSource from its name. Not sure it will be useful, let it commentend for now
#	$self->{$dataSource->name()} = $dataSource;
#	die $self->{CUE}->version(); 
	WARN("Datasource $dataSourceName not found");
	return undef;
}

sub addDataSource {
	my $self = shift;
	my $dataSource = shift; 
	# if param is not an doesn't-> return
	if ( ref($dataSource) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
		# return It
		ERROR ("no DataSource  object in parameter ");
		return (undef );
	}
	
	# DataSource must have it's providerName filled for coherency check
	unless( $dataSource->name() ) { 
		ERROR("Missing provider name in dataSource"); 
		return; 
	}
	
	# foreach dataSource in this albumfile, look for an already existing dataSource with the same name
#	foreach my $existingDataSource ( @{$self->{dataSources}{dataSource}} ) {
#		if($existingDataSource->name() eq $dataSource->name()) {
#			WARN("DataSource ",$dataSource->name()," already exists, overwriting");
#			return undef;
#		}
#	}

	for my $i (0 .. $#{$self->{dataSources}{dataSource}} ) {
		if(${$self->{dataSources}{dataSource}}[$i]->name() eq  $dataSource->name()) {
			WARN("DataSource ",$dataSource->name()," already exists, overwriting");
			$dataSource->albumFile($self);
			return ${$self->{dataSources}{dataSource}}[$i]=$dataSource;
		}
	}

	# A try to ease the access to dataSource from its name. Not sure it will be useful, let it commentend for now
#	$self->{$dataSource->name()} = $dataSource;
#	die $self->{CUE}->version(); 
	$dataSource->albumFile($self);
	push @{$self->{dataSources}{dataSource}}, $dataSource;
}


END { }    # module clean-up code here (global destructor)
1;