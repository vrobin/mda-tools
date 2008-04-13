#!/usr/bin/perl -w
package DataFile::Composer;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

sub new {
	my $class    = shift;
	my %params;
	if(@_) {
	%params= %{shift()};
	}
	my $composer = {};
	bless( $composer, $class );
	if(%params) {
		if (defined($params{id}) ) { 
			$composer->id($params{id}) ;
		}
		if (defined($params{name}) ) { 
			$composer->name($params{name}) ;
		}
		if (defined($params{url}) ) { 
			$composer->url($params{url}) ;
		}		
		if ( defined( $params{rawData} ) ) {
			$composer->rawData( $params{rawData} );
		}
		if ( defined( $params{linkTo} ) ) {
			$composer->linkTo( $params{linkTo} );
		}
	}
	return $composer;
}

# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;
	Tools::blessObject('DataFile::Date', $self->{activeDates});

	if(exists($self->{activePlaces}) and exists($self->{activePlaces}{place}) ) {
		unless(ref($self->{activePlaces}{place}) eq 'ARRAY') {
			my $place=$self->{activePlaces}{place};
			push @{$self->{activePlaces}{place}=[]}, $place;

		}
		Tools::blessObjects('DataFile::Place', $self->{activePlaces}{place});
	}
#	Tools::blessObjects('DataFile::Place', $self->{activePlaces}{place});
	Tools::blessObject('DataFile::Note', $self->{biography});
	Tools::blessObject('DataFile::Place', $self->{birthPlace});
	Tools::blessObject('DataFile::Place', $self->{deathPlace});
	Tools::blessObject('DataFile::Date', $self->{lifeDate});

	if(exists($self->{pictures}) and exists($self->{pictures}{picture}) ) {
		unless(ref($self->{pictures}{picture}) eq 'ARRAY') {
			my $picture=$self->{pictures}{picture};
			push @{$self->{pictures}{picture}=[]}, $picture;

		}
		Tools::blessObjects('DataFile::Picture', $self->{pictures}{picture});
	}	
#	Tools::blessObjects('DataFile::Picture', $self->{pictures}{picture});

	if(exists($self->{tags}) and exists($self->{tags}{tag}) ) {
		unless(ref($self->{tags}{tag}) eq 'ARRAY') {
			my $tag=$self->{tags}{tag};
			push @{$self->{tags}{tag}=[]}, $tag;

		}
		Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});
	}
#	Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});	
}

sub birthPlace  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->birthPlace(@_);}
	
	my $place = shift;
	# if there is no parameter in input
	unless($place) {
		#if there is already an composedPlace in the composer object
		if (ref($self->{birthPlace}) eq 'DataFile::Place'){
			# return It
			return($self->{birthPlace});
		} else {
			# create it
			$self->{birthPlace} = DataFile::Place->new();
		}
		
	}
	# Called with a Place Object, replacing it
	if (ref($place) eq 'DataFile::Place') { 
		$self->{birthPlace}= $place; 
	}
	elsif($place){
		ERROR 'composer->birthPlace called with an unexpected parameter'.ref($place)  ;
	}
	return $self->{birthPlace};	
}

sub activePlaces  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->activePlaces(@_);}
	
	my $places = shift;
	
	# if no artworks array ref is sent
	if(!$places) {
		# if no artworks array exists
		if(ref($self->{activePlaces}{place}) ne 'ARRAY') {
			#create it
			$self->{activePlaces}{place}=[];
			DEBUG  'Initializing artworks array'
		} # returning existing or initialized
		return ($self->{activePlaces}{place});
	}

	if($#$places == -1) {
		WARN "called album->artworks with an empty array, truncating!";
	}

	foreach my $place (@{$places}) {
		if(ref($place) ne 'DataFile::Place') {
			ERROR "album->places called with an array containing at least an unexpected object".ref($place);
			return(undef);
		}
	}
	$self->{activePlaces}{place} = $places;
	return ($self->{activePlaces}{place});
}

