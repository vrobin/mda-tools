#!/usr/bin/perl -w -IJ:\\documents\\Projects\\workspace\\mda-tools\\Perl\\MDALib\\lib
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
		DEBUG "called AlbumFile->dataSources with an empty array, truncating!";
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

	if(exists($toto->{lookupData})) {
		ERROR("Old lookupData element present, you have to edit it manually");
		die;
	}
	$self->{lookupData} = $toto->{lookupData} ;

	# Deserialize dataSources element, transform single element in one element array
	if(exists($toto->{dataSources}) and exists($toto->{dataSources}{dataSource}) ) {
		unless(ref($toto->{dataSources}{dataSource}) eq 'ARRAY') {
			my $dataSource=$toto->{dataSources}{dataSource};
			push @{$toto->{dataSources}{dataSource}=[]}, $dataSource;
		}
	}

	# Add normalized array to the object dataSource
	$self->dataSources($toto->{dataSources}{dataSource});

	# Bless each dataSource existing (blessObject calls associated "deserialize" method)
	foreach my $dataSource (@{$self->dataSources()}) {
		#Tools::blessObject('DataFile::DataSource', $dataSource);
		# to deserialize, this module must know the reader class
		print("DATASOURCE: ",$dataSource->{class}, "\n");
		eval("use  ".$dataSource->{class});
		Tools::blessObject($dataSource->{class}, $dataSource);
		$dataSource->albumFile($self);
	}
	

	# Deserialize lookupDatas element, transform single element in one element array
	if(exists($toto->{lookupDatas}) and exists($toto->{lookupDatas}{lookupData}) ) {
		unless(ref($toto->{lookupDatas}{lookupData}) eq 'ARRAY') {
			my $lookupData=$toto->{lookupDatas}{lookupData};
			push @{$toto->{lookupDatas}{lookupData}=[]}, $lookupData;
		}
	}

	# Add normalized array to the object lookupData
	$self->lookupDatas($toto->{lookupDatas}{lookupData});

	# Bless each dataSource existing (blessObject calls associated "deserialize" method)
	foreach my $lookupData (@{$self->lookupDatas()}) {
		#Tools::blessObject('DataFile::DataSource', $dataSource);
		# to deserialize, this module must know the reader class
		print("LOOKUPDATA: ",$lookupData->{class}, "\n");
		eval("use  ".$lookupData->{class});
		Tools::blessObject($lookupData->{class}, $lookupData);
		$lookupData->albumFile($self);
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

sub lookupData {
	my $self = shift or return undef;
	my $lookupDataName = shift or return undef; 

	# DataSource must have it's providerName filled for coherency check
	unless( $self and $lookupDataName ) { 
		ERROR("Missing lookup data name"); 
		return undef; 
	}
	
	# foreach dataSource in this albumfile, look for an already existing dataSource with the same name
	foreach my $existingLookupData ( @{$self->{lookupDatas}{lookupData}} ) {
		if($existingLookupData->name() eq $lookupDataName) {
			return $existingLookupData;
		}
	}
 
	WARN("Lookupdata $lookupDataName not found");
	return undef;
}

sub lookupDatas  {
	my $self = shift;
	my $lookupDatas = shift;
	
	# if no performances array ref is sent
	if(!$lookupDatas) {
		
		# if no performances array exists
		if(ref($self->{lookupDatas}{lookupData}) ne 'ARRAY') {
			#create it
			$self->{lookupDatas}{lookupData}=[];
			DEBUG 'Initializing normalized date array'
		} # returning existing or initialized
		
		return ($self->{lookupDatas}{lookupData});
	}
	
	if($#$lookupDatas == -1) {
		DEBUG "called AlbumFile->$lookupDatas with an empty array, truncating!";
	}
	
	$self->{lookupDatas}{lookupData} = $lookupDatas;
}

sub addLookupData {
	my $self = shift;
	my $lookupData = shift; 
	# if param is not an doesn't-> return
	if ( ref($lookupData) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Lookup/ ) {
		# return It
		ERROR ("no LookupData object in parameter ");
		return (undef );
	}
	
	# DataSource must have it's providerName filled for coherency check
	unless( $lookupData->name() ) { 
		ERROR("Missing provider name in lookupData"); 
		return; 
	}
	
	# foreach dataSource in this albumfile, look for an already existing dataSource with the same name
#	foreach my $existingDataSource ( @{$self->{dataSources}{dataSource}} ) {
#		if($existingDataSource->name() eq $dataSource->name()) {
#			WARN("DataSource ",$dataSource->name()," already exists, overwriting");
#			return undef;
#		}
#	}

	for my $i (0 .. $#{$self->{lookupDatas}{lookupData}} ) {
		if(${$self->{lookupDatas}{lookupData}}[$i]->name() eq  $lookupData->name()) {
			WARN("LookupData ",$lookupData->name()," already exists, overwriting");
			$lookupData->albumFile($self);
			return ${$self->{lookupDatas}{lookupData}}[$i]=$lookupData;
		}
	}

	$lookupData->albumFile($self);
	push @{$self->{lookupDatas}{lookupData}}, $lookupData;
}

END { }    # module clean-up code here (global destructor)
1;