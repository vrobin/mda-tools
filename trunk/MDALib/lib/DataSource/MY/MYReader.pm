#!/usr/bin/perl -w

package DataSource::MY::MYReader;

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

use Log::Log4perl qw(:easy);
use List::Util qw(min max);

my $DataSourceName = 'MY';
my $DataSourceVer = '0.1';
my $providerName ='MY Reader';
my $providerUrl =undef;

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

my %elements = (
	a => 'album',
	d =>'disc',
	t => 'track',
	w =>'work',
	p => 'performance',
	c => 'composer',
	g => 'tag',
	r => 'credit',
	m => 'composed',
	l => 'label',
	z => 'normalized'
);


# Try to find album from available data
sub retrieve {
	my $self = shift or return(undef);
	ERROR("Retrieve method not available");
	return undef;
}

# range regexp : /?[sadtwpcgrm](([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?
# has to match d*t* (every disc, every track)
# d*t1-3 three first tracks of every discs
# d*t*w*c composer of every disc, every track, every work, every composer
# ag album tag
# exemple add featured artist tag to album: add --target ag 'Featured Artist'='Fabio Biondi' 
#               set work range composed date:   set --target=/a/d*/t*/w/m/date/rawData 1978
# default /d/a  => t*/name == /d/a/t*/name  name /d/a/name
# Shortcut t* = /d/a/t*  w* = /d/a/w*  p* = /d/a/p*
sub add {
	my $self = shift or return undef;
	# the target string in the form /a/d*/t*/w/m/date/rawData value=1978
	my $target  = shift or return undef;
	my @setArguments = @_;
	my %properties;
	# Check command line arguments for "add" action, must be a list of propertie=value parameters
	unless(scalar(@setArguments) > 0 ) {
			ERROR("Not enough arguments in command line, add can only be called with a one or more 'value=myvalue' parameters");
	}
	
	# build the propertie hash
	#foreach my $propertyString (@setArguments) { print($propertyString." ".( $propertyString =~ /^([^=]+)=([^=]+)$/ )."\n"); } die;
	foreach my $propertyString (@setArguments) {
		unless( $propertyString =~ /^([^=]+)=([^=]+)$/ ) {
			ERROR("Unexpected parameter '$propertyString', add can only be called with a one or more 'value=myvalue' parameters");			
		}
		$properties{$1} = $2;
	}
	
	#die Dumper \%properties;
	
	# we need to know the name of the type of the object to add
	unless($target =~ /([^\/]+)$/g ) {
		ERROR("Unexpected malformed object name in $target, target string must end with an array of object name without range ex: /a/tag");
		die;
	} 
	# methodName is everything before the last / 
	# ie. /a/t1,3/index => methodName: index
	my $objectName =$1;

	# resolve object/properties aliasing from element shortcuts hash
	if(exists $elements{$objectName}) {
		$objectName =  $elements{$objectName};
	}
	
	# if $methodName contains anything but letters (like a range for example)
	unless($objectName =~ /^[a-zA-Z]*$/) {
		ERROR("For a 'add' action, last object of the selector must be a single name and can't be a range");
		die;
	}

	unless( substr($objectName,-1,1) eq 's' ) { # if the object is not ending with "s" we mus add it as add works on array of objects
		$objectName.='s'; # add the 's' as every object arrays in MDA end with an 's' (it's input helping)
		$target.='s';  # must also add the 's' to the target string for find method to work 
	}

	# find all objects "targeted" by the set action
	my @targetObjects = $self->getObjectsFromSelectorString($target);
	
	foreach my $objectFound (@targetObjects) {
#		my $addMethodName = 'add'.$objectName;
#		my $className = 'DataFile::'.ucfirst($objectName);
		my $addMethodName= 'add'.ucfirst(substr($objectName, 0,-1));
		my $className = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
		unless($objectFound->can($addMethodName)) {
			ERROR("Object ".ref($objectFound)." doesn't have a $addMethodName for $className object");
			die; # this shouldn't happen if target string is well formed
		}
		
		# Create the object to add
		my $objectToAdd = $className->new();
		
		# Set each property of this new object according to properties found on command line parameters
		foreach my $property ( keys %properties) {
			unless($objectToAdd->can($property)) { # if object doesn't have such accessor, stop
				ERROR("Object ".ref($objectToAdd)." doesn't have a $property property/accessor");
				die; # this shouldn't happen if target string is well formed
			}
			# set the property on the new object
			$objectToAdd->$property($properties{$property});
		}
		$objectFound->$addMethodName($objectToAdd);
	}
	#Dumper \$self; die;
}

