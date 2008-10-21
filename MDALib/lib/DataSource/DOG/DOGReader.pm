#!/usr/bin/perl -w

package DataSource::DOG::DOGReader;

use base qw( DataFile::DataSource );

use strict;
use utf8;

use Tools;

use Data::Dumper;
use XML::Simple;
use Log::Log4perl qw(:easy);

our $dogDomain = 'www.discogs.com';
our $dogKey = 'd342f3094c';
our $DataSourceName = 'DOG';
our $DataSourceVer = '0.1';
our $providerName ='Discogs';
our $providerUrl ='http://www.discogs.com';

#search query
# http://www.discogs.com/search?type=<type>&q=<querystring>&f=xml&api_key=<api_key>
# type = all|releases|artists|labels|pending|catno|forsale

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

	}
	return $dataSource;
}
# Stub for standardized api
sub readFromUrl {
	my $self = shift;
	die("GENERIC METHOD TO OVERLOAD");
	unless(defined($self)) {
		ERROR("Query not called in object context");
		die;
	}
	
	$self->_readClassicalAlbumPageFromUrl(@_);
}

# Stub for standardized api
sub readFromId {
	my $self = shift;
	my $id = shift;
	unless(defined($self)) {
		ERROR("Query not called in object context");
		die;
	}
	unless(defined($id)) {
		ERROR("Missing Id parameter");
		die;
	}
	$self->_readReleaseFromId($id);
}

sub _readReleaseFromId {
	my $self = shift;
	my $id = shift;
	unless(defined($self)) {
		ERROR("Query not called in object context");
		die;
	}
	unless(defined($id)) {
		ERROR("Missing Id parameter");
		die;
	}
	my $content = $self->query('release/'.Tools::URLEncode($id),1);
	$self->album->relativeUrl('release/'.Tools::URLEncode($id));
	$self->album->baseUrl($self->providerUrl());
	$self->album->url($self->album->baseUrl().'/'.$self->album->relativeUrl());
	$self->album->id($id );
	$self->_parseReleaseXML($content);
}

