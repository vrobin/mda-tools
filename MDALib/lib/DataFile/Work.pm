#!/usr/bin/perl -w
package DataFile::Work;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);
use DataFile::Performance;
use DataFile::Composer;
use DataFile::Composed;
use DataFile::Place;

#TODO: Add First Performance Propertie

sub new {
        my $class = shift;
#        my $work = { 'composer' =>  DataFile::Composer->new() };
        my $work = {};
	my %params;
	if (@_) {
		%params = %{ shift() };
	}
    bless ($work, $class);

	if (%params) {
		if ( defined( $params{id} ) ) {
			$work->id( $params{id} );
		}
		if ( defined( $params{index} ) ) {
			$work->index( $params{index} );
		}		
		if ( defined( $params{name} ) ) {
			$work->name( $params{name} );
		}
		if ( defined( $params{length} ) ) {
			$work->length( $params{length} );
		}		
		if ( defined( $params{url} ) ) {
			$work->url( $params{url} );
		}
		if ( defined( $params{relativeUrl} ) ) {
			$work->relativeUrl( $params{relativeUrl} );
		}
		if ( defined( $params{baseUrl} ) ) {
			$work->baseUrl( $params{baseUrl} );
		}
		if ( defined( $params{rawData} ) ) {
			$work->rawData( $params{rawData} );
		}
		if ( defined( $params{workId} ) ) {
			$work->workId( $params{workId} );
		}	
		if ( defined( $params{workIndex} ) ) {
			$work->workIndex( $params{workIndex} );
		}
		if ( defined( $params{linkTo} ) ) {
			$work->linkTo( $params{linkTo} );
		}
	}    
        return $work;
}

# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;

	unless($self->isLink) {	
		Tools::blessObject('DataFile::Composed', $self->{composed});

		if(exists($self->{composers}) and exists($self->{composers}{composer}) ) {
			unless(ref($self->{composers}{composer}) eq 'ARRAY') {
				my $composer=$self->{composers}{composer};
#				$self->{composers}{composer}=undef;
#				$self->{composers}{composer}->[0]=$composer;
				push @{$self->{composers}{composer}=[]}, $composer;
				#push @{$self->{composers}{composer}}, $self->{composers}{composer};
			}
			Tools::blessObjects('DataFile::Composer', $self->{composers}{composer});
		}		

		Tools::blessObject('DataFile::Length', $self->{length});
		if(exists($self->{notes}) and exists($self->{notes}{note}) ) {
			unless(ref($self->{notes}{note}) eq 'ARRAY') {
				my $note=$self->{notes}{note};
				push @{$self->{notes}{note}=[]}, $note;
	
			}
			Tools::blessObjects('DataFile::Note', $self->{notes}{note});
		}
#		Tools::blessObjects('DataFile::Note', $self->{notes}{note});

		if(exists($self->{parts}) and exists($self->{parts}{part}) ) {
			unless(ref($self->{parts}{part}) eq 'ARRAY') {
				my $part=$self->{parts}{part};
				push @{$self->{parts}{part}=[]}, $part;
	
			}
			Tools::blessObjects('DataFile::Part', $self->{parts}{part});
		}
#		Tools::blessObjects('DataFile::Part', $self->{parts}{part});
		Tools::blessObject('DataFile::Date', $self->{publicationDate});
		Tools::blessObject('DataFile::Date', $self->{revisionDate});

		if(exists($self->{tags}) and exists($self->{tags}{tag}) ) {
			unless(ref($self->{tags}{tag}) eq 'ARRAY') {
				my $tag=$self->{tags}{tag};
				push @{$self->{tags}{tag}=[]}, $tag;
	
			}
			Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});
		}
#		Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});
	}
}

sub composers  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->composers(@_);}
	
	my $composers = shift;
	# print("QSD! ".ref($performances->[0])."\n"); >> QSD! DataFile::performance
	# print("QSD! ".ref($performances)."\n"); >> QSD! ARRAY
	# print("QSD! ".ref($performances)." - ".$#$performances."\n");
	
	# if no performances array ref is sent
	if(!$composers) {
		# if no performances array exists
		if(ref($self->{composers}{composer}) ne 'ARRAY') {
			#create it
			$self->{composers}{composer}=[];
			DEBUG 'Initializing normalized date array'
		} # returning existing or initialized
		return ($self->{composers}{composer});
	}

	if($#$composers == -1) {
		DEBUG "called disc->composerswith an empty array, truncating!";
	}

	$self->{composers}{composer} = $composers;
}

