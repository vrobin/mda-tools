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

	# new MDA file creation asked
	createNewMdaFile => undef,

	# MDA file saving asked
	saveMdaFile=> undef,
	
	# the mdaFile has been saved
	mdaFileSaved => undef,
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
	my $self = shift;	# XXX: ignore calling class/object
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
	    -icon => "warning", -title => "MDA - save changes");
	    
	    # the user cancelled the directory change action
	    if($returnvalue =~ /cancel/) {
		    # false is returned to notify the directory change cancellation 
	    	return 0;
	    }
	    if($returnvalue =~ /yes/) {
			fireEvent('saveMdaFile');
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
				GuiOrchestrator->currentMdaFile($fileInDirFullPath);

				# create a new MDA DataFile
				GuiOrchestrator->albumFile( DataFile::AlbumFile->new() );

#TODO: add an eval to handle malformed xml file	
				# load this new DataFile object with the found mda.xml file
				$albumFile->deserialize(GuiOrchestrator->currentMdaFile());
				print(Dumper($albumFile));
				# MDA File has been loaded, so it hasn't changed yet 
				$fileChanged = 0;

				fireEvent('mdaFileLoaded', GuiOrchestrator->currentMdaFile(), GuiOrchestrator->albumFile());
			}
		}else {
			WARN ("Directory entry '$fileInDirFullPath' isn't a directory nor a normal file\n");
		}
	}
	
	# if there was no .mda.xml file found, toggle the noMdaFileInDirectory event
	if(not defined GuiOrchestrator->albumFile() ) {
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

# the gui orchestrator is asked to create a new file
sub createNewMdaFile {
	
	# there is an existing file, ask before overwrite it
	if(defined($albumFile)) {
		# message box display
		my $returnvalue = Tkx::tk___messageBox(-type => "yesno",
	    -message => "You will lose all data for this album, do you really want to create a new file?",
	    -default => "no",
	    -icon => "warning", -title => "MDA - create new file");
	    

	    if($returnvalue =~ /no/) {
			# user choose "don't create new file"
			# action is cancelled
			return 0;
	    }
	    if($returnvalue =~ /yes/) {
		# ignored, the work for creation is done after the if block
	    }
	}

	# Create blank album file
	GuiOrchestrator->albumFile(DataFile::AlbumFile->new());
	
	# the default name must be used as the filename
	GuiOrchestrator->currentMdaFile(File::Spec->catfile($currentDir, '.mda.xml'));

	# creating a new file is similar to loading (like loading a blank file)
	fireEvent('mdaFileLoaded', GuiOrchestrator->currentMdaFile(), GuiOrchestrator->albumFile());

	# as the new file isn't already saved, we must mark it as 'changed' (file must be saved)
	fireEvent('mdaFileChanged');
	print Dumper(GuiOrchestrator->albumFile());
	return 1;
}

sub saveMdaFile {
	
	# if currentDir is invalid
	if(not defined($currentDir) or $currentDir eq '' ) 
	{	# log and return false
		ERROR("unable to save mda file without currentDir set");
		return 0;
	}
	
	# if the mdaFile is empty or invalid, create default file name
	if(not defined($currentMdaFile) or $currentMdaFile eq '' ) 
	{
		GuiOrchestrator->currentMdaFile(File::Spec->catfile($currentDir, '.mda.xml'));
	}
	GuiOrchestrator->albumFile()->serialize(GuiOrchestrator->currentMdaFile());
	fireEvent('mdaFileSaved'); 
}

registerEventListener("createNewMdaFile", sub {return createNewMdaFile(@_); } );
registerEventListener("saveMdaFile", sub {return saveMdaFile(@_); } );
registerEventListener("beforeDirectoryChange", sub {return isChangeDirectoryAllowed(@_); } );
registerEventListener("afterDirectoryChanged", sub {return directoryChanged(@_); } );
registerEventListener("mdaFileChanged", sub { $fileChanged=1; return 1; } );
registerEventListener("mdaFileSaved", sub { $fileChanged=0; return 1; } );
1;