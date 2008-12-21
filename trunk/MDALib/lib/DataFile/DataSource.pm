#!/usr/bin/perl -w
package DataFile::DataSource;

use strict;
use utf8;

use Data::Dumper;
use DataFile::Album;
use DataFile::Date;
use DataFile::Composer;
use DataFile::Picture;
use Tools;

use Log::Log4perl qw(:easy);
use Module::Find;
use YAML::Syck;

sub new {
	my $class  = shift;
	my $dataSource = {};
	my %params;
	if (@_) {
		%params = %{ shift() };
	}
	
	bless( $dataSource, $class );
	if (%params) {
		if ( defined( $params{version} ) ) {
			$dataSource->version( $params{version} );
		}
		if ( defined( $params{name} ) ) {
			$dataSource->name( $params{name} );
		}
		if ( defined( $params{providerName} ) ) {
			$dataSource->providerName( $params{providerName} );
		}
#		if ( defined( $params{reader} ) ) {
#			$dataSource->reader( $params{reader} );
#		}
		if ( defined( $params{providerUrl} ) ) {
			$dataSource->providerUrl( $params{providerUrl} );
		}
	}
	return $dataSource;
}

sub parent {
	return albumFile(@_);
}

sub lookupClass {
	my $selfOrClass = shift;
	print($selfOrClass."\n");
	print(ref($selfOrClass)."\n");
	if(ref($selfOrClass eq ''))
	{ # this is an instance
		return eval('$'.ref($selfOrClass).'::lookupClass');
	}
	# this is a static call
	return eval('$'.$selfOrClass.'::lookupClass');
}

# Static or instance call, returns an array of available dataSources
# modules
sub availableDataSources{
	my @dataSourcesModules;
	foreach my $myModule(findallmod DataSource) {
		if($myModule =~ /.*Reader/ ) {
			eval("use $myModule");
			push @dataSourcesModules, $myModule;
		}
	}
	return @dataSourcesModules;
}

#sub albumFile {
#	my $self = shift;
#	my $albumFile   = shift;
#	if ($albumFile) { $self->{-albumFile} = $albumFile }
#	return $self->{-albumFile};
#}

