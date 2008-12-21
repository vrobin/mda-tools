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
use DataFile::AlbumFile;

our $currentDir = '';
our $currentMdaFile = '';
our $albumFile = undef;


our $fileChanged = 0;

our $eventListeners = {
	# this event is triggered by explorer tree when before changing
	# directory, if 'false' is returned, directory change is cancelled
	beforeDirectoryChange => undef,

	# afterDirectoryChanged + new directory name
	afterDirectoryChanged => undef,
	
	# mdaFileLoaded + complete file path + albumFile reference 
	mdaFileLoaded => undef,
	
	# noMdaFileInFolder is triggered when a new directory is selected that
	# doesn't contain mda file
	noMdaFileInFolder => undef,
	
	# the mdaFile has changed, save can be done
	mdaFileChanged => undef,
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

sub albumFile {
	
	if(@_) 
	{
		$albumFile = shift	
	}
	
	return $albumFile;
} 

# This method is called to check if the directory changing 
# is allowed, if not, false is returned so no directory change will be made
sub isChangeDirectoryAllowed {
	
	# the .mda.xml file had been changed, we must ask the user before
	# loosing changes
	if($fileChanged == 1) {
		
		# message box display
		my $returnvalue = Tkx::tk___messageBox(-type => "yesnocancel",
	    -message => "Save metadata changes ?",
	    -default => "cancel",
	    -icon => "warning", -title => "MDA");
	    
	    # the user cancelled the directory change action
	    if($returnvalue =~ /cancel/) {
		    # false is returned to notify the directory change cancellation 
	    	return 0;
	    }
	    if($returnvalue =~ /yes/) {
# TODO: save MDA File
			albumFile()->serialize(currentMdaFile());
			# file is saved, directory change is allowed with 'return 1' below
	    }
	    if($returnvalue =~ /no/) {
			# user choose "don't save changes"
			# method will return true and directory change will be allowed
	    }
	}
	return 1;
}

# This sub is called when tree widget changed the active directory
# orchestrator load mdaFile if present, and set the property of current
# directory. This sub must be the first callback registered for the
# listener
sub directoryChanged {
	my $newDirectory = shift;
	my $dirFD;

	DEBUG("New directory: $newDirectory\n");
	
	# Save current directory
	GuiOrchestrator->currentDir($newDirectory);
	
	# the directory has changed, undefine mdaFile related variables
	undef($currentMdaFile);
	undef($albumFile);
	$fileChanged=0;

	opendir($dirFD, $newDirectory) || ( ERROR("Cannot open directory") and return );
	
	# Examine each entry in this folder to know how to display it
	foreach my $fileInDir (File::Spec->no_upwards(readdir($dirFD))) {

		my $fileInDirFullPath=File::Spec->catfile($newDirectory, $fileInDir);

		# items has subFolders, so make it expandable
		if(-d $fileInDirFullPath) {
			# Do Nothing when element is a subdir
		}elsif(-f $fileInDirFullPath) {
			DEBUG ("Found file '$fileInDirFullPath'\n");
			
			# if there's a mda.xml file in the new directory
			if($fileInDir =~ /^\.?mda.xml$/) {
				DEBUG("$newDirectory contain '$fileInDir' MDA XML file");
				
				# set the fullpath of the mda file
				currentMdaFile($fileInDirFullPath);

				# create a new MDA DataFile
				albumFile( DataFile::AlbumFile->new() );

				# load this new DataFile object with the found mda.xml file
				$albumFile->deserialize(currentMdaFile());
				print(Dumper($albumFile));
				# MDA File has been loaded, so it hasn't changed yet 
				$fileChanged = 0;
				
				fireEvent('mdaFileLoaded', currentMdaFile(), albumFile());
			}
		}else {
			WARN ("Directory entry '$fileInDirFullPath' isn't a directory nor a normal file\n");
		}
	}
	
	# if there was no .mda.xml file found, toggle the noMdaFileInDirectory event
	if(not defined albumFile() ) {
		fireEvent('noMdaFileInFolder');
	}
	
}

# fire an event and return a "and" of all boolean returned
sub fireBooleanEvent {
	my $event = shift;
	my $result = 1;
	foreach my $callback (@{$eventListeners->{$event}}) {
		#die Dumper($callback);
		$result = $callback->(@_) && $result;		
	}
	return $result;
}

sub fireEvent {
	fireBooleanEvent(@_);
	return undef;
}

registerEventListener("beforeDirectoryChange", sub {return isChangeDirectoryAllowed(@_); } );
registerEventListener("afterDirectoryChanged", sub {return directoryChanged(@_); } );
registerEventListener("mdaFileChanged", sub { $fileChanged=1; return 1; } );

1;