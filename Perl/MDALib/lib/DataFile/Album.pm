#!/usr/bin/perl -w
package DataFile::Album;

use strict;
use utf8;
use Data::Dumper;
use DataFile::Date;
use DataFile::Composer;
use DataFile::Note;
use DataFile::Picture;
use DataFile::Release;
use Tools;
use Log::Log4perl qw(:easy);


sub new {
	my $class = shift;
	my $album = {};
	bless ($album, $class);
	return $album;
}

sub findPerfs{
	my $self = shift;
	my $lookupProperty = shift or return(undef);
	my $lookupValue = shift or return(undef);
	my @foundPerfs;

	if(ref($lookupProperty) eq 'CODE') { # property is a sub to execute
		foreach  (@{$self->performances()}){
	#		print($_->name,"\n");
	#		print("looking ", $_->id()," for $lookupProperty -> $lookupValue\n");
			if(&$lookupProperty() eq $lookupValue) {
	#			print("found composerormance",$_->id(),"\n");
				wantarray?push @foundPerfs, $_:return($_);
			}
		}		
	}else {
		foreach my $perf (@{$self->performances()}){
	#		print("looking ", $perf->id()," for $lookupProperty -> $lookupValue\n");
			if($perf->$lookupProperty() eq $lookupValue) {
	#			print("found performance",$perf->id(),"\n");
				wantarray?push @foundPerfs, $perf:return($perf);
			}
		}
	}
	return @foundPerfs;
}

sub findWorks{
	my $self = shift;
	my $lookupProperty = shift or return(undef);
	my $lookupValue = shift or return(undef);
	my @foundWorks;
	foreach my $work (@{$self->works()}){
#		print("looking ", $work->id()," for $lookupProperty -> $lookupValue\n");
		if($work->$lookupProperty() eq $lookupValue) {
#			print("found work ",$work->id(),"\n");
			wantarray?push @foundWorks, $work:return($work);
		}
	}
	return @foundWorks;
}

sub findCredits{
	my $self = shift;
	my %lookPropertiesHash = %{shift()} or return(undef);
	my @foundCredits;
	ALBUMCREDITS:
	foreach my $credit (@{$self->credits()}){
		LOOKUPPROPERTY:
		foreach my$property (keys %lookPropertiesHash) {
			unless($credit->{$property} and $credit->{$property}eq $lookPropertiesHash{$property} ) {
				next ALBUMCREDITS; # if the credit differs from the looked up property, forgive this one
			}
		}
		# if at the end of the properties the credit matches the properties looked up so add it
		# return immediately with found object if calling is not waiting for a list
		wantarray?push @foundCredits, $credit:return($credit);
	}
	return @foundCredits;
}


sub album {
	my $self = shift;
	if (@_) { $self = shift; }
	return $self;
}

sub name {
	my $self = shift;
	my $name = shift;
	if ($name) { $self->{name} = Tools::trim($name) }
	return $self->{name};
}

