#!/usr/bin/perl -w

package DataSource::CUE::CUEReader;

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
use Tools;
use File::Next;
use Benchmark;
use Cwd;
use Log::Log4perl qw(:easy);


our $DataSourceName = 'CUE';
our $DataSourceVer = '0.1';
our $providerName ='CUE Sheet';
#our $providerName =undef;
our $providerUrl =undef;
our $lookupClass = 'DataSource::CUE::CUELookup';

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
#		if ( defined( $params{providerName} ) ) {
#			$dataSource->providerName( $params{providerName} );
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
	$self->_readCuesFromDir(@_);
}

sub _readCuesFromDir{
	my $self = shift or return(undef);
	my $path = shift or return (undef);
#my $path ='O:\\SB\\CLASSIC EB\\Leonhardt, Gustav\\Frescobaldi, Couperin - Pièces pour clavecin - Leonhardt - Alpha\\';
# utf8::decode($path);

	# save original path (we're working relative to the given directory for ./cd1 ./cd2 tree structures)
 	my  $origPath = getcwd();
 	
 	# working in the given directory
	chdir($path) or die("Unable to chdir to $path");

	#Look for every cue file under the given directory
	my @foundCues; # to record absolute filenames of found cue files
	my $iter = File::Next::files( { sort_files => 1, file_filter => sub { /\.(?:cue|)$/ } }, $path );
	
	while ( defined ( my $file = $iter->() ) ) {
	        push(@foundCues, $file);
	}
	$self-> readCueFromFilenames(@foundCues);
	
	# url of the album is the directory from which looking for cue sheets
	my $cwd=File::Spec->canonpath(getcwd());
	my $regexEscapedCwd = $cwd;
	$regexEscapedCwd =~  s/  (    \) | \\ | \(  | \[  | \] | \. | \*  |  \$  |  \+  |  \? |  \^ | \/ )  /\\$1/gmsx;
	my $urlCompliantCwd = $cwd;
	utf8::encode($urlCompliantCwd);
	$urlCompliantCwd =~ s/\\/\//g;
	$urlCompliantCwd = 'file:///'.Tools::URLEncode($urlCompliantCwd);
 	$self->album->url($urlCompliantCwd);
	
#	print Dumper($album);
	# restoring caller working directory
	chdir($origPath) or ERROR("Unable to chdir to original path $origPath");
}

# For multi disc albums, just pass multiple cuesheets
sub readCueFromFilenames {
	my $self = shift or return(undef);
	my @filenames = @_;
	
	# Validate inputs:
	unless(@filenames and ( scalar(@filenames)>0 ) ) {
		ERROR("Invalid input @filenames");
		return undef;
	}
	foreach my $filename (@filenames)  {
		unless( -e $filename and -r $filename and -f $filename ) {
			ERROR("Unable to find/open file: $filename");
			return undef;
		}else { 
			DEBUG("Valid cue filename: $filename\n"); 
		}
	}
	
	# We have all cue sheets readable file, so let's begin by creating the album object
	my $album = $self->album();
	# Setting it's type (cue is said to be from a compact disc, could be better)
	$album->mediaType('CD');
	
	# numberOfDiscs is first to zero and incremented when a valide cue is found
	$album->numberOfDiscs(0);
	
	# for each cue file name
	foreach my $filename(@filenames) {
		# create the disc object
		my $disc = DataFile::Disc->new();
		# add it to the album
		$album->addDisc($disc);
		# Disc number is definitely put after the cue is validated (see ten lines later)
		# but _readCueFromFilename needs it for track id creation
		$disc->index($album->numberOfDiscs()+1);
		DEBUG("Reading $filename ");
		
		# Call the main cue file analyzer with our newly created disc
		$self->_readCueFromFilename($filename, $disc);
		
		# if the disc has a name, the cue must have been correctly decoded
		if($disc->name()) {
			DEBUG("Disc title found after cue sheet read, adding a disc in the album");
			my $nod = $album->numberOfDiscs();
			$nod++;
			$album->numberOfDiscs($nod);
			$disc->index($nod);
		} else {
			# if the file wasn't a readable cue sheet, we should remove the current disc
			# TODO: Try to unshift discs, but this as to be tested or replaced by a removeDisc method in album class
			shift @{$album->discs};
			WARN("No disc title found after cue sheet read!");
		}
	}
	#numberOfDiscs

	#TODO: add dataProvider name (CUE);
	#$album->url('file://'.$filename);	
	return $album;
}

