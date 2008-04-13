

# mda
# -d --album-dir default = .
# -f --data-file   default = .mda.xml
# retrieve <dsname> [albumid]
# lookup <dsname>  [lookupdatatype=lookupdata]
#
# AMGClassical:
# retrieve amgAlbumSqlId=42:3456
# retrieve amgWorkSqlId=1(1-6=42:20044;7-12=42:20042)|2(1-6=42:20044;7-12=42:20042)

#CUE
# retrieve cuefile=xxx-disc1.cue cuefile=xxx-disc2.cue (order matters)

use strict;
use utf8;

use DataFile::AlbumFile;

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

use Cwd;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $conf = q(
        log4perl.logger                    = INFO, ScreenApp
        log4perl.appender.FileApp          = Log::Log4perl::Appender::File
        log4perl.appender.FileApp.filename = test.log
        log4perl.appender.FileApp.layout   = PatternLayout
        log4perl.appender.FileApp.layout.ConversionPattern = %d> %m%n
	    log4perl.appender.ScreenApp          = Log::Log4perl::Appender::Screen
	    log4perl.appender.ScreenApp.stderr   = 0
	    log4perl.appender.ScreenApp.layout   = PatternLayout
	    log4perl.appender.ScreenApp.layout.ConversionPattern = %p: %F{1}-%L (%M)> %m%n 
	    #%d> %m%n        
    );

# Initialize logging behaviour
Log::Log4perl->init( \$conf );

my $man = 0;
my $help = 0;

my $action;
my $dsName;
my $dataSourceClass;
my $exporterName;
my $exporterClass;
my $albumDir=File::Spec->canonpath(getcwd());
my $origPath='';
my $targetString;
my $dataFile='.mda.xml';
my $albumFile;
my $albumlId;
my $worksIds;
my $discIds;
my $verbosity=0;

######### Action

GetOptions('help|?' => \$help, 
					'man' => \$man,
					'album-dir|d=s' => \$albumDir,
					'data-file|f=s' => \$dataFile,
					'action|a=s' => \$action,
					'data-source|ds=s' => \$dsName,
					# 'amg-album-sql-id=s' => sub { my $arg = shift; my $amgSqlId = shift; }
					'album-id|ai=s' => \$albumlId,
					'disc-id|di=s' => \$discIds,
					'works-ids|di=s' => \$worksIds,
					'target|t=s' => \$targetString,					
					'verbosity|v=i' => \$verbosity,
					'data-exporter|de=s' => \$exporterName
					) or pod2usage(2);
if($help) { pod2usage(1); }
 if($man) {pod2usage(-exitstatus => 0, -verbose => 2);}


# Current directory
# save original path (we're working relative to the given directory for ./cd1 ./cd2 tree structures)
$origPath = getcwd();

# Look for action and dataSource
for my $i (0..$#ARGV)  {
    SWITCH: {
		if(  $ARGV[$i] =~  /^(retrieve|lookup|display)$/ ) { 
			unless(defined($dsName)) {$dsName = splice @ARGV, $i+1, 1; }
			unless(defined($action)) {$action =  splice @ARGV, $i, 1; }
			last SWITCH; 
		}
		# add set or remove calls should look like: [add|set|remove] <DataSourceName> <targetString> <arg|prop=var>      
		# ie. add MY /a/d1/t*/name 123
		if(  $ARGV[$i] =~  /^(add|set|remove)$/ ) { 
			unless(defined($targetString)) {$targetString = splice @ARGV, $i+2, 1; }
			unless(defined($dsName)) {$dsName = splice @ARGV, $i+1, 1; }
			unless(defined($action)) {$action =  splice @ARGV, $i, 1; } 
			last SWITCH; 
		}
		if(  $ARGV[$i] =~  /^(export|export)$/ ) { 
			unless(defined($exporterName)) {$exporterName =  splice @ARGV, $i+1, 1;; }
			unless(defined($action)) {$action = splice @ARGV, $i, 1; } 
			last SWITCH; 
		}		
		my $nothing = 1;
    }
}
#utf8::encode($albumDir);
#$albumDir='O:\M\Travail\Test-folder[(1)]azeéàùuë';
#print STDERR (join("|",@ARGV),"\n");


#utf8::decode($albumDir);
chdir($albumDir) or die("Unable to chdir to $albumDir $?, $!");
#chdir("./CLASSIC WIP/Zelenka - Responsoria; Tuma - Sonatas, Sinfonia - Boni pueri, Musica Floreal - Supraphon/")  or die("Unable to chdir to $albumDir $?, $!");
#	print "\nDataFile:  $dataFile \n ";
#die;

if(defined($dataFile) and -e  $dataFile ) {
	$albumFile = DataFile::AlbumFile->new();	
	$albumFile->deserialize($dataFile );
}
elsif(-e File::Spec->catfile($albumDir, '.mda.xml')) {
	$albumFile = DataFile::AlbumFile->new();	
	$albumFile->deserialize(File::Spec->catfile($albumDir, '.mda.xml'));
}else {
	$albumFile = DataFile::AlbumFile->new();
}

if(defined($dsName)) {
	if(defined($albumlId) and $dsName eq 'AMGClassical' ) {
		$albumFile->{lookupData}{AMG}{albumSqlId}=$albumlId;
	}elsif(defined($worksIds) and $dsName eq 'AMGClassical' ) {
		$albumFile->{lookupData}{AMG}{worksSqlIds}=$worksIds;
	}elsif(defined($albumlId) and $dsName eq 'AKM' ) {
		$albumFile->{lookupData}{AKM}{albumId}=$albumlId;
	}elsif(defined($albumlId) and $dsName eq 'CDU' ) {
		$albumFile->{lookupData}{CDU}{albumId}=$albumlId;
	}	
}
#print("$action : $dsName : $albumDir");


