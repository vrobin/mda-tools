#!/usr/bin/perl -w

package DataSource::FIL::FILReader;

use strict;
use utf8;

BEGIN {
	use Exporter ();
	our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

	# set the version for version checking
	$VERSION = 1.00;

	# if using RCS/CVS, this may be preferred
	$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;

	@ISA         = qw(Exporter DataFile::DataSource);
	@EXPORT      = qw();           #&readClassicalAlbumPageFromFile);
	%EXPORT_TAGS = ();             # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK = qw();
}
our @EXPORT_OK;

#use HTML::TreeBuilder::XPath;
use HTML::Entities;
use Data::Dumper;

use File::Next;
use Benchmark;
use Cwd;
use Audio::FLAC::Header;
use Log::Log4perl qw(:easy);

use Tools;
use DataFile::Album;
use DataFile::Award;
use DataFile::Credit;
use DataFile::Disc;
use DataFile::Length;
use DataFile::Label;
use DataFile::Note;
use DataFile::Part;
use DataFile::Performance;
use DataFile::Rating;
use DataFile::Tag;
use DataFile::Track;
use DataFile::Work;

our $DataSourceName = 'FIL';
our $DataSourceVer = '0.1';
our $providerName ='File Reader';
our $providerUrl = undef;
our $lookupClass = 'DataSource::FIL::FILLookup';

sub new {
	my $class  = shift;
	my $dataSource;
	my %params;
	if (@_) {
		%params = %{ shift() };
	}
	$params{name} = $DataSourceName;
	$params{version} = $DataSourceVer;
	$params{providerName}= $providerName;
	$params{providerUrl}= $providerUrl;

	$dataSource = $class->SUPER::new(\%params);	
	
	bless( $dataSource, $class );
	$dataSource->class( __PACKAGE__ );
	
	if (%params) {
#		if ( defined( $params{version} ) ) {
#			$dataSource->version( $params{version} );
#		}
#		if ( defined( $params{name} ) ) {
#			$dataSource->name( $params{name} );
#		}
#		if ( defined( $params{providerName} ) ) {
#			$dataSource->providerName( $params{providerName} );
#		}
##		if ( defined( $params{reader} ) ) {
##			$dataSource->reader( $params{reader} );
##		}
#		if ( defined( $params{providerUrl} ) ) {
#			$dataSource->providerUrl( $params{providerUrl} );
#		}
	}

	return $dataSource;
}

# Try to find album from available data
sub retrieve {
	my $self = shift or return(undef);
	if ($self->albumFile->{lookupData}{albumDir}) {
		$self->readFromDir($self->albumFile->{lookupData}{albumDir});
	}else {
		$self->readFromDir('.');
	}
}

# Stub for standardized api
sub readFromDir {
	my $self = shift;
	$self->album( $self->_readFilesFromDir(@_) );
}

sub _readFilesFromDir{
	my $self = shift;
	my $path = shift or return (undef);

	# save original path (we're working relative to the given directory for ./cd1 ./cd2 tree structures)
 	my  $origPath = getcwd();
 	
 	# working in the given directory
	chdir($path) or die("Unable to chdir to $path");

	#Look for every cue file under the given directory
	my @foundFiles; # to record absolute filenames of found cue files
	my $iter = File::Next::files( { sort_files => 1, file_filter => sub { /\.(?:flac|)$/ } }, $path );
	
	while ( defined ( my $file = $iter->() ) ) {
	        push(@foundFiles, $file);
	}
	my $album = $self->_readFilesFromFilenames(@foundFiles);

#	print Dumper($album);
	# restoring caller working directory
	chdir($origPath) or ERROR("Unable to chdir to original path $origPath");
	return($album);
}