sub addTag {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->addTag(@_);}
	
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

sub addComposerAsLink {
	my $self = shift or return undef;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->addComposerAsLink(@_);}
	
	my $composer = shift or return undef;
	$self->addComposer( DataFile::Composer->new( { linkTo => $composer}) );
#	my $composerLink = DataFile::Composer->new( { linkTo => $composer});
#	$composerLink->parent($self);
#	$self->addComposer( $composerLink); 	 
}

sub findTags{
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->findTags(@_);}

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
	if($self->isLink) { return $self->linkedWork()->tags(@_);}
	
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

sub addComposer {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->addComposer(@_);}
	
	my $composer = shift; 
	# if param is not an doesn't-> return
	# if ( ref($composer) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
		 if ( ref($composer) ne 'DataFile::Composer' ) {
		# return It
		ERROR ("no DataFile::Composer object in parameter ");
		return (undef );
	}
	
	# Composer must have its providerName filled for coherency check
	unless( $composer->id()  or$composer->name()   ) { 
		ERROR("Missing id  or name for Composer object"); 
		return; 
	}
	
	# foreach composer in this object, look for an already existing composer with the same id
	foreach my $existingComposer ( @{$self->{composers}{composer}} ) {
		if($existingComposer->id() eq $composer->id()) {
			ERROR("Composer ",$composer->id()," already exists, can't add it, try an update");
			return undef;
		}
		unless (defined($existingComposer->id()) and defined($composer->id()) ) {
			if($existingComposer->name() eq $composer->name()) {
				ERROR("Composer ",$composer->name()," already exists, can't add it, try an update");
				return undef;
			}			
		}
	}
	# A try to ease the access to dataSource from its name. Not sure it will be useful, let it commentend for now
	if($composer->can('parent') ) {
		$composer->parent($self);
	}
	push @{$self->{composers}{composer}}, $composer;
}


# fake object for "one composer only" datasources
sub composer  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->composer(@_);}
	
	my $composer = shift;
	# if there is no parameter in input
	unless(defined($composer)) {
		#if there is already a composer in the composer object
		if (ref($self->{composers}{composer}->[0]) eq 'DataFile::Composer'){
			# return It
			return($self->{composers}{composer}->[0]);
		} else {
			# create it
			$self->{composers}{composer}->[0] = DataFile::Composer->new();
		}
	}
	# Called with a composer Object, replacing it
	if (ref($composer) eq 'DataFile::Composer') { 
		$self->{composers}{composer}->[0]= $composer; 
	}
	elsif($composer){
		ERROR 'work composer called with an unexpected parameter'.ref($composer)  ;
	}
	return $self->{composers}{composer}->[0];	
}

sub work {
        my $self = shift;
        if (@_) { $self = shift; }
        return $self;
}

sub addNote {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->addNote(@_);}
	
	my $note = shift; 
	unless( $note ) { ERROR("pas de note"); return; }
	push @{$self->{notes}{note}}, $note;
}

sub addPart {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->addPart(@_);}
	
	my $part = shift; 
	unless( $part ) { ERROR("pas de part/movement"); return; }
	push @{$self->{parts}{part}}, $part;
}

sub index {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->index(@_);}
	
	my $index = shift;
	if ($index) { $self->{index} = Tools::trim($index) }
	return $self->{index};
}

sub url {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->url(@_);}
	
	my $url   = shift;
	if ($url) { $self->{url} = Tools::trim($url) }
	return $self->{url};
}

sub baseUrl {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->baseUrl(@_);}
	
	my $baseUrl   = shift;
	if ($baseUrl) { $self->{baseUrl} = Tools::trim($baseUrl) }
	return $self->{baseUrl};
}

