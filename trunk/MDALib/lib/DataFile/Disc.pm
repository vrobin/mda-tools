#!/usr/bin/perl -w
package DataFile::Disc;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

my $album;

sub new {
	my $class    = shift;
	my %params;
	if(@_) {
	%params= %{shift()};
	}
	my $disc = {};
	bless( $disc, $class );
	
	if(%params) {
		if (defined($params{index}) ) { 
			$disc->index($params{index}) ;
		}
		if ( defined( $params{indexName} ) ) {
			$disc->indexName( $params{indexName} );
		}
	}
	return $disc;
}

sub parent {
	return album(@_);
}

#sub album {
#	my $self = shift;
#	my $album   = shift;
#	if ($album) { $self->{-album} = Tools::trim($album) }
#	return $self->{-album};
#}

sub album {
	my $self = shift;
	my $album = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($album) {
		#if there is already an object
		if (ref($self->{-album}) eq 'DataFile::Album') {
			# return It
			return $self->{-album};
		}else { # create a new empty object of this type
			$self->{-album}= DataFile::Album->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($album) eq 'DataFile::Album') { 
		$self->{-album}= $album; 
	}
	elsif($album){  # We only insert objects of the good type
		ERROR('Object ->album called with an unexpected parameter '.ref($album).' waiting a DataFile::Album');
	}
	# Return the set object
	return $self->{-album};
}

sub url {
	my $self = shift;
	my $url   = shift;
	if ($url) { $self->{url} = Tools::trim($url) }
	return $self->{url};
}

sub baseUrl {
	my $self = shift;
	my $baseUrl   = shift;
	if ($baseUrl) { $self->{baseUrl} = Tools::trim($baseUrl) }
	return $self->{baseUrl};
}

sub relativeUrl {
	my $self = shift;
	my $relativeUrl   = shift;
	if ($relativeUrl) { $self->{relativeUrl} = Tools::trim($relativeUrl) }
	return $self->{relativeUrl};
}

#sub addTrack{
#	my $self = shift  or return(undef);
#	my $track = shift or return(undef);
#	unless(ref($track) eq 'DataFile::Track') {
#		ERROR("Disc -> adddTrack with a non track object");
#	}
#	push(@{$self->tracks()}, $track);
#}

sub addTrack {
	my $self = shift;
	my $track = shift; 
	# if param is not an doesn't-> return
	# if ( ref($track) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
		 if ( ref($track) ne 'DataFile::Track' ) {
		# return It
		ERROR ("no DataFile::Track object in parameter ");
		return (undef );
	}
	
	# DataSource must have it's providerName filled for coherency check
	unless( $track->name() or  $track->id() or  $track->index()) { 
		ERROR("Missing name  or id or index in Track"); 
		return; 
	}
	
	# foreach track in this object, look for an already existing track with the same name
#	foreach my $existingTrack ( @{$self->{tracks}{track}} ) {
#		if($existingDataSource->name() eq $track->name()) {
#			ERROR("Track ",$track->name()," already exists, can't add it, try an update");
#			return undef;
#		}
#	}
	# A try to ease the access to dataSource from its name. Not sure it will be useful, let it commentend for now
	if($track->can('parent') ) {
		$track->parent($self);
	}
	push @{$self->{tracks}{track}}, $track;
}

sub tracks  {
	my $self = shift;
	my $tracks = shift;
	
	# if no tracks array ref is sent
	if(!$tracks) {
		# if no tracks array exists

		if(ref($self->{tracks}{track}) ne 'ARRAY') {
			#create it
			$self->{tracks}{track}=[];
			DEBUG  'Initializing credits array'
		} # returning existing or initialized
		return ($self->{tracks}{track});
	}

	if($#$tracks == -1) {
		WARN "called object->tracks with an empty array, truncating!";
	}

	foreach my $track (@{$tracks}) {
		if(ref($track) ne 'DataFile::Track') {
			ERROR "album->tracks called with an array containing at least an unexpected object".ref($track);
			return(undef);
		}
		if($track->can('parent')) {
			$track->parent($self);
		}
	}
	$self->{tracks}{track} = $tracks;
}	

sub index {
	my $self    = shift;
	my $index = shift;
	if ($index) { $self->{index} = Tools::trim($index) }
	return $self->{index};
}

sub id {
	my $self    = shift;
	my $id = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
}

sub name () {
	 my $self = shift;
	my $name = shift;
	if ($name) { $self->{name} = Tools::trim($name); }
	return $self->{name};
}

sub indexName {
	my $self    = shift;
	my $indexName = shift;
	if ($indexName) { $self->{indexName} = Tools::trim($indexName) }
	return $self->{indexName};
}

sub disc {
	my $self = shift;
	if (@_) { $self = shift; }
	return $self;
}

# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;

	if(exists($self->{tracks}) and exists($self->{tracks}{track}) ) {
		unless(ref($self->{tracks}{track}) eq 'ARRAY') {
			my $track=$self->{tracks}{track};
			push @{$self->{tracks}{track}=[]}, $track;

		}
		Tools::blessObjects('DataFile::Track', $self->{tracks}{track});
	}	
#	Tools::blessObjects('DataFile::Track', $self->{tracks}{track});
	# Initialize backpointer track -> disc for each track found 
	foreach my $track (@{$self->tracks()}) {
		$track->parent($self);
	}
}

END { }    # module clean-up code here (global destructor)
1;
