#!/usr/bin/perl -w
package DataFile::Note;

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
	my $note = {};
	bless( $note, $class );
	if(%params) {
		if (defined($params{type}) ) { 
			$note->type($params{type}) ;
		}
		if (defined($params{author}) ) { 
			$note->author($params{author}) ;
		}
		if ( defined( $params{rawData} ) ) {
			$note->rawData( $params{rawData} );
		}
		if ( defined( $params{text} ) ) {
			$note->text( $params{text} );
		}
	}
	return $note;
}

sub type {
	my $self = shift;
	my $type   = shift;
	if ($type) { $self->{'type'} = Tools::trim($type) }
	return $self->{'type'};
}

sub author {
	my $self = shift;
	my $author   = shift;
	if ($author) { $self->{'author'} = Tools::trim($author) }
	return $self->{'author'};
}


sub note {
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

sub text {
	my $self    = shift;
	my $text = shift;
	if ($text) {
# old tweak to force rawData not to be an attribute, but content text
#		$self->{text}{forceText} = 'true';
		$self->{text}{content} = Tools::trim($text);
	}
	return $self->{text}{content};
}


END { }    # module clean-up code here (global destructor)
1;