if( defined($dsName) ) {
	if(length($dsName) < 2) {
		die("Invalid datasource name '$dsName': DataSource name must be at least 2 characters long");
	}
	# Build DS class name: DataFile::ABC::ABCdefgReader
	$dataSourceClass='DataSource::'.substr($dsName,0,3).'::'.$dsName.'Reader';
	eval("use  $dataSourceClass");
}

if( defined($exporterName) ) {
	# Build DS class name: DataFile::ABC::ABCdefgReader
	$exporterClass='DataExport::'.$exporterName;
	eval("use  $exporterClass");
}

SWITCH: {
	if(  $action =~  /^retrieve$/) {
		unless($dsName eq 'CDU') { #TODO: to be removed as soon as CDU dataSource exists, used to save CDUID
			my $dataSource = $dataSourceClass->new();
			$albumFile->addDataSource($dataSource);
			$albumFile->dataSource($dsName)->retrieve();
		}
		$albumFile->serialize( File::Spec->catfile($albumDir, '.mda.xml'));
		last SWITCH;
	}
	if(  $action =~  /^export/) {
		my $dataExporter = $exporterClass->new(); 
		$dataExporter->export($albumFile);
		last SWITCH;		
	}
	if(  $action =~  /^(set|remove|add)/) {
		my $dataSource = $albumFile->dataSource($dsName);
		unless(ref $dataSource) {
			print("Creating $dsName dataSource\n");
			$dataSource =  $dataSourceClass->new();
			$albumFile->addDataSource($dataSource);
		} 
		$albumFile->dataSource($dsName)->$action($targetString, @ARGV);
		$albumFile->serialize( File::Spec->catfile($albumDir, '.mda.xml'));
		last SWITCH;		
	}			
	if(  $action =~  /^display$/) {
		print($albumFile->dataSource($dsName)->toString($verbosity));
		last SWITCH;		
	}	
	my $nothing = 1;
}

# set MY /a/d*/t*/name value="Alfred is king"
# set MY /a/d*/t*/name "Alfred is king"
# add MY /a/d*/t*/tag  attribute1="value" attribute2="value2" (add tag with those attributes)
# remove MY /a/d*/t*/tag  attribute1="searchvalue"  (remove tag with attribute1=searchvalue)
# remove MY /a/d*/t*/tag  (remove every tags)

# restoring caller working directory
chdir($origPath) or ERROR("Unable to chdir to original path $origPath");
print("Finished without major errors.");

__END__

=head1 NAME

sample - Using Getopt::Long and Pod::Usage


GetOptions('help|?' => \$help, 
					'man' => \$man,
					'album-dir|d=s' => \$albumDir,
					'data-file|f=s' => \$dataFile,
					'action|a=s' => \$action,
					'data-source|ds=s' => \$dsName,
					# 'amg-album-sql-id=s' => sub { my $arg = shift; my $amgSqlId = shift; }
					'album-id|ai=s' => \$albumlId,
					'disc-id|di=s' => \$discIds,
					'verbosity|v=i' => \$verbosity,
					'data-exporter|de=s' => \$exporterName
					) or pod2usage(2);
					
=head1 SYNOPSIS

mda  <action> <dataSource|dataExporter> [options]

   Actions:
      retrieve	retrieve all information for the given dataSource 
		(overwrite previously retrieved data for the same data source)
      lookup	search datasource for possible albums, display candidates
      display   display datasource collected information in a human readable format
      set		define a property or a set of properties as specified in -target parameter

   DataSource:
      AMGClassical	all music classical 
      CUE		cue sheet reader
      FIL		flac files reader
      AKM		arkivmusic
      MY		manually defin personnal properties
      
   DataExporter:
   	AMGClassical2Flac	Basic stupid AMG only Flac file tagger (proof of concept)
         	
   Options:
      -help		brief help message
      -man		full documentation
      -album-dir	base directory for the album
      -data-file	name of the datafile, by default .mda.xml (not implemented yet
      -action		equivalent of <action>
      -data-source	equivalent of <datasource>
      -disc-ids		freedb: discId, syntax is AD1151B for single disc or 1(AD11051B)|2(AD5861B) for single and multi-disc
      -works-ids AMG: works if for tracks 1(1-3=42:456;4-6=42:789)|2(1,2,3=42:741)
      -album-id		AMG albumId, syntax is an amg album id like found in the url parameter sql=
			AKM: albumId, syntax is an ArkivMusic album id integer like found in the url parameter album_id=
      -verbosity

=head1 OPTIONS

=over 8

=item B<-target>

[MY] Specify the target element for set, unset, remove or add actions.

It's a sort of xpath notation 
ex: --target /album/name=tutu, 
--target /a/label/rawData=toto,
--target composer/name=toto,

relative path is considered to be /a (album level by default)

=item B<-freedb-disc-id>
Specify a freedb discId, syntax is AD11051B for single disc or 1(AD11051B)|2(AD5861B) for single and multi-disc

=item B<-help>
Print a brief help message and exits.

=item B<-man>
Prints the manual page and exits.

=item B<-works-ids>
Specify a set of work ids, syntax is  discnum(trackrange=workid;)|    ex:  1(1-3=42:456;4-6=42:789)|2(1,2,3=42:741)
 
=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut