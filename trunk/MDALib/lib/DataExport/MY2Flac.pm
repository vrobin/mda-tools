#!/usr/bin/perl -w

package DataExport::MY2Flac;
use base qw(DataExport::FileTagExporter);

use strict;
use utf8;

use DataFile::AlbumFile;

use Audio::FLAC::Header;
use Log::Log4perl qw(:easy);
use Sort::Naturally;
use Data::Dumper;
use File::Next;



my %instrumentistRoles = (

);

my %singerRoles = (

);

my %ignoreRoles = (

);

my %orchestraRoles = (
	'Orchestra' =>'',
	'Orchestre' => '',
	'orchestre' => ''
);

my %choirRoles = (
	'Chorus' => '',
	'Choir' => ''
);

my %conductorRoles= (
	'Conductor' => ''
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

	# To export AMGClassical, we need AMGClassical data in the file
	unless(defined($albumFile->dataSource('MY'))) {
		# Hey, this exporter is calles AMGClassical2Flac!
		ERROR("AMGClassical dataSource not found in albumFile object");
		die;
	}
	ERROR("MY2Flac exporter is not yet designed to be used alone; sorry.");
	die;
	
	# shortcut to the target dataSource (this exporter is a single/simple dataSource exporter)
	$self->dataSource($albumFile->dataSource('MY'));
	
	# TODO: check for the need of using a "PATH parameter", shouldn't be needed as it's done earlier in
	# caller, the exporter is currently designed to be called from the working directory
	 
	# read basic files tag and directory structure for guessing correct trakc and disc structure and ordering
	$self->readFlacFilesFromCurrentDir();
	
	# Check if guessed or read in tags tracknum/discnum is correct
	if($self->checkTrackAndDiscCoherency() == 0 ) {
		# TODO: don't die and try later to guess work/track association from performance and average work length
		WARN("Track and Disc failed between flac files and AMG DataSource");
		die; # won't die when guessing algorithm between works and tracks is written
	}

	# Backup original tags if there are ones
	$self->backupTags();
	
	# now, we can read tag from dataSource
	$self->generateTags();
	
	$self->writeTags();
	# return It
}