sub deathPlace  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->deathPlace(@_);}
		
	my $place = shift;
	# if there is no parameter in input
	unless($place) {
		#if there is already an composedPlace in the composer object
		if (ref($self->{deathPlace}) eq 'DataFile::Place'){
			# return It
			return($self->{deathPlace});
		} else {
			# create it
			$self->{deathPlace} = DataFile::Place->new();
		}
		
	}
	# Called with a Place Object, replacing it
	if (ref($place) eq 'DataFile::Place') { 
		$self->{deathPlace}= $place; 
	}
	elsif($place){
		ERROR 'composer->deathPlace called with an unexpected parameter'.ref($place)  ;
	}
	return $self->{deathPlace};	
}

sub composer {
	my $self = shift;
	if (@_) { $self = shift; }
	return $self;
}
sub activeDates  {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->activeDates(@_);}
	
	my $date = shift;
	# if there is no parameter in input
	unless($date) {
		#if there is already an publicationDate in the composer object
		if (ref($self->{activeDates}) eq 'DataFile::Date'){
			# return It
			return($self->{activeDates});
		} else {
			# create it
			$self->{activeDates} = DataFile::Date->new();
		}
		
	}
	# Called with a Date Object, replacing it
	if (ref($date) eq 'DataFile::Date') { 
		$self->{activeDates}= $date; 
	}
	elsif($date){
		ERROR 'composer activeDates called with an unexpected parameter'.ref($date)  ;
	}
	return $self->{activeDates};	
}


sub addPicture {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->addPicture(@_);}
	
	my $picture = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($picture) ne 'DataFile::Picture' ) {
		# return It
		ERROR ("no picture object in parameter ");
		return (undef );
	}

	# if theres no artwork url, return in error (that's the least we need)
	unless( $picture->url() ) { 
		ERROR("artwork url name manquant"); 
		return; 
	}
	push @{$self->{pictures}{picture}}, $picture;
}

sub parent {
	my $self = shift or return undef;
	my $parent = shift or return undef;
	
	# if parent is called without a parameter, it's a get:  look for appropriate composer parent
	if (!defined($parent)) {
		# if the composer is associated with a work
		if(defined($self->work)){
			return $self->work;
		}
		if(defined($self->dataSource)){
			return $self->dataSource;
		}
		return undef; # if there's no dataSource nor work in the composer, it has no parents
	}
	#else it's a SET
	if(ref($parent) eq 'DataFile::Work' ) {
		$self->work($parent);
	}
	if( (ref($parent) eq 'DataFile::DataSource') or( ref($parent) =~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) ) {
		$self->dataSource($parent);
	}	
}

sub work {
	my $self = shift or return undef;
	my $work = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($work) {
		#if there is already an object
		if (ref($self->{-work}) eq 'DataFile::Work') {
			# return It
			return $self->{-work};
		}else { # create a new empty object of this type
			#$self->{-work}= DataFile::Work->new();
			#as work is a backreference, we don't create new empty object but return undef
			return undef;
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($work) eq 'DataFile::Work') { 
		$self->{-work}= $work; 
	}
	elsif($work){  # We only insert objects of the good type
		ERROR 'Object ->work called with an unexpected parameter '.ref($work).' waiting a DataFile::Work';
	}
	# Return the set object
	return $self->{-work};
}

sub dataSource {
	my $self = shift;
	my $dataSource = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($dataSource) {
		#if there is already an object
		if ( (ref($self->{-dataSource}) eq 'DataFile::DataSource') or ( ref($self->{-dataSource}) =~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) ) {
			# return It
			return $self->{-dataSource};
		}else { # create a new empty object of this type
			#$self->{dataSource}= DataFile::DataSource->new();
			#as work is a backreference, we don't create new empty object but return undef
			return undef;			
		}
	}
	# There's a parameter in input, it's a SET
	if ( (ref($dataSource) eq 'DataFile::DataSource')  or ( ref($dataSource) =~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) ) { 
		$self->{-dataSource}= $dataSource; 
	}
	elsif($dataSource){  # We only insert objects of the good type
		ERROR('Object ->dataSource called with an unexpected parameter '.ref($dataSource).' waiting a DataFile::DataSource');
	}
	# Return the set object
	return $self->{-dataSource};
}


sub addActivePlace {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->addActivePlace(@_);}	

	my $place = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($place) ne 'DataFile::Place' ) {
		# return It
		ERROR ("no tag  object in parameter ");
		return (undef );
	}

	# if theres no composer name, return in error (that's the least we need)
	unless( $place->rawData() ) { 
		ERROR("place rawData manquant"); 
		return; 
	}

