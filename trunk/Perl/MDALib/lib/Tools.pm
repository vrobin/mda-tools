#!/usr/bin/perl -w
# -CSD
package Tools;

use strict;
use utf8;
use LWP::UserAgent;
use HTTP::Cookies;
use Log::Log4perl qw(:easy);
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Spec::Functions;
use Data::Dumper;

my $cacheDir = 'D:\\Dev\\Projects\\workspace\\MDA\\Playground\\html\\cache\\';
my $tagSeparator =';';

#sub addObject {
#	my ($callingObject, $typeOfObject, $newObject, $existingArray) = @_;
#
#	# if param is not a Composer object -> return 
#	if ( ref($newObject) ne $typeOfObject ) {
#		# return It
#		ERROR ("no $typeOfObject  object in parameter ");
#		return (undef );
#	}
#
#	# if theres no object ID, return in error (that's the least we need)
#	unless( $newObject->id() ) { 
#		ERROR("Missing id for $typeOfObject object"); 
#		return; 
#	}
#	if($newObject->can('parent')) {
#		$newObject->parent($callingObject);
#	}
#	push @{$existingArray}, $newObject;
#}
#
#
#
## adding an array of object is always the same thing, this helper function
## check if the passed object is an array and contains the good classes
#sub arrayOfObjectAccessors {
#	my ($callingObject, $typeOfObject, $newArray, $existingArray) = @_;
#
#	# if no  array ref is sent, caller certainly needs the existing array
#	if(!$newArray) {
#		# if no  array exists
#		if(ref($existingArray) ne 'ARRAY') {
#			#create it
#			$existingArray=[];
#			DEBUG 'Initializing normalized date array'
#		} # returning existing or initialized
#		return ($existingArray);
#	}
#	if($#$newArray == -1) {
#		DEBUG "called object->arrayOfObjects ($typeOfObject) type  with an empty array, truncating!";
#	}
#	
#	# check objects type in the array and adding disc reference
#	foreach my $object (@{$newArray}) {
#		if(ref($object) ne $typeOfObject) {
#			ERROR "object->arrayOfObjects ($typeOfObject) called with an array containing at least an unexpected object".ref($object);
#			return(undef);
#		}
#		# Fillilng parent ref (if applicable)
#		if($object->can('parent')) {
#			$object->parent($callingObject);
#		}
#	}
#	$existingArray= $newArray;
#}

sub blessObject {
	my $className = shift or return undef;
	my $object = shift or return undef;
#	if($className eq 'DataFile::Work') {
#		print "XXXXXXXX\n".Dumper($object);
#	}
	if(ref($object)) {
		bless $object, $className;

		if( ref($object) ne  $className) {
			ERROR("Error while blessing object as  $className class");
			die;
		}

		if($object->can('deserialize') ) {
			$object->deserialize();
		}
	}	
}

sub blessObjects {
	my $className = shift or return undef;
	my $objects = shift or return undef;
#print("XXX: ", $className);
#print(" / ", ref($objects)," / ", caller(),"\n");		
	unless ($objects) { return undef;}
	foreach my $object (@{$objects}) {
		Tools::blessObject($className, $object);
	}
}


#sub urlencode{
#	my $string = shift or return undef;	
#	#$string =~ s/([^\w()'*~!.-\/:,])/sprintf '%%%02x', ord $1/eg;   # encode
#	$string =~ s/([^\w()'*~!.-\/:,])/sprintf '%%%02x', ord $1/eg;   # encode
#	return $string;
#}
#
#sub urldecode{
#	my $string = shift or return undef;
#    $string =~ s/%([A-Fa-f\d]{2})/chr hex $1/eg;                # decode
#    return $string;
##        s/%([[:xdigit:]]{2})/chr hex $1/eg;          # same thing
#}