# For multi disc albums, just pass multiple cuesheets
sub _readFilesFromFilenames {
	my $self = shift;
	my @filenames = @_;
	
	# Validate inputs:
	unless(@filenames and ( scalar(@filenames)>0 ) ) {
		ERROR("Invalid input @filenames");
		return undef;
	}
	
	# Validate files and find number of discs:
	my %dirs;
	foreach my $filepath (@filenames)  {
		unless( -e $filepath and -r $filepath and -f $filepath) {
			ERROR("Unable to find/open file: $filepath");
			return undef;
		}else {  # if we have a valid filename
			# get the directory where the file is
			my ($volume,$directories,$file) = File::Spec->splitpath( $filepath );
			# and increment a counter in the forme of a hash where keys are directory  $dirs{Disc1}, $dirs{Disc2}
			$dirs{File::Spec->catpath( $volume, $directories, '')}++;
			DEBUG("Valid file: $filepath\n"); 
		}
	}
		
	# We have all cue sheets readable file, so let's begin by creating the album object
	my $album = DataFile::Album->new();
	# Setting it's type (cue is said to be from a compact disc, could be better)
	$album->mediaType('CD');
	
	# TODO: could try to detect multidisc of the form "<discnum>-<tracknum> <trackname>.flac"
	# We assume that there is one disc per directory so there's as much disc as we found different directories
	$album->numberOfDiscs(scalar keys %dirs);

	# for each directory, create a new disc and find tracklength
	my $discnum = 0;
	foreach my $dir (sort keys %dirs) {
		DEBUG("-- $dir $dirs{$dir}\n");
		# new dir from dirs, that's another disc
		$discnum++;
		# create the disc object
		my $disc = DataFile::Disc->new();
		# add it to the album
		$album->addDisc($disc);	
		$disc->index($discnum);
		my $escapedDirname = Tools::regexEscape($dir);
		#$escapedDirname =~ s/\\/\\\\/g;
		#$escapedDirname =~ s/\(/\\\(/g;
		#$escapedDirname =~ s/\)/\\\)/g;
		# Protect regexp special characters with backslash
		# read all files of a given $dif as one disc
		$self->_readDiscFilesFromFilenames($disc,  grep(  /^$escapedDirname/,  @filenames) );
	}

	#TODO: add dataProvider name (FIL);
	#$album->url('file://'.$filename);	
	return $album;
}

#sub readCueFromFilename {
#	return readCueFromFilenames(@_);
#}