sub _parseReleaseXML{
	my $self = shift;
	my $content = shift;
	unless(defined($self)) {
		ERROR("Query not called in object context");
		die;
	}
	unless(defined($content)) {
		ERROR("Missing content parameter");
		die;
	}
	unless(exists($content->{release})) {
		ERROR("Missing release content");
		die;
	}
	my $dogRelease = $content->{release};
	
	if(exists($dogRelease->{id}) and defined($dogRelease->{id}) ) {
		$self->album->id($dogRelease->{id});
	}

	if(exists($dogRelease->{title}) and defined($dogRelease->{title}) ) {
		$self->album->name($dogRelease->{title});
	}
	
	if(exists($dogRelease->{notes}) and defined($dogRelease->{notes}) ) {
		$self->album->addNote(DataFile::Note->new({ text => $dogRelease->{notes} } ));
	}

	if(exists($dogRelease->{country}) and defined($dogRelease->{country})) {
		$self->album->origin->country($dogRelease->{country});
		$self->album->origin->rawData($dogRelease->{country});
	}
	
	if(defined($dogRelease->{genres}->{genre} and scalar(@{$dogRelease->{genres}->{genre}})>0) ) {
		foreach my $dogGenre (@{$dogRelease->{genres}->{genre}}) {
			$self->album->addTag(DataFile::Tag->new( {name => 'genre', value =>$dogGenre } ));
		}
	}
	
	if(defined($dogRelease->{styles}->{style} and scalar(@{$dogRelease->{styles}->{style}})>0) ) {
		foreach my $dogStyle (@{$dogRelease->{styles}->{style}}) {
			$self->album->addTag(DataFile::Tag->new( {name => 'style', value =>$dogStyle } ));
		}
	}
	
	if(defined($dogRelease->{images}->{image} and scalar(@{$dogRelease->{images}->{image}})>0) ) {
		foreach my $dogImage (@{$dogRelease->{images}->{image}}) {
			my $picture = DataFile::Picture->new();
			if(defined($dogImage->{uri})) {
				$picture->url($dogImage->{uri});
			}
			if(defined($dogImage->{width})) {
				$picture->width($dogImage->{width});
			}
			if(defined($dogImage->{height})) {
				$picture->height($dogImage->{height});
			}
			if(defined($dogImage->{uri150})) {
				$picture->thumbnail->width(150);
				$picture->thumbnail->url($dogImage->{uri150});
			}
			if(defined($dogImage->{type})) {
				$picture->type($dogImage->{type});
			}
			$self->album->addArtwork($picture);
		}
	}


# release, label and formats notes:
# one label and one format => one release with one forrmat
# several labels and one format => each release has the same format
# several labels and several formats => label number must match format number, each format is associated with a label in order of appearance 
	# begin with label/catno (each label+catno is a "release")

	if(defined($dogRelease->{labels}->{label}) and scalar(@{$dogRelease->{labels}->{label}})>0 ) {
		foreach my $dogLabel (@{$dogRelease->{labels}->{label}}) {
			my $release=DataFile::Release->new();
			if(defined($dogLabel->{name})) {
				$release->label->name($dogLabel->{name});
			}
			if(defined($dogLabel->{catno})) {
				$release->catalogNumber($dogLabel->{catno});
			}
			$self->album->addRelease($release);
		}
	}else {
		my $release=DataFile::Release->new();
		$release->label->name('Unknown Label');
		$release->catalogNumber('No Catalog Number');
		$self->album->addRelease($release);
		WARN("DOG Release has no label!");
	}
	
	#release are filled in MDA objects, try to associate mda release with each dog format found
	# if there is at least one format object returned by DOG
	if(defined($dogRelease->{formats}->{format}) and scalar(@{$dogRelease->{formats}->{format}})>0 ) {
		# if there's only one DOG format, associate it with each DOG release previously found and set in MDA objects
		if( scalar(@{$dogRelease->{formats}->{format}}) == 1 ) { # only one DOG format
			my $dogFormat = $dogRelease->{formats}->{format}->[0];
			foreach my $mdaRelease (@{$self->album->releases}) { # for each MDA release
				if(defined($dogFormat->{name})) {
					$mdaRelease->mediaType($dogFormat->{name});
				}
				if(defined($dogFormat->{qty})) {
					$mdaRelease->numberOfMedia($dogFormat->{qty});
				}
				if(defined($dogFormat->{descriptions}->{description} and scalar(@{$dogFormat->{descriptions}->{description}})>0) ) {
					foreach my $dogDescription ($dogFormat->{descriptions}->{description}) {
						$mdaRelease->addTag(DataFile::Tag->new( {name =>'description', value=>$dogDescription}) );
					}
				}
			}
		# if there's more than one DOG format and the number of DOG format is the same as the number
		# of DOG label+catnum, assume each format has to be associated to the corresponding label+catnum
		} elsif( scalar(@{$dogRelease->{formats}->{format}}) == scalar(@{$self->album->releases}) ) {
			my $index=0;
			foreach my $mdaRelease (@{$self->album->releases}) { # for each MDA release
				my $dogFormat = $dogRelease->{formats}->{format}->[$index];
				if(defined($dogFormat->{name})) {
					$mdaRelease->mediaType($dogFormat->{name});
				}
				if(defined($dogFormat->{qty})) {
					$mdaRelease->numberOfMedia($dogFormat->{qty});
				}
				if(defined($dogFormat->{descriptions}->{description} and scalar(@{$dogFormat->{descriptions}->{description}})>0) ) {
					foreach my $dogDescription ($dogFormat->{descriptions}->{description}) {
						$mdaRelease->addTag(DataFile::Tag->new( {name =>'description', value=>$dogDescription}) );
					}
				}
				$index++;
			}
		}else {
			ERROR("DOG has ".scalar(@{$dogRelease->{formats}->{format}}) ." formats and ".scalar(@{$self->album->releases})." release, don't know how to associate release with format");
			die;
		}
	}

	# Releases objects are now correctly filled, try to handle date by assigning DOG Release Date to each 
	# release found (or create a new release for it if there is none)
	if(defined($dogRelease->{released}) and length($dogRelease->{released})>0 ) { # if there's a release date in DOG
	
		unless(scalar(@{$self->album->releases})>0) { # if there's no release in MDA object, 
			$self->album->addRelease(DataFile::Release->new()); #create an empty one only for holding releaseDate
		}
		
		foreach my $mdaRelease (@{$self->album->releases}) { # for each MDA release
			$mdaRelease->date->rawData($dogRelease->{released});
			$mdaRelease->date->normalizeAndSetDate();
		}
	}
# track position in DOG
# A1 A2 A3 B1 B2 B3 C
# 1.1 1.2 1.3 2.1 2.2 2.3 3
# B2-i B2-ii B2-iii  B2-iv
	
	# TRACK
	if(defined($dogRelease->{tracklist}->{track}) and scalar(@{$dogRelease->{tracklist}->{track}})>0 ) {
		my $work;
		my $index=0;
		my $usingDiskAndTrack;
		my $track;
		foreach my $dogTrack (@{$dogRelease->{tracklist}->{track}}) {
			# if there's a position filled in the current DOG Track
			if(exists($dogTrack->{position}) and defined($dogTrack->{position}) and not ref($dogTrack->{position})) { # empty position is an empty hash ref
				my($discIndex, $trackIndex) = $dogTrack->{position} =~ m/[^\d]*(\d+)[^\d]+(\d+)[^\d]*/g;
				 $track=DataFile::Track->new();
				if(defined($discIndex) and defined($trackIndex)) {
					$usingDiskAndTrack=1;
					$track->index($trackIndex);
					unless(exists($self->album->discs->[$discIndex-1]) and ref($self->album->discs->[$discIndex-1]) eq 'DataFile::Disc') {
						$self->album->discs->[$discIndex-1]=DataFile::Disc->new();
						$self->album->discs->[$discIndex-1]->index($discIndex);
						$self->album->discs->[$discIndex-1]->id('disc-'.$dogRelease->{id}.'-'.$discIndex);
					}
					unless(exists($self->album->discs->[$discIndex-1]->tracks->[$trackIndex-1]) and ref($self->album->discs->[$discIndex-1]->tracks->[$trackIndex-1]) eq 'DataFile::Track') {
						$self->album->discs->[$discIndex-1]->tracks->[$trackIndex-1] = $track;
					}
				}else { # not able to find a cd01.03 or 1.3 pattern: use simple position index
					if(defined($usingDiskAndTrack)) {
						ERROR("Disc and Track position pattern found for some tracks but not for all ". Dumper($dogTrack));
						die;
					}
					$index++;
					$track->index($index);
					unless(exists($self->album->discs->[0]) and ref($self->album->discs->[0]) eq 'DataFile::Disc') {
						$self->album->discs->[0]=DataFile::Disc->new();
						$self->album->discs->[0]->index(1);
						$self->album->discs->[0]->id('disc-'.$dogRelease->{id}.'-'.1);
					}
					$self->album->discs->[0]->addTrack($track);
				}
				if(defined($work)) {
					$track->work( DataFile::Work->new({linkTo => $work}) );
				}
				$track->rawIndex($dogTrack->{position});
				$track->name($dogTrack->{title});
				# if there's a duration
				if(exists($dogTrack->{duration}) and defined($dogTrack->{duration}) and not ref($dogTrack->{duration})) { # empty duration is an empty hash ref
					$track->length->rawData($dogTrack->{duration});
					$track->length->extractSecondsFromRawDataMMSS();
				}  # if POSITION is defined but empty in the DOG Track (it might be an index track)
			}elsif( exists($dogTrack->{position}) and defined($dogTrack->{position}) and ref($dogTrack->{position}) eq 'HASH' and scalar(keys(%{$dogTrack->{position}}))==0  ) {
			# position is an empty hash ref, it's an empty position in DOG
				if( (not exists($dogTrack->{title})) or length($dogTrack->{title})<1 ) { # if the track doesn't have the characteristics of a track index.
					ERROR("Unexpected DOG track object, looks like a trackindex with no title: ". Dumper($dogTrack));
					die;					
				}
				if( Tools::trim($dogTrack) ->{title} eq '-' ) { # it's the end of a DOG "track index" set
					undef($work);
				} else {
					# if we have a DOG "track index"", it has to be handled like a work in MDA object structure
					$work = DataFile::Work->new();
					$work->name($dogTrack->{title});
					$work->id('work-'.$dogRelease->{id}.'-'.scalar(@{$self->album->works}));
					$self->album->addWork($work);
				}
			}else {
				ERROR("Unexpected DOG track object position: ". Dumper($dogTrack));
				die;
			}
#	<track>
#		<position>7</position>
#		<artists>
#			<artist>
#				<name>Plan, The</name>
#				<anv>Plan</anv>
#			</artist>
#		</artists>
#		<title>Red Shift</title>
#		<extraartists>
#			<artist>
#				<name>Cem Salman</name>
#				<anv>M. Salman</anv>
#				<role>Producer, Other [Artistic Direction]</role>
#			</artist>
#		</extraartists>
#		<duration/>
#	</track>
			#TRACK ARTISTS
			if(defined($dogTrack->{artists}->{artist}) and scalar(@{$dogTrack->{artists}->{artist}})>0 ) {
				# for each artist in DOG track
				foreach my $dogTrackArtist (@{$dogTrack->{artists}->{artist}}) {
					my $credit =  DataFile::Credit->new();

					# NAME get the artist name 
					if(exists($dogTrackArtist->{name})) {
						$credit->name(Tools::trim($dogTrackArtist->{name}));
					} else {
						ERROR("DOG Artist without a name, this shouldn't happen!");
						die;
					}
					# ANV get the artist alias
					if(exists($dogTrackArtist->{anv})) {
						# artist alias shouldn't be an array, check it
						if(defined($dogTrackArtist->{anv}) and ref($dogTrackArtist->{anv}) eq 'ARRAY') {
							ERROR("DOG artist alias is an array where single value is expected!");
							die;
						}elsif(defined($dogTrackArtist->{anv})) {
							$credit->addAlias($dogTrackArtist->{anv});
						}else {
							ERROR("DOG artist alias exists but it's undefined!");
							die;
						}
					}
					$credit->role('ARTIST');
					$track->performance->addCredit($credit);
				}
			}
			#TRACK EXTRAARTISTS
			if(defined($dogTrack->{extraartists}->{artist}) and scalar(@{$dogTrack->{extraartists}->{artist}})>0 ) {
				# for each artist in DOG track
				foreach my $dogTrackArtist (@{$dogTrack->{extraartists}->{artist}}) {
					unless(exists($dogTrackArtist->{role}) and defined($dogTrackArtist->{role})) {
						ERROR("Extra artist found but role isn't defined, this shouldn't happen");
						die;
					}				
					foreach my $role (split( /,/,  $dogTrackArtist->{role}) ) {	
						my $credit =  DataFile::Credit->new();
						# NAME get the artist name 
						if(exists($dogTrackArtist->{name})) {
							$credit->name(Tools::trim($dogTrackArtist->{name}));
						} else {
							ERROR("DOG Artist without a name, this shouldn't happen!");
							die;
						}
						# ANV get the artist alias
						if(exists($dogTrackArtist->{anv})) {
							# artist alias shouldn't be an array, check it
							if(defined($dogTrackArtist->{anv}) and ref($dogTrackArtist->{anv}) eq 'ARRAY') {
								ERROR("DOG artist alias is an array where single value is expected!");
								die;
							}elsif(defined($dogTrackArtist->{anv})) {
								$credit->addAlias($dogTrackArtist->{anv});
							}else {
								ERROR("DOG artist alias exists but it's undefined!");
								die;
							}
						}
						$credit->role($role);
						$track->performance->addCredit($credit);
					}
				}
			}
		}
	}
	
	#ALBUM ARTISTS
	if(defined($dogRelease->{artists}->{artist}) and scalar(@{$dogRelease->{artists}->{artist}})>0 ) {
		# for each artist in DOG track
		foreach my $dogArtist (@{$dogRelease->{artists}->{artist}}) {
			my $credit =  DataFile::Credit->new();
			# NAME get the artist name 
			if(exists($dogArtist->{name})) {
				$credit->name(Tools::trim($dogArtist->{name}));
			} else {
				ERROR("DOG Artist without a name, this shouldn't happen!");
				die;
			}
			# ANV get the artist alias
			if(exists($dogArtist->{anv})) {
				# artist alias shouldn't be an array, check it
				if(defined($dogArtist->{anv}) and ref($dogArtist->{anv}) eq 'ARRAY') {
					ERROR("DOG artist alias is an array where single value is expected!");
					die;
				}elsif(defined($dogArtist->{anv})) {
					$credit->addAlias($dogArtist->{anv});
				}else {
					ERROR("DOG artist alias exists but it's undefined!");
					die;
				}
			}
			$credit->role('ARTIST');
			$self->album->addCredit($credit);
		}
	}
	#ALBUM EXTRAARTISTS
	if(defined($dogRelease->{extraartists}->{artist}) and scalar(@{$dogRelease->{extraartists}->{artist}})>0 ) {
		# for each artist in DOG track
		foreach my $dogArtist (@{$dogRelease->{extraartists}->{artist}}) {
			unless(exists($dogArtist->{role}) and defined($dogArtist->{role})) {
				ERROR("Extra artist found but role isn't defined, this shouldn't happen");
				die;
			}				
			foreach my $role (split( /,/,  $dogArtist->{role}) ) {	
				my $credit =  DataFile::Credit->new();
				# NAME get the artist name 
				if(exists($dogArtist->{name})) {
					$credit->name(Tools::trim($dogArtist->{name}));
				} else {
					ERROR("DOG Artist without a name, this shouldn't happen!");
					die;
				}
				# ANV get the artist alias
				if(exists($dogArtist->{anv})) {
					# artist alias shouldn't be an array, check it
					if(defined($dogArtist->{anv}) and ref($dogArtist->{anv}) eq 'ARRAY') {
						ERROR("DOG artist alias is an array where single value is expected!");
						die;
					}elsif(defined($dogArtist->{anv})) {
						$credit->addAlias($dogArtist->{anv});
					}else {
						ERROR("DOG artist alias exists but it's undefined!");
						die;
					}
				}
				$credit->role($role);
				# Handle credits which are not related to the whole album
				# Two or more tracks: A1, A3, B3, B4
				# Several adjacent tracks: A2 to A6
				# Mixed: A1, A3 to A5, A7 to B4, B8
				#	{
				#	'tracks' => '1, 4, 10',
				#	'name' => 'Ali Memedeov',
				#	'role' => 'Drums [Hand Drums]'
				#	},
				# if there's a track range in the credit, we have to find the good tracks to associate the credits with those tracks
				if(exists($dogArtist->{tracks})) {
					foreach my $trackOrTrackRange (split( /,/,  $dogArtist->{tracks}) ) { # for each track or track range found in tracks
						my $trackRangeBegin;
						my $trackRangeEnd;
						# try to find the begin and and of range if tracks element in in the forms <pos> to <pos>
						if($trackOrTrackRange =~ / *([^ ]) +to +([^ ]+) */ ) {
							$trackRangeBegin=$1;
							$trackRangeEnd=$2;
						}else { # else, consider a single track as a range with begin and end equals
							$trackRangeBegin = $trackRangeEnd = Tools::trim($trackOrTrackRange);
						}
						# as range from DOG are track positions and as positions are freeform (2.1, 2.2 or A1 B1, etc)
						# it's not possible to directly get the good track object and we must look for the begin of 
						# the range and stop at it's end by sweeping disc/track objects
						my $rangeBeginFound=undef;
						DISC: foreach my $disc (@{$self->album->discs}) {
							TRACK: foreach my $track (@{$disc->tracks}) {
								if($track->rawIndex() eq $trackRangeBegin) { # if we found the beginning of the range
									$rangeBeginFound=1; # set the boolean to validate credit adding to the following tracks
								}
								if($rangeBeginFound) { # if we're sweeping tracks that are in the trackRange
									$track->performance->addCredit($credit);
								}
								if($track->rawIndex() eq $trackRangeEnd) { # if it's the end of the range, no more sweeping is needed
									last DISC; # and we can start again with next trackOrTrackRange
									# TODO: possible problem if a track as several identical positions, 
									# if the problem is found, replace "last DISC;" by  "undef($rangeBeginFound);""
								}
							}
						}
					}
				}else { # artist is really an album wide credit, so don't do anything special, simply add the credit to the album
					$self->album->addCredit($credit);
				}
			}
		}
	}

			#TODO: Credits -artists, extraartists- (level)

#  ['image-', 'format-', 'artist', 'label-', 'description-', 'genre-', 'style-', 'track-' ]	
			#print Dumper $dogTrack;
	print Dumper($content);
	print("\n=====================================\n");
	print Dumper($self);
	die;
}


