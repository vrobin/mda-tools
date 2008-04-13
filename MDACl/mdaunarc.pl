#!/usr/bin/perl -w
#-CSD

use strict;
use utf8;

#use DataFile::AlbumFile;

use Encode;
use Data::Dumper;
use File::Next;
use File::Find;
use File::Spec;
use Cwd;

#use open ':utf8';
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# unrar
my $unrarCmd = "c:\\Progra~1\\7-Zip\\7z x  -y";
my $unzipCmd = $unrarCmd;
my $zipCmd = "c:\\Progra~1\\7-Zip\\7z a -y -tzip";
my $unapeCmd = "c:\\progra~1\\monkeyaudio\\mac";
my $path='.';
my @foundFiles;
my $origDir = cwd();
my $windows;
my $archiveType;
my $filename;
my $longFilename;
my $dirname;

#my $pouet='12345678';
#my @prout = (1,2,3);
#print($#prout);
#die;

if ($^O =~ /^m?s?win/i) {
	$windows = 1;
}


# try to find one archive
my $iter = File::Next::files( { sort_files => 1, file_filter => sub { /\.(?:rar|zip)$/i } }, $path );

while ( defined ( my $file = $iter->() ) ) {
#	print("long: ",$file,"\n");
	push(@foundFiles, $file);
}

# and only one archive as I don't want to do all archives at once
unless ( scalar(@foundFiles)==1 ) {
	print("Program is designed to find one and only one archive (zip or rar) in current directory (found ".  scalar(@foundFiles)." archives)\n");
	die;
}


# check archive readability
$filename = $foundFiles[0];
unless( -f $filename and -r $filename) {
	print("Sorry, found file '$filename' is not readable or not a standard file\n");
	die;
}


# Creating a directory with the name of the archive without the extension 
if($windows) {
	$longFilename =Win32::GetLongPathName($filename);
	unless($longFilename =~ /(.*)\.(?:rar|zip)$/i ) {
		print("Error while generating directory name from archive name $longFilename'\n");
		die;
	}
	$dirname = $1; 
	utf8::decode($dirname);
	Win32::CreateDirectory($dirname);
	print("Created win32 directory for $dirname");
	unless($^E eq '') {
		print("Error creating directory $dirname : $^E \n");
		die;
	}
}else {
	$longFilename = $filename;
	unless($longFilename =~ /(.*)\.(?:rar|zip)$/i ) {
		print("Error while generating directory name from archive name $longFilename'\n");
		die;
	}
	$dirname = $1;
	mkdir($1);		
	print("Created directory for $1");
}

# set newly created directory as current dir
if($windows) {
	Win32::SetCwd($dirname);
	unless($^E eq '') {
		print("Error creating directory $dirname : $^E \n");
		die;
	}
}else {
	chdir $dirname or die "unable to chdir $dirname ($?)";
}

# set unarchive commande basic
my $unarcCmd;
if($longFilename =~ /(.*)\.(?:zip)$/i ) {
	$archiveType = 'zip';
	$unarcCmd=$unzipCmd;
}elsif($longFilename =~ /(.*)\.(?:rar)$/i ) {
	$archiveType= 'rar';
	$unarcCmd=$unrarCmd;
}


#push @args, ("$filename", "-o$dirname") ;
#utf8::decode($filename);

# generate commande line, 
my @args = split(' ', $unarcCmd);
push @args, File::Spec->catfile('..',$filename);
# execute the command
system(@args) == 0 or die "system @args failed: $?";


# Move  images to "covers" dir
mkdir('Covers') or print("Error during 'Covers' directory creation (maybe dir already exists)");

$iter = File::Next::files( { sort_files => 1, file_filter => sub { /\.(?:png|bmp|jpg|gif|pdf)$/i } }, $path );
while ( defined ( my $file = $iter->() ) ) {
#	print("long: ",$file,"\n");
	my ($drive, $path, $filename) = File::Spec->splitpath ($file);
	unless($file eq  File::Spec->catfile('Covers',$filename) ) {
		rename $file,  File::Spec->catfile('Covers',$filename);
	}
}

# Move  orig.zip saved files to  to "orig" dir
mkdir('ORIG') or print("Error during 'Covers' directory creation (maybe dir already exists)");

