#!/usr/bin/perl -w

package DataExport::FileTagExporter;

use strict;
use utf8;

use DataFile::AlbumFile;

use Audio::FLAC::Header;
use Log::Log4perl qw(:easy);
use Sort::Naturally;
use Data::Dumper;
use File::Next;

my $tagSeparator =';';

my @tagNames=(
'ALBUM',
'AMGGENRE',
'AMGWORKTYPE',
'ARTIST',
'ARTISTSORT',
'CATNUM',
'CHOIR',
'CHOIRSORT',
'COMPOSER',
'COMPOSERSORT',
'CONDUCTOR',
'CONDUCTORSORT',
'DISC',
'DISCC',
'GENRE',
'INSTRUMENTIST',
'INSTRUMENTISTSORT',
'LABEL',
'MDATAGGED',	
'ORCHESTRA',
'ORCHESTRASORT',
'ORIGYEAR',
'PERIOD',
'RECYEAR',
'ROLENAME',
'SINGER',
'SINGERSORT',
'TITLE',
'TRACKNUMBER',
'WORK',
'YEAR');


my %instrumentistRoles = (
	
);

my %singerRoles = (

);

my %ignoreRoles = (

);

my %orchestraRoles = (

);

my %choirRoles = (

);

my %conductorRoles= (

);

sub new {
	my $class  = shift;
	my $dataExporter = {};
	my %params;
	if (@_) {
		%params = %{ shift() };
	}
	
	bless( $dataExporter, $class );

	if (%params) {
		if ( defined( $params{foo} ) ) {
			$dataExporter->foo( $params{foo} );
		}
	}
	return $dataExporter;
}


# comparison method for sorting files and guessing disc numbers from files
sub test($$) {
	my $a = $_[0]->[2];
	my $b = $_[1]->[2];
# would be useful to prevent bug with multidisc in single directory where '02-8track05.flac', is before  '1-01track01.flac', (28 before 101)
#	$a =~ s/-/_/g;
#	$b =~ s/-/_/g;
	ncmp($a, $b);
}

# comparison method that prevent problems with 1-02 considered as integer value 102 instead of two integers values 1 and 02
sub ncmpFileHashRef {
	my $a = $_[0];
	my $b = $_[1];
# would be useful to prevent bug with multidisc in single directory where '02-8track05.flac', is before  '1-01track01.flac', (28 before 101)
	$a =~ s/[-\/]/_/g;
	$b =~ s/[-\/]/_/g;
	ncmp($a, $b);	
}

# upper case all keys of a H
sub force_uc_hash {
    my $hashref = shift;
    foreach my $key (keys %{$hashref} ) {
        $hashref->{uc($key)} = $hashref->{$key};
        force_uc_hash($hashref->{uc($key)}) if ref $hashref->{$key} eq 'HASH';
        delete($hashref->{$key}) unless $key eq uc($key);
   }
   return $hashref;
}

sub export {
	my $self = shift or return (undef);

	ERROR("Stub method, must override");
	die;
}

sub guessCatalogAndOpusFromString {
	my $self = shift or return undef;
	my $string =  shift or return undef;
	my $workTag;
    while ($string =~ /\W((A|ABWV|AV|AWV|B|BC|BERI|BI|BUXWV|BV|BW|BWV|C|CT|CW|D|DF|E|ED|EG|EHWV|F|FBWV|FP|FS|FWV|G|GWWV|H|HESS|HRV|HW|HWV|IN|J|JB|JC|JSW|JW|K|KK|KV|KWV|L|LOWV|LV|LW|LWV|M|MB|MS|MWV|N|OP|P|R|RMWV|RN|RO|RC|RHV|RSWV|RV|S|SCHARWV|SEV|SMWV|SSWV|SV|SWV|SZ|T|TRV|TWV|V|VB|VR|WOO|W|WD|WK|WSF|WQ|WV|WWVZ|ZWV)( |\.){0,2}(posth( |\.){0,2})?[abcdefgh]?(\d+:)?\d+(\/?[abcdefgh]|\/\d+)?)/gi) 
    {
        #print "QSD: $1, ends at ", pos $_, "\n";
        $self->addItemToMultiItemsTagRef(\$workTag, $1);
    }
    return $workTag;
}

