#!/usr/bin/perl -w
package DataFile::Picture;

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
	my $picture = {};
	bless( $picture, $class );
	if(%params) {
		if (defined($params{id}) ) { 
			$picture->id($params{id}) ;
		}
		if (defined($params{url}) ) { 
			$picture->url($params{url}) ;
		}
		if (defined($params{type}) ) { 
			$picture->type($params{type}) ;
		}		
		if ( defined( $params{rawData} ) ) {
			$picture->rawData( $params{rawData} );
		}
	}
	return $picture;
}

sub type {
	my $self = shift;
	my $type   = shift;
	if ($type) { $self->{'type'} = Tools::trim($type) }
	return $self->{'type'};
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

sub thumbnail {
	my $self = shift;
	my $thumbnail = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($thumbnail) {
		#if there is already an object
		if (ref($self->{thumbnail}) eq 'DataFile::Picture') {
			# return It
			return $self->{thumbnail};
		}else { # create a new empty object of this type
			$self->{thumbnail}= DataFile::Picture->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($thumbnail) eq 'DataFile::Picture') { 
		$self->{thumbnail}= $thumbnail; 
	}
	elsif($thumbnail){  # We only insert objects of the good type
		ERROR('Object ->thumbnail called with an unexpected parameter '.ref($thumbnail).' waiting a DataFile::Picture');
	}
	# Return the set object
	return $self->{thumbnail};
}

sub width {
	my $self = shift;
	my $width   = shift;
	if ($width) { $self->{width} = Tools::trim($width) }
	return $self->{width};
}

sub height {
	my $self = shift;
	my $height   = shift;
	if ($height) { $self->{height} = Tools::trim($height) }
	return $self->{height};
}

sub picture {
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