sub relativeUrl {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->relativeUrl(@_);}
	
	my $relativeUrl   = shift;
	if ($relativeUrl) { $self->{relativeUrl} = Tools::trim($relativeUrl) }
	return $self->{relativeUrl};
}

sub id {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->id(@_);}
	
	my $id   = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
}


sub composed  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->composed(@_);}
	
	my %parameters;
	# if there is a parameter, try to assign it to the parameters hash
	if(@_ ) {
		%parameters=%{shift()};
	}

	# if composed object is not defined and not of the good type
	unless(ref($self->{composed}) eq 'DataFile::Composed') {
		#create it
		$self->{composed} = DataFile::Composed->new();
	}
	
	# if no hash is sent in parameter
	unless(%parameters) {
		# return the empty composed object just created
		return($self->{composed});
	}

	if(defined($self->composed->rawData() )) {
		WARN "Composed  already defined, overriding old data" 
	}				
	$self->composed->date->rawData( Tools::trim($parameters{rawData})); 
	$self->composed->place->rawData( Tools::trim($parameters{rawData})); 

	$self->composed->place->country( Tools::trim($parameters{country}));
	$self->composed->place->city(Tools::trim($parameters{city}));

	return $self->{composed};
}


sub publicationDate  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->publicationDate(@_);}
	
	my $date = shift;
	# if there is no parameter in input
	unless($date) {
		#if there is already an publicationDate in the composer object
		if (ref($self->{publicationDate}) eq 'DataFile::Date'){
			# return It
			return($self->{publicationDate});
		} else {
			# create it
			$self->{publicationDate} = DataFile::Date->new();
		}
		
	}
	# Called with a Date Object, replacing it
	if (ref($date) eq 'DataFile::Date') { 
		$self->{publicationDate}= $date; 
	}
	elsif($date){
		ERROR 'albumReleaseDate called with an unexpected parameter'.ref($date)  ;
	}
	return $self->{publicationDate};	
}

sub length  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->length(@_);}
	
	my $length = shift;
	
	# S'il n'y a pas de paramètre en entrée
	unless($length) {
		#if there is already an albumLength
		if (ref($self->{'length'}) eq 'DataFile::Length') {
			# return It
			return $self->{'length'};
		}else {
			$self->{'length'}= DataFile::Length->new();
		}
	}
	# Called with a Date Object, replacing it
	if (ref($length) eq 'DataFile::Length') { 
		$self->{'length'}= $length; 
	}
	elsif($length){
		ERROR 'album->length called with an unexpected parameter'.ref($length)  ;
	}
	return $self->{'length'};
}

sub revisionDate  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->revisionDate(@_);}
	
	my $date = shift;
	# if there is no parameter in input
	unless($date) {
		#if there is already an revisionDate in the composer object
		if (ref($self->{revisionDate}) eq 'DataFile::Date'){
			# return It
			return($self->{revisionDate});
		} else {
			# create it
			$self->{revisionDate} = DataFile::Date->new();
		}
		
	}
	# Called with a Date Object, replacing it
	if (ref($date) eq 'DataFile::Date') { 
		$self->{revisionDate}= $date; 
	}
	elsif($date){
		ERROR 'albumReleaseDate called with an unexpected parameter'.ref($date)  ;
	}
	return $self->{revisionDate};	
}

sub language {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->language(@_);}
	
	my $language = shift;
	if ($language) { 
		if(defined($self->{language}) ) { WARN "Language already defined, overriding old language" }
		$self->{language} = Tools::trim($language) }
	return $self->{language};
}

sub period {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->period(@_);}
	
	my $period = shift;
	if ($period) { 
		if(defined($self->{period}) ) { WARN "Period already defined, overriding old period" }
		$self->{period} = Tools::trim($period) }
	return $self->{period};
}

sub name () {
	 my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedWork()->name(@_);}
	 
	my $name = shift;
	if ($name) { $self->{name} = Tools::trim($name); }
	return $self->{name};
}

