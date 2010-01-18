#!/usr/bin/perl -w
package DataFile::Performance;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);


sub new {
        my $class = shift;
        my $performance = {};
        bless ($performance, $class);
		my %params;
		if (@_) {
			%params = %{ shift() };
		}
	
	if (%params) {
		if ( defined( $params{id} ) ) {
			$performance->id( $params{id} );
		}
		if ( defined( $params{index} ) ) {
			$performance->index( $params{index} );
		}		
		if ( defined( $params{length} ) ) {
			$performance->length( $params{length} );
		}		
		if ( defined( $params{value} ) ) {
			$performance->value( $params{value} );
		}
		if ( defined( $params{url} ) ) {
			$performance->url( $params{url} );
		}
		if ( defined( $params{rawData} ) ) {
			$performance->rawData( $params{rawData} );
		}
		if ( defined( $params{workId} ) ) {
			$performance->workId( $params{workId} );
		}	
		if ( defined( $params{workIndex} ) ) {
			$performance->workIndex( $params{workIndex} );
		}
		if ( defined( $params{linkTo} ) ) {
			$performance->linkTo( $params{linkTo} );
		}
	}        
        return $performance;
}

sub performance {
        my $self = shift;
        if (@_) { $self = shift; }
        return $self;
}

sub rawData {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->rawData(@_);}	

	my $rawData   = shift;
	if ($rawData) { 
# old tweak to force rawData not to be an attribute, but content text
#		$self->{rawData}{forceText} = 'true'; 
		$self->{rawData}{content} = Tools::trim($rawData) 
	}
	return $self->{rawData}{content};
}

## TODO: check, this method should call $self->work->index !
#sub workIndex {
#	my $self = shift;
#
#	# if $self is a link, call linked object method
#	if($self->isLink) { return $self->linkedPerformance()->workIndex(@_);}	
#	
#	my $workIndex   = shift;
#	if ($workIndex) { $self->work->index= Tools::trim($workIndex) }
#	return $self->{workIndex};
#}


sub addTag {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->addTag(@_);}	
	
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


# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;
	
	#  works are deserialized as an array by xmlsimple but work link in a performanc object is not an array
	#if(defined($self->{work}[0])) { $self->{work} = $self->{work}[0]; } else { delete($self->{work}) };

	unless($self->isLink) {
		if(exists($self->{awards}) and exists($self->{awards}{award}) ) {
			unless(ref($self->{awards}{award}) eq 'ARRAY') {
				my $award=$self->{awards}{award};
				push @{$self->{awards}{award}=[]}, $award;
	
			}
			Tools::blessObjects('DataFile::Award', $self->{awards}{award});
		}
		#Tools::blessObjects('DataFile::Award', $self->{awards}{award});

		if(exists($self->{credits}) and exists($self->{credits}{credit}) ) {
			unless(ref($self->{credits}{credit}) eq 'ARRAY') {
				my $credit=$self->{credits}{credit};
				push @{$self->{credits}{credit}=[]}, $credit;
	
			}
			Tools::blessObjects('DataFile::Credit', $self->{credits}{credit});
		}	
#		Tools::blessObjects('DataFile::Credit', $self->{credits}{credit});

		if(exists($self->{date}) and ref($self->{date})) {
			Tools::blessObject('DataFile::Date', $self->{date});
		}
		
		if(exists($self->{length}) and ref($self->{length})) {
			Tools::blessObject('DataFile::Length', $self->{length});
		}

		if(exists($self->{notes}) and exists($self->{notes}{note}) ) {
			unless(ref($self->{notes}{note}) eq 'ARRAY') {
				my $note=$self->{notes}{note};
				push @{$self->{notes}{note}=[]}, $note;
	
			}
			Tools::blessObjects('DataFile::Note', $self->{notes}{note});
		}
#		Tools::blessObjects('DataFile::Note', $self->{notes}{note});
		
		if(exists($self->{place}) and ref($self->{place})) {
			Tools::blessObject('DataFile::Place', $self->{place});
		}
		
		if(exists($self->{tags}) and exists($self->{tags}{tag}) ) {
			unless(ref($self->{tags}{tag}) eq 'ARRAY') {
				my $tag=$self->{tags}{tag};
				push @{$self->{tags}{tag}=[]}, $tag;
	
			}
			Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});
		}
#		Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});
		if(exists($self->{work}) and ref($self->{work}) ) {
			Tools::blessObject('DataFile::Work', $self->{work});
			$self->work->parent($self);
		}	
	}
}

