#!/usr/bin/perl -w

package DataExport::BasicMultiDS2Flac;
use base qw(DataExport::FileTagExporter);

use strict;
use utf8;

use DataFile::AlbumFile;
use DataExport::MY2Flac;
use DataExport::AMGClassical2Flac;

use Audio::FLAC::Header;
use Log::Log4perl qw(:easy);
use Sort::Naturally;
use Data::Dumper;
use File::Next;

#TODO: check publication date, if posterior to composer's death, try middle composer's active dates
#TODO: better detection of opus:  Op. 2a/3  
#TODO: add "First Performance" handling in AMGClassical Datasource
#TODO: add pdf extension in livret in mdaunarc.pl
#TODO: understand why objects are copied (wav, ape) in ORIG folderl
#TODO: check why this isn't working anymore: set MY /a/d1/t1-9/performance/date/rawData 2000
#DONE: alias for lekeu credits 
#DONE: no opus tag if no opus information
#DONE: do not add disc nor discc if discnumber <2
#DONE: Remove 'sir' particle in name for sort order generation

my %tagNamesDataSourcePriority=(
'DEFAULT' => 'MY',
'ALBUM' => 'MY',
'AMGGENRE' => 'AMG',
'AMGWORKTYPE' => 'AMG',
'ARTIST' => 'BOTH',
'ARTISTSORT' => 'BOTH',
'BAND' => 'BOTH',
'CATNUM' => 'MY',
'CHOIR' => 'BOTH',
'CHOIRSORT' => 'BOTH',
'COMPOSER' => 'BOTH',
'COMPOSERSORT' => 'BOTH',
'CONDUCTOR' => 'BOTH',
'CONDUCTORSORT' => 'BOTH',
'DISC' => 'MY',
'DISCC' => 'MY',
'GENRE' => 'BOTH',
'INSTRUMENTIST' => 'BOTH',
'INSTRUMENTISTSORT' => 'BOTH',
'LABEL' => 'MY',
'OPUS' => 'BOTH',
'ORCHESTRA' => 'BOTH',
'ORCHESTRASORT' => 'BOTH',
'ORIGYEAR' => 'MY',
'PERIOD' => 'MY',
'RECYEAR' => 'MY',
'SINGER' => 'BOTH',
'SINGERSORT' => 'BOTH',
'TITLE' => 'MY',
'TRACKNUMBER' => 'MY',
'WORK' => 'MY',
'YEAR' => 'MY'
);

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
'OPUS',	
'ORCHESTRA',
'ORCHESTRASORT',
'ORIGYEAR',
'PERIOD',
'RECYEAR',
'SINGER',
'SINGERSORT',
'TITLE',
'TRACKNUMBER',
'WORK',
'YEAR');

my %instrumentistRoles = (
	'Bass Viol' => '',
	'Bassoon' => '',
	'Guitar' => '',
	'Harpsichord' => '',
	'Oboe' => '',
	'Piano' => '',
	'Theorbo' => '',
	'Traverse Flute' => '',
	'Viol' => '',
	'Violin' => ''		
);

my %singerRoles = (
	'Vocals' => '',
	'Tenor (Vocal)' => '',
	'Bass (Vocal)' => '',
	'Soprano (Vocal)' => ''
);

my %ignoreRoles = (
	'Art Direction' => '',
	'Art Supervisor' => '',
	'Artwork' => '',
	'Assistant' => '',
	'Assistant Engineer' => '',
	'Audio Supervisor' => '',
	'Balance Engineer' => '',
	'Collaboration' => '',
	'Cover Design' => '',
	'Cover Art' => '',
	'Design' => '',
	'Digital Edition' => '',
	'Editing' => '',
	'Editorial Production' => '',
	'Engineer' => '',
	'Engraving' => '',
	'Interviewer' => '',
	'Liner Notes' => '',
	'Liner Note Translation' => '',
	'Photography' => '',
	'Producer' => '',
	'Recording' => '',
	'Translation' => '',
	'Typesetting' => ''
#	'' => '',
);

my %orchestraRoles = (
	'Ensemble' => '',
	'Orchestra' => ''
);

my %choirRoles = (
	'Choir' => '',
	'Chorus' => ''
);

my %conductorRoles= (
	'Conductor' => '',
	'Choir Master' => '',
	'Director' => '',
	'Ensemble Director' => ''
);

