#!/usr/bin/perl -w
package DataFile::Part;

use strict;
use Data::Dumper;
use utf8;
use Tools;
use Log::Log4perl qw(:easy);

sub new {
	my $class  = shift;
	my $part = {};
	my %params;
	if (@_) {
		%params = %{ shift() };
	}
	
	bless( $part, $class );
	if (%params) {
		if ( defined( $params{id} ) ) {
			$part->id( $params{id} );
		}
		if ( defined( $params{index} ) ) {
			$part->index( $params{index} );
		}		
		if ( defined( $params{name} ) ) {
			$part->name( $params{name} );
		}
		if ( defined( $params{value} ) ) {
			$part->value( $params{value} );
		}
		if ( defined( $params{url} ) ) {
			$part->url( $params{url} );
		}
		if ( defined( $params{rawData} ) ) {
			$part->rawData( $params{rawData} );
		}
	}
	return $part;
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

sub name {
	my $self = shift;
	my $name   = shift;
	if ($name) { $self->{name} = Tools::trim($name) }
	return $self->{name};
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

sub index {
	my $self = shift;
	my $index   = shift;
	if ($index) { $self->{index} = Tools::trim($index) }
	return $self->{index};
}

sub id {
	my $self = shift;
	my $id   = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
}

END { }    # module clean-up code here (global destructor)
1;