# insert an item in a multi item tag and return the new tag don't if item is already present
sub addItemToMultiItemsTag {
	my $self = shift or return undef;
	my $originalTag = shift;
	my $itemToAdd = shift or return undef;
	
	$itemToAdd = Tools::trim($itemToAdd);
	unless(defined($itemToAdd)) {
		return $originalTag;
	}
	# Check if tagToAdd contains separator => error
	if($itemToAdd =~ /$tagSeparator/) {
		ERROR("Can't add '$itemToAdd' item because it contains an item separator '$tagSeparator' ");
		return $originalTag;
	}

	# look for the tagToAdd in the originalTag 
	#if($originalTag =~ /[${tagSeparator}^]${itemToAdd}[${tagSeparator}\$]/) {
	if($originalTag =~ /(^|;)${itemToAdd}($|;)/) {
		ERROR("Item '$itemToAdd' already found in tag '$originalTag' ");
		return $originalTag;
	}
	return( $originalTag.(length($originalTag)==0?'':$tagSeparator).$itemToAdd)
}

my %genreAliases = (
	'Chamber' 			=> 'Musique de chambre',
	'Classical' 						=> 'Classique'
);

my %nameAliases = (
	'George Frideric Handel' 			=> 'Georg Friedrich Händel',
	'Georg Friedrich Haendel'			=> 'Georg Friedrich Händel',
	'Handel' 									=> 'Georg Friedrich Händel',
	'Haendel' 									=> 'Georg Friedrich Händel'
);

sub itemAlias {
	my $self = shift or return undef;
	my $item = shift or return(undef);
	if(exists($nameAliases{$item})) {
		return $nameAliases{$item};
	}
	
	if(exists($genreAliases{$item})) {
		return $genreAliases{$item};
	}
	
	# no aliases found, return original item
	return $item;
}

# same as upper method but takes a reference in input and returns success or failure
sub addItemToMultiItemsTagRef {
	my $self = shift or return undef;
	my $originalTagRef = shift;
	my $itemToAdd = shift or return undef;
	
	$itemToAdd = Tools::trim($itemToAdd);
	unless(defined($itemToAdd)) {
		return 0;
	}
	# Check if tagToAdd contains separator => error
	if($itemToAdd =~ /$tagSeparator/) {
		ERROR("Can't add '$itemToAdd' item because it contains an item separator '$tagSeparator' ");
		return 0;
	}
	
	$itemToAdd = $self->itemAlias($itemToAdd);
	
	# look for the tagToAdd in the originalTag 
	#if($originalTag =~ /[${tagSeparator}^]${itemToAdd}[${tagSeparator}\$]/) {
	if($$originalTagRef =~ /(^|;)${itemToAdd}($|;)/) {
		DEBUG("Item '$itemToAdd' already found in tag '$$originalTagRef' ");
		return 0;
	}
	$$originalTagRef=$$originalTagRef.(length($$originalTagRef)==0?'':$tagSeparator).$itemToAdd;
	return 1;
}

sub createSortField {
	my $self = shift or return undef;
	my $item = shift or return undef;
	if($item =~ m/,/) { # if item already contains a comma, don't change it, chances are it's already sort or unsortable
		return $item;
	}
	# Eliminate 'Sir' particle from sort field
	$item=~ s/^sir +(.*)$/$1/gi;
	$item=~ s/^(.*)[\s]+([\w]*)$/$2, $1/g;
	return $item;
}

sub multiItemTagFusion{
	my $self = shift or return undef;
	my $multiItemTag1 = shift;
	my $multiItemTag2 = shift;
	my @itemList1 = split $tagSeparator, $multiItemTag1;
	my @itemList2 = split $tagSeparator, $multiItemTag2;
	foreach my $item (@itemList2) {
		unless(grep(/${item}/,@itemList1) ) {
			push @itemList1, $item;
		}
	}
	join $tagSeparator, @itemList1;
}

sub isItemInTag {
	my $self = shift or return undef;
	my $itemToFind = shift or return undef;
	my $originalTag = shift;

	$itemToFind = Tools::trim($itemToFind);
	unless(defined($itemToFind)) {
		ERROR("isItemInTag call with an empty item");
		return 0; # null item doesn't exist, it can't be found
	}
	# Check if tagToAdd contains separator => error
	if($itemToFind =~ /$tagSeparator/) {
		ERROR("Can't find '$itemToFind' item because it contains an item separator '$tagSeparator' ");
		return 0;
	}
	if($originalTag =~ /(^|;)${itemToFind}($|;)/) {
		return 1;
	}
	return 0;
}

