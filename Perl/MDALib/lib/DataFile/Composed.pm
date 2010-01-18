#!/usr/bin/perl -w
package DataFile::Composed;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

# TODO: create composed like objects for published

sub new {
        my $class = shift;
        my $composed = {};
        bless ($composed, $class);
        return $composed;
}

# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;
	Tools::blessObject('DataFile::Date', $self->{date});
	Tools::blessObject('DataFile::Place', $self->{place});
}

sub composed {
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

sub place  {
	my $self = shift;
	my $place = shift;
	# if there is no parameter in input
	unless($place) {
		#if there is already an composedPlace in the composer object
		if (ref($self->{place}) eq 'DataFile::Place'){
			# return It
			return($self->{place});
		} else {
			# create it
			$self->{place} = DataFile::Place->new();
		}
		
	}
	# Called with a Place Object, replacing it
	if (ref($place) eq 'DataFile::Place') { 
		$self->{place}= $place; 
	}
	elsif($place){
		ERROR 'album->composed->place called with an unexpected parameter'.ref($place)  ;
	}
	return $self->{place};	
}

sub date  {
	my $self = shift;
	my $date = shift;
	# if there is no parameter in input
	unless($date) {
		#if there is already an composedDate in the composer object
		if (ref($self->{date}) eq 'DataFile::Date'){
			# return It
			return($self->{date});
		} else {
			# create it
			$self->{date} = DataFile::Date->new();
		}
		
	}
	# Called with a Date Object, replacing it
	if (ref($date) eq 'DataFile::Date') { 
		$self->{date}= $date; 
	}
	elsif($date){
		ERROR 'albumReleaseDate called with an unexpected parameter'.ref($date)  ;
	}
	return $self->{date};	
}


END { }    # module clean-up code here (global destructor)
1;