sub parent {
	my $self = shift or return undef;
	my $parent = shift or return undef;
	
	# if parent is called without a parameter, it's a get:  look for appropriate performance parent
	if (!defined($parent)) {
		# if the work  is associated with a track
		if(defined($self->track)){
			return $self->track;
		}
		if(defined($self->album)){
			return $self->album;
		}
		return undef; # if there's no album nor track in the performance, it has no parents
	}
	#else it's a SET
	if(ref($parent) eq 'DataFile::Track' ) {
		$self->track($parent);
	}
	if( ref($parent) eq 'DataFile::Album' ) {
		$self->album($parent);
	}	
}

sub track {
	my $self = shift or return undef;
	my $track = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($track) {
		#if there is already an object
		if (ref($self->{-track}) eq 'DataFile::Track') {
			# return It
			return $self->{-track};
		}else { # create a new empty object of this type
			#$self->{-track}= DataFile::Track->new();
			#as track is a backreference, we don't create new empty object but return undef
			return undef;
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($track) eq 'DataFile::Track') { 
		$self->{-track}= $track; 
	}
	elsif($track){  # We only insert objects of the good type
		ERROR 'Object ->track called with an unexpected parameter '.ref($track).' waiting a DataFile::Track';
	}
	# Return the set object
	return $self->{-track};
}

sub album {
	my $self = shift;
	my $album = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($album) {
		#if there is already an object
		if (ref($self->{-album}) eq 'DataFile::Album' ) {
			# return It
			return $self->{-album};
		}else { # create a new empty object of this type
			#$self->{album}= DataFile::Album->new();
			#as work is a backreference, we don't create new empty object but return undef
			return undef;			
		}
	}
	# There's a parameter in input, it's a SET
	if ( ref($album) eq 'DataFile::Album'  ) { 
		$self->{-album}= $album; 
	}
	elsif($album){  # We only insert objects of the good type
		ERROR('Object ->album called with an unexpected parameter '.ref($album).' waiting a DataFile::Album');
	}
	# Return the set object
	return $self->{-album};
}

################
# Link handling part

# id of linked work (xlink:href contains the #id of the pointed reference)
sub href {
	my $self = shift;
	my $referenceTo  = shift;
	if ($referenceTo) { $self->{'xlink:href'} =  '#'.Tools::trim($referenceTo) }
	return defined($self->{'xlink:href'})?substr($self->{'xlink:href'},1):undef;
}

# test if current Work is a link or a real work, returns true if current object is a link
sub isLink {
	my $self = shift or return(undef);
	return ( defined($self->{'xlink:href'}) and defined($self->{-linkedWork}) and ref($self->{-linkedWork}) eq 'DataFile::Work' )?1:0;
}

# Link this work to the work object passed in parameter 
sub linkTo {
	my $self = shift or return(undef);
	my $workToBeLinked = shift or return(undef);
	
	if($workToBeLinked->isLink) {
		ERROR("Can't build link from a link, object must be a full Work Object");
		return undef;
	}

	if ( ref($workToBeLinked) ne 'DataFile::Work' ) {
		# return It
			ERROR("linkTo must be provided with a DataFile::Work object not ".ref($workToBeLinked));
			return(undef);
	}
	unless(defined($workToBeLinked->id)) {
			ERROR('Work->linkTo must be provided with a DataFile::Work containing an ID');
			return(undef);		
	}
	
	# Delete all the content of current object (a link doesn't contain anything but the href element)
	delete @$self{keys %$self};
	$self->href($workToBeLinked->id);
	$self->linkedWork($workToBeLinked);
}

# If work is a link object, return the work object reference linked 
sub linkedWork {
	my $self = shift;
	my $workToBeLinked   = shift;
	
	# If passed object isn't a work
	if ( defined($workToBeLinked) and (ref($workToBeLinked) ne 'DataFile::Work') ) {
		# return It
		ERROR("linkTo must be provided with a DataFile::Work object not ".ref($workToBeLinked));
		return(undef);
	}

	# if work to link with is already a link, force the link to be to the real work object
	if(defined($workToBeLinked) and $workToBeLinked->isLink) {
		$workToBeLinked = $workToBeLinked->linkedWork;
	}
	
	if ($workToBeLinked) { $self->{-linkedWork} = $workToBeLinked }
	return $self->{-linkedWork};
}

END { }    # module clean-up code here (global destructor)
1;