sub generateTags{
	my $self = shift or return undef;
	ERROR("Stub metod, must override");
	return undef;
}

sub checkMetaFlac{
	my $self = shift or return undef;
	system("metaflac", "--version");
	return $?
}


# wipe all tags except 'MDABCK-*' and 'MDATAGGED'
sub wipeMDATags{
	my $self = shift or return undef;
	my $trackTagsHashRef = shift or return undef;
	#die Dumper \$trackTagsHashRef;
	
	# for each tag
	foreach my $key (keys %{$trackTagsHashRef}) {
		# if tag isn't a backup tag
		unless($key =~ /^MDABKP-/ or $key =~ /^MDATAGGED$/ ) {
			delete($trackTagsHashRef->{$key});
		}
	}
	#$trackTagsHashRef->{MDATAGGED}=1;
}

# get a hash of tags and postfix them 'MDABCK-'
sub backupOriginalTags{
	my $self = shift or return undef;
	my $trackTagsHashRef = shift or return undef;
	#die Dumper \$trackTagsHashRef;
	
	foreach my $key (keys %{$trackTagsHashRef}) {
		$trackTagsHashRef->{'MDABKP-'.$key}=$trackTagsHashRef->{$key};
		delete($trackTagsHashRef->{$key});
	}
	$trackTagsHashRef->{MDATAGGED}=1;
}

