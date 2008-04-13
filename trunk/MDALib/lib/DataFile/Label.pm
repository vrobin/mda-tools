#!/usr/bin/perl -w
package DataFile::Label;

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
	my $label = {};
	bless( $label, $class );
	if(%params) {
		if (defined($params{id}) ) { 
			$label->seconds($params{id}) ;
		}
		if ( defined( $params{rawData} ) ) {
			$label->rawData( $params{rawData} );
		}
		if ( defined( $params{name} ) ) {
			$label->name( $params{name} );
		}
	}
	return $label;
}

sub id {
	my $self = shift;
	my $id   = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
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

sub name {
	my $self = shift;
	my $name = shift;
	if ($name) { $self->{name} = Tools::trim($name);}
	return $self->{name};
}

sub label {
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