sub toString {
	my $self = shift or return undef;
	my $verb = shift;
	my $string="\n\n";
	# TODO: implement different displaymode or verbosity
	unless(defined($verb)) {
		$verb = 0;
	}
	
	# Datasource information
	$string.=($verb>=1?"Datasource: ".$self->name():'');
	
	# newline if datasource info was displayed
	$string.=($verb>=1?"\n":'');
	
	# Album General
	if(defined($self->album->name()) or defined($self->album->label->name()) or defined($self->album->catalogNumber()) ) {
		$string.=($verb>=1?"Album: ":'');
		$string.=($verb>=0?$self->album->name():'');
		$string.=($verb>=1?" - ".$self->album->label->name():'');
		$string.=($verb>=1?" [".$self->album->catalogNumber()."] ":'');
		$string.=($verb>=0?"\n":'');
	}
	
	# Album Credits
	if(scalar(@{$self->album->credits()})>0) {
		$string.=($verb>=2?"Credits:\n":'');
		if($verb>=2) {
			my %displayedCredits;
			foreach(@{$self->album->credits()}) {
				push @{$displayedCredits{$_->name()}}, $_->role();			
			}
			foreach(sort(keys(%displayedCredits))) {
				$string.=$_;
				$string.=($verb>=3?" [".join(', ',@{$displayedCredits{$_}})."]":'');
				$string.=', ';
			}
			# remove last useless ', ' token and add a newline
			$string=substr($string, 0, -2);
			$string.="\n";
		}
	}

	# Album Tags
	if(scalar(@{$self->album->tags()})>0) {
		$string.=($verb>=2?"Tags:\n":'');
		if($verb>=2) {
			my %displayedTags;
			foreach(@{$self->album->tags()}) {
				push @{$displayedTags{$_->name()}}, $_->value();			
			}
			foreach(sort(keys(%displayedTags))) {
				$string.=$_;
				$string.=($verb>=3?" [".join(', ',@{$displayedTags{$_}})."]":'');
				$string.=', ';
			}
			# remove last useless ', ' token and add a newline
			$string=substr($string, 0, -2);
			$string.="\n";
		}
	}
	
	if(scalar(@{$self->album->discs()})>0) {
		DISC:
		foreach my $disc (@{$self->album->discs()}) {
			# if there's several discs, write disc number
			$string.=($verb>=1?"Disc":'');
			if( (defined($self->album->numberOfDiscs()) and $self->album->numberOfDiscs()>1) or (scalar(@{$self->album->discs()})>1)  ) {
				$string.=(' '.$verb>=1?$disc->index():'');
			}
			$string.=($verb>=1?": ":'');
			$string.=($verb>=0?$disc->name():'');
			$string.="\n";
			if(scalar(@{$disc->tracks()})>0) {
				TRACK:
				foreach my $track (@{$disc->tracks()}) {
					$string.=($verb>=1?"Track ":'');
					$string.=(' '.$verb>=0?$track->index().': ':'');
					$string.=($verb>=0?$track->name().(defined($track->nameDetail())?' - '.$track->nameDetail():''):'');
					$string.="\n";
					if(defined($track->{performance}) and not $track->performance->isLink() ) {
						$string.=($verb>=1?"  Perf: ":'');
						$string.=($verb>=1?$track->performance->name():'');
						$string.=($verb>=1?"\n  ":'');
						# Perf Credits
						if(scalar(@{$track->performance->credits()})>0) {
							$string.=($verb>=2?"Credits:\n  ":'');
							if($verb>=2) {
								my %displayedCredits;
								foreach(@{$track->performance->credits()}) {
									push @{$displayedCredits{$_->name()}}, $_->role();			
								}
								foreach(sort(keys(%displayedCredits))) {
									$string.=$_;
									$string.=($verb>=3?" [".join(', ',@{$displayedCredits{$_}})."]":'');
									$string.=', ';
								}
								# remove last useless ', ' token and add a newline
								$string=substr($string, 0, -2);
								$string.="\n";
							}
						}							
					}
					# Track work
					if(defined($track->{work}) and not $track->work->isLink() ) {
						$string.=($verb>=1?"  Work: ":'');
						$string.=($verb>=1?$track->work->name():'');
						$string.=($verb>=1?"\n  ":'');
						# Work Credits
						if(scalar(@{$track->work->composers()})>0) {
							$string.=($verb>=2?"  by:  ":'');
							if($verb>=2) {
								foreach my $composer(@{$track->work->composers()}) {
									$string.=($verb>=2?$composer->name():'');
									$string.=($verb>=2?' (' . join(' - ', $composer->lifeDate->normalized()) . ')':'');
									$string.=($verb>=2?"\n  ":'');											
								}
								# remove last useless ', ' token and add a newline
								$string=substr($string, 0, -2);
								$string.="\n";
							}
						}							
					}						
				}
			}
		}
	}
	# Album works
	if(scalar(@{$self->album->works()})>0) {
		WORK:
		foreach my $work (@{$self->album->works()}) {
			$string.=($verb>=1?"Work: ":'');
			$string.=($verb>=1?$work->name():'');
			# Work composers
			if(scalar(@{$work->composers()})>0) {
				$string.=($verb>=2?" by ":'');
				if($verb>=2) {
					foreach my $composer(@{$work->composers()}) {
						$string.=($verb>=2?$composer->name():'');
						if( scalar(@{$composer->lifeDate->normalized()}>0) ) {
							$string.=($verb>=2?' (' . join(' - ', @{$composer->lifeDate->normalized()}) . ')':'');
						}
						$string.=($verb>=2?", ":'');											
					}
					# remove last useless ', ' token and add a newline
					$string=substr($string, 0, -2);
					$string.="\n";
				}
			}
		}
	}
	# Album performances
	if(scalar(@{$self->album->performances()})>0) {
		WORK:
		foreach my $performance (@{$self->album->performances()}) {
			$string.=($verb>=1?"Perf: ":'');
			$string.=($verb>=1?$performance->name():'');
			# Perf Credits
			if(scalar(@{$performance->credits()})>0) {
				$string.=($verb>=2?"\n  Credits: ":'');
				if($verb>=2) {
					my %displayedCredits;
					foreach(@{$performance->credits()}) {
						push @{$displayedCredits{$_->name()}}, $_->role();			
					}
					foreach(sort(keys(%displayedCredits))) {
						$string.=$_;
						$string.=($verb>=3?" [".join(', ',@{$displayedCredits{$_}})."]":'');
						$string.=', ';
					}
					# remove last useless ', ' token and add a newline
					$string=substr($string, 0, -2);
					$string.="\n";
				}
			}		
		}
	}	
	$string.="\n";
	return $string;
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

sub albumFile {
	my $self = shift;
	my $albumFile = shift;
	
	# If there's no parameter in the input, it's a GET
	unless($albumFile) {
		#if there is already an object
		if (ref($self->{-albumFile}) eq 'DataFile::AlbumFile') {
			# return It
			return $self->{-albumFile};
		}else { # create a new empty object of this type
			$self->{-albumFile}= DataFile::AlbumFile->new();
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($albumFile) eq 'DataFile::AlbumFile') { 
		$self->{-albumFile}= $albumFile; 
	}
	elsif($albumFile){  # We only insert objects of the good type
		ERROR('Object ->-albumFile called with an unexpected parameter '.ref($albumFile).' waiting a DataFile::AlbumFile');
	}
	# Return the set object
	return $self->{-albumFile};
}

#sub album {
#	my $self = shift;
#	my $album   = shift;
#	if ($album) { $self->{album} = Tools::trim($album); $album->parent($self); }
#	
#	return $self->{album};
#}

sub album {
	my $self = shift;
	my $album = shift;
	
	# If there's no parameter in the input, it's a GET
	unless(defined($album)) {
		#if there is already an object
		if (ref($self->{album}) eq 'DataFile::Album') {
			# return It
			return $self->{album};
		}else { # create a new empty object of this type
			$self->{album}= DataFile::Album->new();
			$self->{album}->parent($self); 
		}
	}
	# There's a parameter in input, it's a SET
	if (ref($album) eq 'DataFile::Album') { 
		$self->{album}= $album; 
		$self->{album}->parent($self); 
	}
	elsif($album){  # We only insert objects of the good type
		ERROR('Object ->album called with an unexpected parameter '.ref($album).' waiting a DataFile::Album');
	}
	# Return the set object
	return $self->{album};
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

# providerName element accessor, returns or set providerName
sub providerName {
	my $selforClassname = shift;
	my $providerName   = shift;

	if(not ref($selforClassname)) # param isn't a reference, must be a static call
	{ # if  $self is not a reference, it must be a class (class access)
		my $varName = $selforClassname.'::providerName';
		no strict "refs"; 	
		return $$varName;
	}

	if ($providerName) { $selforClassname->{providerName} = Tools::trim($providerName) }

	return $selforClassname->{providerName};
}

# name element accessor, returns or set name
sub name {
	my $selforClassname = shift;
	my $name   = shift;
	if(not ref($selforClassname)) # param isn't a reference, must be a static call
	{ # if  $self is not a reference, it must be a class (class access)
		my $varName = $selforClassname.'::DataSourceName';
		no strict "refs"; 	
		return $$varName;
	}
	if ($name) { $selforClassname->{name} = Tools::trim($name) }
	return $selforClassname->{name};
}

sub class {
	my $self = shift;
	my $class   = shift;
	if ($class) { $self->{class} = Tools::trim($class) }
	return $self->{class};
}

# providerUrl element accessor, returns or set providerUrl
sub providerUrl {
	my $selforClassname = shift;
	my $providerUrl   = shift;

	if(not ref($selforClassname)) # param isn't a reference, must be a static call
	{ # if  $self is not a reference, it must be a class (class access)
		my $varName = $selforClassname.'::providerUrl';
		no strict "refs"; 	
		return $$varName;
	}
	
	if ($providerUrl) { $selforClassname->{providerUrl} = Tools::trim($providerUrl) }
	return $selforClassname->{providerUrl};
}

sub version {
	my $self = shift;
	my $version   = shift;
	if ($version) { $self->{version} = Tools::trim($version) }
	return $self->{version};
}

sub deserialize {
	my $self = shift or return undef;
	my $album = $self->{album};
#	print("Deserializing ".$self->{class}."\n");
	if(defined($album)) {
		Tools::blessObject('DataFile::Album', $album);
	}else {
		$album = DataFile::Album->new();
	}
	
	if(exists($self->{composers}) and exists($self->{composers}{composer}) ) {
		unless(ref($self->{composers}{composer}) eq 'ARRAY') {
			my $composer=$self->{composers}{composer};
			push @{$self->{composers}{composer}=[]}, $composer;

		}
		Tools::blessObjects('DataFile::Composer', $self->{composers}{composer});
	}
	#Tools::blessObjects('DataFile::Composer', $self->{composers}{composer});
	$album->dataSource($self);
	# Initialize backpointer composer -> dataSource for each composer found 
	foreach my $composer (@{$self->composers()}) {
		$composer->parent($self);
	}
	$self->recreateLinks();
}

#  recreate reference between xlink:href and real objects
sub recreateLinks {
	my $self = shift or return undef;
	my @composerObjects;
	my @workObjects;
	my @performanceObjects;
	my @composerLinks;
	my @workLinks;
	my @performanceLinks;

#### recreate WORKS links
	# find works objects and links in album
	foreach(@{$self->album->works}) {
		if(defined($_->href)) {
			push @workLinks, $_;
		} elsif(defined($_->id)) {
			push @workObjects, $_;
		}else {
			ERROR("album work object isn't a link and has no id");
		}
	}

	# find work objects and links in album tracks works
	DISC:	
	foreach(@{$self->album->discs}) {
		TRACK:
		foreach(@{$_->tracks}) {
			unless(defined($_->{work})) {
				next TRACK;
			}

			if(defined($_->work->href)) {
				push @workLinks, $_->work;
			} elsif(defined($_->work->id)) {
				push @workObjects, $_->work;
			}else {
				WARN("Ignoring Track work object that isn't a link and has no id");
#				push @performanceObjects, $_->performance;				
			}	
		}	
	}

	# find work objects and links in album tracks works
	PERFORMANCE:	
	foreach(@{$self->album->performances}) {
		unless(defined($_->{work})) {
			next PERFORMANCE;
		}

		if(defined($_->work->href)) {
			push @workLinks, $_->work;
		} elsif(defined($_->work->id)) {
			push @workObjects, $_->work;
		}else {
			ERROR("Track work object isn't a link and has no id");
			die Dumper $_->{work};
		}		
	}
	
	foreach my $workLink (@workLinks) {
		my @foundWorkObjects=grep {$_->id eq $workLink->href() }  @workObjects;
		unless (scalar(@foundWorkObjects)==1) {
			ERROR("Cannot find work objects for work href: ", $workLink->href());
			last;
		}
		$workLink->linkedWork($foundWorkObjects[0]);
	}


#### recreate PERFORMANCES links
	# find performance objects and links in album
	foreach(@{$self->album->performances}) {
		if(defined($_->href)) {
			push @performanceLinks, $_;
		} elsif(defined($_->id)) {
			push @performanceObjects, $_;
		}else {
			ERROR("album performance object isn't a link and has no id");
		}
	}

	# find performance objects and links in album tracks works
	DISC2:	
	foreach(@{$self->album->discs}) {
		TRACK2:
		foreach(@{$_->tracks}) {
			unless(defined($_->{performance})) {
				next TRACK2;
			}
			if(defined($_->performance->href)) {
				push @performanceLinks, $_->performance;
			} elsif(defined($_->performance->id)) {
				push @performanceObjects, $_->performance;
			}else {
				DEBUG("Ignoring Track performance object that isn't a link and has no id");
#				push @performanceObjects, $_->performance;
				#die Dumper $_->performance;
			}
		}	
	}

	foreach my $performanceLink (@performanceLinks) {
		my @foundPerformanceObjects=grep  {$_->id eq $performanceLink->href() }  @performanceObjects;
		unless (scalar(@foundPerformanceObjects)==1) {
			ERROR("Cannot find performance objects for performance href: ", $performanceLink->href());
			last;
		}
		$performanceLink->linkedPerformance($foundPerformanceObjects[0]);
	}

#####
	# find composers objects and links in dataSource
	foreach(@{$self->composers}) {
		if(defined($_->href)) {
			push @composerLinks, $_;
		} elsif(defined($_->id)) {
			push @composerObjects, $_;
		}else {
			ERROR("DataSource composer object isn't a link and has no id");
		}
	}

	# find composers objects and links in album composers	
	foreach(@{$self->album->composers()}) {
		#die Dumper \$_;
		if(defined($_->href)) {
			push @composerLinks, $_;
		} elsif(defined($_->id)) {
			push @composerObjects, $_;
		}else {
			ERROR("Album composer object isn't a link and has no id");
		}
	}		

	# find composers objects and links in previously found works objects
	foreach(@workObjects) {
		foreach(@{$_->composers}) {
			if(defined($_->href)) {
				push @composerLinks, $_;
			} elsif(defined($_->id)) {
				push @composerObjects, $_;
			}else {
				ERROR("Composer object isn't a link and has no id (this shouldn't happen)");
			}
		}		
	}
	
	foreach my $composerLink (@composerLinks) {
		my @foundComposerObjects=grep {$_->id eq $composerLink->href() } @composerObjects;
		unless (scalar(@foundComposerObjects)==1) {
			ERROR("Cannot find composer objects for composer href: ", $composerLink->href());
			last;
		}
		$composerLink->linkedComposer($foundComposerObjects[0]);
	}
	
}

sub composers  {
	my $self = shift;
	my $composers = shift;
	
	# if no composers array ref is sent
	if(!$composers) {
		# if no composers array exists

		if(ref($self->{composers}{composer}) ne 'ARRAY') {
			#create it
			$self->{composers}{composer}=[];
			DEBUG 'Initializing credits array'
		} # returning existing or initialized
		return ($self->{composers}{composer});
	}

	if($#$composers == -1) {
		WARN "called object->composers with an empty array, truncating!";
	}

	foreach my $composer (@{$composers}) {
		if(ref($composer) ne 'DataFile::Composer') {
			ERROR "datasource->composers called with an array containing at least an unexpected object".ref($composer);
			return(undef);
		}
		if($composer->can('parent')) {
			$composer->parent($self);
		}
	}
	$self->{composers}{composer} = $composers;
}

END { }    # module clean-up code here (global destructor)
1;