sub id {
	my $self = shift;
	my $id = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
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

# fake object for "one release only" datasources
sub release  {
	my $self = shift;

	my $release = shift;
	# if there is no parameter in input
	unless(defined($release)) {
		#if there is already a release in the release object
		if (ref($self->{releases}{release}->[0]) eq 'DataFile::Release'){
			# return It
			return($self->{releases}{release}->[0]);
		} else {
			# create it
			$self->{releases}{release}->[0] = DataFile::Release->new();
		}
	}
	# Called with a release Object, replacing it
	if (ref($release) eq 'DataFile::Release') { 
		$self->{releases}{release}->[0]= $release; 
	}
	elsif($release){
		ERROR 'work release called with an unexpected parameter'.ref($release)  ;
	}
	return $self->{releases}{release}->[0];	
}

sub numberOfDiscs{
	my $self = shift;
	my $numberOfDiscs = shift;
	if (defined($numberOfDiscs)) { 
		#$self->{numberOfDiscs} = Tools::trim($numberOfDiscs);
		# by default, album->numberOfDiscs goes in first release number of Media
		$self->release->numberOfMedia(Tools::trim($numberOfDiscs));
		DEBUG("Album -> numberOfDiscs set to $numberOfDiscs");
	}
	if(  defined($self->release->numberOfMedia()) and  $self->release->numberOfMedia() !~ /^[0-9]+$/ )  {
		WARN "Number of discs, not in integer format! -".$self->release->numberOfMedia()."-";
	}
	return $self->release->numberOfMedia();
}

sub mediaType{
	my $self = shift;
	my $mediaType = shift;
	if (defined($mediaType)) { 
		#$self->{mediaType} = Tools::trim($mediaType);
		# by default, album->mediaType goes in first release number of Media
		$self->release->mediaType(Tools::trim($mediaType));
		DEBUG("Album -> mediaType set to $mediaType");
	}
	return $self->release->mediaType();
}

#sub mediaType{
#	my $self = shift;
#	my $mediaType = shift;
#	if ($mediaType) { $self->{mediaType} = Tools::trim($mediaType) }
#	return $self->{mediaType};   	
#}

sub performances  {
	my $self = shift;
	my $performances = shift;
	# print("QSD! ".ref($performances->[0])."\n"); >> QSD! DataFile::performance
	# print("QSD! ".ref($performances)."\n"); >> QSD! ARRAY
	# print("QSD! ".ref($performances)." - ".$#$performances."\n");
	
	# if no performances array ref is sent
	if(!$performances) {
		# if no performances array exists
		if(ref($self->{performances}{performance}) ne 'ARRAY') {
			#create it
			$self->{performances}{performance}=[];
			DEBUG 'Initializing performances array'
		} # returning existing or initialized
		return ($self->{performances}{performance});
	}

	if($#$performances == -1) {
		WARN "called album->performances with an empty array, truncating!";
	}

	foreach my $performance(@{$performances}) {
		if(ref($performance) ne 'DataFile::Performance') {
			ERROR "album->performances called with an array containing at least an unexpected object".ref($performance);
			return(undef);
		}
	}
	$self->{performances}{performance} = $performances;
}


sub artworks  {
	my $self = shift;
	my $artworks = shift;
	
	# if no artworks array ref is sent
	if(!$artworks) {
		# if no artworks array exists
		if(ref($self->{artworks}{picture}) ne 'ARRAY') {
			#create it
			$self->{artworks}{picture}=[];
			DEBUG  'Initializing artworks array'
		} # returning existing or initialized
		return ($self->{artworks}{picture});
	}

	if($#$artworks == -1) {
		WARN "called album->artworks with an empty array, truncating!";
	}

	foreach my $artwork (@{$artworks}) {
		if(ref($artwork) ne 'DataFile::Picture') {
			ERROR "album->artworks called with an array containing at least an unexpected object".ref($artwork);
			return(undef);
		}
	}
	$self->{artworks}{picture} = $artworks;
	return ($self->{artworks}{picture});
}

sub releases  {
	my $self = shift;
	my $releases = shift;
	
	# if no releases array ref is sent
	if(!$releases) {
		# if no releases array exists
		if(ref($self->{releases}{release}) ne 'ARRAY') {
			#create it
			$self->{releases}{release}=[];
			DEBUG 'Initializing releases array'
		} # returning existing or initialized
		return ($self->{releases}{release});
	}

	if($#$releases == -1) {
		WARN "called album->releases with an empty array, truncating!";
	}

	foreach my $release (@{$releases}) {
		if(ref($release) ne 'DataFile::Release') {
			ERROR "album->releases called with an array containing at least an unexpected object".ref($release);
			return(undef);
		}
	}
	$self->{releases}{release} = $releases;
	return ($self->{releases}{release});
}

sub awards  {
	my $self = shift;
	my $awards = shift;
	
	# if no awards array ref is sent
	if(!$awards) {
		# if no awards array exists
		if(ref($self->{awards}{award}) ne 'ARRAY') {
			#create it
			$self->{awards}{award}=[];
			DEBUG 'Initializing awards array'
		} # returning existing or initialized
		return ($self->{awards}{award});
	}

	if($#$awards == -1) {
		WARN "called album->awards with an empty array, truncating!";
	}

	foreach my $award (@{$awards}) {
		if(ref($award) ne 'DataFile::Award') {
			ERROR "album->awards called with an array containing at least an unexpected object".ref($award);
			return(undef);
		}
	}
	$self->{awards}{award} = $awards;
	return ($self->{awards}{award});
}

sub notes  {
	my $self = shift;
	my $notes = shift;
	
	# if no notes array ref is sent
	if(!$notes) {
		# if no notes array exists

		if(ref($self->{notes}{note}) ne 'ARRAY') {
			#create it
			$self->{notes}{note}=[];
			DEBUG 'Initializing notes array'
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
	$self->{notes}{note} = $notes;
	return $self->{notes}{note};
}

sub credits  {
	my $self = shift;
	my $credits = shift;
	
	# if no credits array ref is sent
	if(!$credits) {
		# if no credits array exists

		if(ref($self->{credits}{credit}) ne 'ARRAY') {
			#create it
			$self->{credits}{credit}=[];
			DEBUG 'Initializing credits array'
		} # returning existing or initialized
		return ($self->{credits}{credit});
	}

	if($#$credits == -1) {
		DEBUG "called album->credits with an empty array, truncating!";
	}

	foreach my $credit (@{$credits}) {
		if(ref($credit) ne 'DataFile::Credit') {
			ERROR "album->credits called with an array containing at least an unexpected object".ref($credit);
			return(undef);
		}
	}
	$self->{credits}{credit} = $credits;
	return $self->{credits}{credit};
}

sub discs  {
	my $self = shift;
	my $discs = shift;
	
	# if no discs array ref is sent
	if(!$discs) {
		# if no discs array exists

		if(ref($self->{discs}{disc}) ne 'ARRAY') {
			#create it
			$self->{discs}{disc}=[];
			DEBUG  'Initializing discs array'
		} # returning existing or initialized
		return ($self->{discs}{disc});
	}

	if($#$discs == -1) {
		WARN "called album->discs with an empty array, truncating!";
	}

	foreach my $disc (@{$discs}) {
		if(ref($disc) ne 'DataFile::Disc') {
			ERROR "album->discs called with an array containing at least an unexpected object".ref($disc);
			return(undef);
		}
	}
	$self->{discs}{disc} = $discs;
	return $self->{discs}{disc};
}

sub tags  {
	my $self = shift;
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

sub works  {
	my $self = shift;
	my $works = shift;
	# print("QSD! ".ref($works->[0])."\n"); >> QSD! DataFile::Work
	# print("QSD! ".ref($works)."\n"); >> QSD! ARRAY
	# print("QSD! ".ref($works)." - ".$#$works."\n");
	
	# if no works array ref is sent
	if(!$works) {
		# if no works array exists
		if(ref($self->{works}{work}) ne 'ARRAY') {
			#create it
			$self->{works}{work}=[];
			DEBUG 'Initializing works array'
		} # returning existing or initialized
		return ($self->{works}{work});
	}

	if($#$works == -1) {
		WARN "called album->works with an empty array, truncating!";
	}

	foreach my $work(@{$works}) {
		if(ref($work) ne 'DataFile::Work') {
			ERROR "album->works called with an array containing at least an unexpected object".ref($work);
			return(undef);
		}
	}
	$self->{works}{work} = $works;
}

sub addNote {
	my $self = shift;
	my $note = shift; 
	unless( $note ) { ERROR("pas de note"); return; }
	# if note isn't a note object, could be a raw note to insert
	unless (ref($note) eq 'DataFile::Note') {
		$note = DataFile::Note->new( {rawData => $note});
	}
	push @{$self->{notes}{note}}, $note;
}

# stub to releases/release[0]/label
sub  label  {
	my $self = shift;
	my $label = shift;
	if (defined($label)) { 
		$self->release->label(Tools::trim($label));
		DEBUG("Album -> label set to $label");
	}
	return $self->release->label();	
	
# Before, when label was attached to album instead of release
#	# S'il n'y a pas de paramètre en entrée
#	unless($label) {
#		#if there is already an albumLabel
#		if (ref($self->{'label'}) eq 'DataFile::Label') {
#			# return It
#			return $self->{'label'};
#		}else {
#			$self->{'label'}= DataFile::Label->new();
#		}
#	}
#	# Called with a Label Object, replacing it
#	if (ref($label) eq 'DataFile::Label') { 
#		$self->{'label'}= $label; 
#	}
#	elsif($label){
#		ERROR 'album->label called with an unexpected parameter'.ref($label)  ;
#	}
#	return $self->{'label'};
}

sub  length  {
	my $self = shift;
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

sub addComposerAsLink {
	my $self = shift or return undef;
	my $composer = shift or return undef;
	$self->addComposer( DataFile::Composer->new( { linkTo => $composer}) ); 
}
	
sub addComposer {
	my $self = shift;
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

sub addCredit {
	my $self = shift;
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
	push @{$self->{credits}{credit}}, $credit;
}

sub addDisc {
	my $self = shift;
	my $disc = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($disc) ne 'DataFile::Disc' ) {
		# return It
		ERROR ("no disc  object in parameter ");
		return (undef );
	}

	# if theres no composer name, return in error (that's the least we need)
#	unless( $disc->name() ) { 
#		ERROR("disc name manquant"); 
#		return; 
#	}
	$disc->album($self);
	push @{$self->{discs}{disc}}, $disc;
}

sub parent {
	return dataSource(@_);
}

sub dataSource {
	my $self = shift;
	my $dataSource = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($dataSource) {
		#if there is already an object
		#	# if ( ref($objectName) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
		if (ref($self->{-dataSource}) =~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
			# return It
			return $self->{-dataSource};
		}else { # create a new empty object of this type
			#$self->{dataSource}= DataFile::DataSource->new();
			#as work is a backreference, we don't create new empty object but return undef
			return undef;			
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($dataSource) =~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/) { 
		$self->{-dataSource}= $dataSource; 
	}
	elsif($dataSource){  # We only insert objects of the good type
		ERROR('Object ->dataSource called with an unexpected parameter '.ref($dataSource).' waiting a DataFile::DataSource');
		die("ZZZZ");
		die Dumper \$dataSource;
	}
	# Return the set object
	return $self->{-dataSource};
}

sub findTags{
	my $self = shift;
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

sub findComposers{
	my $self = shift;
	my $lookupProperty = shift or return(undef);
	my $lookupValue = shift or return(undef);
	my @foundComposers;
	#TODO: check if this piece of crap is working
	if(ref($lookupProperty)  eq 'CODE') {
		foreach  (@{$self->composers()}){
	#		print("looking ", $_->id()," for $lookupProperty -> $lookupValue\n");
			if(&$lookupProperty() eq $lookupValue) {
	#			print("found composerormance",$_->id(),"\n");
				wantarray?push @foundComposers, $_:return($_);
			}
		}		
	}else {
		foreach my $composer (@{$self->composers()}){
	#		print("looking ", $composer->id()," for $lookupProperty -> $lookupValue\n");
			if($composer->$lookupProperty() eq $lookupValue) {
	#			print("found composerormance",$composer->id(),"\n");
				wantarray?push @foundComposers, $composer:return($composer);
			}
		}
	}
	return @foundComposers;
}

sub composers  {
	my $self = shift;
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


# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;

	if(exists($self->{artworks}) and exists($self->{artworks}{picture}) ) {
		unless(ref($self->{artworks}{picture}) eq 'ARRAY') {
			my $picture=$self->{artworks}{picture};
			push @{$self->{artworks}{picture}=[]}, $picture;
		}
		Tools::blessObjects('DataFile::Picture', $self->{artworks}{picture});
	}
#	Tools::blessObjects('DataFile::Picture', $self->{artworks}{picture});

	if(exists($self->{awards}) and exists($self->{awards}{award}) ) {
		unless(ref($self->{awards}{award}) eq 'ARRAY') {
			my $award=$self->{awards}{award};
			push @{$self->{awards}{award}=[]}, $award;
		}
		Tools::blessObjects('DataFile::Award', $self->{awards}{award});
	}
	
	if(exists($self->{composers}) and exists($self->{composers}{composer}) ) {
		unless(ref($self->{composers}{composer}) eq 'ARRAY') {
			my $composer=$self->{composers}{composer};
#			$self->{composers}{composer}=undef;
#			$self->{composers}{composer}->[0]=$composer;
			push @{$self->{composers}{composer}=[]}, $composer;
			#push @{$self->{composers}{composer}}, $self->{composers}{composer};
		}
		Tools::blessObjects('DataFile::Composer', $self->{composers}{composer});
	}
	if(exists($self->{credits}) and exists($self->{credits}{credit}) ) {
		unless(ref($self->{credits}{credit}) eq 'ARRAY') {
			my $credit=$self->{credits}{credit};
			push @{$self->{credits}{credit}=[]}, $credit;

		}
		Tools::blessObjects('DataFile::Credit', $self->{credits}{credit});
	}

#	Tools::blessObjects('DataFile::Credit', $self->{credits}{credit});
	if(exists($self->{discs}) and exists($self->{discs}{disc}) ) {
		unless(ref($self->{discs}{disc}) eq 'ARRAY') {
			my $disc=$self->{discs}{disc};
			push @{$self->{discs}{disc}=[]}, $disc;

		}
		Tools::blessObjects('DataFile::Disc', $self->{discs}{disc});
	}
# 	Tools::blessObjects('DataFile::Disc', $self->{discs}{disc});

	Tools::blessObject('DataFile::Label', $self->{label});
	Tools::blessObject('DataFile::Length', $self->{length});
	if(exists($self->{notes}) and exists($self->{notes}{note}) ) {
		unless(ref($self->{notes}{note}) eq 'ARRAY') {
			my $note=$self->{notes}{note};
			push @{$self->{notes}{note}=[]}, $note;

		}
		Tools::blessObjects('DataFile::Note', $self->{notes}{note});
	}
#	Tools::blessObjects('DataFile::Note', $self->{notes}{note});
	Tools::blessObject('DataFile::Place', $self->{origin});
	if(exists($self->{performances}) and exists($self->{performances}{performance}) ) {
		unless(ref($self->{performances}{performance}) eq 'ARRAY') {
			my $performance=$self->{performances}{performance};
			push @{$self->{performances}{performance}=[]}, $performance;

		}
		Tools::blessObjects('DataFile::Performance', $self->{performances}{performance});
	}
#	Tools::blessObjects('DataFile::Performance', $self->{performances}{performance});

	if(exists($self->{ratings}) and exists($self->{ratings}{rating}) ) {
		unless(ref($self->{ratings}{rating}) eq 'ARRAY') {
			my $rating=$self->{ratings}{rating};
			push @{$self->{ratings}{rating}=[]}, $rating;

		}
		Tools::blessObjects('DataFile::Rating', $self->{ratings}{rating});
	}
#	Tools::blessObjects('DataFile::Rating', $self->{ratings}{rating});

	if(exists($self->{releases}) and exists($self->{releases}{release}) ) {
		unless(ref($self->{releases}{release}) eq 'ARRAY') {
			my $release=$self->{releases}{release};
			push @{$self->{releases}{release}=[]}, $release;

		}
		Tools::blessObjects('DataFile::Release', $self->{releases}{release});
	}
#	Tools::blessObjects('DataFile::Release', $self->{releases}{release});

	if(exists($self->{tags}) and exists($self->{tags}{tag}) ) {
		unless(ref($self->{tags}{tag}) eq 'ARRAY') {
			my $tag=$self->{tags}{tag};
			push @{$self->{tags}{tag}=[]}, $tag;

		}
		Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});
	}
#	Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});	

	if(exists($self->{works}) and exists($self->{works}{work}) ) {
		unless(ref($self->{works}{work}) eq 'ARRAY') {
			my $work=$self->{works}{work};
			push @{$self->{works}{work}=[]}, $work;

		}
		Tools::blessObjects('DataFile::Work', $self->{works}{work});
	}
#	Tools::blessObjects('DataFile::Work', $self->{works}{work});

	# Initialize backpointer disc -> album for each disc found 
	foreach my $disc (@{$self->discs()}) {
		$disc->album($self);
	}
	# Initialize backpointer performance -> album for each performance found 
	foreach my $performance (@{$self->performances()}) {
#TODO: check if all this "parent" calls couldn't be made in Tools::blessObjects 		
		$performance->parent($self);
	}
	# Initialize backpointer work -> album for each work found 
	foreach my $work (@{$self->works()}) {
		$work->parent($self);
	}

}

sub addArtwork {
	my $self = shift;
	my $artwork = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($artwork) ne 'DataFile::Picture' ) {
		# return It
		ERROR ("no picture object in parameter ");
		return (undef );
	}

	# if theres no artwork url, return in error (that's the least we need)
	unless( $artwork->url() ) { 
		ERROR("artwork url name manquant"); 
		return; 
	}
	push @{$self->{artworks}{picture}}, $artwork;
}

sub addTag {
	my $self = shift;
	my $tag = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($tag) ne 'DataFile::Tag' ) {
		# return It
		ERROR ("no tag  object in parameter ");
		return (undef );
	}

	# if theres no tag url, return in error (that's the least we need)
	unless( $tag->name() ) { 
		ERROR("tag url name manquant"); 
		return; 
	}
	push @{$self->{tags}{tag}}, $tag;
}

sub addAward {
	my $self = shift;
	my $award = shift; 
	
	# if param is not a Award object -> return 
	if ( ref($award) ne 'DataFile::Award' ) {
		# return It
		ERROR ("no award  object in parameter ");
		return (undef );
	}

	# if theres no composer name, return in error (that's the least we need)
	unless( $award->name() ) { 
		ERROR("award name manquant"); 
		return; 
	}
	push @{$self->{awards}{award}}, $award;
}


sub addWork {
	my $self = shift;
	my $work = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($work) ne 'DataFile::Work' ) {
		# return It
		ERROR ("no work  object in parameter ");
		return (undef );
	}

	# if theres no composer name, return in error (that's the least we need)
	unless( $work->name() ) { 
		ERROR("work name manquant"); 
		return; 
	}
	push @{$self->{works}{work}}, $work;
}

sub addPerformance {
	my $self = shift;
	my $performance = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($performance) ne 'DataFile::Performance' ) {
		# return It
		ERROR ("no performance  object in parameter ");
		return (undef );
	}

	# TODO: s'assurer que l'on a soit un workId, soit un workIndex
	# TODO: gérer les doublons?
	# TODO: Merger les éléments existants
	# if theres no composer name, return in error (that's the least we need)
	unless( $performance->url() ) { 
		ERROR("performance url manquant"); 
		return; 
	}
	push @{$self->{performances}{performance}}, $performance;
}

sub addRating {
	my $self = shift;
	my $rating = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($rating) ne 'DataFile::Rating' ) {
		# return It
		ERROR ("no rating  object in parameter ");
		return (undef );
	}

	# if theres no composer name, return in error (that's the least we need)
	unless( $rating->value() ) { 
		ERROR("rating value manquant"); 
		return; 
	}
	push @{$self->{ratings}{rating}}, $rating;
}