# make a search query on discogs, return xml content
sub searchQuery {
	my $self = shift;
	my $queryString =  shift;
	my $queryType = shift;
	my $maxAnswers = shift;
	my $answer;
	unless(defined($self)) {
		ERROR("Query not called in object context");
		die;
	}
	if( not defined($queryString) or length($queryString) < 1)  {
		ERROR("No query string or empty query string can't query Discogs for an empty string");
		die;
	}
	if( not defined($queryType) or length($queryType) < 1)  {
		$queryType='all';
	}

	unless(defined($maxAnswers) )  {
		$maxAnswers=50;
	}

	$queryString='search?type='.$queryType.'&q='.Tools::URLEncode($queryString);
	my $answerPage;
	my $page=0;
	do {
		$page++;
		$answerPage =$self->query($queryString.'&page='.$page, 1); # second parameter stands for "noCache"
		# @{$answer->{searchresults}->{result}}
		if(defined($answer)) {
			push @{$answer->{searchresults}->{result}}, @{$answerPage->{searchresults}->{result}};
			$answer->{searchresults}->{end} = $answerPage->{searchresults}->{end};
		}else {
			$answer = $answerPage;
		}
#		print("LOOP: $page \n");
	}while($answerPage->{searchresults}->{end}<= $answerPage->{searchresults}->{numResults} and $answerPage->{searchresults}->{end}<=$maxAnswers );
	return $answer;
}