sub new {
	my $class  = shift;
	my $dataExporter = {};
	my %params;
	if (@_) {
		%params = %{ shift() };
	}

	$dataExporter = $class->SUPER::new(\%params);	

	bless( $dataExporter, $class );
	
#	$dataExporter->class( __PACKAGE__ );
		
	
	if (%params) {
		if ( defined( $params{foo} ) ) {
			$dataExporter->foo( $params{foo} );
		}
		if ( defined( $params{bar} ) ) {
			$dataExporter->bar( $params{bar} );
		}
	}
	return $dataExporter;
}

# Export data contained in data.xml into  tags of every flac files of the directory (album)
sub export {
	my $self = shift or return (undef);
	# The parameter is the albumFile object
	# TODO: check for null and use a $self->albumFile properties if dataExporter->albumFile has been done by the calling code
	my $albumFile = shift;
	
	if(defined($albumFile)) {
		$self->albumFile($albumFile);
	}
	
	unless( defined($self->albumFile()) ) {
		ERROR("export must be called with a valid AlbumFile object");
		die;
	}
	 
	# read basic files tag and directory structure for guessing correct track and disc structure and ordering
	# using default FileTagExporterMethod
	$self->readFilesFromCurrentDir();
	
	# now, we can read tag from dataSource
	$self->generateTags();

	# and write it down
	$self->writeTags();
	
}