# TODO: chercher si le tag existe deja pour faire un update
	push @{$self->{activePlaces}{place}}, $place;
}

sub addTag {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->addTag(@_);}
		
	my $tag = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($tag) ne 'DataFile::Tag' ) {
		# return It
		ERROR ("no tag  object in parameter ");
		return (undef );
	}

	# if theres no composer name, return in error (that's the least we need)
	unless( $tag->name() ) { 
		ERROR("tag name manquant"); 
		return; 
	}
	unless( $tag->value() ) { 
		ERROR("tag name manquant"); 
		return; 
	}

# TODO: chercher si le tag existe deja pour faire un update
	push @{$self->{tags}{tag}}, $tag;
}


sub id {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->id(@_);}
		
	my $id   = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
}

################
# Link handling part

# id of linked composer (xlink:href contains the #id of the pointed reference)
sub href {
	my $self = shift or return(undef);
	my $referenceTo  = shift;
	if ($referenceTo) { $self->{'xlink:href'} =  '#'.Tools::trim($referenceTo) }
		return defined($self->{'xlink:href'})?substr($self->{'xlink:href'},1):undef;
}

# test if current Composer is a link or a real composer, returns true if current object is a link
sub isLink {
	my $self = shift or return(undef);
	return ( defined($self->{'xlink:href'}) and defined($self->{-linkedComposer}) and ref($self->{-linkedComposer}) eq 'DataFile::Composer' )?1:0;
}

# Link this composer to the composer object passed in parameter 
sub linkTo {
	my $self = shift or return(undef);
	my $composerToBeLinked = shift or return(undef);
	
	if($composerToBeLinked->isLink) {
		ERROR("Can't build link from a link, object must be a full Composer Object");
		return undef;
	}

	if ( ref($composerToBeLinked) ne 'DataFile::Composer' ) {
		# return It
			ERROR("linkTo must be provided with a DataFile::Composer object not ".ref($composerToBeLinked));
			return(undef);
	}
	unless(defined($composerToBeLinked->id)) {
			ERROR('Composer->linkTo must be provided with a DataFile::Composer containing an ID');
			return(undef);		
	}
	
	# Delete all the content of current object (a link doesn't contain anything but the href element)
	delete @$self{keys %$self};
	$self->href($composerToBeLinked->id);
	$self->linkedComposer($composerToBeLinked);
}

# If composer is a link object, return the composer object reference linked 
sub linkedComposer {
	my $self = shift;
	my $composerToBeLinked   = shift;
	
	# If passed object isn't a composer
	if ( defined($composerToBeLinked) and (ref($composerToBeLinked) ne 'DataFile::Composer') ) {
		# return It
		ERROR("linkTo must be provided with a DataFile::Composer object not ".ref($composerToBeLinked));
		return(undef);
	}

	# if composer to link with is already a link, force the link to be to the real composer object
	if(defined($composerToBeLinked) and $composerToBeLinked->isLink) {
		$composerToBeLinked = $composerToBeLinked->linkedComposer;
	}
	
	if ($composerToBeLinked) { $self->{-linkedComposer} = $composerToBeLinked }
	return $self->{-linkedComposer};
}

#sub biography {
#	my $self = shift;
#	
#	# if $self is a link, call linked object method
#	if($self->isLink) { return $self->linkedComposer()->biography(@_);}
#	
#	my $biography   = shift;
#	if ($biography) { $self->{biography} = Tools::trim($biography) }
#	return $self->{biography};
#}

