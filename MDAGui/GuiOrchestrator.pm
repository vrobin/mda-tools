#!/usr/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

package GuiOrchestrator;


use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);

use Carp;
use English;
use utf8;
use Data::Dumper;
use Log::Log4perl qw(:easy);

our $currentDir = undef;
our $currentMdaFile =  undef;

#my $albumFile = DataFile::AlbumFile->new();

our $fileChanged = 0;

our $eventListeners = {
	beforeDirectoryChange => undef,
	afterDirectoryChanged => undef,	
};


# This method register event name with function method
# this is used for glueing components and widgets together
sub registerEventListener {
	my $event = shift;
	my $function = shift;
	
	if ( ref $function ne 'CODE' ) {
		ERROR( 'registerEventListener called without a code reference' );
		return;
	}
	push(@{$eventListeners->{$event}}, $function);
}

sub currentMdaFile {
	my $self = shift;	# XXX: ignore calling class/object
	
	if(@_) 
	{
		$currentMdaFile = shift	
	}
	
	return $currentMdaFile;
} 

sub currentDir {
	my $self = shift;	# XXX: ignore calling class/object
	
	if(@_) 
	{
		$currentDir = shift	
	}
	
	return $currentDir;
} 

# This method is called to check if the directory changing 
# is allowed, if not, false is returned so no directory change will be made
sub isChangeDirectoryAllowed {
	if($fileChanged == 1) {
		my $returnvalue = Tkx::tk___messageBox(-type => "yesnocancel",
	    -message => "Save metadata changes ?",
	    -default => "cancel",
	    -icon => "warning", -title => "MDA");
	    
	    if($returnvalue =~ /no/) {
	    	return 1;
	    }
	    if($returnvalue =~ /cancel/) {
	    	return 0;
	    }
	    if($returnvalue =~ /yes/) {
# TODO: save MDA File
	    	return 1;
	    }
	}
	return 1;
}
sub directoryChanged {
	my $newDirectory = shift;
	print("New directory: $newDirectory\n");
# TODO: Handle new directory hand associated properties
}

# fire an event and return a "and" of all boolean returned
sub fireBooleanEvent {
	my $event = shift;
	my $result = 1;
	foreach my $callback (@{$eventListeners->{$event}}) {
		#die Dumper($callback);
		$result = $result && $callback->(@_);		
	}
	return $result;
}

sub fireEvent {
	fireBooleanEvent(@_);
	return undef;
}

registerEventListener("beforeDirectoryChange", sub {return isChangeDirectoryAllowed(@_); } );
registerEventListener("afterDirectoryChanged", sub {return directoryChanged(@_); } );


1;