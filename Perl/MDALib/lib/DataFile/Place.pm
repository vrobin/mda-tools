#!/usr/bin/perl -w
package DataFile::Place;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

# TODO: create place like objects for published

sub new {
	my $class = shift;
	my $place = {};        

	my %params;
	if (@_) {
		%params = %{ shift() };
	}
	
	bless( $place, $class );
	if (%params) {
		if ( defined( $params{country} ) ) {
			$place->country( $params{country} );
		}
		if ( defined( $params{city} ) ) {
			$place->city( $params{city} );
		}
		if ( defined( $params{rawData} ) ) {
			$place->rawData( $params{rawData} );
		}
	}        
	return $place;        
}

sub place {
        my $self = shift;
        if (@_) { $self = shift; }
        return $self;
}

sub rawData {
	my $self = shift;
	my $rawData = shift;
	 if ($rawData) { 
# old tweak to force rawData not to be an attribute, but content text
#	 	$self->{rawData}{forceText} = 'true';
	 	$self->{rawData}{content} = Tools::trim($rawData) 
	}
	return $self->{rawData}{content};
}

sub country {
	my $self = shift;
	my $country = shift;
	 if ($country) { 
	 	$self->{country} = Tools::trim($country) 
	}
	return $self->{country};
}

sub city {
	my $self = shift;
	my $city = shift;
	 if ($city) { 
	 	$self->{city} = Tools::trim($city) 
	}
	return $self->{city};
}

END { }    # module clean-up code here (global destructor)
1;