# set fields in object according to a object hierarchy string (see "add")
sub set {
	my $self = shift or return undef;
	# the target string in the form /a/d*/t*/w/m/date/rawData value=1978
	my $target  = shift or return undef;
	my @setArguments = @_;
	# Check command line arguments for "set" action
	unless(scalar(@setArguments) == 1 ) {
		if(scalar(@setArguments) == 0 ) {
			ERROR("Not enough arguments in command line, set can only be called with a single value or a value=myvalue pair");
		}else {
			ERROR("Too many arguments in command line, set can only be called with a single value or a value=myvalue pair");
		}

	}
	
	# find all objects "targeted" by the set action
	my @objectsToSet = $self->getObjectsFromSelectorString($target);
	# we need to now the name of the method to call upon each returned object
	unless($target =~ /([^\/]*)$/g ) {
		ERROR("Unexpected malformed range string ', this shouldn't happen");
		die;
	} 
	# methodName is everything before the last / 
	# ie. /a/t1,3/index => methodName: index
	my $methodName =$1;

	# resolve object/properties aliasing from element shortcuts hash
	if(exists $elements{$methodName}) {
		$methodName =  $elements{$methodName};
	}
	
	# if $methodName contains anything but letters (like a range for example)
	unless($methodName =~ /^[a-zA-Z]*$/) {
		ERROR("For a 'set' action, last object of the selector must be a single name and can't be a range");
		die;
	}
	
	foreach my $objectFound (@objectsToSet) {
		unless($objectFound->can($methodName)) {
			ERROR("Object ".ref($objectFound)."doesn't have a $methodName property/accessor");
			die; # this shouldn't happen if target string is well formed
		}
		$objectFound->$methodName($setArguments[0]);
		if($methodName eq 'rawData' and $objectFound->can('normalizeAndSetDate')) {
			#die("DDDDDDDD");
			$objectFound->normalizeAndSetDate();
		}
	}
	#Dumper \$self; die;
}


# transform an index range string like 1  or  1-3   or 1,2,3   in a list of integers(0,1,2) ready to use with an array
sub rangeStringToIndexList {
	my $self = shift or return undef;
	my $rangeString = shift or return undef;
	my @indexList;
	unless($rangeString =~ /^(([0-9]+-[0-9]+)|(\*)|([0-9]+(,[0-9]+)*))$/ ) {
		ERROR("Malformed range string ($rangeString), range must be something like [*|1|1-3|1,2,3]. \n");
		die;
	}

	if($rangeString =~ /^([0-9]+)$/ ) {
		if($rangeString == 0) {
			ERROR("Range must be a positive integer (not zero)");
			die;
		}
		push(@indexList, $rangeString-1) ;
	}
	elsif($rangeString =~ /^(([0-9]+)-([0-9]+)$)/ ) {
		if($2 == 0 or $3 == 0) {
			ERROR("Range must be a positive integer (not zero)");
			die;
		}
		if($2 > $3) {
			ERROR("Range must be increasing (1-3 but not 3-1");
			die;			
		}
		@indexList= ( ($2-1)..($3-1) );		
	}elsif($rangeString =~ /^([0-9]+(,[0-9]+)*)$/ ) {
		#TODO: check for duplicates
		@indexList = split(',', $rangeString);
		for my $i (0..$#indexList) {
			$indexList[$i]--;
		}
	}
	return @indexList;
}