sub generateTags{
	my $self = shift or return undef;
	
	my $MYDE;
	my $AMGClassicalDE; 
	if( defined($self->albumFile->dataSource('MY'))  ) {
		$MYDE=DataExport::MY2Flac->new();
		$MYDE->dataSource($self->albumFile->dataSource('MY'));
		$MYDE->readFlacFilesFromCurrentDir();
		$MYDE->backupTags();
		$MYDE->generateTags();
	}
#	local $Data::Dumper::Maxdepth = 5;
#	print Dumper \$MYDE->filesInDirHash(); die;
	
	if( defined($self->albumFile->dataSource('AMGClassical'))  ) {
		$AMGClassicalDE=DataExport::AMGClassical2Flac->new();
		$AMGClassicalDE->dataSource($self->albumFile->dataSource('AMGClassical'));
		$AMGClassicalDE->readFlacFilesFromCurrentDir();
		# Check if guessed or read in tags tracknum/discnum is correct
		if($AMGClassicalDE->checkTrackAndDiscCoherency() == 0 ) {
			# TODO: don't die and try later to guess work/track association from performance and average work length
			WARN("Track and Disc failed between flac files and AMG DataSource");
			die; # won't die when guessing algorithm between works and tracks is written
		}
		$AMGClassicalDE->backupTags();
		$AMGClassicalDE->generateTags();
	}
	# two previous real dataSource had their tags cleaned for each generateTags to properly work
	# so it also needs to be done on the multiDS to work properly
	$self->backupTags();

	# for each file
	FILE:
	for my $i (0..scalar(@{$self->foundFilesArray})-1 ) {
		# initialize three "tracks" each containing {tags} hash (myTrack and amgTrack {tags} hash contain generated tags)
		my $multiDsTrack = $self->foundFilesArray->[$i];
		my $multiDsTags = $self->foundFilesArray->[$i]->{tags};
		my $myTrack;
		my $amgTrack;
		my $myTags;
		my $amgTags;
		
		# try to set myTrack and amgTrack to corresponding multiDsTrack and check consistency
		if(defined($MYDE)) {
			$myTrack =  $MYDE->foundFilesArray->[$i];
			unless(  ($multiDsTrack->{guessedDiscNum} ==  $myTrack->{guessedDiscNum} )  
			and ($multiDsTrack->{guessedTrackNum} ==  $myTrack->{guessedTrackNum} )  
			and ($multiDsTrack->{filePath} eq  $myTrack->{filePath} ) ) {
				ERROR("Mismatch track file information mismatch between BasicMultiDS2Flac and AMGClassical2Flac (disc number or tracknumber or pathname");
				die;
			}
			$myTags = $myTrack->{tags};
		}
		if(defined($AMGClassicalDE)) {
			$amgTrack =  $AMGClassicalDE->foundFilesArray->[$i];
			unless(  ($multiDsTrack->{guessedDiscNum} ==  $amgTrack->{guessedDiscNum} )  
			and ($multiDsTrack->{guessedTrackNum} ==  $amgTrack->{guessedTrackNum} )  
			and ($multiDsTrack->{filePath} eq  $amgTrack->{filePath} ) ) {
				ERROR("Mismatch track file information mismatch between BasicMultiDS2Flac and AMGClassical2Flac (disc number or tracknumber or pathname");
				die;
			}
			$amgTags = $amgTrack->{tags};
		}
		
		# if a dataExport/dataSource is missing, use only the one remaining
		if(defined($myTrack) and not defined($amgTrack)) {
			$multiDsTrack->{tags} = $myTrack->{tags};
			next FILE;
		}elsif( not defined($myTrack) and defined($amgTrack)) {
			$multiDsTrack->{tags} = $amgTrack->{tags};
			next FILE;
		}elsif( not defined($myTrack) and not defined($amgTrack)) {
			# if no datasource was found, it's a big mistake 
			ERROR("No datasource information (neither AMGClassical nor MY) for file ", $multiDsTrack->{filePath});
		}

		if(defined($MYDE)) {
			foreach my $tagName ( keys %{$myTags}){
				# $self->getDsTrack($track->{guessedDiscNum}, $track->{guessedTrackNum});
				#print("MYDE: ", $tagName, " ", $myTags->{$tagName}, "\n");
				if($tagName =~ /^MDATAGGED$/ or $tagName =~ /^MDABCK-.*$/  or $tagName =~ /^MDABKP-.*$/ ) {
					DEBUG("Discarding backup tag $tagName = ".$myTags->{$tagName});
					next;
				}
				# if the tag isn't listed in the priority hash, it can be an error, so report it
				unless(exists($tagNamesDataSourcePriority{$tagName}) ) {
					WARN("Tag $tagName isn't in the SourcePriority Hash, trying to import it");
					if(exists($multiDsTags->{$tagName}) ){
						if ($tagNamesDataSourcePriority{DEFAULT} eq 'MY' )  {
							WARN("Tag $tagName already exists in multiDsTags, overwriting old tag (this shouldn't be possible)");
							$multiDsTags->{$tagName} = $myTags->{$tagName};
						}else { # tag already exists and MY is not the default
							WARN("Tag $tagName already exists in multiDsTags, default isn't set to MY, not overwritten");
						}
					}else { # tagName doesn't exist in multiDsTags
						WARN("Tag $tagName doesn't exist multiDsTags, importing it");
						$multiDsTags->{$tagName} = $myTags->{$tagName};
					}
				# tagName exists in tagNamesDataSourcePriority
				}elsif($tagNamesDataSourcePriority{$tagName} eq 'MY') { # we have priority, no question, overwrite
					$multiDsTags->{$tagName} = $myTags->{$tagName};
				}elsif($tagNamesDataSourcePriority{$tagName} eq 'BOTH') { # BOTH ds are kept, need to fusion tags
					$multiDsTags->{$tagName} = $self->multiItemTagFusion($multiDsTags->{$tagName}, $myTags->{$tagName});
				}else {
					unless(exists($multiDsTags->{$tagName}) ){ # but the tag doesn't exist, so import it anyway
						$multiDsTags->{$tagName} = $myTags->{$tagName};
					}
				}
				#print("MUDS: ", $tagName, " ", $multiDsTags->{$tagName}, "\n");
			}
		}
		if(defined($AMGClassicalDE)) {
			foreach my $tagName ( keys %{$amgTags}){
				#print("$tagName\n");
				# $self->getDsTrack($track->{guessedDiscNum}, $track->{guessedTrackNum});
				#print($tagName, " ", $amgTags->{$tagName}, "\n");
				if($tagName =~ /^MDATAGGED$/ or $tagName =~ /^MDABCK-.*$/  or $tagName =~ /^MDABKP-.*$/ ) {
					next;
				}
				# if the tag isn't listed in the priority hash, it can be an error, so report it
				unless(exists($tagNamesDataSourcePriority{$tagName}) ) {
					WARN("Tag $tagName isn't in the SourcePriority Hash, trying to import it");
					if(exists($multiDsTags->{$tagName}) ){
						if ($tagNamesDataSourcePriority{DEFAULT} eq 'AMG' )  {
							WARN("Tag $tagName already exists in multiDsTags, overwriting old tag (this shouldn't be possible)");
							$multiDsTags->{$tagName} = $amgTags->{$tagName};
						}else { # tag already exists and MY is not the default
							WARN("Tag $tagName already exists in multiDsTags, default isn't set to AMG, not overwritten");
						}
					}else { # tagName doesn't exist in multiDsTags
						WARN("Tag $tagName doesn't exist multiDsTags, importing it");
						$multiDsTags->{$tagName} = $amgTags->{$tagName};
					}
				# tagName exists in tagNamesDataSourcePriority
				}elsif($tagNamesDataSourcePriority{$tagName} eq 'AMG') { # we have priority, no question, overwrite
					$multiDsTags->{$tagName} = $amgTags->{$tagName};
				}elsif($tagNamesDataSourcePriority{$tagName} eq 'BOTH') { # BOTH ds are kept, need to fusion tags
					$multiDsTags->{$tagName} = $self->multiItemTagFusion($multiDsTags->{$tagName}, $amgTags->{$tagName});
				}else {
					unless(exists($multiDsTags->{$tagName}) ){ # but the tag doesn't exist, so import it anyway
						$multiDsTags->{$tagName} = $amgTags->{$tagName};
					}
				}
			}
		}
	}
}

