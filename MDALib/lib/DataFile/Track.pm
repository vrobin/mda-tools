#!/usr/bin/perl -w
package DataFile::Track;

use strict;
use Data::Dumper;
use utf8;
use Tools;
use Log::Log4perl qw(:easy);

sub new {
	my $class  = shift;
	my $track = {};
	my %params;
	if (@_) {
		%params = %{ shift() };
	}
	
	bless( $track, $class );
	if (%params) {
		if ( defined( $params{id} ) ) {
			$track->id( $params{id} );
		}
		if ( defined( $params{index} ) ) {
			$track->index( $params{index} );
		}		
		if ( defined( $params{name} ) ) {
			$track->name( $params{name} );
		}
		if ( defined( $params{length} ) ) {
			$track->length( $params{length} );
		}		
		if ( defined( $params{nameDetail} ) ) {
			$track->nameDetail( $params{nameDetail} );
		}		
		if ( defined( $params{value} ) ) {
			$track->value( $params{value} );
		}
		if ( defined( $params{url} ) ) {
			$track->url( $params{url} );
		}
		if ( defined( $params{rawData} ) ) {
			$track->rawData( $params{rawData} );
		}
		if ( defined( $params{workId} ) ) {
			$track->workId( $params{workId} );
		}	
		if ( defined( $params{workIndex} ) ) {
			$track->workIndex( $params{workIndex} );
		}
		if ( defined( $params{performanceId} ) ) {
			$track->performanceId( $params{performanceId} );
		}
		if ( defined( $params{performance} ) ) {
			$track->performance( $params{performance} );
		}		
		if ( defined( $params{samples} ) ) {
			$track->samples( $params{samples} );
		}
		if ( defined( $params{sampleRate} ) ) {
			$track->sampleRate( $params{sampleRate} );
		}	
		if ( defined( $params{perfIndex} ) ) {
			$track->perfIndex( $params{perfIndex} );
		}				
	}
	return $track;
}

sub parent {
	return disc(@_);
}

sub disc {
	my $self = shift;
	my $disc   = shift;
	if ($disc) { $self->{-disc} = Tools::trim($disc) }
	return $self->{-disc};
}

sub url {
	my $self = shift;
	my $url   = shift;
	if ($url) { $self->{url} = Tools::trim($url) }
	return $self->{url};
}

sub baseUrl {
	my $self = shift;
	my $baseUrl   = shift;
	if ($baseUrl) { $self->{baseUrl} = Tools::trim($baseUrl) }
	return $self->{baseUrl};
}

sub relativeUrl {
	my $self = shift;
	my $relativeUrl   = shift;
	if ($relativeUrl) { $self->{relativeUrl} = Tools::trim($relativeUrl) }
	return $self->{relativeUrl};
}

sub workId {
	my $self = shift;
	my $workId   = shift;
	return $self->work->id($workId);
}