sub remove {
	my $self = shift or return undef;
	# the target string in the form /a/d*/t*/w/m/date/rawData value=1978
	my $target  = shift or return undef;
	my @setArguments = @_;
	
	# Check command line arguments must be empty for remove (at first) 
	unless(scalar(@setArguments) == 0 ) {
		ERROR("Too many arguments in command line, remove can only be called with a target sting");
		die;
	}
	
	# find all objects "targeted" by the set action
	my @objectsToRemove = $self->getObjectsFromSelectorString($target, 1);
# Debug code
#	foreach (@objectsToRemove) {
#		print $_, "\n"
#	}
	# we need to now the name of the property to remove 
	#or to detect the presence of a range for deleting array parts 
	unless($target =~ /([^\/]*)$/g ) {
		ERROR("Unexpected malformed range string ', this shouldn't happen");
		die;
	} 
	# methodName is everything before the last / 
	# ie. /a/t1,3/index => methodName: index
	my $methodName =$1;
	# resolve object/properties aliasing from element shortcuts hash
	if(exists $elements{$methodName}) {
		$methodName =  $elements{$methodName};
	}
	foreach my $objectFound (@objectsToRemove) {
		print(ref($objectFound),"\n");
	}
	# if $methodName contains only letters 
	if($methodName =~ /^[a-zA-Z]*$/) { # range last object is a property, undef it
		foreach my $objectFound (@objectsToRemove) {
			if(ref($objectFound->$methodName())) { # if element found is an object
				#print "aze: $objectFound \n";
				#%{$objectFound} = {};   # empty it
				undef($objectFound->{$methodName});  # else it must be a value, just undef it				
			}else {
#				die(ref($objectFound)."$methodName");
				undef($objectFound->{$methodName});  # else it must be a value, just undef it
			}
		}
	}else { # last parameter must be a range, so delete complete object
		foreach my $objectFound (@objectsToRemove) {
			#print("aze: ".join( '/', keys (%{$objectFound}))."\n");
				print "qsd: $objectFound \n";
			%{$objectFound} = {};
		}
	}
	

	#Dumper \$self; die;}
}