sub generateTags{
	my $self = shift or return undef;
#my @tagNames=(
#		'ALBUM',
#		'AMGGENRE',
#		'AMGWORKTYPE',
#		'ARTIST',
#		'ARTISTSORT',
#		'CATNUM',
#		'CHOIR',
#		'CHOIRSORT',
#		'COMPOSER',
#		'COMPOSERSORT',
#		'CONDUCTOR',
#		'CONDUCTORSORT',
#		'DISC',
#		'DISCC',
#		'GENRE',
#		'INSTRUMENTIST',
#		'INSTRUMENTISTSORT',
#		'LABEL',
#		'MDATAGGED',	
#		'ORCHESTRA',
#		'ORCHESTRASORT',
#		'ORIGYEAR',
#		'PERIOD',
#		'RECYEAR',
#		'SINGER',
#		'SINGERSORT',
#		'TITLE',
#		'TRACKNUMBER',
#		'WORK',
#		'YEAR');
	# Look for an album year
	my $albumName			= $self->guessAlbumName();
	my $year						= $self->guessAlbumYear();
	my $discc 					= $self->guessDiscCount;
	my $label 					= $self->guessLabel();
	my $catNum 				= $self->guessAlbumCatNum();
	my $albumGenre 			= $self->guessAlbumGenre();
	my $albumPeriod 		= $self->guessAlbumPeriod();
	my $albumWorkName 	= $self->guessAlbumWorkName();
	my $albumRecYear 		= $self->guessAlbumRecYear();
	my $albumOrigYear 	= $self->guessAlbumOrigYear();
	my $albumComposerName	= $self->guessAlbumComposerName();
	my $albumCatalogNumber	= $self->guessAlbumCatalogNumber();


	# Featured Artist became ARTIST tag so we can browse by this name even in "not classical browsing"
	my $albumFeaturedArtist = $self->dataSource->album->findCredits( { 'role' => 'Featured Artist'} );

	#TODO: Add Genre and Role Handling at album level!	
	TRACK:  # for each found track (each media file)
	foreach my $track (@{$self->foundFilesArray()}) {
		
		my $discName = $self->guessDiscName($track->{guessedDiscNum});
		
		# HANDLING ALBUM WIDE INFORMATION
		##########################
		if(defined($year)) 				{ $track->{tags}->{YEAR}=$year; }
		if(defined($label)) 				{ $track->{tags}->{LABEL}=$label; }
		if(defined($albumName)) 	{ $track->{tags}->{ALBUM}=$albumName; }
		if(defined($discName)) 		{ $track->{tags}->{ALBUM}=$discName; } # discName has priority over albumName
		if(defined($albumGenre))	{ $track->{tags}->{GENRE}=$albumGenre; }
		if(defined($albumPeriod))	{ $track->{tags}->{PERIOD}=$albumPeriod; }
		if(defined($albumRecYear))			{ $track->{tags}->{RECYEAR}=$albumWorkName; }
		if(defined($albumOrigYear))			{ $track->{tags}->{ORIGYEAR}=$albumOrigYear; }
		if(defined($albumWorkName))		{ $track->{tags}->{WORK}=$albumWorkName; }
		if(defined($albumCatalogNumber))	{ $track->{tags}->{WORK}=$albumCatalogNumber; }
		if(defined($discc) and $discc > 1 )	{ $track->{tags}->{DISCC}=$discc; }
		if(defined($albumComposerName))	{ 
			$track->{tags}->{COMPOSER}=$albumComposerName; 
			$track->{tags}->{COMPOSERSORT} = $self->createSortField($albumComposerName);
		}

		#Try to generate the ClXX tag
		# Classique 19ème
		if(defined($track->{tags}->{ORIGYEAR})) {
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{GENRE}, "Classique ".(substr($track->{tags}->{ORIGYEAR}, 0, -2)+1).'ème');
		}
		# if there's an album period, I want it to be in the genre also
		if(defined($albumPeriod)) {
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{GENRE},$albumPeriod);
		}
		$track->{tags}->{TRACKNUMBER} = $track->{guessedTrackNum};
		if(defined($discc) and $discc > 1 ) {	 
			$track->{tags}->{DISC} = $track->{guessedDiscNum};
		}
		
		# for each role in album level
		foreach my $roleObject ($self->findAlbumCredits) {
			$self->fillTrackCreditsTagFromRoleObject($track, $roleObject);
		} 
		
		# Featured Artist became ARTIST tag so we can browse by this name even in "not classical browsing"
		if(ref($albumFeaturedArtist)) {
			my $name= $albumFeaturedArtist->name;
			unless( $self->isItemInTag($name,  $track->{tags}->{ARTIST}) ) { 
				$self->addItemToMultiItemsTagRef(\$track->{tags}->{ARTIST}, $name);
				my $sortName = $name;
				# TODO: create a "generateSortName" method that looks for exceptions
				# don't invert sort name if featured artist is an orchestra or ensemble
				unless($self->isItemInTag($name, $track->{tags}->{ORCHESTRA})) {
					$sortName=$self->createSortField($sortName);
				}
				$self->addItemToMultiItemsTagRef(\$track->{tags}->{ARTISTSORT},$sortName);
			}
		}
		

		# try to get the current track in the dataSource
		my $dsTrack = $self->getDsTrack($track->{guessedDiscNum}, $track->{guessedTrackNum});
						
		# if this track (discindex-trackindex) doesn't exist in the dataSource
		unless(defined($dsTrack)) {
			next TRACK; #  we can continue to the other track 
		}

		# BEGIN TRACK WIDE INFORMATION
		#######################
		my $trackOrigYear = $self->guessTrackOrigYear($dsTrack);
		my $trackRecYear = $self->guessTrackRecYear($dsTrack);

		if(defined($dsTrack->name)) {  $track->{tags}->{TITLE} = $dsTrack->name; }
		if(defined($dsTrack->work->name)) {  $track->{tags}->{WORK} = $dsTrack->work->name; }
		if(defined($dsTrack->work->composer->name)) {  
			$track->{tags}->{COMPOSER} = $dsTrack->work->composer->name;
			$track->{tags}->{COMPOSERSORT} = $self->createSortField($dsTrack->work->composer->name); 
		}
		if(defined($trackOrigYear)) {  $track->{tags}->{ORIGYEAR} = $trackOrigYear; }
		if(defined($trackRecYear)) {  $track->{tags}->{RECYEAR} = $trackRecYear; }
		
		# Begin Track CREDITS stuff
		# for each role, try to find the tag to add it (composer, orchestra, instrumentist, etc).
		foreach my $roleObject (@{$dsTrack->performance->credits}) {
			$self->fillTrackCreditsTagFromRoleObject($track, $roleObject);
		} 

		# Begin TAGS and GENRE Stuff
		# TODO: support multiple GENRES in MY tags !!! (see guessTrackGenre)
		
		my $trackGenre = $self->guessTrackGenre($dsTrack);
		if(defined($trackGenre)) {
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{GENRE}, $trackGenre);
		}

		my $trackPeriod = $self->guessTrackPeriod($dsTrack);
		if(defined($trackPeriod)) {
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{GENRE}, $trackPeriod);
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{PERIOD}, $trackPeriod);
		}
		
		$self->addItemToMultiItemsTagRef(\$track->{tags}->{GENRE}, 'Classique');

		#Try to generate the ClXX tag
		# Classique 19ème
		if(defined($track->{tags}->{ORIGYEAR})) {
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{GENRE}, "Classique ".(substr($track->{tags}->{ORIGYEAR}, 0, -2)+1).'ème');
		}

	}	continue {
		if(defined($track->{tags}->{ORCHESTRA} )) { $track->{tags}->{BAND} = $track->{tags}->{ORCHESTRA}; }
		if(defined($track->{tags}->{TITLE} )) { $track->{tags}->{OPUS} = $self->guessCatalogAndOpusFromString($track->{tags}->{TITLE}); }
	}
}