sub biography {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->biography(@_);}
	
	my $biography = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($biography) {
		#if there is already an object
		if (ref($self->{biography}) eq 'DataFile::Note') {
			# return It
			return $self->{biography};
		}else { # create a new empty object of this type
			$self->{biography}= DataFile::Note->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($biography) eq 'DataFile::Note') { 
		$self->{biography}= $biography; 
	}
	elsif($biography){  # We only insert objects of the good type
		ERROR('Object ->biography called with an unexpected parameter '.ref($biography).' waiting a DataFile::Note');
	}
	# Return the set object
	return $self->{biography};
}


sub rawData {
	my $self    = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->rawData(@_);}
	
	my $rawData = shift;
	if ($rawData) {
# old tweak to force rawData not to be an attribute, but content text
#		$self->{rawData}{forceText} = 'true';
		$self->{rawData}{content} = Tools::trim($rawData);
	}
	return $self->{rawData}{content};
}

sub findTags{
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->findTags(@_);}
	
	my $lookupProperty = shift or return(undef);
	my $lookupValue = shift or return(undef);
	my @foundTags;
	#TODO: check if this piece of crap is working
	if(ref($lookupProperty)  eq 'CODE') {
		foreach  (@{$self->tags()}){
	#		print("looking ", $_->id()," for $lookupProperty -> $lookupValue\n");
			if(&$lookupProperty() eq $lookupValue) {
	#			print("found tagormance",$_->id(),"\n");
				wantarray?push @foundTags, $_:return($_);
			}
		}		
	}else {
		foreach my $tag (@{$self->tags()}){
	#		print("looking ", $tag->id()," for $lookupProperty -> $lookupValue\n");
			if($tag->$lookupProperty() eq $lookupValue) {
	#			print("found tagormance",$tag->id(),"\n");
				wantarray?push @foundTags, $tag:return($tag);
			}
		}
	}
	return @foundTags;
}

sub tags  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->tags(@_);}
	
	my $tags = shift;
	
	# if no tags array ref is sent
	if(!$tags) {
		# if no tags array exists
		if(ref($self->{tags}{tag}) ne 'ARRAY') {
			#create it
			$self->{tags}{tag}=[];
			DEBUG  'Initializing tags array'
		} # returning existing or initialized
		return ($self->{tags}{tag});
	}

	if($#$tags == -1) {
		WARN "called album->tags with an empty array, truncating!";
	}

	foreach my $work(@{$tags}) {
		if(ref($work) ne 'DataFile::Tag') {
			ERROR "album->tags called with an array containing at least an unexpected object".ref($tags);
			return(undef);
		}
	}
	$self->{tags}{tags} = $tags;
}

sub lifeDate {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->lifeDate(@_);}

	my $date = shift;

	# if there is no parameter in input
	unless ($date) {
		#if there is already an lifeDate in the composer object
		if ( ref( $self->{lifeDate} ) eq 'DataFile::Date' ) {
			# return It
			return ( $self->{lifeDate} );
		}
		else {
			# create it
			$self->{lifeDate} = DataFile::Date->new();
		}

	}
	# Called with a Date Object, replacing it
	if ( ref($date) eq 'DataFile::Date' ) {
		$self->{lifeDate} = $date;
	}
	elsif ($date) {
		ERROR 'albumReleaseDate called with an unexpected parameter'
		  . ref($date);
	}
	return $self->{lifeDate};
}

sub url {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->url(@_);}

	
	my $url   = shift;
	if ($url) { $self->{url} = Tools::trim($url) }
	return $self->{url};
}


sub baseUrl {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->baseUrl(@_);}
	
	my $baseUrl   = shift;
	if ($baseUrl) { $self->{baseUrl} = Tools::trim($baseUrl) }
	return $self->{baseUrl};
}

sub relativeUrl {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->relativeUrl(@_);}
		
	my $relativeUrl   = shift;
	if ($relativeUrl) { $self->{relativeUrl} = Tools::trim($relativeUrl) }
	return $self->{relativeUrl};
}

sub name {
	my $self = shift or return(undef);
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedComposer()->name(@_);}
	
	my $name = shift;
	if ($name) { $self->{name} = Tools::trim($name) }
	return $self->{name};
}

END { }    # module clean-up code here (global destructor)
1;