sub getHttpContent {
	my %params;
	if (@_) {
		%params = %{ shift() };
	}else {
		ERROR("getHttpContent must be called with an hashRef containing at least an 'url' key");
		die;
	}
	unless(exists($params{'url'}) and defined($params{'url'}) and length($params{'url'})>0  ) {
		ERROR("getHttpContent must be called with an hashRef containing at least an 'url' key");
		die;
	}
	
	my $url = $params{'url'};
	my $forceReload;
	my $noCache;
	if(exists($params{'forceReload'})) {
		$forceReload=1;
	}
	if(exists($params{'noCache'})) {
		$noCache=1;
	}
#	print("XXX: $url \n");
	my ( $package, $filename, $line ) = caller;

	if ( $package !~ /^DataSource::[^:]*::/ ) {
		ERROR(
"getUrl function is designed to be called by a DataSource (ie packaged in DataSource::) but called from $package"
		);
		return (undef);
	}
	my $cacheDir;
	my $cacheFile;
	unless($noCache) {
	# extracting calling package name, if calling package is DataSource::AMG::AMGClassical.pm
		$package =~ /^(DataSource::[^:]*)::/;
	
		# cacheDir = $cacheDir/DataSource::AMG/
		$cacheDir = File::Spec->catdir( $cacheDir, $1 );
	
		# cacheDir = $cacheDir/DataSourceAMG
		$cacheDir =~ s/:://g;
	
		# Building cache Directory from cache dir and 3 level subdirs (from md5 hash)
		# filePath looks like D:\Java\workspaces\MDA\Playground\html\cache\DataSourceAMG\d\a\a\
		$cacheDir = File::Spec->catdir( $cacheDir, getCachePathFromUrl($url) );
	
		# cache directory doesn't exist, building it
		unless ( -d $cacheDir ) {
			recursiveMkdir($cacheDir);
		}
		$cacheFile = File::Spec->catfile($cacheDir, UrlToFilename($url));
		# TODO: add and check for a "force refresh parameter" to bypass/update the cache
		# There is a non null sized file with this name, let's declare it a cache it and return the filename 
		unless($forceReload) {
			if(-s $cacheFile ){
				DEBUG("Return cached data in: $cacheFile");
				open(FH, "<:utf8", "$cacheFile") || die("unable to open cache file $cacheFile");
						my $content;
				while(<FH>){
					$content.=$_;
				}
				close FH or ERROR("Error while closing cache file $cacheFile");
				return $content;
			}
		}
	}
	# if it's not in the cache, let's begin serious http work
	my $ua = LWP::UserAgent->new;
	my $response;

	# AMG can be real slow!
	$ua->timeout(30);
	$ua->env_proxy;
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6'	);
	$ua->default_header("Accept-Encoding" => "gzip");
	$ua->cookie_jar(HTTP::Cookies->new());  #( {} ));
	$ua->cookie_jar()->set_cookie(undef, 'JSESSIONID', '456',"/", ".arkivmusic.com", undef, 0, 0, 60*60, 0);
	$response = $ua->get($url);
	if ( $response->is_success ) {
		unless($noCache) {
			DEBUG("Caching file: $cacheFile");
			open(FH, ">:utf8", "$cacheFile")|| die(ERROR ("unable to open cache file $cacheFile"));
			print FH $response->decoded_content;    # or whatever
			close FH or ERROR("Error while closing cache file $cacheFile");
		}
		return($response->decoded_content)
	}
	else {
		die $response->status_line;
		return(undef);
	}
}

