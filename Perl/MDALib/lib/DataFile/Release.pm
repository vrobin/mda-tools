#!/usr/bin/perl -w
package DataFile::Release;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

# TODO: create release like objects for published

sub new {
        my $class = shift;
        my $release = {};
        bless ($release, $class);
        return $release;
}

sub release {
        my $self = shift;
        if (@_) { $self = shift; }
        return $self;
}

# TODO: add note handling and object in release (has defined in collection.xsd)

# Take every objects in the structure and bless to the appropriate object
sub deserialize{
	my $self = shift or return undef;
	Tools::blessObject('DataFile::Date', $self->{date});
	Tools::blessObject('DataFile::Label', $self->{label});
	
	if(exists($self->{tags}) and exists($self->{tags}{tag}) ) {
		unless(ref($self->{tags}{tag}) eq 'ARRAY') {
			my $tag=$self->{tags}{tag};
			push @{$self->{tags}{tag}=[]}, $tag;

		}
		Tools::blessObjects('DataFile::Tag', $self->{tags}{tag});
	}
}

sub catalogNumber {
	my $self = shift;
	my $catNum = shift;
	if ($catNum) { $self->{catalogNumber} = Tools::trim($catNum) }
	return $self->{catalogNumber};   	

}

sub mediaType{
	my $self = shift;
	my $mediaType = shift;
	if ($mediaType) { $self->{mediaType} = Tools::trim($mediaType) }
	return $self->{mediaType};   	
}

sub rawData {
	my $self = shift;
	my $rawData = shift;
	 if ($rawData) { 
# old tweak to force rawData not to be an attribute, but content text
#	 	$self->{rawData}{forceText} = 'true';
	 	$self->{rawData}{content} = Tools::trim($rawData) 
	}
	return $self->{rawData}{content};
}
sub label  {
	my $self = shift;
	my $label = shift;
	# if there is no parameter in input
	unless($label) {
		#if there is already an releaseLabel in the composer object
		if (ref($self->{label}) eq 'DataFile::Label'){
			# return It
			return($self->{label});
		} else {
			# create it
			$self->{label} = DataFile::Label->new();
		}
		
	}
	# Called with a Label Object, replacing it
	if (ref($label) eq 'DataFile::Label') { 
		$self->{label}= $label; 
	}
	elsif($label){
		ERROR 'album->release->label called with an unexpected parameter'.ref($label)  ;
	}
	return $self->{label};	
}

sub numberOfMedia{
	my $self = shift;
	my $numberOfMedia = shift;
	if ($numberOfMedia) { $self->{numberOfMedia} = Tools::trim($numberOfMedia) }
	return $self->{numberOfMedia};   	
}

sub addTag {
	my $self = shift;
	my $tag = shift; 
	# if param is not an doesn't-> return
	# if ( ref($tag) !~ m/DataSource\:\:[\w]{0,3}\:\:[\w]*Reader/ ) {
		 if ( ref($tag) ne 'DataFile::Tag' ) {
		# return It
		ERROR ("no DataFile::Tag object in parameter ");
		return (undef );
	}
	
	#  tag must have these properties filled for coherency check
	unless( $tag->name() ) { 
		ERROR("Missing name  in Tag"); 
		return; 
	}
	
	# foreach tag in this object, look for an already existing tag with the same name
#	foreach my $existingTag ( @{$self->{tags}{tag}} ) {
#		if($existingDataSource->name() eq $tag->name()) {
#			ERROR("Tag ",$tag->name()," already exists, can't add it, try an update");
#			return undef;
#		}
#	}
	# A try to ease the access to dataSource from its name. Not sure it will be useful, let it commentend for now
	if($tag->can('parent') ) {
		$tag->parent($self);
	}
	push @{$self->{tags}{tag}}, $tag;
}

sub date  {
	my $self = shift;
	my $date = shift;
	# if there is no parameter in input
	unless($date) {
		#if there is already an releaseDate in the composer object
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


END { }    # module clean-up code here (global destructor)
1;