sub work {
	my $self = shift;
	my $work = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($work) {
		#if there is already an object
		if (ref($self->{work}) eq 'DataFile::Work') {
			# return It
			return $self->{work};
		}else { # create a new empty object of this type
			$self->{work}= DataFile::Work->new();
			# TODO: check that parent is called for all new objects created and returned by accessors like this
			$self->{work}->parent($self);
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($work) eq 'DataFile::Work') { 
		$self->{work}= $work; 
	}
	elsif($work){  # We only insert objects of the good type
		ERROR('Object ->work called with an unexpected parameter '.ref($work).' waiting a DataFile::Work');
	}
	# Return the set object
	return $self->{work};
}

sub performanceId {
	my $self = shift;
	my $performanceId   = shift;
	return $self->performance->id($performanceId);
}

sub performance {
	my $self = shift;
	my $performance = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($performance) {
		#if there is already an object
		if (ref($self->{performance}) eq 'DataFile::Performance') {
			# return It
			return $self->{performance};
		}else { # create a new empty object of this type
			$self->{performance}= DataFile::Performance->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($performance) eq 'DataFile::Performance') { 
		$self->{performance}= $performance; 
	}
	elsif($performance){  # We only insert objects of the good type
		ERROR('Object ->performance called with an unexpected parameter '.ref($performance).' waiting a DataFile::Performance');
	}
	# Return the set object
	return $self->{performance};
}

sub perfIndex {
	my $self = shift;
	my $perfIndex   = shift;
	if ($perfIndex) { $self->{perfIndex} = Tools::trim($perfIndex) }
	return $self->{perfIndex};
}

sub rawData {
	my $self = shift;
	my $rawData   = shift;
	if ($rawData) { 
# old tweak to force rawData not to be an attribute, but content text
#		$self->{rawData}{forceText} = 'true'; 
		$self->{rawData}{content} = Tools::trim($rawData) 
	}
	return $self->{rawData}{content};
}

sub value {
	my $self = shift;
	my $value   = shift;
	if ($value) { $self->{value} = Tools::trim($value) }
	return $self->{value};
}

sub sampleRate {
	my $self = shift;
	my $sampleRate   = shift;
	if ($sampleRate) { $self->{sampleRate} = Tools::trim($sampleRate) }
	return $self->{sampleRate};
}

sub samples {
	my $self = shift;
	my $samples   = shift;
	if ($samples) { $self->{samples} = Tools::trim($samples) }
	return $self->{samples};
}

sub name {
	my $self = shift;
	my $name   = shift;
	if ($name) { $self->{name} = Tools::trim($name) }
	return $self->{name};
}

sub nameDetail {
	my $self = shift;
	my $nameDetail   = shift;
	if ($nameDetail) { $self->{nameDetail} = Tools::trim($nameDetail) }
	return $self->{nameDetail};
}

#sub url {
#	my $self = shift;
#	my $url   = shift;
#	if ($url) { $self->{url} = Tools::trim($url) }
#	return $self->{url};
#}

sub index {
	my $self = shift;
	my $index   = shift;
	if ($index) { $self->{index} = Tools::trim($index) }
	return $self->{index};
}

# used to hold vinyl or tape index freeform as used in discogs A1, A2, B1, B2 etc.
sub rawIndex {
	my $self = shift;
	my $rawIndex   = shift;
	if ($rawIndex) { $self->{rawIndex} = Tools::trim($rawIndex) }
	return $self->{rawIndex};
}

sub length  {
	my $self = shift;
	my $length = shift;
	
	# S'il n'y a pas de paramètre en entrée
	unless($length) {
		#if there is already an albumLength
		if (ref($self->{'length'}) eq 'DataFile::Length') {
			# return It
			return $self->{'length'};
		}else {
			$self->{'length'}= DataFile::Length->new();
		}
	}
	# Called with a Date Object, replacing it
	if (ref($length) eq 'DataFile::Length') { 
		$self->{'length'}= $length; 
	}
	elsif($length){
		ERROR 'track->length called with an unexpected parameter'.ref($length)  ;
	}
	return $self->{'length'};
}

# TODO: add performance rating? (to be added either in perf or track or both)

sub id {
	my $self = shift;
	my $id   = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
}

# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;
	Tools::blessObject('DataFile::Length', $self->{length});
	
	# these lines are no longer used as we array-ify objects manually in $object->deserialize methods, not with xmlsimple parameter
	# performances are deserialized as an array by xmlsimple but track performance object is not an array
	#$self->{'performance'} = $self->{'performance'}[0];
	#if(defined($self->{performance}[0])) { $self->{performance} = $self->{performance}[0]; } else { delete($self->{performance}) };


	if(exists($self->{performance}) and defined($self->{performance}) ) {
		Tools::blessObject('DataFile::Performance', $self->{performance});
		$self->performance->parent($self);
	}

	#if(defined($self->{work}[0])) { $self->{work} = $self->{work}[0]; } else { delete($self->{work}) };
	#if(ref($self->{work}) eq 'ARRAY' and scalar(@{$self->{work}})==0 ) { delete($self->{work})}

	if(exists($self->{work}) and defined($self->{work}) ) {
		Tools::blessObject('DataFile::Work', $self->{work});
		$self->work->parent($self);
	}	
}

END { }    # module clean-up code here (global destructor)
1;