# Orig Year is either (in order of priority):
# - the work Composition Date
# - the work publication Date
# - the work revision Date
# - the composer mean active years
# - the composer  birth year + 7.5 + (death year - birth year)/2
sub guessOrigYear{
	my $self = shift or return undef;
	my $work = shift or return undef;
	
	# Composed Date
	if(scalar(@{$work->composed->date->normalized}) >0 ) {
		return int $work->composed->date->meanYear();
	}
	
	# Publication Date
	if(scalar(@{$work->publicationDate->normalized}) >0 ) {
		return int $work->publicationDate->meanYear();
	}
	
	# Revision Date
	if(scalar(@{$work->revisionDate->normalized}) >0 ) {
		return int $work->revisionDate->meanYear();
	}
	
	if(scalar(@{$work->composer->activeDates->normalized}) >0 ) {
		return int $work->composer->activeDates->meanYear();
	}

	if(scalar(@{$work->composer->lifeDate->normalized}) >0 ) {
		return int($work->composer->lifeDate->meanYear()+7.5);
	}
	return -1;
}

# Album Year is either (in order of priority):
# - the album release date
# - the max of performance record date (if there's at least one performance record date)
sub guessAlbumYear{
	my $self = shift or return undef;

	my $albumYear;
	
	if(defined($self->albumFile->dataSource('MY'))) {
		
	}
	# if there is a release Date
	if( ref($self->dataSource->album->releases->[0]) and scalar(@{$self->dataSource->album->releases->[0]->date()->normalized})>0 ) { 
		# return it
		return int($self->dataSource->album->releases->[0]->date->meanYear);
	}
	# else return max performances year
	return $self->maxPerformancesYear();
}

sub meanPerformancesYear{
	my $self = shift or return undef;

	my $albumYear;
	
	my $yearCount=0;
	my $nbFoundRecDate=0;
	
	foreach my $perf ( @{$self->dataSource->album->performances()}) {
		if(ref($perf->date->normalized) and scalar(@{$perf->date->normalized}) > 0 ) {
			$yearCount+=$perf->date->meanYear;
			$nbFoundRecDate++;
		}
	}
	
	# if we found some performances record date
	if($yearCount!=0) { # albumYear equals the mean value of record dates
		return(int($yearCount/$nbFoundRecDate));
	}
	ERROR("No performances year found, can't calculate mean performances year");
	return -1;
}

sub maxPerformancesYear{
	my $self = shift or return undef;

	my $albumYear;
	
	my $maxYear=-1;
	my $nbFoundRecDate=0;
	
	foreach my $perf ( @{$self->dataSource->album->performances()}) {
		if(ref($perf->date->normalized) and scalar(@{$perf->date->normalized}) > 0 ) {
			$maxYear=($maxYear > $perf->date->meanYear)?$maxYear:$perf->date->meanYear;
			$nbFoundRecDate=1;
		}
	}
	
	# if we found some performances record date
	if($maxYear>-1) { # albumYear equals the mean value of record dates
		return(int($maxYear));
	}
	ERROR("No performances year found, can't calculate max  performances year");
	return -1;
}


END { }    # module clean-up code here (global destructor)
1;