sub getObjects {
	my $self =  shift or return(undef);
	my $params = shift or return(undef); # ( selectorArray, noAutoCreate, currentObject)
	unless(defined($params->{selectorArray})) {
			#Debug Code
#		ERROR("getObjects called without selector array");
		return(undef);	
	}

	unless(defined($params->{currentObject})) {
			#Debug Code
#		ERROR("getObjects called without a current object");
		return(undef);	
	}
	
	my @foundObjects;
	my @remainingSelectorObjectsList = @{$params->{selectorArray}};
	#print(join('/', @remainingSelectorObjectsList)."\n");

	my $selectorItemString = shift @remainingSelectorObjectsList;
	my $objectName;
	my $objectRange;
	my $currentObject = $params->{currentObject};
	
	# Regex coach test: [sadtwpcgrm](([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?
	# v2: ([a-zA-Z]*)(([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?$
	#print("Element: $element \n");
	if($selectorItemString =~ /^([a-zA-Z]*)(([0-9]+-[0-9]+)|(\*)|([0-9]+(,[0-9]+)*))?$/) {
		#print("$1:$2:$3:$4:$5:$6:$7 \n"); 
		$objectName = $1;
		$objectRange = $2;
	} else { 
		ERROR "Malformed range string ($selectorItemString), target string is (/<target><range>)+=<value> with target an mda object [disc|track|album| ...] and range [*|1|1-3|1,2,3]. \nEx: /album/track1-5/name Requiem  ";
		die; 
	}
			#Debug Code
#			ERROR("no create ", ref($currentObject));

	# resolve object/properties aliasing from element shortcuts hash
	if(exists $elements{$objectName}) {
		$objectName =  $elements{$objectName};
	}
			#Debug Code
#			ERROR("Next: ", $objectName);
	# if there's an object range, we'll have to call several the setFromObjectList for each object targeted by the range
	if(defined($objectRange)) {
			#Debug Code
#		ERROR("define range");
		#Debug Code
		#print("objectRange defini\n");
		unless( substr($objectName,-1,1) eq 's' ) { # if the object is not ending with "s" it mus be an error
			$objectName.='s'; # add the 's' as every object arrays in MDA end with an 's' (it's input helping)
		}
		# we have the name of an array of objects, get the array to call every object in the rang $objectRange
		# but before, verify if the current object has the array asked
		unless($currentObject->can($objectName)) {
			#Debug Code
#			ERROR("Object ". ref($currentObject)." has no property ${objectName}");
			die;
		}
		# the {<object_name>s} element doesn't exist
		if($params->{noAutoCreate} and (not exists($currentObject->{$objectName}) ) ) {
			#Debug Code
#			ERROR("no create");
			return undef;
		}
		# the {<object_name>s}{<object_name>} doesn't exist)
		if($params->{noAutoCreate} and (not exists($currentObject->{$objectName}{substr($objectName,0,-1)}) ) ) {
			#Debug Code
#			ERROR("no create");
			return undef;
		}
		# the {<object_name>s}{<object_name>} exists, but it's not an array ref
		if($params->{noAutoCreate} and (ref($currentObject->{$objectName}{substr($objectName,0,-1)}) ne 'ARRAY' ) ) {
			#Debug Code
#			ERROR("no create");
			return undef;
		}
		
		# ok, the array exists, get it and call setFromObjectList for each elements pointed by $objectRange
		my $objectArrayRef = $currentObject->$objectName();
		
		my @targetIndexes;
		if($objectRange eq '*') {
			@targetIndexes = (0..$#{$objectArrayRef})
		} else {
			@targetIndexes = $self->rangeStringToIndexList($objectRange);
		}
		# @targetIndexes contains all indexes of object to apply the next hierarchy command or to return

		# all array elements must exists, creating missing ones (even if we wan't to call a 'remove' in the end :-/ )
		unless($params->{noAutoCreate}) {
			for my $i (0..max(@targetIndexes)) {
				unless(exists($objectArrayRef->[$i]) and ref($objectArrayRef->[$i])) { # object doesn't exist, we must create it
					#my $addMethodName= 'add'.substr($objectName, 0,-1);
					my $objectClassName = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
					$objectArrayRef->[$i] = $objectClassName->new();
					# if object has index, try to set this index
					#if($objectArrayRef->[$i]->can('index')) 
					if( (ref($objectArrayRef->[$i]) eq 'DataFile::Disc') or (ref($objectArrayRef->[$i]) eq 'DataFile::Work')  or (ref($objectArrayRef->[$i]) eq 'DataFile::Performance') or (ref($objectArrayRef->[$i]) eq 'DataFile::Track')) {
						$objectArrayRef->[$i]->index($i+1);
					#
					# if($objectArrayRef->[$i]->can('id')) 
					#if( (ref($objectArrayRef->[$i]) eq 'DataFile::Work')  or (ref($objectArrayRef->[$i]) eq 'DataFile::Performance') or (ref($objectArrayRef->[$i]) eq 'DataFile::Track'))
						$objectArrayRef->[$i]->id($i+1);
					}
					if($objectArrayRef->[$i]->can('parent')) {
						$objectArrayRef->[$i]->parent($currentObject);
					}			
				}			
			}
		}
		for my $i (@targetIndexes) {
			#print("$self->setFromObjectList($objectArrayRef->[$i], @params); \n")
			# if noAutoCreate, skip unexisting objects
			if($params->{noAutoCreate} and (not exists($objectArrayRef->[$i]))  ) { next; }
			# if noAutoCreate, skip array elements that are not real objects
			if($params->{noAutoCreate} and not(ref($objectArrayRef->[$i]))) { next; }
			if(scalar(@remainingSelectorObjectsList)==0) { # this was a final node add it to found objects
				#my $objectClassName = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
				#$objectArrayRef->[$i] = $objectClassName->new();
				#$objectArrayRef->[$i] = undef;
				push @foundObjects, $objectArrayRef->[$i];
			}else { # continue hierarchy exploration
			 #( selectorArray, noAutoCreate, currentObject)
				#push @foundObjects, $self->getObjectsFromSelectorArray($objectArrayRef->[$i], @remainingSelectorObjectsList);
				push @foundObjects, $self->getObjects({ currentObject => $objectArrayRef->[$i], selectorArray => \@remainingSelectorObjectsList, noAutoCreate => $params->{noAutoCreate}});
			}
		}

	} else { # no object range given, calling single object code
		unless($currentObject->can($objectName)  ) {
			ERROR("Object ". ref($currentObject)." has no property $objectName");
			die;
		}
		
		if(scalar(@remainingSelectorObjectsList)==0) { # this was a final node: return it
			#Debug Code
#			print("dernier objet\n");
			push @foundObjects, $currentObject;
		}else { # continue hierarchy exploration
			# get next object in the hierarchy
			my $nextObject;
			# Continue exploring only if object exists or
			if(!$params->{noAutoCreate} or (exists($self->{$objectName})) ) { 
				$nextObject=$currentObject->$objectName();
				push @foundObjects, $self->getObjects({ currentObject => $nextObject, selectorArray => \@remainingSelectorObjectsList, noAutoCreate => $params->{noAutoCreate}});			
			}
			# call accessor
			#push @foundObjects,$self->getObjectsFromSelectorArray($nextObject, @remainingSelectorObjectsList);
		}
	}
	return @foundObjects;

}

# walk an object hierarchy (with <object>[range]/ selectors) and return all found objects
# die on not found objects
sub getObjectsFromSelectorString {
	my $self = shift or return undef;
	my $selectorString = shift or return undef;
	my $noAutoCreate = shift;
	
	# split the selectorString
	my @selectorObjectsList = split ( /\//, $selectorString);
	
	# if selector begins with a root / (like "/d/a" ") it result in an empty string first element
	if($selectorObjectsList[0] eq '' ) { # if first element is '', target begin with a / 
		shift @selectorObjectsList;  # shift this unused empty element root
	}else { 	# target doesn't begin with a root / but with a relative path t*/c for example
		# relative are considered to begin at album level, add elements for absolute naming (a)
		unshift @selectorObjectsList, 'a';
	}
#	my @foundObjects = $self->getObjectsFromSelectorArray($self, @selectorObjectsList);
	my @foundObjects = $self->getObjects({ currentObject => $self, selectorArray => \@selectorObjectsList, noAutoCreate => $noAutoCreate});	
#	foreach(@foundObjects) {
#		print("getObjectsFromSelectorString found:". ref($_)."\n");
#	}
	return @foundObjects;
}

# TODO: clean this code and make it working
#            for example, walking the tree to delete a given tag spawns empty elements
#            example "remove MY /a/w*/tags" with no works, create an empty work ( exactly works->[0] )
sub getObjectsFromSelectorArray {
	my $self = shift or return undef;
	my $currentObject = shift or return undef;
	my @remainingSelectorObjectsList = @_;
	my @foundObjects;

#	push @t1,@t2;
#	 @t1 = (@t1,@t2);
#	die Dumper \@t1;
	
	# Debug code
	#print(join('/', @remainingSelectorObjectsList)."\n");

	 # it's not the end "method=value" part but  the next element to walk in the hierarchy string /album/track/name 
	my $selectorItemString = shift @remainingSelectorObjectsList;
	my $objectName;
	my $objectRange;
	# Regex coach test: [sadtwpcgrm](([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?
	# v2: ([a-zA-Z]*)(([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?$
	#print("Element: $element \n");
	if($selectorItemString =~ /^([a-zA-Z]*)(([0-9]+-[0-9]+)|(\*)|([0-9]+(,[0-9]+)*))?$/) {
		#print("$1:$2:$3:$4:$5:$6:$7 \n"); 
		$objectName = $1;
		$objectRange = $2;
	} else { 
		ERROR "Malformed range string ($selectorItemString), target string is (/<target><range>)+=<value> with target an mda object [disc|track|album| ...] and range [*|1|1-3|1,2,3]. \nEx: /album/track1-5/name Requiem  ";
		die; 
	}

	# resolve object/properties aliasing from element shortcuts hash
	if(exists $elements{$objectName}) {
		$objectName =  $elements{$objectName};
	}

	# if there's an object range, we'll have to call several the setFromObjectList for each object targeted by the range
	if(defined($objectRange)) {  
		#Debug Code
		#print("objectRange defini\n");
		unless( substr($objectName,-1,1) eq 's' ) { # if the object is not ending with "s" it mus be an error
			$objectName.='s'; # add the 's' as every object arrays in MDA end with an 's' (it's input helping)
		}
		# we have the name of an array of objects, get the array to call every object in the rang $objectRange
		# but before, verify if the current object has the array asked
		unless($currentObject->can($objectName)) {
			ERROR("Object ". ref($currentObject)." has no property ${objectName}");
			die;
		}
		# ok, the array exists, get it and call setFromObjectList for each elements pointed by $objectRange
		my $objectArrayRef = $currentObject->$objectName();
		
		my @targetIndexes;
		if($objectRange eq '*') {
			@targetIndexes = (0..$#{$objectArrayRef})
		} else {
			@targetIndexes = $self->rangeStringToIndexList($objectRange);
		}
		# @targetIndexes contains all indexes of object to apply the next hierarchy command or to return

		# all array elements must exists, creating missing ones (even if we wan't to call a 'remove' in the end :-/ )
		for my $i (0..max(@targetIndexes)) {
			unless(exists($objectArrayRef->[$i]) ) { # object doesn't exist, we must create it
				#my $addMethodName= 'add'.substr($objectName, 0,-1);
				my $objectClassName = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
				$objectArrayRef->[$i] = $objectClassName->new();
				# if object has index, try to set this index
				#if($objectArrayRef->[$i]->can('index')) {
				if( (ref($objectArrayRef->[$i]) eq 'DataFile::Work')  or (ref($objectArrayRef->[$i]) eq 'DataFile::Performance') or (ref($objectArrayRef->[$i]) eq 'DataFile::Track')) {
					$objectArrayRef->[$i]->index($i+1);
				#}
				#if($objectArrayRef->[$i]->can('id')) {
				#if( (ref($objectArrayRef->[$i]) eq 'DataFile::Work')  or (ref($objectArrayRef->[$i]) eq 'DataFile::Performance') or (ref($objectArrayRef->[$i]) eq 'DataFile::Track')) {
					$objectArrayRef->[$i]->id($i+1);
				}
				if($objectArrayRef->[$i]->can('parent')) {
					$objectArrayRef->[$i]->parent($currentObject);
				}			
			}			
		}
		for my $i (@targetIndexes) {
			#print("$self->setFromObjectList($objectArrayRef->[$i], @params); \n")
			if(scalar(@remainingSelectorObjectsList)==0) { # this was a final node add it to found objects
				#my $objectClassName = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
				#$objectArrayRef->[$i] = $objectClassName->new();
				#$objectArrayRef->[$i] = undef;
				push @foundObjects, $objectArrayRef->[$i];
			}else { # continue hierarchy exploration
				push @foundObjects, $self->getObjectsFromSelectorArray($objectArrayRef->[$i], @remainingSelectorObjectsList);
			}
#				unless($objectArrayRef->[$i]->can($objectName)) {
#					ERROR("Object ". ref($currentObject)." has no property $objectName");
#					return;
#				}
			}
#			print Dumper $objectArrayRef;
#			print Dumper  \@targetIndexes;
	} else { # no object range given, calling single object code
		# alias has been made, try to see if we can find next object
		#Debug Code
		#print("objectRange non defini\n"); 
		unless($currentObject->can($objectName)  ) {
			ERROR("Object ". ref($currentObject)." has no property $objectName");
			die;
		}
		if(scalar(@remainingSelectorObjectsList)==0) { # this was a final node: return it
			#Debug Code
			#print("dernier objet\n");
			push @foundObjects, $currentObject;
		}else { # continue hierarchy exploration
			# get next object in the hierarchy
			my $nextObject=$currentObject->$objectName();
			# call accessor
			push @foundObjects,$self->getObjectsFromSelectorArray($nextObject, @remainingSelectorObjectsList);
#			my @localFoundObjects =   $self->getObjectsFromSelectorArray($nextObject, @remainingSelectorObjectsList);
#			if(scalar(@localFoundObjects) > 0 ) {
#				push @foundObjects, @localFoundObjects;
#			}else { 
#				push @foundObjects, $self;
#			}
		}
	}
	return @foundObjects;
}

END { }    # module clean-up code here (global destructor)
1;


# set fields in object according to a object hierarchy string (see "add")
#sub set {
#	my $self = shift or return undef;
#	# the target string in the form /a/d*/t*/w/m/date/rawData=1978
#	my $target  = shift or return undef;
#	
#	#print $target;
#	# get range field and value to attribute
#	my ($range, $value) =  split(/=/,$target);
#	
#	# Return error if there is no target=value string as input
#	unless(defined $range and defined $value) {
#		ERROR("Problem with target string, must be something like /d/a/t*/c/name=value");
#		return undef;
#	}
#	
#	# explode every part of the object hierarcgy
#	my @objectList = split ( /\//, $range);
#	
#
#	# target doesn't begin with a / (like /d/a) but with a relative path t*/c
#	if($objectList[0] ne '' ) { # relative are considered to begin at album level, add elements for absolute naming (a)
#		unshift @objectList, 'a';
#	}else { 	# if first element is '', target begin with a / 
#		shift @objectList;  # shift this unused empty element
#	}
#	# try to call the find the good target and set it to the good value
#	return $self->setFromObjectList($self, @objectList, $value);
##	foreach (@objectList){
##		print("$_ \n");
##	}
#}

#
#sub setFromObjectList {
#	my $self = shift or return undef;
#	my $currentObject = shift or return undef;
#	my @params = @_;
#	print(join('/', @params)."\n");
#
#	if(scalar(@params) == 2) {
#
#		# we're ending up with method and value fields
#		my ($method, $value) = @params;
#		# if object can't do given method (surely a parameter error)
#		unless($currentObject->can($method)) {
#			ERROR("Object ". ref($currentObject)." has no property $method");
#			return;
#		}
#		print("calling $method with param $value \n"); 
#		# if it can, call the method with the value and return (it's the final object)
#		return $currentObject->$method($value);
#	}else { # it's not the end "method=value" part but  the next element to walk in the hierarchy string /album/track/name 
#		my $element = shift @params;
#		my $objectName;
#		my $objectRange;
#		# Regex coach test: [sadtwpcgrm](([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?
#		# v2: ([a-zA-Z]*)(([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?$
#		#print("Element: $element \n");
#		if($element =~ /^([a-zA-Z]*)(([0-9]+-[0-9]+)|(\*)|([0-9]+(,[0-9]+)*))?$/) {
#			#print("$1:$2:$3:$4:$5:$6:$7 \n");  die;
#			$objectName = $1;
#			$objectRange = $2;
#		} else { 
#			ERROR "Malformed range string ($element), target string is (/<target><range>)+=<value> with target an mda object [disc|track|album| ...] and range [*|1|1-3|1,2,3]. \nEx: /album/track1-5/name=Requiem  ";
#			die; 
#		}
#		# resolve object/properties aliasing from element shortcuts hash
#		if(exists $elements{$objectName}) {
#			$objectName =  $elements{$objectName};
#		}
#		# if there's an object range, we'll have to call several times the setFromObjectList for each object targeted by the range
#		if(defined($objectRange)) { 
#			unless(substr($objectName,-1,1) eq 's') { # if the object is not ending with "s" it mus be an error
#				$objectName.='s'; # add the 's' as every object arrays in MDA end with an 's' (it's input helping)
#			}
#			# we have the name of an array of objects, get the array to call every object in the rang $objectRange
#			# but before, verify if the current object has the array asked
#			unless($currentObject->can($objectName)) {
#				ERROR("Object ". ref($currentObject)." has no property ${objectName}");
#				die;
#			}
#			# ok, the array exists, get it and call setFromObjectList for each elements pointed by $objectRange
#			my $objectArrayRef = $currentObject->$objectName();
#			my @targetIndexes;
#			if($objectRange eq '*') {
#				@targetIndexes = (0..$#{$objectArrayRef})
#			} else {
#				@targetIndexes = $self->rangeStringToIndexList($objectRange);
#			}
#			# targetIndexes contains all index of object to apply the next hierarchy command
#			print("max val: ".max(@targetIndexes)."\n");
#			
#			# all array elements must exists, creating missing ones 
#			for my $i (0..max(@targetIndexes)) {
#				unless(ref $objectArrayRef->[$i]) { # object doesn't exist, we must create it
#					#my $addMethodName= 'add'.substr($objectName, 0,-1);
#					my $objectClassName = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
#					$objectArrayRef->[$i] = $objectClassName->new();
#					# if object has index, try to set this index
#					if($objectArrayRef->[$i]->can('index')) {
#						$objectArrayRef->[$i]->index($i+1);
#					}
#				}			
#			}
#			for my $i (@targetIndexes) {
#				#print("$self->setFromObjectList($objectArrayRef->[$i], @params); \n")
#				$self->setFromObjectList($objectArrayRef->[$i], @params);
##				unless($objectArrayRef->[$i]->can($objectName)) {
##					ERROR("Object ". ref($currentObject)." has no property $objectName");
##					return;
##				}
#			}
##			print Dumper $objectArrayRef;
##			print Dumper  \@targetIndexes;
#		} else { # no object range given, calling single object code
#			# alias has been made, try to see if we can find next object
#			unless($currentObject->can($objectName)) {
#				ERROR("Object ". ref($currentObject)." has no property $objectName");
#				return;
#			}
#			# get next object in the hierarchy
#			my $nextObject=$currentObject->$objectName();
#			# call accessor
#			return $self->setFromObjectList($nextObject, @params);
#		}
#	}
#	return undef;
#}

#
#sub remove {
#	my $self = shift or return undef;
#	# the target string in the form /a/d*/t*/w/m/date/rawData
#	my $target  = shift or return undef;
#	
#	#print $target;
#	# get range field and value to attribute
#	my $range =  $target;
#	
#	# Return error if there is no target=value string as input
#	unless(defined $range) {
#		ERROR("Problem with target string, must be something like /d/a/t*/c/name");
#		return undef;
#	}
#	
#	# explode every part of the object hierarcgy
#	my @objectList = split ( /\//, $range);
#	
#
#	# target doesn't begin with a / (like /d/a) but with a relative path t*/c
#	if($objectList[0] ne '' ) { # relative are considered to begin at album level, add elements for absolute naming (a)
#		unshift @objectList, 'a';
#	}else { 	# if first element is '', target begin with a / 
#		shift @objectList;  # shift this unused empty element
#	}
#	# try to call the find the good target and set it to the good value
#	return $self->removeFromObjectList($self, @objectList);
##	foreach (@objectList){
##		print("$_ \n");
##	}
#}
#
#sub removeFromObjectList {
#	my $self = shift or return undef;
#	my $currentObject = shift or return undef;
#	my @params = @_;
#	print(join('/', @params)."\n");
#
#		 # it's not the end "method=value" part but  the next element to walk in the hierarchy string /album/track/name 
#		my $element = shift @params;
#		my $objectName;
#		my $objectRange;
#		# Regex coach test: [sadtwpcgrm](([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?
#		# v2: ([a-zA-Z]*)(([0-9]+-[0-9]+)|Z|([0-9]+(,[0-9]+)*))?$
#		#print("Element: $element \n");
#		if($element =~ /^([a-zA-Z]*)(([0-9]+-[0-9]+)|(\*)|([0-9]+(,[0-9]+)*))?$/) {
#			#print("$1:$2:$3:$4:$5:$6:$7 \n");  die;
#			$objectName = $1;
#			$objectRange = $2;
#		} else { 
#			ERROR "Malformed range string ($element), target string is (/<target><range>)+=<value> with target an mda object [disc|track|album| ...] and range [*|1|1-3|1,2,3]. \nEx: /album/track1-5/name=Requiem  ";
#			die; 
#		}
#		# resolve object/properties aliasing from element shortcuts hash
#		if(exists $elements{$objectName}) {
#			$objectName =  $elements{$objectName};
#		}
#		# if there's an object range, we'll have to call several the setFromObjectList for each object targeted by the range
#		if(defined($objectRange)) { 
#			unless(substr($objectName,-1,1) eq 's') { # if the object is not ending with "s" it mus be an error
#				$objectName.='s'; # add the 's' as every object arrays in MDA end with an 's' (it's input helping)
#			}
#			# we have the name of an array of objects, get the array to call every object in the rang $objectRange
#			# but before, verify if the current object has the array asked
#			unless($currentObject->can($objectName)) {
#				ERROR("Object ". ref($currentObject)." has no property ${objectName}");
#				die;
#			}
#			# ok, the array exists, get it and call setFromObjectList for each elements pointed by $objectRange
#			my $objectArrayRef = $currentObject->$objectName();
#			my @targetIndexes;
#			if($objectRange eq '*') {
#				@targetIndexes = (0..$#{$objectArrayRef})
#			} else {
#				@targetIndexes = $self->rangeStringToIndexList($objectRange);
#			}
#			# targetIndexes contains all index of object to apply the next hierarchy command
##			print("max val: ".max(@targetIndexes)."\n");
##			
##			# all array elements must exists, creating missing ones 
##			for my $i (0..max(@targetIndexes)) {
##				unless(ref $objectArrayRef->[$i]) { # object doesn't exist, we must create it
##					#my $addMethodName= 'add'.substr($objectName, 0,-1);
##					my $objectClassName = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
##					$objectArrayRef->[$i] = $objectClassName->new();
##				}			
##			}
#			for my $i (@targetIndexes) {
#				#print("$self->setFromObjectList($objectArrayRef->[$i], @params); \n")
#				if(scalar(@params)==0) { # this was a final node: deleting
#					my $objectClassName = 'DataFile::'.ucfirst(substr($objectName, 0,-1));
#					$objectArrayRef->[$i] = $objectClassName->new();
#					#$objectArrayRef->[$i] = undef;
#				}else { # continue hierarchy exploration
#					$self->removeFromObjectList($objectArrayRef->[$i], @params);
#				}
##				unless($objectArrayRef->[$i]->can($objectName)) {
##					ERROR("Object ". ref($currentObject)." has no property $objectName");
##					return;
##				}
#			}
##			print Dumper $objectArrayRef;
##			print Dumper  \@targetIndexes;
#		} else { # no object range given, calling single object code
#			# alias has been made, try to see if we can find next object
#			unless($currentObject->can($objectName)) {
#				ERROR("Object ". ref($currentObject)." has no property $objectName");
#				return;
#			}
#			if(scalar(@params)==0) { # this was a final node: deleting
#				$currentObject->{$objectName} = undef;
#			}else { # continue hierarchy exploration
#				# get next object in the hierarchy
#				my $nextObject=$currentObject->$objectName();
#				# call accessor
#				return $self->removeFromObjectList($nextObject, @params);
#			}
#		}
#	return undef;
#}