sub getContentFromUrl {
	my $url = shift or return undef;
	my $forceReload = shift;
#	print("XXX: $url \n");
	my ( $package, $filename, $line ) = caller;

	if ( $package !~ /^DataSource::[^:]*::/ ) {
		ERROR(
"getUrl function is designed to be called by a DataSource (ie packaged in DataSource::) but called from $package"
		);
		return (undef);
	}

# extracting calling package name, if calling package is DataSource::AMG::AMGClassical.pm
	$package =~ /^(DataSource::[^:]*)::/;

	# cacheDir = $cacheDir/DataSource::AMG/
	my $cacheDir = File::Spec->catdir( $cacheDir, $1 );

	# cacheDir = $cacheDir/DataSourceAMG
	$cacheDir =~ s/:://g;

	# Building cache Directory from cache dir and 3 level subdirs (from md5 hash)
	# filePath looks like D:\Java\workspaces\MDA\Playground\html\cache\DataSourceAMG\d\a\a\
	$cacheDir = File::Spec->catdir( $cacheDir, getCachePathFromUrl($url) );

	# cache directory doesn't exist, building it
	unless ( -d $cacheDir ) {
		recursiveMkdir($cacheDir);
	}
	my $cacheFile = File::Spec->catfile($cacheDir, UrlToFilename($url));
	# TODO: add and check for a "force refresh parameter" to bypass/update the cache
	# There is a non null sized file with this name, let's declare it a cache it and return the filename 
	if(-s $cacheFile ){
		DEBUG("Return cached data in: $cacheFile");
		open(FH, "<:utf8", "$cacheFile") || die("unable to open cache file $cacheFile");
				my $content;
		while(<FH>){
			$content.=$_;
		}
		close FH or ERROR("Error while closing cache file $cacheFile");
		return $content;
	}
	
	# if it's not in the cache, let's begin serious http work
	my $ua = LWP::UserAgent->new;
	my $response;

	# AMG can be real slow!
	$ua->timeout(30);
	$ua->env_proxy;
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6'	);
	$ua->cookie_jar(HTTP::Cookies->new( {} ));
	$ua->cookie_jar()->set_cookie(undef, 'JSESSIONID', '456',"/", ".arkivmusic.com", undef, 0, 0, 60*60, 0);
	$response = $ua->get($url);
	if ( $response->is_success ) {
		DEBUG("Caching file: $cacheFile");
		open(FH, ">:utf8", "$cacheFile")|| die(ERROR ("unable to open cache file $cacheFile"));
		print FH $response->decoded_content;    # or whatever
		close FH or ERROR("Error while closing cache file $cacheFile");
		return($response->decoded_content)
	}
	else {
		die $response->status_line;
		return(undef);
	}
}

sub recursiveMkdir {
	my $path = shift or return undef;
	my $buildingPath = '/';
	my ( $drive, $directories, $file ) = File::Spec->splitpath( $path, 1 );

	foreach my $subdir ( File::Spec->splitdir($directories) ) {

		#		print("subdir: $subdir\n");
		$buildingPath = File::Spec->catdir( $buildingPath, $subdir );

		#print(File::Spec->catpath($drive,$buildingPath, '')."\n");
		unless ( -d File::Spec->catpath( $drive, $buildingPath, '' ) ) {
			mkdir( File::Spec->catpath( $drive, $buildingPath, '' ) );
		}
	}
}

sub UrlToFilename {
	my $url = shift or return undef;
	$url =~ s/[;\?&]?(jsessionid|token)=[^\$?;:= %&]*//g;
	$url =~ s/^http:\/\/[^\/]*//g;
	$url =~ s/[^0-9a-zA-Z_]/_/g;
	return $url;
}

# Generate a 3 level dir1/dir2/dir3 from the md5 hash of the url (for filetree balancing)
sub getCachePathFromUrl {
	my $url    = shift or return undef;
	my $digest = md5_hex($url);

	#print ("url: $url  hash: $digest\n");
	# my @tripath = (split(//, substr($digest, 0,3)));
	my $hashTreePath = $digest;
	return catdir( $hashTreePath =~ /(.)(.)(.).*/ );
}

# Perl trim function to remove whitespace from the start and end of the string
# Corrigé pour trimer les "non breakable spaces" &nbsp; 0xAO"
sub trim {
	my $string = shift;
	unless (defined($string)) { return undef };
	$string =~ s/^(\s|\xA0)+//;
	$string =~ s/(\s|\xA0)+$//;
	$string =~ s/\xA0/ /g;

	# Ancienne version avec les entities
	#	$string =~ s/^\s+//;
	#	$string =~ s/\s+$//;
	#	$string = encode_entities($string);
	#	$string =~ s/^(&nbsp;)+//;
	#	$string =~ s/(&nbsp;)+$//;
	#	$string = decode_entities($string);
	#	$string =~ s/^\s+//;
	#	$string =~ s/\s+$//;
	return $string;
}

sub regexEscape {
	my $string = shift;
	unless (defined($string)) { return undef };
	$string =~   s/  (    \) | \\ | \(  | \[  | \] | \. | \*  |  \$  |  \+  |  \? |  \^ | \/ )  /\\$1/gmsx;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub URLDecode {
	my $theURL = $_[0];
	$theURL =~ tr/+/ /;
	$theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
	$theURL =~ s/<!--(.|\n)*-->//g;
	return $theURL;
}

sub URLEncode {
	my $theURL = $_[0];
	# original: $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
	$theURL =~ s/([^\w()'*~!.-\/:,])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
	return $theURL;
}


END { }    # module clean-up code here (global destructor)
1;