# Archive everything that isn't a flac/wav/ape/flc/mpc/mp3/ogg/m4a/cue in orig.zip
$iter = File::Next::files( { sort_files => 1, file_filter => sub { $_ !~ /\.(?:flac|wav|ape|flc|mpc|mp3|ogg|m4a|cue|aac|gif|png|bmp|jpg)$/i and $File::Next::dir !~ /^ORIG/} }, $path );
while ( defined ( my $file = $iter->() ) ) {
	print("long: ",$file,"\n");
	#my ($drive, $path, $filename) = File::Spec->splitpath ($file);
	#rename $file,  File::Spec->catfile('Covers',$filename);

	# generate commande line, 
	@args = split(' ', $zipCmd);
	push @args, ('orig.zip', $file);
	# execute the command
	system(@args) == 0 or die "system @args failed: $?";	
	
	# move this archived file in orig folder for better understanding of what happened
	my ($drive, $path, $filename) = File::Spec->splitpath ($file);
	rename $file,  File::Spec->catfile('ORIG',$filename);
	print("XXXX: rename $file, ". File::Spec->catfile('ORIG',$filename) ."\n");
}

# Create null "archive" named as the original archive.. for memory
if($windows) {
	Win32::CreateFile($longFilename);
	print("Created win32 file for $longFilename");
	unless($^E eq '') {
		print("Error creating empty archive $longFilename : $^E \n");
		die;
	}
}else {
	open(FH, ">", $longFilename) or die("Error creating empty archive $longFilename");
	close(FH) or  die("Error closing empty archive $longFilename");
}

# generate commande line to add the fake archive name to the archive, 
@args = split(' ', $zipCmd);

#push @args, ('orig.zip', "*.$archiveType");

#add the fake archive to orig.zip and remove this fake archive
if($windows) { # must use short name for argument passed to archiver
	push @args, ('orig.zip', Win32::GetANSIPathName($longFilename));
	system(@args) == 0 or die "system @args failed: $?";
	unlink(Win32::GetANSIPathName($longFilename)) or die("Error while deleting file $longFilename");	

}else{
	push @args, ('orig.zip', $longFilename);
	system(@args) == 0 or die "system @args failed: $?";	
	unlink($longFilename) or die("Error while deleting file $longFilename");
}

# Uncompress every ape files found in the subtree
$iter = File::Next::files( { sort_files => 1, file_filter => sub { $_ =~ /\.(?:ape)$/i and $File::Next::dir !~ /^ORIG/}  }, '.' );
while ( defined ( my $file = $iter->() ) ) {
my $outFile = $file;
$outFile =~ s/\.(?:ape)$/\.wav/g;

if ( -e $outFile) {
	print("Can't decompress $file, output file $outFile already exists!\n");
	die;
}

 # execute the command to uncompress ape files
@args = split(' ', $unapeCmd);
push @args, ($file, $outFile, '-d' );
print(join ' ' , @args );
system(@args) == 0 or die "system @args failed: $?";
rename $file,  File::Spec->catfile('ORIG',$file);
print("XXXX: rename $file, ". File::Spec->catfile('ORIG',$file) ."\n");
}

chdir $origDir;


#die(utf8::is_utf8($toto));
#	utf8::encode($toto);
#	encode("unicode", $toto);
#foreach(@foundFiles) {
#	my $printFileName = $_;	
#	if( -f $_ and -r $_) {
#		if ($^O =~ /^m?s?win/i) {
#			#$detectedOS = 'win';
#			$printFileName =Win32::GetLongPathName($_);
#			Win32::CreateDirectory($printFileName.".3");
#			unless($^E eq '') {
#				print("Error creating directory $printFileName : $^E \n");
#				die;
#			}
#		}else {
#			mkdir($printFileName."-test");		
#		}
#		print("readable $printFileName\n");
#		#utf8::decode($printFileName);
#		
#	}else {
#		print("not readable $printFileName\n");
#	}
#}

#my $some_dir='.';
##binmode( DIR, ':utf8');
#opendir(DIR, $some_dir) || die "can't opendir $some_dir: $!";
##my @file = map { decode("utf8", $_) } readdir(DIR);
##print join "\n", @file; 
#my @files = readdir(DIR);
#foreach (@files) {
#	print "abs:  ", File::Spec->rel2abs( $_ ), "\n";
#	my $toto =Win32::GetLongPathName($_);
#	print("long: ",$toto,"\n");
#}
##print join "\n", readdir(DIR); 
#closedir DIR;
#print("\nàéîôù");
#if( -r $foundFiles[0] and -r $foundFiles[0]) {
#	print("readable\n");
#}else {
#	print("not readable\n");
#}