sub query {
	my $self = shift;
	my $queryString =  shift;
	my $noCache = shift;
	unless(defined($self)) {
		ERROR("Query not called in object context");
		die;
	}
	if( not defined($queryString) or length($queryString) < 1)  {
		ERROR("No query string or empty query string can't query Discogs for an empty string");
		die;
	}
	
	# should use &page=xxx to iterate through results
	$queryString = 'http://'.$dogDomain.'/'.$queryString.'?f=xml&api_key='.$dogKey;
	WARN("Discogs url: $queryString \n");
	my $content = Tools::getHttpContent( { url => $queryString, noCache => $noCache } );
	
	my $xmlparser = XML::Simple->new();
	my $xmlContent = $xmlparser->XMLin($content, KeyAttr => [], ForceArray => ['image','format', 'artist', 'label', 'description', 'genre', 'style', 'track' ]);
	unless($xmlContent->{stat} eq 'ok') {
		ERROR("Discogs query error: ", $xmlContent->{error}->{msg});
		die;
	}
	WARN("Discogs request $xmlContent->{requests}/5000");
	return $xmlContent;
}

#$VAR1 = {
#          'version' => '1.0',
#          'stat' => 'ok'
#          'requests' => '30',
#          'exactresults' => {
#                            'result' => [
#                                        {
#                                          'num' => '1',
#                                          'title' => 'AIR',
#                                          'type' => 'artist',
#                                          'uri' => 'http://www.discogs.com/artist/AIR'
#                                        },
#                                        {
#                                          'num' => '2',
#                                          'title' => 'Air (2)',
#                                          'type' => 'artist',
#                                          'uri' => 'http://www.discogs.com/artist/Air+(2)'
#                                        },
#                                        {
#                                          'num' => '3',
#                                          'title' => 'Air (3)',
#                                          'type' => 'artist',
#                                          'uri' => 'http://www.discogs.com/artist/Air+(3)'
#                                        },
#                                        {
#                                          'num' => '4',
#                                          'title' => 'Air (4)',
#                                          'type' => 'artist',
#                                          'uri' => 'http://www.discogs.com/artist/Air+(4)'
#                                        },
#                                        {
#                                          'num' => '5',
#                                          'title' => 'Air (5)',
#                                          'type' => 'artist',
#                                          'uri' => 'http://www.discogs.com/artist/Air+(5)'
#                                        },
#                                        {
#                                          'num' => '6',
#                                          'title' => 'Air (6)',
#                                          'type' => 'artist',
#                                          'uri' => 'http://www.discogs.com/artist/Air+(6)'
#                                        },
#                                        {
#                                          'num' => '7',
#                                          'title' => 'Air',
#                                          'type' => 'label',
#                                          'uri' => 'http://www.discogs.com/label/Air'
#                                        },
#                                        {
#                                          'num' => '8',
#                                          'title' => 'AIR (2)',
#                                          'type' => 'label',
#                                          'uri' => 'http://www.discogs.com/label/AIR+(2)'
#                                        },
#                                        {
#                                          'num' => '9',
#                                          'title' => 'Air (3)',
#                                          'type' => 'label',
#                                          'uri' => 'http://www.discogs.com/label/Air+(3)'
#                                        }
#                                      ]
#                          },
#          'searchresults' => {
#                             'numResults' => '9732',
#                             'start' => '1',
#                             'end' => '20'
#                             'result' => [
#                                         {
#                                           'summary' => 'Air ',
#                                           'num' => '1',
#                                           'title' => 'Air',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/Air'
#                                         },
#                                         {
#                                           'summary' => "A\x{ef}r, , ",
#                                           'num' => '2',
#                                           'title' => "A\x{ef}r",
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/A%C3%AFr'
#                                         },
#                                         {
#                                           'summary' => "AIR, Nicolas Godin & Jean-Beno\x{ee}t Dunckel, Born in Versailles and now based in Paris, they founded ...  the Record Makers label together.A - Amour I - Imagination R - R\x{ea}ve",
#                                           'num' => '3',
#                                           'title' => 'AIR',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/AIR'
#                                         },
#                                         {
#                                           'summary' => 'Trans Air ',
#                                           'num' => '4',
#                                           'title' => 'Trans Air',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/Trans+Air'
#                                         },
#                                         {
#                                           'summary' => 'Bel Air ',
#                                           'num' => '5',
#                                           'title' => 'Bel Air',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/Bel+Air'
#                                         },
#                                         {
#                                           'summary' => 'Air Play ',
#                                           'num' => '6',
#                                           'title' => 'Air Play',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/Air+Play'
#                                         },
#                                         {
#                                           'summary' => 'AIR (2) ',
#                                           'num' => '7',
#                                           'title' => 'AIR (2)',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/AIR+(2)'
#                                         },
#                                         {
#                                           'summary' => 'Air Edel ',
#                                           'num' => '8',
#                                           'title' => 'Air Edel',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/Air+Edel'
#                                         },
#                                         {
#                                           'summary' => 'Air (3) ',
#                                           'num' => '9',
#                                           'title' => 'Air (3)',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/Air+(3)'
#                                         },
#                                         {
#                                           'summary' => 'mt air ',
#                                           'num' => '10',
#                                           'title' => 'mt air',
#                                           'type' => 'label',
#                                           'uri' => 'http://www.discogs.com/label/mt+air'
#                                         },
#                                         {
#                                           'summary' => '
#   Air Liquide - Air Liquide Label: Blue Catalog#: BLUE 006 Format: CD Country:Germany Released ...  Vocals, Lyrics By - Mary S. Applegate Notes:Published by Three-O-Three Music.  Tracklisting: 1 Air ...  Liquide Things Happen  2 Air Liquide Tanz Der Lemminge II  3 Air Liquide Liquid Air (The Bionaut Remix)  4',
#                                           'num' => '11',
#                                           'title' => 'Air Liquide - Air Liquide',
#                                           'type' => 'release',
#                                           'uri' => 'http://www.discogs.com/release/14807'
#                                         },
#                                         {
#                                           'summary' => 'Air Wave, , ',
#                                           'num' => '12',
#                                           'title' => 'Air Wave',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+Wave'
#                                         },
#                                         {
#                                           'summary' => 'Air & Space, , ',
#                                           'num' => '13',
#                                           'title' => 'Air & Space',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+%26+Space'
#                                         },
#                                         {
#                                           'summary' => 'Air Power, , ',
#                                           'num' => '14',
#                                           'title' => 'Air Power',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+Power'
#                                         },
#                                         {
#                                           'summary' => 'Air (3), , ',
#                                           'num' => '15',
#                                           'title' => 'Air (3)',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+(3)'
#                                         },
#                                         {
#                                           'summary' => 'Tet Air, , ',
#                                           'num' => '16',
#                                           'title' => 'Tet Air',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Tet+Air'
#                                         },
#                                         {
#                                           'summary' => 'Air Libre, , ',
#                                           'num' => '17',
#                                           'title' => 'Air Libre',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+Libre'
#                                         },
#                                         {
#                                           'summary' => 'Air Sphere, , ',
#                                           'num' => '18',
#                                           'title' => 'Air Sphere',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+Sphere'
#                                         },
#                                         {
#                                           'summary' => 'Air Afrique, , ',
#                                           'num' => '19',
#                                           'title' => 'Air Afrique',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+Afrique'
#                                         },
#                                         {
#                                           'summary' => 'Air Forge, , ',
#                                           'num' => '20',
#                                           'title' => 'Air Forge',
#                                           'type' => 'artist',
#                                           'uri' => 'http://www.discogs.com/artist/Air+Forge'
#                                         }
#                                       ]
#                           }
#        };

1;