# TODO: add performance rating? (to be added either in perf or track or both)
sub url {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->url(@_);}	
	
	my $url   = shift;
	if ($url) { $self->{url} = Tools::trim($url);}
	return $self->{url};
}

sub baseUrl {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->baseUrl(@_);}	
	
	my $baseUrl   = shift;
	if ($baseUrl) { $self->{baseUrl} = Tools::trim($baseUrl) }
	return $self->{baseUrl};
}

sub relativeUrl {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->relativeUrl(@_);}	
	
	my $relativeUrl   = shift;
	if ($relativeUrl) { $self->{relativeUrl} = Tools::trim($relativeUrl) }
	return $self->{relativeUrl};
}

sub name {
	my $self = shift;
	
	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->name(@_);}	
	
	my $name   = shift;
	if ($name) { $self->{name} = Tools::trim($name);}
	return $self->{name};
}

sub workId {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->workId(@_);}	
	
	my $workId   = shift;
	return $self->work->id($workId);
}

sub workAsLink {
	my $self = shift or return undef;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->workAsLink(@_);}	
	
	my $composer = shift or return undef;
	$self->addComposer( DataFile::Composer->new( { linkTo => $composer}) ); 
}

sub work {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->work(@_);}	
	
	my $work = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($work) {
		#if there is already an object
		if (ref($self->{work}) eq 'DataFile::Work') {
			# return It
			return $self->{work};
		}else { # create a new empty object of this type
			$self->{work}= DataFile::Work->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($work) eq 'DataFile::Work') { 
		$self->{work}= $work; 
	}
	elsif($work){  # We only insert objects of the good type
		ERROR('Object ->work called with an unexpected parameter '.ref($work).' waiting a DataFile::Work');
	}
	# Return the set object
	return $self->{work};
}

sub id {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->id(@_);}	
	
	my $id = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
}


sub  length  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->lenght(@_);}	
	
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

sub index {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->index(@_);}	
	
	my $index = shift;
	if ($index) { $self->{index} = Tools::trim($index) }
	return $self->{index};
}

sub place  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->place(@_);}	
	
	my $place = shift;
	# if there is no parameter in input
	unless($place) {
		#if there is already an composedPlace in the composer object
		if (ref($self->{place}) eq 'DataFile::Place'){
			# return It
			return($self->{place});
		} else {
			# create it
			$self->{place} = DataFile::Place->new();
		}
		
	}
	# Called with a Place Object, replacing it
	if (ref($place) eq 'DataFile::Place') { 
		$self->{place}= $place; 
	}
	elsif($place){
		ERROR 'album->composed->place called with an unexpected parameter'.ref($place)  ;
	}
	return $self->{place};	
}

sub date  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->date(@_);}	
	
	my $date = shift;
	# if there is no parameter in input
	unless($date) {
		#if there is already an composedDate in the composer object
		if (ref($self->{date}) eq 'DataFile::Date'){
			# return It
			return($self->{date});
		} else {
			# create it
			$self->{date} = DataFile::Date->new();
		}
		
	}
	# Called with a Date Object, replacing it
	if (ref($date) eq 'DataFile::Date') { 
		$self->{date}= $date; 
	}
	elsif($date){
		ERROR 'albumReleaseDate called with an unexpected parameter'.ref($date)  ;
	}
	return $self->{date};	
}

#sub addNote {
#	my $self = shift;
#
#	# if $self is a link, call linked object method
#	if($self->isLink) { return $self->linkedPerformance()->addNote(@_);}	
#	
#	my $note = shift; 
#	unless( $note ) { ERROR("pas de note"); return; }
#	push @{$self->{notes}{note}}, $note;
#}

sub addNote {
	my $self = shift;
	my $note = shift; 
	# if param is not an doesn't-> return
	# if ( ref($note) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
		 if ( ref($note) ne 'DataFile::Note' ) {
		# return It
		ERROR ("no DataFile::Note object in parameter ");
		return (undef );
	}
	
	if($note->can('parent') ) {
		$note->parent($self);
	}
	push @{$self->{notes}{note}}, $note;
}
sub addCredit {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->addCredit(@_);}	
	
	my $credit = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($credit) ne 'DataFile::Credit' ) {
		# return It
		ERROR ("no credit  object in parameter ");
		return (undef );
}

	# if theres no composer name, return in error (that's the least we need)
	unless( $credit->name() ) { 
		ERROR("credit name manquant"); 
		return; 
	}

# TODO: chercher si le credit existe deja pour faire un update
	push @{$self->{credits}{credit}}, $credit;
}


