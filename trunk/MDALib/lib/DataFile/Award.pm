#!/usr/bin/perl -w
package DataFile::Award;

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
	my $award = {};
	bless( $award, $class );
	if(%params) {
		if (defined($params{name}) ) { 
			$award->name($params{name}) ;
		}		
		if ( defined( $params{rawData} ) ) {
			$award->rawData( $params{rawData} );
		}
	}
	return $award;
}

sub name {
	my $self = shift;
	my $name   = shift;
	if ($name) { $self->{'name'} = Tools::trim($name) }
	return $self->{'name'};
}


sub award {
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