# Only used from within the datasource.
# Read the cue 'filename' and record its content in the disc object 
sub _readDiscFilesFromFilenames {
	my $self = shift;
	my $disc = shift or return (undef);
	my @filenames = @_;
	my $trackIndex = 0;
	my %workTracks;
	$workTracks{$disc->index()}={};
	
	foreach my $filename (@filenames) {
		my $flacInfo;  # info header from flac file
		my $flacTags; # tags from flac file
		my $cwd=File::Spec->canonpath(getcwd());
		my $regexEscapedCwd = Tools::regexEscape($cwd);
		
		my $urlCompliantCwd = $cwd;
		utf8::encode($urlCompliantCwd);
		$urlCompliantCwd =~ s/\\/\//g;
		$urlCompliantCwd = Tools::URLEncode($urlCompliantCwd);

		$filename = File::Spec->canonpath($filename);
		
		my $urlCompliantFilename = $filename;
		utf8::encode($urlCompliantFilename);
		$urlCompliantFilename =~ s/\\/\//g;
		$urlCompliantFilename = Tools::URLEncode($urlCompliantFilename);
;		
		
		# Read the flac headers (info and tags)
		my $flac = Audio::FLAC::Header->new("$filename");
		
		# if flac is unreadable
		unless ($flac) { ERROR("Error while reading flac header for $filename"); return undef;};
		
		# It's a new valid flac, the track index is incremented
        $trackIndex++;
		
		$flacInfo = $flac->info();
        $flacTags = $flac->tags();
        
        
		my $track = DataFile::Track->new( { index => $trackIndex }); # TODO: add performer/composer in work and perf objects -- , perfIndex => $1, perfId => $perfId } );
		$disc->addTrack($track);		


		# fill uri relativeUri baseUri of track
		if (File::Spec->file_name_is_absolute( $filename )) {

			$track->url('file:///'.$urlCompliantFilename);
			# Escaping \ because they need it to be used as a regex
			
			$filename =~ m/$regexEscapedCwd\\(.*)/;
			my $foundDir = $1;
			$foundDir =~ s/\\/\//g;
			utf8::encode($foundDir);
			$foundDir = Tools::URLEncode($foundDir);
			$track->relativeUrl($foundDir);
			#ERROR("cur: $mycwd  \nfilename: $myfile\ntest: $1" );
		}else {
			$track->url('file:///'.$urlCompliantCwd.'/'.$urlCompliantFilename);
			$track->relativeUrl($urlCompliantFilename);
		}
		$track->baseUrl('file:///'.$urlCompliantCwd);
		#TODO: add disc base/relativeUrl from filename
		#TODO: add album base/relativeUrl from cwd		
		$disc->album->url ('file:///'.$urlCompliantCwd);
		$track->url() =~ /(.*)\/([^\/]*)$/;
		$disc->url ($1);
        utf8::decode($flacTags->{TITLE});
        
        $track->name( $flacTags->{TITLE});
        
        
#########################################
########################################
# Personnal horrible mess to extract data contained in flac files         
        # AMG-TRACK-WORK-SQL -> 42:484483
        # OK AMG-ALBUM-SQL -> 43:124707
        # OK AMG-ALBUM-LABEL-N-REF -> Naive[30399]
        # AMG-WORK-COMPOSER-SQL -> 41:7073
        # OK AMG-ALBUM-FEATUREDARTIST-SQL -> NN:NNNN
        # track range format 1#01-2#03,2,5=41:123;

        if ( $flacTags->{'AMG-ALBUM-SQL'} && !($self->albumFile->{lookupData}{AMG}{albumSqlId}))  {
        	$self->albumFile->{lookupData}{AMG}{albumSqlId}=$flacTags->{'AMG-ALBUM-SQL'};
        }
        # if there's no album sql but a track-work-sql (manually entered work id for the track)
        if( (! $flacTags->{'AMG-ALBUM-SQL'}) and $flacTags->{'AMG-TRACK-WORK-SQL'} ) {
        	my $workSqlId = $flacTags->{'AMG-TRACK-WORK-SQL'};
        	push @{$workTracks{$disc->index()}{$workSqlId}}, $trackIndex;
        	
#        	my $workSqlId = $flacTags->{'AMG-TRACK-WORK-SQL'};
#        	my $workSqlIdEscaped = Tools::regexEscape($workSqlId);
#        	my $trackId = $disc->index().'#'.$trackIndex;
#        	if( $self->albumFile->{lookupData}{amgWorkSqlId} and  $self->albumFile->{lookupData}{amgWorkSqlId} =~ m/$workSqlIdEscaped/g ) {
#        		my $newString = Tools::regexEscape($self->albumFile->{lookupData}{amgWorkSqlId});
#        		$newString =~ s/(.*[^;]*?)(=${workSqlIdEscaped};.*)/$1,${trackId}$2/g;
#        		 $self->albumFile->{lookupData}{amgWorkSqlId}=$newString;
#        		ERROR($newString);
#        	}else {
#        		$self->albumFile->{lookupData}{amgWorkSqlId}.=$trackId.'='. $flacTags->{'AMG-TRACK-WORK-SQL'}.';';
#        	}
        }
        if ( $flacTags->{'AMG-ALBUM-LABEL-N-REF'} && !($self->albumFile->{lookupData}{labelName}))  {
        	 $flacTags->{'AMG-ALBUM-LABEL-N-REF'} =~ /([^[]+)\[([\d]+)\]?/g;
        	 $self->albumFile->{lookupData}{labelName}=$1;
        	 $self->albumFile->{lookupData}{catalogNumber}=$2;
        }
        if( $flacTags->{'AMG-ALBUM-FEATUREDARTIST-SQL'} && !($self->albumFile->{lookupData}{AMG}{featuredArtistSqlId}) ) {
        	$self->albumFile->{lookupData}{AMG}{featuredArtistSqlId} =  $flacTags->{'AMG-ALBUM-FEATUREDARTIST-SQL'};
        }
		$track->samples($flacInfo->{TOTALSAMPLES});
		$track->sampleRate($flacInfo->{SAMPLERATE});
		# Use the flac check as Id, this would permit us to retrieve the file if it's renamed
		$track->id($flacInfo->{MD5CHECKSUM});
		#print("samples: ",$track->samples() ," samplerate: ",$track->sampleRate(),"\n");
		$track->length(DataFile::Length->new( { 
			seconds => $track->samples() / $track->sampleRate()
		 }));		
	}
	#%workTracks contains:
#	$VAR1 = {
#          '2' => {
#                   '42:20044' => [
#                                   1,
#                                   2,
#                                   3,
#                                   4,
#                                   5,
#                                   6
#                                 ],
#                   '42:20042' => [
#                                   7,
#                                   8,
#                                   9,
#                                   10,
#                                   11,
#                                   12
#                                 ]
#                 }
#        };
# Generate the amgWorkSqlId looking like: DISCINDEX(tracklist=worksql) ie: 1(1-6=42:20044;7-12=42:20042)|2(1-6=42:20044;7-12=42:20042)
	#print Dumper \%workTracks;  # $workTracks{$disc->index()}{$workSqlId}}
	# following is an horrible mess to transform (1,3,4,8,9,10,12,14,15,16,19); in  '1', '3-4', '8-10','12','14-16','19'
	my $amgWorkSqlId=undef;
	#foreach work
	WORK:
	foreach my $workSqlId (keys %{$workTracks{$disc->index()}}) {
		#print("Workid: $workSqlId\n");
		
		#print Dumper \@{$workTracks{$disc->index()}{$workSqlId}}; 
		my $lastTrackIndex = undef;
		my $beginRange = undef;
		my $endRange = undef;
		my $trackListString = undef;
		# for each track 
		my @sortedWorkTracks = sort {$a <=> $b}  @{$workTracks{$disc->index()}{$workSqlId}};
		# Test Pattern @sortedWorkTracks =(1,3,4,8,9,10,12,14,15,16,19);
		$workTracks{$disc->index()}{$workSqlId}=[];
		TRACK: 
		foreach my $trackIndex (@sortedWorkTracks) {
			# print $trackIndex;
			# if this is the first track
			if(!$lastTrackIndex){
				$beginRange =  $trackIndex;
				$lastTrackIndex = $trackIndex;
				next TRACK;
			} # if the found track is following the previous  track, it's in the current range
			elsif ($trackIndex == ($lastTrackIndex+1) ) {
				 $lastTrackIndex = $trackIndex;
				 next TRACK;
			} # found track isn't following, so the range is close 
			else { # this is not a range, but a single track
				if( $beginRange == $lastTrackIndex ) {
					DEBUG("found single track $lastTrackIndex\n");
					push @{$workTracks{$disc->index()}{$workSqlId}}, "$lastTrackIndex"; 
				} elsif ( $beginRange == $lastTrackIndex-1 ) {
					push @{$workTracks{$disc->index()}{$workSqlId}}, "$beginRange,$lastTrackIndex";
				} else {
					push @{$workTracks{$disc->index()}{$workSqlId}}, "$beginRange-$lastTrackIndex"; 
					DEBUG("Found range: $beginRange-$lastTrackIndex\n ");
				}
				$beginRange = $trackIndex;
			}
			$lastTrackIndex = $trackIndex;
		}
		if($beginRange == $lastTrackIndex ) {
			push @{$workTracks{$disc->index()}{$workSqlId}}, "$lastTrackIndex";
		} elsif($beginRange == $lastTrackIndex-1 ) {
			push @{$workTracks{$disc->index()}{$workSqlId}}, "$beginRange,$lastTrackIndex";
		} else {
			push @{$workTracks{$disc->index()}{$workSqlId}}, "$beginRange-$lastTrackIndex";
		} 
		DEBUG("$beginRange-$lastTrackIndex=$workSqlId\n");
	}
	
# Now %workTracks looks like
#$VAR1 = {
#          '2' => {
#                   '42:20044' => [
#                                   '1',
#                                   '3-4',
#                                   '8-10',
#                                   '12',
#                                   '14-16',
#                                   '19'
#                                 ],
#                   '42:20042' => [
#                                   '1',
#                                   '3-4',
#                                   '8-10',
#                                   '12',
#                                   '14-16',
#                                   '19'
#                                 ]
#                 }
#        };
	my @workSqlIdTrackList; 
	foreach my $workSqlId (keys %{$workTracks{$disc->index()}}) {
		push @workSqlIdTrackList, join(',',@{$workTracks{$disc->index()}{$workSqlId}} )."=$workSqlId";
	}

	# if there's works id recorded
	if(@workSqlIdTrackList) {
		unless($self->albumFile->{lookupData}{AMG}{worksSqlIds}) {
			$self->albumFile->{lookupData}{AMG}{worksSqlIds} = '';
		}
	 	$self->albumFile->{lookupData}{AMG}{worksSqlIds}.='disc-'.$disc->index()."(".join(';',@workSqlIdTrackList ).");";
	}

	#print join(';',@workSqlIdTrackList );
#	print $self->albumFile->{lookupData}{amgWorksSqlIds};

######### End of personnal horrible mess
#####################################################
######################################################

	return $disc;
}

END { }    # module clean-up code here (global destructor)
1;