# the track that contains the tag we want to fill and the role object to analyze
sub fillTrackCreditsTagFromRoleObject {
	my $self = shift or return undef;
	my $track = shift or return undef;	
	my $roleObject = shift or return undef;	
	
	ROLENAME:
	foreach my $roleName (split(',', $roleObject->role)) {
		$roleName = Tools::trim($roleName);
		# Instrumentists roles	
		if( exists $instrumentistRoles{$roleName} ) {
			my $name= $roleObject->name;
			if( $self->isItemInTag($name,  $track->{tags}->{INSTRUMENTIST}) ) { next ROLENAME; }
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{INSTRUMENTIST}, $roleObject->name);
			my $sortName = $roleObject->name;
			$sortName=$self->createSortField($sortName);
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{INSTRUMENTISTSORT}, $sortName);
		# Conductor roles	
		} elsif( exists $conductorRoles{$roleName} ) {
			my $name= $roleObject->name;
			if( $track->{tags}->{CONDUCTOR} =~ /$name/ ) { next ROLENAME; }
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{CONDUCTOR},$roleObject->name);
			my $sortName = $roleObject->name;
			$sortName=$self->createSortField($sortName);
#			unless($sortName =~ m/,/) { 
#				$sortName =~ s/^(.*)[\s]+([\w]*)$/$2, $1/g;
#			}
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{CONDUCTORSORT}, $sortName);
		# Singer roles	
		} elsif( exists $singerRoles{$roleName} ) {
			my $name= $roleObject->name;
			if( $self->isItemInTag($name, $track->{tags}->{SINGER}) ) { next ROLENAME; }
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{SINGER}, $roleObject->name);
			my $sortName = $roleObject->name;
			$sortName=$self->createSortField($sortName);
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{SINGERSORT},$sortName);
		# Choir roles	
		} elsif( exists $choirRoles{$roleName} ) {
			my $name= $roleObject->name;
			if( $self->isItemInTag($name, $track->{tags}->{CHOIR}) )	{ next ROLENAME; }
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{CHOIR}, $roleObject->name);
			my $sortName = $roleObject->name;
			# TODO: remove prefix for correct ordering, nothing done now in choir sorting field
			#$name =~ s/^(.*)[\s]+([\w]*)$/$2, $1/g;
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{CHOIRSORT}, $sortName);
		# Orchestra  roles	
		} elsif( exists $orchestraRoles{$roleName} ) {
			my $name= $roleObject->name;
			if($self->isItemInTag($name, $track->{tags}->{ORCHESTRA})) { next ROLENAME; }
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{ORCHESTRA}, $roleObject->name);
			my $sortName = $roleObject->name;
			# TODO: remove prefix for correct ordering, nothing done now in orchestra sorting field
			#$name =~ s/^(.*)[\s]+([\w]*)$/$2, $1/g;
			$self->addItemToMultiItemsTagRef(\$track->{tags}->{ORCHESTRASORT}, $sortName);
		# Ignored  roles	
		} elsif( exists $ignoreRoles{$roleName} ) {
			DEBUG("Ignoring ".$roleObject->name." (".$roleName.")");
		} else {
			ERROR("Unknown ".$roleObject->name." (".$roleName.")");
			print Dumper \%instrumentistRoles; die;
		}
	}
}
sub getDsTrack{
	my $self = shift or return undef;
	my $discNumber = shift or return undef;
	my $trackNumber = shift or return undef;
	#printf("Looking for cd $discNumber    tr $trackNumber\n");
	if( exists($self->dataSource->album->discs->[$discNumber-1]) 
		and ref($self->dataSource->album->discs->[$discNumber-1]) 
		and exists($self->dataSource->album->discs->[$discNumber-1]->tracks->[$trackNumber-1])
		and ref($self->dataSource->album->discs->[$discNumber-1]->tracks->[$trackNumber-1]) ) 
	{
		return($self->dataSource->album->discs->[$discNumber-1]->tracks->[$trackNumber-1]);
	}
	return undef;	
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


sub guessAlbumCatalogNumber{
	my $self = shift or return undef;
	
	if( ref($self->dataSource->album) 
		and defined($self->dataSource->album->catalogNumber()) 
		) { 
		# return it
		return $self->dataSource->album->catalogNumber();
	}
	return undef;
}

sub guessAlbumComposerName{
	my $self = shift or return undef;
	
	if( exists($self->dataSource->album->composers->[0]) 
		and ref($self->dataSource->album->composers->[0]) 
		and scalar(@{$self->dataSource->album->composers} == 1)
		and defined($self->dataSource->album->composers->[0]->name()) 
		) { 
		# return it
		return $self->dataSource->album->composers->[0]->name();
	}
	return undef;
}

sub guessAlbumWorkName{
	my $self = shift or return undef;
	
	if( exists($self->dataSource->album->works->[0]) 
		and ref($self->dataSource->album->works->[0]) 
		and scalar(@{$self->dataSource->album->works} == 1)
		and defined($self->dataSource->album->works->[0]->name()) 
		) { 
		# return it
		return $self->dataSource->album->works->[0]->name();
	}
	return undef;
}

sub guessAlbumRecYear{
	my $self = shift or return undef;
	
	if( exists($self->dataSource->album->performances->[0]) 
		and ref($self->dataSource->album->performances->[0]) 
		and scalar(@{$self->dataSource->album->performances} == 1)
		and ref($self->dataSource->album->performances->[0]->date)
		and scalar(@{$self->dataSource->album->performances->[0]->date->normalized}) > 0
		) { 
		# return it
		return $self->dataSource->album->performances->[0]->date->meanYear;
	}
	return undef;
}

sub findAlbumCredits{
	my $self = shift or return undef;
	
	if( exists($self->dataSource->album->performances->[0]) 
		and ref($self->dataSource->album->performances->[0]) 
		and defined($self->dataSource->album->performances->[0]->credits)
		and scalar(@{$self->dataSource->album->performances->[0]->credits}> 0)
		) { 
		# return it
		return $self->dataSource->album->performances->[0]->credits;
	}
	return undef;
}

sub guessAlbumOrigYear{
	my $self = shift or return undef;

	if( exists($self->dataSource->album->works->[0]) 
		and ref($self->dataSource->album->works->[0]) 
		and scalar(@{$self->dataSource->album->works} == 1)
		and ref($self->dataSource->album->works->[0]->composed)
		and ref($self->dataSource->album->works->[0]->composed->date)
		and scalar(@{$self->dataSource->album->works->[0]->composed->date->normalized}) > 0
		) { 
		# return it
		return $self->dataSource->album->works->[0]->composed->date->meanYear;
	}
	return undef;
}

sub guessTrackPeriod{
	my $self = shift or return undef;
	my $dsTrack = shift or return undef;

	# if there's only one work and this work has a period defined
	if( defined($dsTrack->work)  
		and ref($dsTrack->work) 
		and defined($dsTrack->work->period)
		) {
		# return it
		return $dsTrack->work->period;
	}
	
	# if there's only one composer and this composer has a period tag
	if( defined( $dsTrack->work->composer ) and ref( $dsTrack->work->composer) ) {
		my @foundPeriodTags = $dsTrack->work->composer->findTags('name', 'Period' );
		if(scalar(@foundPeriodTags)==1) {
			my $tag = $foundPeriodTags[0];
			unless( defined($tag->value) ) {
				ERROR("Composer Period tag without a value!");
				die;
			} 
			# found a period in composer, return it; 
			return $tag->value;
		}elsif(scalar(@foundPeriodTags)==0) {
			DEBUG("Ignoring Composer without Period tag");
		}else {
			ERROR(" Composer Period tag isn't multi valued, this shouldn't happen!");
			die;
		}
	}
	# if there is a release Date
	my @foundPeriodTags =$dsTrack->work->findTags('name', 'Period');
	my @periodNames;
	foreach my $tag (@foundPeriodTags) {
# TODO: try not to add duplicate genre
		push @periodNames, $tag->value;
	}
	if(scalar(@periodNames) > 0 ) {
		return join ';', @periodNames;
	}
	# TODO: could guess period from dates, but it shouldn't be done in MY tag generato
	# it would fit better in the final tag exporter if no period have been found in any DS
	return undef;
}

sub guessTrackGenre{
	my $self = shift or return undef;
	my $dsTrack = shift or return undef;

	# if there is genre tags
	my @foundGenreTags =$dsTrack->work->findTags('name', 'Genre');
	my @genreNames;
	foreach my $tag (@foundGenreTags) {
# TODO: try not to add duplicate genre
		push @genreNames, $tag->value;
	}
	return join ';', @genreNames;
}

sub guessTrackOrigYear{
	my $self = shift or return undef;
	my $dsTrack = shift or return undef;
	
	if( defined($dsTrack->work) 
		and ref($dsTrack->work) 
		and ref($dsTrack->work->composed)
		and ref($dsTrack->work->composed->date)
		and scalar(@{$dsTrack->work->composed->date->normalized}) > 0
		) { 
		# return it
		return $dsTrack->work->composed->date->meanYear;
	}
	return undef;
}

sub guessTrackRecYear{
	my $self = shift or return undef;
	my $dsTrack = shift or return undef;
	
	if( defined($dsTrack->performance) 
		and ref($dsTrack->performance) 
		and ref($dsTrack->performance->date)
		and scalar(@{$dsTrack->performance->date->normalized}) > 0
		) { 
		# return it
		return $dsTrack->performance->date->meanYear;
	}
	return undef;
}

# Album Year is either (in order of priority):
# - the album release date
# - the max of performance record date (if there's at least one performance record date)
sub guessAlbumYear{
	my $self = shift or return undef;

	# if there is a release Date
	if( exists($self->dataSource->album->releases->[0]) 
		and ref($self->dataSource->album->releases->[0]) 
		and scalar(@{$self->dataSource->album->releases->[0]->date()->normalized})>0 ) { 
		# return it
		return int($self->dataSource->album->releases->[0]->date->meanYear);
	}
	return undef;
}

sub guessLabel{
	my $self = shift or return undef;

	# if there is a release Date
	if( ref($self->dataSource->album->label) 
		and defined($self->dataSource->album->label->name) ) { 
		# return it
		return $self->dataSource->album->label->name;
	}
	# else return undef
	return undef;
}

sub guessAlbumCatNum{
	my $self = shift or return undef;

	# if there is a release Date
	if( ref($self->dataSource->album) 
		and defined($self->dataSource->album->catalogNumber) ) { 
		# return it
		return $self->dataSource->album->label->name;
	}
	# else return undef
	return undef;
}

sub guessAlbumGenre{
	my $self = shift or return undef;

	my $genreTag;
	
	# if there is a genre tag in album tags
	if( defined($self->dataSource->album->tags) 
		and scalar(@{$self->dataSource->album->tags} > 0 )
	){ 	
		my @foundGenreTags = $self->dataSource->album->findTags('name', 'Genre');
		my @genreNames;
		foreach my $tag (@foundGenreTags) {
	# TODO: try not to add duplicate genre
			$self->addItemToMultiItemsTagRef( \$genreTag, $tag->value);
		}
	}
	#die $self->dataSource->album->works->[0];
	# if there's only one work and this work has a period defined
	if( exists($self->dataSource->album->works->[0]) 
		and ref($self->dataSource->album->works->[0]) 
		and scalar(@{$self->dataSource->album->works}) == 1
		and defined($self->dataSource->album->works->[0]->tags) 
		and scalar(@{$self->dataSource->album->works->[0]->tags}) > 0 )  
	{
		# return it
		my @foundGenreTags = $self->dataSource->album->works->[0]->findTags('name', 'Genre');
		my @genreNames;
		foreach my $tag (@foundGenreTags) {
	# TODO: try not to add duplicate genre
			$self->addItemToMultiItemsTagRef( \$genreTag, $tag->value);
		}
	}
	return $genreTag;
}

sub guessAlbumPeriod{
	my $self = shift or return undef;

	# if there's a period tag in album tags
	if( defined( $self->dataSource->album->tags )  ) {
		my @foundPeriodTags = $self->dataSource->album->findTags('name', 'Period' );
		if(scalar(@foundPeriodTags)==1) {
			my $tag = $foundPeriodTags[0];
			unless( defined($tag->value) ) {
				ERROR("Composer Period tag without a value!");
				die;
			} 
			# found a period in composer, return it; 
			return $tag->value;
		}elsif(scalar(@foundPeriodTags)==0) {
			WARN("Ignoring empty Composer Period tag value")
		}else {
			ERROR(" Composer Period tag isn't multi valued, this shouldn't happen!");
			die;
		}
	}
	
	# if there's only one work and this work has a period defined
	if( exists($self->dataSource->album->works->[0]) 
		and ref($self->dataSource->album->works->[0]) 
		and scalar(@{$self->dataSource->album->works} == 1)
		and defined($self->dataSource->album->works->[0]->period)
		) { 
		# return it
		return $self->dataSource->album->works->[0]->period;
	}
	
	# if there's only one composer and this composer has a period tag
	if( exists( $self->dataSource->composers->[0] ) and ref( $self->dataSource->composers->[0]) ) {
		my @foundPeriodTags = $self->dataSource->composers->[0]->findTags('name', 'Period' );
		if(scalar(@foundPeriodTags)==1) {
			my $tag = $foundPeriodTags[0];
			unless( defined($tag->value) ) {
				ERROR("Composer Period tag without a value!");
				die;
			} 
			# found a period in composer, return it; 
			return $tag->value;
		}elsif(scalar(@foundPeriodTags)==0) {
			WARN("Ignoring empty Composer Period tag value")
		}else {
			ERROR(" Composer Period tag isn't multi valued, this shouldn't happen!");
			die;
		}
	}
	
	# TODO: could guess period from dates, but it shouldn't be done in MY tag generato
	# it would fit better in the final tag exporter if no period have been found in any DS
	return undef;
}

sub guessDiscCount{
	my $self = shift or return undef;

	if(defined($self->dataSource->album->numberOfDiscs)) {
		return $self->dataSource->album->numberOfDiscs;
	}
	return undef;
}

sub guessDiscName{
	my $self = shift or return undef;
	my $discIndex = shift or return undef;

	if(exists($self->dataSource->album->discs->[$discIndex-1]) and defined($self->dataSource->album->discs->[$discIndex-1]->name) ) {
		return $self->dataSource->album->discs->[$discIndex-1]->name();
	}
	return undef;
}

sub guessAlbumName{
	my $self = shift or return undef;

	if(defined($self->dataSource->album->name())) {
		return $self->dataSource->album->name();
	}
	return undef;
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

# Verify that all guessedDiscNum and guessedTrackNum correspond to the data contained in AMGDataSource
sub checkTrackAndDiscCoherency {
	my $self = shift or return undef;
	
	# simple consistency check of dataSource
	unless(defined ($self->dataSource->album->numberOfDiscs) and ref($self->dataSource->album->discs()) eq 'ARRAY') {
		ERROR("No disc or track information in AMG DataSource");
		return 0;
	}
	
	# further consistency check (should have been done during retrieve action)
	unless( $self->dataSource->album->numberOfDiscs == scalar(@{$self->dataSource->album->discs()}) ) {
		ERROR("Consistency check failes, AMG numberOfDiscs attribute and Album->Discs count differs");
		die;	
	}
	
	# Check the number of discs
	unless($self->dataSource->album->numberOfDiscs == scalar(keys %{$self->filesInDirHash()}  ) ) {
		ERROR("Number of discs mismatch between AMG DataSource and number of discs found in directory structure");
		return 0;
	}

	# Check the number of tracks between each discs
	foreach my $discPath (sort keys %{$self->filesInDirHash()}) {
		# take the first file disc number
		my $currentDiscNumber = $self->filesInDirHash()->{$discPath}->[0]->{guessedDiscNum};
		# take the number of track files found for this given disc
		my $currentDiscTrackCount = scalar(@{$self->filesInDirHash()->{$discPath}});
		# if the file track count in the given disc is not the same as the track count found in AMG DataSource
		unless($currentDiscTrackCount == scalar(@{$self->dataSource->album->discs->[$currentDiscNumber-1]->tracks()}) ) {
			ERROR("Wrong number of tracks found for disc number $currentDiscNumber, waiting ".scalar(@{$self->dataSource->album->discs->[$currentDiscNumber-1]->tracks()})." but found $currentDiscTrackCount");
			return 0;
		}
	}
	return 1;
}


END { }    # module clean-up code here (global destructor)
1;