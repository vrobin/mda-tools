#!/usr/bin/perl -w
package DataFile::Lookup;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

sub new {
	my $class    = shift;
	my $params;
	if(@_) {
		$params = shift();
	}
	my $lookup = {};
	bless( $lookup, $class );
	if(ref($params) eq 'HASH') {
		if ( defined( $params->{version} ) ) {
			$lookup->version( $params->{version} );
		}
		if ( defined( $params->{name} ) ) {
			$lookup->name( $params->{name} );
		}
		if ( defined( $params->{providerName} ) ) {
			$lookup->providerName( $params->{providerName} );
		}
#		if ( defined( $params{reader} ) ) {
#			$dataSource->reader( $params{reader} );
#		}
		if ( defined( $params->{providerUrl} ) ) {
			$lookup->providerUrl( $params->{providerUrl} );
		}
	}
	return $lookup;
}

sub class {
	my $self = shift;
	my $class   = shift;
	if ($class) { $self->{class} = Tools::trim($class) }
	return $self->{class};
}

sub name {
	my $self = shift;
	my $name   = shift;
	if ($name) { $self->{name} = Tools::trim($name) }
	return $self->{name};
}

sub version {
	my $self = shift;
	my $version   = shift;
	if ($version) { $self->{version} = Tools::trim($version) }
	return $self->{version};
}

sub providerUrl {
	my $self = shift;
	my $providerUrl   = shift;
	if ($providerUrl) { $self->{providerUrl} = Tools::trim($providerUrl) }
	return $self->{providerUrl};
}

sub providerName {
	my $self = shift;
	my $providerName   = shift;
	if ($providerName) { $self->{providerName} = Tools::trim($providerName) }
	return $self->{providerName};
}

sub retrievalParams {
	my $self = shift;	# XXX: ignore calling class/object
	my $varName = ref($self).'::retrievalParams';
# Commenting out as retrievalParams is read-only
#	$self->{retrievalParams} = shift if @_;
#	die $className;
	no strict "refs"; 	
	return $$varName;
}

sub retrievalParamsByCriteriaAndValue {
	my $self = shift;	# XXX: ignore calling class/object
	my $criteria = shift;
	my $value = shift;
	my $params = $self->retrievalParams();
	my $foundParams = undef;
	foreach my $param (keys(%{$params})) {
		if(exists($params->{$param}->{$criteria}) and $params->{$param}->{$criteria} eq $value ) {
			$foundParams->{$param} = $params->{$param};
		}
	}
	return $foundParams;
}

sub retrievalParamsByCriteriasAndValuesHashRef {
	my $self = shift;	# XXX: ignore calling class/object
	my $criteriaAndValueHashRef = shift;
	my $params = $self->retrievalParams();
	my $foundParams = undef;
	foreach my $param (keys(%{$params})) {
		my $paramMatch = 1;
		foreach my $criteria (keys(%{$criteriaAndValueHashRef})) {
			if(not (exists($params->{$param}->{$criteria}) and $params->{$param}->{$criteria} eq $criteriaAndValueHashRef->{$criteria} )) {
				$paramMatch=0;
			}
		}
		if($paramMatch) {
			$foundParams->{$param} = $params->{$param};
		}
	}
	return $foundParams;
}

sub setRetrievalParam {
	my $self = shift;
	my $paramName = shift;
	my $paramValue = shift;
	#$self->{retrievalDatas}{retrievalDatas}{}
}

#sub lookupData {
#	my $self = shift or return undef;
#	my $lookupDataName = shift or return undef; 
#
#	# DataSource must have it's providerName filled for coherency check
#	unless( $self and $lookupDataName ) { 
#		ERROR("Missing lookup data name"); 
#		return undef; 
#	}
#	
#	# foreach dataSource in this albumfile, look for an already existing dataSource with the same name
#	foreach my $existingLookupData ( @{$self->{lookupDatas}{lookupData}} ) {
#		if($existingLookupData->name() eq $lookupDataName) {
#			return $existingDataSource;
#		}
#	}
# 
#	WARN("Lookupdata $lookupDataName not found");
#	return undef;
#}
#
#sub lookupDatas  {
#	my $self = shift;
#	my $lookupDatas = shift;
#	
#	# if no performances array ref is sent
#	if(!$lookupDatas) {
#		
#		# if no performances array exists
#		if(ref($self->{lookupDatas}{lookupData}) ne 'ARRAY') {
#			#create it
#			$self->{lookupDatas}{lookupData}=[];
#			DEBUG 'Initializing normalized date array'
#		} # returning existing or initialized
#		
#		return ($self->{lookupDatas}{lookupData});
#	}
#	
#	if($#$lookupDatas == -1) {
#		DEBUG "called AlbumFile->$lookupDatas with an empty array, truncating!";
#	}
#	
#	$self->{lookupDatas}{lookupData} = $lookupDatas;
#}


1;