sub credits  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->credits(@_);}	
	
	my $credits = shift;
	
	# if no credits array ref is sent
	if(!$credits) {
		# if no credits array exists

		if(ref($self->{credits}{credit}) ne 'ARRAY') {
			#create it
			$self->{credits}{credit}=[];
			DEBUG  'Initializing credits array'
		} # returning existing or initialized
		return ($self->{credits}{credit});
	}

	if($#$credits == -1) {
		WARN "called album->credits with an empty array, truncating!";
	}

	foreach my $credit (@{$credits}) {
		if(ref($credit) ne 'DataFile::Credit') {
			ERROR "album->credits called with an array containing at least an unexpected object".ref($credit);
			return(undef);
		}
	}
	$self->{credits}{credit} = $credits;
}


sub notes  {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->notes(@_);}	
	
	my $notes = shift;
	
	# if no notes array ref is sent
	if(!$notes) {
		# if no notes array exists

		if(ref($self->{notes}{note}) ne 'ARRAY') {
			#create it
			$self->{notes}{note}=[];
			DEBUG  'Initializing notes array'
		} # returning existing or initialized
		return ($self->{notes}{note});
	}

	if($#$notes == -1) {
		WARN "called album->notes with an empty array, truncating!";
	}

	foreach my $note (@{$notes}) {
		if(ref($note) ne 'DataFile::Note') {
			ERROR "album->notes called with an array containing at least an unexpected object".ref($note);
			return(undef);
		}
	}
	$self->{albumData}{notes}{note} = $notes;
}

sub recordType {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->recordType(@_);}	

	
	my $recordType = shift;
	if ($recordType) { $self->{recordType} = Tools::trim($recordType) }
	return $self->{recordType};
}

sub excerpt {
	my $self = shift;

	# if $self is a link, call linked object method
	if($self->isLink) { return $self->linkedPerformance()->excerpt(@_);}	
	
	my $excerpt = shift;
	if ($excerpt) { $self->{excerpt} = Tools::trim($excerpt) }
	return $self->{excerpt};
}

sub parent {
	my $self = shift or return undef;
	my $parent = shift or return undef;
	
	# if parent is called without a parameter, it's a get:  look for appropriate performance parent
	if (!defined($parent)) {
		# if the performance is associated with a track
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

# id of linked performance (xlink:href contains the #id of the pointed reference)
sub href {
	my $self = shift;
	my $referenceTo  = shift;
	if ($referenceTo) { $self->{'xlink:href'} =  '#'.Tools::trim($referenceTo) }
	return defined($self->{'xlink:href'})?substr($self->{'xlink:href'},1):undef;
}

# test if current Performance is a link or a real performance, returns true if current object is a link
sub isLink {
	my $self = shift or return(undef);
	return ( defined($self->{'xlink:href'}) and defined($self->{-linkedPerformance}) and ref($self->{-linkedPerformance}) eq 'DataFile::Performance' )?1:0;
}

# Link this performance to the performance object passed in parameter 
sub linkTo {
	my $self = shift or return(undef);
	my $performanceToBeLinked = shift or return(undef);
	
	if($performanceToBeLinked->isLink) {
		ERROR("Can't build link from a link, object must be a full Performance Object");
		return undef;
	}

	if ( ref($performanceToBeLinked) ne 'DataFile::Performance' ) {
		# return It
			ERROR("linkTo must be provided with a DataFile::Performance object not ".ref($performanceToBeLinked));
			return(undef);
	}
	unless(defined($performanceToBeLinked->id)) {
			ERROR('Performance->linkTo must be provided with a DataFile::Performance containing an ID');
			return(undef);		
	}
	
	# Delete all the content of current object (a link doesn't contain anything but the href element)
	delete @$self{keys %$self};
	$self->href($performanceToBeLinked->id);
	$self->linkedPerformance($performanceToBeLinked);
}

# If performance is a link object, return the performance object reference linked 
sub linkedPerformance {
	my $self = shift;
	my $performanceToBeLinked   = shift;
	
	# If passed object isn't a performance
	if ( defined($performanceToBeLinked) and (ref($performanceToBeLinked) ne 'DataFile::Performance') ) {
		# return It
		ERROR("linkTo must be provided with a DataFile::Performance object not ".ref($performanceToBeLinked));
		return(undef);
	}

	# if performance to link with is already a link, force the link to be to the real performance object
	if(defined($performanceToBeLinked) and $performanceToBeLinked->isLink) {
		$performanceToBeLinked = $performanceToBeLinked->linkedPerformance;
	}
	
	if ($performanceToBeLinked) { $self->{-linkedPerformance} = $performanceToBeLinked }
	return $self->{-linkedPerformance};
}


END { }    # module clean-up code here (global destructor)
1;
