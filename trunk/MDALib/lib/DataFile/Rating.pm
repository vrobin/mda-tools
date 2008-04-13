#!/usr/bin/perl -w
package DataFile::Rating;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

sub new {
	my $class    = shift;
	my %params;
	if(@_) {
	%params= %{shift()};
	}
	my $rating = {};
	bless( $rating, $class );
	if(%params) {
		if (defined($params{providerName}) ) { 
			$rating->providerName($params{providerName}) ;
		}
		if (defined($params{value}) ) { 
			$rating->value($params{value}) ;
		}
		if (defined($params{valueMax}) ) { 
			$rating->valueMax($params{valueMax}) ;
		}		
		if (defined($params{type}) ) { 
			$rating->type($params{type}) ;
		}
		if (defined($params{providerName}) ) { 
			$rating->providerName($params{providerName}) ;
		}		
		if ( defined( $params{rawData} ) ) {
			$rating->rawData( $params{rawData} );
		}
	}
	return $rating;
}

sub providerName {
	my $self = shift;
	my $provider   = shift;
	if ($provider) { $self->{providerName} = Tools::trim($provider) }
	return $self->{providerName};
}

sub type {
	my $self = shift;
	my $type   = shift;
	if ($type) { $self->{type} = Tools::trim($type) }
	return $self->{type};
}

sub deserialize{
	my $self = shift or return undef;
	# TODO: to be finished for amazon like rating (grade + note) not yet implemented
	# Rating has only one note and note is deserialized as an array by default, correct it if needed

# this code was used to convert the array in single object (because of deserialize parameters)
# it's no longer used as array-ifying is done manually in $object->deserialize calls)
#	if(defined($self->{note}) ) {
#		$self->{note} = $self->{note}[0];
#	}
	if(exists($self->{note}) and defined($self->{note}) ) {
		Tools::blessObject('DataFile::Note', $self->{note});
	}
}

# TODO: handle note type for amz rating
# TODO: add deserialize for these note
sub value {
	my $self = shift;
	my $value   = shift;
	if ($value) { $self->{value} = Tools::trim($value) }
	return $self->{value};
}

sub valueMax{
	my $self = shift;
	my $valueMax   = shift;
	if ($valueMax) { $self->{valueMax} = Tools::trim($valueMax) }
	return $self->{valueMax};
}

sub  note  {
	my $self = shift;
	my $note = shift;
	
	# S'il n'y a pas de paramètre en entrée
	unless($note) {
		#if there is already an note
		if (ref($self->{'note'}) eq 'DataFile::Note') {
			# return It
			return $self->{'note'};
		}else {
			$self->{'note'}= DataFile::Note->new();
		}
	}
	# Called with a Note  Object, replacing it
	if (ref($note) eq 'DataFile::Note') { 
		$self->{'note'}= $note; 
	}
	elsif($note){
		ERROR 'rating->note called with an unexpected parameter'.ref($note)  ;
	}
	return $self->{'note'};
}

sub rating {
	my $self = shift;
	if (@_) { $self = shift; }
	return $self;
}

sub rawData {
	my $self    = shift;
	my $rawData = shift;
	if ($rawData) {
# old tweak to force rawData not to be an attribute, but content text
#		$self->{rawData}{forceText} = 'true';
		$self->{rawData}{content} = Tools::trim($rawData);
	}
	return $self->{rawData}{content};
}


END { }    # module clean-up code here (global destructor)
1;