sub addRelease {
	my $self = shift;
	my $release = shift; 
	
	# if param is not a Composer object -> return 
	if ( ref($release) ne 'DataFile::Release' ) {
		# return It
		ERROR ("no release  object in parameter ");
		return (undef );
	}

	# if theres no composer name, return in error (that's the least we need)
#	unless( $release->value() ) { 
#		ERROR("release value manquant"); 
#		return; 
#	}
	push @{$self->{releases}{release}}, $release;
}


# DONE: Transform this text field in Place object!
#sub origin{
#	my $self = shift;
#	my $origin = shift;
#	if ($origin) { $self->{origin} = Tools::trim($origin) }
#	return $self->{origin};   	
#}

sub origin {
	my $self = shift;
	my $origin = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($origin) {
		#if there is already an object
		if (ref($self->{origin}) eq 'DataFile::Place') {
			# return It
			return $self->{origin};
		}else { # create a new empty object of this type
			$self->{origin}= DataFile::Place->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($origin) eq 'DataFile::Place') { 
		$self->{origin}= $origin; 
	}
	elsif($origin){  # We only insert objects of the good type
		ERROR('Object ->origin called with an unexpected parameter '.ref($origin).' waiting a DataFile::Place');
	}
	# Return the set object
	return $self->{origin};
}

sub channels{
	my $self = shift;
	my $channels = shift;
	if ($channels) { $self->{channels} = Tools::trim($channels) }
	return $self->{channels};   	
}

sub providerName{
	my $self = shift;
	my $providerName = shift;
	if ($providerName) { $self->{providerName} = Tools::trim($providerName) }
	return $self->{providerName};   	
}

sub providerVersion{
	my $self = shift;
	my $providerVersion = shift;
	if ($providerVersion) { $self->{providerVersion} = Tools::trim($providerVersion) }
	return $self->{providerVersion};   	
}

# previous version, before moving catalogue Number in release object
#sub catalogNumber {
#	my $self = shift;
#	my $catNum = shift;
#	if ($catNum) { $self->{catalogNumber} = Tools::trim($catNum) }
#	return $self->{catalogNumber};   	
#
#}

sub catalogNumber{
	my $self = shift;
	my $catalogNumber = shift;
	if (defined($catalogNumber)) { 
		$self->release->catalogNumber(Tools::trim($catalogNumber));
		DEBUG("Album -> catalogNumber set to $catalogNumber");
	}
	return $self->release->catalogNumber();
}

sub albumSparsCode {
	my $self = shift;
	my $sparsCode = shift;
	if ($sparsCode) { $self->{sparsCode} = Tools::trim($sparsCode) }
	return $self->{sparsCode};
}

#sub  releaseDate  {
#	my $self = shift;
#	my $date = shift;
#	
#	# if there's no input parameter
#	unless($date) {
#		#if there is already an albumReleaseDate
#		if (ref($self->{releaseDate}) eq 'DataFile::Date') {
#			# return It
#			return $self->{releaseDate};
#		}else {
#			$self->{releaseDate}= DataFile::Date->new();
#		}
#	}
#	# Called with a Date Object, replacing it
#	if (ref($date) eq 'DataFile::Date') { 
#		$self->{releaseDate}= $date; 
#	}
#	elsif($date){
#		ERROR 'albumReleaseDate called with an unexpected parameter'.ref($date)  ;
#	}
#	return $self->{releaseDate};
#}

END { }    # module clean-up code here (global destructor)
1;
