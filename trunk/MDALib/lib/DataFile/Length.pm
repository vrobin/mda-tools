#!/usr/bin/perl -w
package DataFile::Length;

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
	my $length = {};
	bless( $length, $class );
	if(%params) {
		if (defined($params{seconds}) ) { 
			$length->seconds($params{seconds}) ;
		}
		if (defined($params{frames}) ) { 
			$length->frames($params{frames}) ;
		}		
		if ( defined( $params{rawData} ) ) {
			$length->rawData( $params{rawData} );
		}
	}
	return $length;
}

sub seconds {
	my $self = shift;
	my $seconds   = shift;
	if ($seconds) { $self->{'seconds'} = Tools::trim($seconds) }
	return $self->{'seconds'};
}

sub frames {
	my $self = shift;
	my $frames   = shift;
	if ($frames) { $self->{'frames'} = Tools::trim($frames) }
	return $self->{'frames'};
}

sub length {
	my $self = shift;
	if (@_) { $self = shift; }
	return $self;
}

sub extractSecondsFromRawDataMMSS  {
	my $self = shift or return undef;
	my $timeString = $self->rawData();
	my ($minutes, $seconds);
	if ($timeString =~ /[0-9]+:[0-9]+/ ) {
		($minutes, $seconds) = ( $timeString =~ /([0-9]+):([0-9]+)/g );
	}else { 
		ERROR "unknown time string format '$timeString' while expected mmm:ss "; 
		return(undef);
	}
	$self->seconds ( $minutes*60+$seconds  );
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