# Exoirter can be associated with a full albumFile (multiple dataSource exporters)
sub albumFile {
	my $self = shift;
	my $albumFile = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($albumFile) {
		#if there is already an object
		if (ref($self->{-albumFile}) eq 'DataFile::AlbumFile') {
			# return It
			return $self->{-albumFile};
		}else { # create a new empty object of this type
			$self->{-albumFile}= DataFile::AlbumFile->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($albumFile) eq 'DataFile::AlbumFile') { 
		$self->{-albumFile}= $albumFile; 
	}
	elsif($albumFile){  # We only insert objects of the good type
		ERROR('Object ->-albumFile called with an unexpected parameter '.ref($albumFile).' waiting a DataFile::AlbumFile');
	}
	# Return the set object
	return $self->{-albumFile};
}

# Exporter can also be associated with a dataSource (single dataSource exporters)
sub dataSource {
	my $self = shift or return undef;
	my $dataSource = shift;

	# If there's no parameter in the input, it's a GET
	unless($dataSource) {
		#if there is already an object
		if (ref($self->{dataSource}) =~  m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/) {
			# return It
			return $self->{dataSource};
		}else { # create a new empty object of this type
			ERROR("No dataSource set!");
		}
	}

	# There's a parameter in input, it's a SET
	if (ref($dataSource) =~  m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) { 
		$self->{dataSource}= $dataSource; 
	}
	elsif($dataSource){  # We only insert objects of the good type
		ERROR('Object ->dataSource called with an unexpected parameter '.ref($dataSource).' waiting a DataFile::DataSource');
	}
	# Return the set object
	return $self->{dataSource};
}

# Verify that all guessedDiscNum and guessedTrackNum correspond to the data contained in AMGDataSource
sub checkTrackAndDiscCoherency {
	my $self = shift or return undef;
	WARN ("Stub method should be overriden");
	return 1;
}

sub readFilesFromCurrentDir {
	my $self = shift or return undef;
	
	unless(scalar(@_)!=0) {
		return $self->readFlacFilesFromCurrentDir(@_); # default is flac reader
	}
	#TODO: implement different readers and write a selector from there readFilesFromCurrentDir( type => 'flac') for example
}

# Read flac files and check their respective TRACKNUM and DISCID (in tags or guessed by file/dir structure)
# Dies if it founds any error to prevent destroy of original TRACKNUM tags
# full foundFilesArray and filesInDirHash
sub readFlacFilesFromCurrentDir {
	my $self = shift or return undef;

	#my %discFiles=%{$_};
	#my $iter = File::Next::files( { sort_files => 1, file_filter => sub { /\.(?:flac|)$/ } }, '.');
	my $iter = File::Next::files( { sort_files => \&test, file_filter => sub { /\.(?:flac|)$/ } }, '.');
	
	# for each flac file found in this folder/subfolders, collect information 
	while ( defined ( my $filePath = $iter->() ) ) {
		#print $file."\n";
		unless( -e $filePath and -r $filePath and -f $filePath) {
			ERROR("Unable to find/open file: $filePath");
			die;
		}
		# Read the flac headers (info and tags)
		my $flac = Audio::FLAC::Header->new("$filePath");
		
		# if flac is unreadable
		unless ($flac) { ERROR("Error while reading flac header for $filePath"); die;};			
		# create a hash representing the file and holding its path+filename, flacinfo and flactags
		#push(@{$self->foundFilesArray}, { filePath => $filePath, flacInfo =>  $flac->info(), tags =>  force_uc_hash($flac->tags()) });
		$self->addFoundFile( { filePath => $filePath, flacInfo =>  $flac->info(), tags =>  force_uc_hash($flac->tags()) });
	}

	# Validate files and find number of discs:
	#my %dirs;
	foreach my $file (@{$self->foundFilesArray()})  {
		my $filePath = $file->{filePath};
		# if we have a valid filename
		# get the directory where the file is
		my ($volume,$directories,$filename) = File::Spec->splitpath( $filePath );
		# and increment a counter in the forme of a hash where keys are directory  $dirs{Disc1}, $dirs{Disc2}
		push @{$self->{filesInDirHash}->{File::Spec->catpath( $volume, $directories, '')}}, $file;

		DEBUG("Valid file: $filePath\n");
	}	
	# %dirs contains a tree structure in the form disc->file
# Handle multi-discs in single folder (ie. in the form):
#       "disc1 - track1.flac"  "disc1 - track2.flac" "disc2 - track1.flac"
#  or  "1-1 toto.flac" "1-2 toto.flac" "2-1 toto.flac" "2-2 toto.flac"
# a function that detecting repeating patterns in the files / path should be written
# handling such weirdness as [1-01 1-02 1-10 1-12] or files like [101 102 103 ... 110 111 201 202 203 ] or ""disc1 01""
#	$VAR1 = {
#          '' => [
#                  '1-1track01.flac',
#                  '1-2track02.flac',
#                  '1-9track03.flac',
#                  '1-10track04.flac',
#                  '02-09track05.flac',
#                  '2-10track06.flac',
#                  'track07.flac',
#                  'track08.flac',
#                  'track09.flac',
#                  'track10.flac',
#                  'track11.flac',
#                  'track12.flac'
#                ],
#          'cd 1\\' => [
#                        'cd 1\\track01.flac',
#                        'cd 1\\track02.flac',
#                        'cd 1\\track03.flac',
#                        'cd 1\\track04.flac',
#                        'cd 1\\track05.flac',
#                        'cd 1\\track06.flac',
#                        'cd 1\\track07.flac',
#                        'cd 1\\track08.flac',
#                        'cd 1\\track09.flac',
#                        'cd 1\\track10.flac',
#                        'cd 1\\track11.flac',
#                        'cd 1\\track12.flac'
#                      ],
#          'cd 02\\' => [
#                         'cd 02\\track1.flac',
#                         'cd 02\\track2.flac',
#                         'cd 02\\track3.flac',
#                         'cd 02\\track04.flac',
#                         'cd 02\\track05.flac',
#                         'cd 02\\track06.flac',
#                         'cd 02\\track07.flac',
#                         'cd 02\\track08.flac',
#                         'cd 02\\track09.flac',
#                         'cd 02\\track10.flac',
#                         'cd 02\\track11.flac',
#                         'cd 02\\track12.flac'
#                       ]
#        };
	# YEAR

	my $wellGuessTrackNumCount=0;
	my $badlyGuessTrackNumCount=0;
	my $guessedDiscNum = 0;
	foreach my $diskFolder (nsort(keys(%{$self->{filesInDirHash}}))) {
		$guessedDiscNum++;
		my $guessedTrackNum = 0;
		foreach my $file (@{$self->{filesInDirHash}{$diskFolder}}) {
			$guessedTrackNum++;
			$file->{guessedTrackNum} = $guessedTrackNum;
			$file->{guessedDiscNum} = $guessedDiscNum;
			if(defined($file->{tags})) {
				# try to alias track, tracknum to tracknumber this shouldn't be necessary as both squeezecenter and foobar use TRACKNUMBER 
				unless( defined($file->{tags}->{TRACKNUMBER}) ) {
					if( defined($file->{tags}->{TRACK}) and ($file->{tags}->{TRACK} =~ /^[\d\-\/]+$/) ) {
						$file->{tags}->{TRACKNUMBER} = $file->{tags}->{TRACK}
					} elsif( defined($file->{tags}->{TRACKNUM}) and ($file->{tags}->{TRACKNUM} =~ /^[\d\-\/]+$/) ) {
						$file->{tags}->{TRACKNUMBER} = $file->{tags}->{TRACKNUM};
					}
				}	
				if(defined($file->{tags}->{TRACKNUMBER})) {
					# must transform any TRACKNUMBER of the form 02-14 ou 02/14 in 2
					#$flacTrackNum =~ s/^0*(\d*).*/$1/g;
					#if($guessedTrackNum == $file->{tags}->{TRACKNUMBER} ) {
						
					# tracknumber tag must be of the form  "3" or "03" or " 03" or all of those with "/04" or "-05"	
					if($file->{tags}->{TRACKNUMBER} =~ m/^\s*0*${guessedTrackNum}(\D+|$).*/ ) {
						$wellGuessTrackNumCount++;
					}else {
						$badlyGuessTrackNumCount++;
					}
				}
			}
		}
	}
	#       some               TRACKNUMBER tag were found in flac files                                        
	if( ($wellGuessTrackNumCount  + $badlyGuessTrackNumCount != 0) and 
	#                              But not in all files"
				($wellGuessTrackNumCount + $badlyGuessTrackNumCount !=  scalar(@{$self->foundFilesArray})) ) { 
		ERROR("TRACKNUMBER tag not present in all files, erase or complete TRACKNUMBER tags and make sure flac filename order or TRACKNUMBER tags are set according to the album track order");
		INFO('Total files found: '.scalar(@{$self->foundFilesArray})." well guessed: $wellGuessTrackNumCount versus wrong guessed: $badlyGuessTrackNumCount");
		die;
	} # if no TRACKNUMBER were found in flac files
	elsif($wellGuessTrackNumCount  + $badlyGuessTrackNumCount == 0) {
		WARN("No TRACKNUMBER tags, trusting filename order!");
		#TODO: put a --force-filename-ordering in commandline
	}
	# if some track numbers are not well guessed, we need to check the concistency of TRACKNUMBERS tags and reorder %dirs hash of arrays
	elsif( $wellGuessTrackNumCount != scalar(@{$self->foundFilesArray})) {
		
		# First, force reordering of the array of tracks contained under each disk directory
		foreach my $diskFolder (nsort(keys(%{$self->{filesInDirHash}}))) { 
			# according to the flacTag TRACKNUMBER (naturally sorted because of the 3/27 that could be mixed between 02 and 04)
			@{$self->{filesInDirHash}{$diskFolder}} = sort { &ncmpFileHashRef($a->{tags}->{TRACKNUMBER}, $b->{tags}->{TRACKNUMBER}); } @{$self->{filesInDirHash}->{$diskFolder}};
			
			# for each reordered directory
			for my $i (1..scalar(@{$self->{filesInDirHash}{$diskFolder}})) {
				my $flacTrackNum = $self->{filesInDirHash}{$diskFolder}->[$i-1]->{tags}->{TRACKNUMBER};
				# must transform any TRACKNUMBER of the form 02-14 ou 02/14 in 2
				$flacTrackNum =~ s/^\s*0*(\d*).*/$1/g;
				# if this extracted tracknumber doesn't follow a strict incrementing pattern 1-2-3-4-5...
				unless($flacTrackNum == $i) {
					ERROR("TRACKNUMBER tag contained in file".$self->{filesInDirHash}{$diskFolder}->[$i-1]->{filePath}." breaks consecutive integer numbering of file per directory");
					ERROR("Waiting for TRACKNUMBER=$i but found TRACKNUMBER=$flacTrackNum");
					die;
				}
				$self->{filesInDirHash}{$diskFolder}->[$i-1]->{guessedTrackNum}=$i;
			}
		}
	}
	
	# either we had no TRACKNUMBER tags at all 
	# or a full well formed TRACKNUMBER set
	# in either case, $file->{guessedTrackNum} contains what we think is the correct track number
	# and, $file->{guessedDiscNum} contains what we think is the correct disc  number
	#die Dumper $self->foundFilesArray->[1];
#	foreach(@{$self->foundFilesArray}) {
#		print $_->{guessedDiscNum}." - ".$_->{guessedTrackNum}." ".$_->{filePath}."\n";
#	}	
}

sub writeTags {
	my $self = shift or return undef;
	return $self->writeFlacTags(@_);
}

sub writeFlacTags {
	my $self = shift or return undef;
	if($self->checkMetaFlac() != 0) {	
		ERROR("Metaflac not found or not working");
		die;
	}

	foreach my $track (@{$self->foundFilesArray()}) {		
		# verify that metaflac can read the file
		if(system("metaflac", "--show-md5sum", $track->{filePath}) != 0) {
			ERROR("Metaflac cannot read md5sum ");
			die  Dumper $track->{filePath};
		}
		
		# Create the temporary file holding tags for the metaflac to import
		my $TAGFILE;
# "metaflac", "--import-tags-from=- ", $track->{filePath}
		open($TAGFILE, '>', "mda-tag.$$.tmp") or die "Can't open metaflac: $!";
		foreach my $tagName (keys %{$track->{tags}}) {
			unless(utf8::is_utf8($track->{tags}->{$tagName})) {
				utf8::decode($track->{tags}->{$tagName});
			}
			print($TAGFILE "$tagName=".$track->{tags}->{$tagName}."\n");
		}
		close($TAGFILE) or die "Can't close  mda-tag.$$.tmp: $!";
		
		# call metaflac to do the real tagging, wipe previous tags and read from temporary file
		system("metaflac", "--remove-all-tags","--import-tags-from=mda-tag.$$.tmp", $track->{filePath});
		
		# delete temporary file
		unlink("mda-tag.$$.tmp")  or die "Can't unlink mda-tag.$$.tmp: $!";
	}
}

sub backupTags {
	my $self = shift or return undef;
	
	foreach my $track (@{$self->foundFilesArray()}) {
		# File already have been MDA tagged: wipe all non backup tags
		if(defined($track->{tags}->{MDATAGGED})) {
			$self->wipeMDATags($track->{tags});
		} else { # File have never been tagged with MDA, backup original tags
			$self->backupOriginalTags($track->{tags});
		}
	}
}

sub addFoundFile {
	my $self = shift;
	my $foundFile = shift; 

	# if param is not an doesn't-> return
	# if ( ref($foundFile) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
	unless ( ref($foundFile) ) {
		ERROR ("Object isn't a reference");
		return (undef );
	}
	
	#  foundFile must have these properties filled for coherency check
	unless( defined($foundFile->{filePath})  ) { 
		ERROR("Missing filePath  in FoundFile"); 
		return; 
	}

	push @{$self->{foundFilesArray}}, $foundFile;
}

# File objects looks like:
# {
#   'tags' => {
#                 'TITLE' => 'Music for the Tempest - \'O bid your faithful Ariel fly\'',
#                 'ALBUM' => 'Music for the Tempest ; Overture to the Duenna ;  Three Cantatas - The Parley of Instruments  & Choir (Paul Nicholson)',
#                 'TRACKNUMBER' => '02',
#                 'GENRE' => 'Classical',
#                 'DATE' => '1994',
#                 'ARTIST' => 'Linley, Thomas the Younger',
#                 'VENDOR' => 'reference libFLAC 1.1.4 20070213'
#               },
#   'guessedDiscNum' => 1,
#   'guessedTrackNum' => 2,
#   'flacInfo' => {
#                 'MD5CHECKSUM' => 'e9fde21842435bec3a82768c66803a17',
#                 'NUMCHANNELS' => 2,
#                 'SAMPLERATE' => 44100,
#                 'MINIMUMBLOCKSIZE' => 4096,
#                 'TOTALSAMPLES' => 12673164,
#                 'BITSPERSAMPLE' => 6,
#                 'MINIMUMFRAMESIZE' => 9695,
#                 'MAXIMUMBLOCKSIZE' => 268435456
#               },
#   'filePath' => '02.flac'
# };
# simple array of found "files" objects in filepath/filename order
sub foundFilesArray {
	my $self = shift;
	my $foundFilesArray   = shift;
	if ($foundFilesArray) { $self->{foundFilesArray} = $foundFilesArray; }
	return $self->{foundFilesArray};
}

# hash of array of reference to flac files 
# $filesInDirHash{dirName}
# with dirName supposed to be a disc. each entry contains a well ordered fileObjectsRef array
sub filesInDirHash {
	my $self = shift;
	my $filesInDirHash   = shift;
	if ($filesInDirHash) { $self->{filesInDirHash} = $filesInDirHash; }
	return $self->{filesInDirHash};
}

END { }    # module clean-up code here (global destructor)
1;