sub readCueFromFilename {
	return readCueFromFilenames(@_);
}

# Only used from within the datasource.
# Read the cue 'filename' and record its content in the disc object 
sub _readCueFromFilename {
	my $self = shift or return(undef);
	my $filename = shift or return (undef);
	$filename = File::Spec->canonpath($filename);
	my $disc = shift or return(undef);
	my $cwd=File::Spec->canonpath(getcwd());
	
		my $regexEscapedCwd = $cwd;
		$regexEscapedCwd =~  s/  (    \) | \\ | \(  | \[  | \] | \. | \*  |  \$  |  \+  |  \? |  \^ | \/ )  /\\$1/gmsx;
		
		my $urlCompliantCwd = $cwd;
		utf8::encode($urlCompliantCwd);
		$urlCompliantCwd =~ s/\\/\//g;
		$urlCompliantCwd = Tools::URLEncode($urlCompliantCwd);

		my $urlCompliantFilename = $filename;
		utf8::encode($urlCompliantFilename);
		$urlCompliantFilename =~ s/\\/\//g;
		$urlCompliantFilename = Tools::URLEncode($urlCompliantFilename);

	# TODO: check for other encoding types on other systems... no info right now.
	open( FH, "<:encoding(iso-8859-15)", $filename ) or ( ERROR("Unable to open file $filename") and return undef);
	if (File::Spec->file_name_is_absolute( $filename )) {
		my $mycwd = $cwd;
		$disc->url('file:///'.$urlCompliantFilename);
		# Escaping \ because they need it to be used as a regex
		$filename =~ m/${regexEscapedCwd}\\(.*)/;
		my $foundDir = $1;
		$foundDir =~ s/\\/\//g;
		utf8::encode($foundDir);		
		$foundDir = Tools::URLEncode($foundDir);
		$disc->relativeUrl($foundDir);
		#ERROR("cur: $mycwd  \nfilename: $myfile\ntest: $1" );
	}else {
		$disc->url('file:///'.$urlCompliantCwd.'/'.$urlCompliantFilename);
		$disc->relativeUrl($urlCompliantFilename);
	}
	$disc->baseUrl('file:///'.$urlCompliantCwd);
	my $data = join "", <FH>;

	my ( $header, $tracks ) = (
		$data =~ m{
                \A                # start of string
                (.*?)             # capture all header text
                (^ \s* (?:TRACK|FILE) .*)  # capture all tracklist text
                \z                # end of string
              }xms
	);

	unless ( $header && $tracks ) {
		ERROR("Unable to find header/tracks in cue file $filename");
		return undef;
	}

	my @lines = split /\r*\n/, $header;

  LINE:
	foreach my $line (@lines) {
		$line = Tools::trim($line);

		$line =~ m/\S/ or next LINE;

		my ( $keyword, $data ) = (
			$line =~ m/ 
        \A          # anchor at string beginning
        (\w+)       # capture keyword (e.g. FILE, PERFORMER, TITLE)
        \s+ ['"]?   # optional quotes
        (.*?)       # capture all text as keyword's value  
        (?:         # non-capture cluster
          ['"]      # quote, followed by
          (?:       
            \s+     # spacing, followed by
            \w+     # word (e.g. MP3, WAVE)
          )?        # make cluster optional
        )?          
        \z          # anchor at line end
      /xms
		);
		if ( $keyword eq 'REM' ) {
			$data =~ / GENRE \s+ ([^\s]*)  \s* /xms 
				and $disc->album->addTag( DataFile::Tag->new({ name => 'GENRE', value => $1 } ) );
			$data =~ / DISCID \s+ ([0-9A-Fa-f]*)  \s* /xms
			  and $1 !~ /^0*$/ and $disc->id( $1 );
			  # Generate the FDB:discIds like: DISCINDEX(<discid>) ie: 1(AD11051B)|2(AD5861B) or for single disc AD11051B
# Forget it, discId is stored in CUE DataSource content as disc->id
#			 my $discid=$disc->id();
#			  if($disc->id() and $self->albumFile->{lookupData}{FDB}{discIds} !~ /$discid/ ) {
#			  	$self->albumFile->{lookupData}{FDB}{discIds}=$self->albumFile->{lookupData}{FDB}{discIds}.(length($self->albumFile->{lookupData}{FDB}{discIds})>0?'|':'').$disc->index()."(".$disc->id().")";
#			  }
# Attempt to handle FDB discindex, a more "cmdline friendly" syntax has been used 
#			  if($disc->id() and not (grep {$disc->id() eq $_->{content} } @{$self->albumFile->{lookupData}{FDB}{discIds}{discId}}) ) {
#			  	push @{$self->albumFile->{lookupData}{FDB}{discIds}{discId}},{ content => $disc->id(), index => $disc->index() };
#			  }
		}
		if ( $keyword eq 'PERFORMER' ) {
			#print("Artist: $data\n");
			# is the new credit already existing?
			my $newCredit = $disc->album->findCredits(  { name => $data, role => $keyword } );
			# If a credit with thies properties was found, log it
			if($newCredit)	{
				DEBUG("Don't add already existing credit: $keyword -> $data")
			} else {
				# credit not found, so add it to the album
				$disc->album->addCredit( DataFile::Credit->new( { name => $data, role => $keyword }) );
			}
		}
		if ( $keyword eq 'TITLE' ) {
			# print("Album name: $data\n");
			$disc->name($data);
			# No index Name like CD1 or CD2, we could use the last level directory
			$disc->indexName();
		}

		#print("KW: $keyword, VAL: $data \n")
	}
	@lines = split /\r*\n/, $tracks;
	my @works;
	my @perfs;
	my $track;
	
	foreach my $line (@lines) {
		$line=Tools::trim($line);
		#print($line);
		# TRACK 01
		# TRACK 02 AUDIO
		if(	$line =~ /\A TRACK \s+ (\d+) .* \z/xms ) {
			# For simplicity, don't use work with cue data... if we knew the performer is the composer
			# we could use the work to hold composer information
			#my $workId='work-'.($disc->id()?$disc->id():$disc->index()).'-'.$1;
			my $perfId='perf-'.($disc->id()?
						$disc->id()
						:$disc->index()).'-'.$1;
			my $performance = DataFile::Performance->new( {index => $1, id => $perfId  });
			#push @perfs, $performance;
			#$track = DataFile::Track->new( { index => $1, workIndex => $1, workId => $workId, perfId => $perfId } );
			$track = DataFile::Track->new( { index => $1, performance => $performance } );
			$disc->addTrack($track);
		  # push @works,  DataFile::Work->new( { index => $1, id => $workId} );
		}

		next unless $track;

		# TITLE Track Name
		# TITLE "Track Name"
		# TITLE 'Track Name'
		if(	$line =~ /\A TITLE \s+ ['"]? (.*?) ['"]? \z/xms ) {
		   $track->name($1); 
		   #$works[-1]->name($1); 
		}

		# PERFORMER Artist Name
		# PERFORMER "Artist Name"
		# PERFORMER 'Artist Name'
		$line =~ /\A PERFORMER \s+ ['"]? (.*?) ['"]? \z/xms
		  and $track->performance->addCredit( DataFile::Credit->new( { name => $1, role => 'PERFORMER' }) );
		
		if(	$line =~ /\A ISRC \s+  (\w*) .* \z/xms and  $1 !~ /^0*$/ ) {
			 $track->id(  $1 );
		}

		# INDEX 01 06:32:20
#		$line =~ /\A INDEX \s+ (?: \d+ \s+) ([\d:]+) \z/xms
#		  and $tracks[-1]->index($1);
	}
	close(FH) or ERROR("Unable to close file $filename");
	#push @{$disc->album->performances()},@perfs;
	#$disc->album->performances(\@perfs);
	#$album->works(\@works);
	return $disc;


}

END { }    # module clean-up code here (global destructor)
1;

