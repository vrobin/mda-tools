#!/usr/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

package DirExplorerTree;
#package MDA::GUI::DirExplorerTree;

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);

use Carp;
use English;
use utf8;
use Data::Dumper;
use File::Find;
use File::Next;
use File::Spec;
#use File::Util;
use Log::Log4perl qw(:easy);


my $mediaExtensions = [ '.cue', '.ape', '.wav', '.flac', '.mp3', '.wv', 'aiff'];
my $windows = 0;
if ($OSNAME =~ /^m?s?win/xmi) {
	$windows = 1;
	use Win32API::File; 
}


sub new {
	my $class = shift;
	my $self = {
		tree => undef,
		parentWindow => undef
	}; 
	bless( $self, $class );
	return $self;
}

# Initialize the tree
sub init {
	my $self = shift;
	$self->tree($self->parentWindow()->new_treectrl());
	# use local $tree variable to prevent multiple tree getter calls
	my $tree=$self->tree();

	$tree->configure(-selectmode => 'browse',
					-showroot => 'yes',
					-showrootbutton => 'no', 
					-showbuttons => 'yes',
					-showlines => 'false',
					-xscrollincrement => 20);

##############################################################################
### Creation of pictos

	# object contains for each type of picto, the path of the picto
	my %pictos = (
         folderPicto => { path => "graphics/folder.png" },
          drivePicto => { path => "graphics/drive.png" },
        cdDrivePicto => { path => "graphics/drive_cd.png" },
     myComputerPicto => { path => "graphics/computer.png" },
           homePicto => { path => "graphics/house.png" },
          musicPicto => { path => "graphics/music.png" },
       mdaAwarePicto => { path => "graphics/folder_star.png" }
	);
	
	# for each of these picto, create a tkImage reference and store it in %pictos hash
	foreach my $picto(keys %pictos) {
#		print("$picto", "=> ", $pictos{$picto}{path},"\n");
		$pictos{$picto}{tkImage} = Tkx::image("create", "photo", -format => "png", -file => $pictos{$picto}{path});
	}


##############################################################################
### Creation of states
	
	# Declare the different state of an item in the treectrl
	# first the different known folders type
    my @folderStates = (
    	"hasSubFolders", 
    	"hasMediaFile", 
    	"hasMdaXmlFile", 
    	"isRootFolder",
        "isFixedDrive", 
        "isRemovableDrive", 
        "isNetworkDrive", 
        "isCDROM",
        "isOther"
    );
        
	foreach my $folderState (@folderStates) {
		print $folderState, "\n";
		$tree->state("define", $folderState);
	}

##############################################################################
### Creation of elements

    $tree->element("create", "elemImg", "image",  -image => [
	$pictos{myComputerPicto}{tkImage}, ["isRootFolder"],
	$pictos{mdaAwarePicto}{tkImage}, ["hasMdaXmlFile"],
	$pictos{musicPicto}{tkImage},  ["hasMediaFile", "!hasMdaXmlFile"],
	$pictos{cdDrivePicto}{tkImage}, ["isCDROM"],
	$pictos{drivePicto}{tkImage}, ["isFixedDrive"],
	$pictos{folderPicto}{tkImage}, []
	]
	);
    
#	$tree->element("create", "myComputerFolderImage", "image", -image => $pictos{myComputerPicto}{tkImage});
#	$tree->element("create", "classicFolderImage", "image", -image => $pictos{folderPicto}{tkImage});
	$tree->element("create", "folderTxt", "text");

#   $T element create sel.e rect -fill [list $::SystemHighlight {selected focus} gray {selected !focus}] -open e -showfocus yes
	$tree->element("create", "sel.e", "rect", 
	-fill => ['SystemHighlight', ['selected', 'focus'], 'gray', ['selected', '!focus']],
	-open =>"e",
	-showfocus => "yes"
	);
##############################################################################
### Creation of styles

	my $styleFolder=$tree->style("create", "folderStyle");
	my $styleClassicFolder=$tree->style("create", "scf");
	my $styleMyComputerFolder = $tree->style("create", "srf");

	
	#my $style2=$tree->style("create", "s2");
	$tree->style('elements', "folderStyle", 'elemImg sel.e folderTxt');
	
#	$tree->style('elements', $styleClassicFolder, 'classicFolderImage folderTxt');
#	$tree->style('elements', $styleMyComputerFolder, 'myComputerFolderImage folderTxt');
	#$tree->style('elements', $style2, 'folderImg folderTxt');

	$tree->style("layout", "folderStyle",  "elemImg", -expand=>'ns',  -padx => '0 0');
	$tree->style("layout", "folderStyle",  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');
	$tree->style("layout", "folderStyle",  "sel.e", -ipadx => '0 0', -union => ['folderTxt']);
	
#	$tree->style("layout", $styleClassicFolder,  "classicFolderImage", -expand=>'ns');
#	$tree->style("layout", $styleClassicFolder,  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');
#
#	$tree->style("layout", $styleMyComputerFolder,  "myComputerFolderImage", -expand=>'ns');
#	$tree->style("layout", $styleMyComputerFolder,  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');

##############################################################################
### Creation of columns

	my $column = $tree->column("create", 
	                               -text=>"taper sur", 
	                               -image => $pictos{folderPicto}{tkImage}, 
	                               -tags =>"folderColumn",
	                               -itemstyle => 'folderStyle');
	my $column2 = $tree->column("create", -text=>"âàèé");                               
	$tree->configure(-treecolumn => 'tag folderColumn');
#	$tree->column('configure', $column, -itemstyle => 'folderStyle');


	$self->_initTreeStructure();

	$tree->m_notify("bind", $tree, "<Expand-before>", [
       sub {
       	   my $t = shift;
           my $i = shift;
           my $event = shift;
           my $detail = shift;
#           my $item=$tree->item("create", -button => 'yes');
#				#$tree->item("collapse", $item);
#				$tree->item("text", $item, "folderTag", "TEST" );           
#				$tree->item("lastchild", $i, $item);
#				$tree->item("collapse", $item);
          print "Clicked at $i - $t - e: $event - d: $detail\n";
#          Tkx::update("idletasks");
#          Tkx::update();
          return $i;
       },    Tkx::Ev("%T", "%I", "%e", "%d")]);
	$tree->notify("bind", $tree, "<Expand-after>", [
       sub {
       	my $t = shift;
       	my $i = shift;
       	$tree->item("configure", $i, -button => 'yes');
          Tkx::update();
       },    Tkx::Ev("%T", "%I")]);   
	$tree->m_notify("bind", $tree, "<Collapse-after>", [
       sub {
       	my $t = shift;
       	my $i = shift;
       	$tree->item("configure", $i, -button => 'yes');
          #Tkx::update();
       },    Tkx::Ev("%T", "%I")]); 

	return;
}

# Fill the root and 
sub _initTreeStructure {
	my $self = shift;
	# use local $tree variable to prevent multiple tree getter calls
	my $tree=$self->tree();
		
	my $treeRoot = $tree->item("id", "root");

	print "XXX: ".$treeRoot."\n";

	my @roots;
	if($windows) {
		@roots = Win32API::File::getLogicalDrives();
	}else {
		push @roots, q{/};
	}
	$tree->item("configure", $treeRoot, -button => 'yes');
#	$tree->item("style", "set", $treeRoot, $column, $styleFolder);

	# it seems that as Root item exist from the begining, its style must be set
	# as column -itemstyle doesn't apply to root item
	$tree->item("style", "set", $treeRoot, "tag folderColumn", "folderStyle");
	$tree->item("text", $treeRoot, "folderColumn", "My Computer" );
	$tree->item("state", "set", $treeRoot, "isRootFolder" );
	$tree->item("tag", "add", $treeRoot, "isRootFolder" );
	

	foreach my $root (@roots) {		
		$self->_addFolder($treeRoot, $root);
	}
}

#		print "$root"."\n";
#		my $item=$tree->item("create", -button => 'yes');
#		$tree->item("state", "set", $item, "hasMediaFile");
#		$tree->item("collapse", $item);
#		$tree->item("lastchild", $treeRoot, $item);
#		$tree->item("text", $item, "folderTag", "$root" );
#		$self->_addFolder($item, $root);
#		my $itemC1=$tree->item("create", -button => 'no');
#		$tree->item("collapse", $itemC1);
#		$tree->item("lastchild", $item, $itemC1);
#		$tree->item("text", $itemC1, "folderTag", "itemC1" );
#		my $itemC2=$tree->item("create", -button => 'no');
#		$tree->item("collapse", $itemC2);
#		$tree->item("lastchild", $item, $itemC2);
#		$tree->item("text", $itemC2, "folderTag", "itemC2" );
#		my $itemC3=$tree->item("create", -button => 'no');
#		$tree->item("collapse", $itemC3);
#		$tree->item("lastchild", $item, $itemC3);
#		$tree->item("text", $itemC3, "folderTag", "itemC3" );	
#	die;
#	my $itemfils=$tree->item("create");
#	my $itemfils2=$tree->item("create");
#	$tree->item("lastchild", $treeRoot, $itemfils);
#	$tree->item("lastchild", $itemfils, $itemfils2);
#	
#	$tree->item("text", $itemfils, "folder", "Allo?" );
#	$tree->item("text", $itemfils2, "folder", "A l'huile!" );
#	print $tree->item("create", -count => 5);	
# Old Code
#	my $folderPicto=Tkx::image("create", "photo", -format => "png", -file => );
#	my $myComputerPicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/computer.png");
#	my $homePicto=Tkx::image("create", "photo", -format => "png", -file => );
#	my $musicPicto=Tkx::image("create", "photo", -format => "png", -file => );
#	my $mdaAwarePicto=Tkx::image("create", "photo", -format => "png", -file => );


# create a folder item (for tktreectrl) from the full dirname
# create it folder or not, and whith the good item tag 
# (music dir, mda.xml dir or normal dir)
sub _createFolderItem {
	my $self = shift;
	my $parentItem = shift;
	if(not defined $parentItem){
		ERROR("Missing input parameter: directory name");
		croak;
	}
	
}

sub _addFolder {
	my $self = shift;
	my $parentItem = shift;
	my $folderPath = shift;
	my $tree=$self->tree();
#	$folderPath='c:\\toto\\tutu';

	# Normalize folderpath, so / and \ are both considered as root
	$folderPath=File::Spec->canonpath( $folderPath ) ;
	if (not defined $parentItem){
		ERROR("Missing input parameter: parent item");
		croak;
	}

	if (not defined $folderPath){
		ERROR("Missing input parameter: folder path");
		croak;
	}

	if (not -d $folderPath) {
		WARN("Parameter '$folderPath' isn't a folder");
		#die;		
	}


#	my $item=$tree->item("create", -button => 'yes');
#	$tree->item("state", "set", $item, "hasMediaFile");
#	$tree->item("lastchild", $parentItem, $item);
	# We have a real folder in parameter, so create the corresponding item
	my $item=$tree->item("create");
	# The text of the item is the name of the folder we're adding (or else, it could be a drive or a root)
#	my $itemText = ( (File::Spec->splitdir( $folderPath ))[-1]);
#	if ($itemText =~ /^$/) {
#		$itemText = ( (File::Spec->splitdir( $folderPath ))[-2]);
#	}

# TODO: handle windows drive roots (floppy, hard drive, removable, disk, network)
	# Detect drive and dirs
	my ($drive, $dirs, $file) = File::Spec->splitpath( $folderPath, 1 );

#	if( length($drive) ) { print Dumper($drive).  "drive $drive found\n"}
#	if( length($dirs) ) { print length($didrs)." dirs $dirs found\n"}
#	if( length($file) ) { print "file $file found\n"}

	# prepare a test for "root directory guessing"
	my $itemText;
	my $rootDir = File::Spec->rootdir;
	print("YYYYYYYYYYYY $rootDir xxxxxxxxxx\n");
	#$rootDir =~ s/([\\(){}[\]\^\$*+?.|])/\\$1/g;
	$rootDir =~ s{ ( [\\(){}[\]\^\$*+?.|] ) }{\\$1}xg;

	print("XXXXXXXXXXX $rootDir xxxxxxxxxx\n");
#	if( $dirs =~ m/^${rootDir}$/) { print "dir  $dirs is a root\n"}
#	die;

# TODO: replace Stylename with StateTag which is more exact
my %driveTypeStylename = (
	    Win32API::File::DRIVE_UNKNOWN => "isOther",
	Win32API::File::DRIVE_NO_ROOT_DIR => "isOther",
	  Win32API::File::DRIVE_REMOVABLE => "isRemovableDrive",
          Win32API::File::DRIVE_FIXED => "isFixedDrive",
         Win32API::File::DRIVE_REMOTE => "isNetworkDrive",
	      Win32API::File::DRIVE_CDROM => "isCDROM",
        Win32API::File::DRIVE_RAMDISK => "isOther"
);
	# The path is the path of a windows system drive root
#	if($windows and length($drive) and ($dirs =~ m/^${rootDir}$/) ) {
	if($windows and length($drive) and ($dirs =~ m{^ $rootDir $}x) ) {
		# define the drive type and associate the item with this state
		my $driveType = Win32API::File::GetDriveType( $folderPath );
		$tree->item("configure", $item, -button => 'yes');
		$tree->item("collapse", $item);
		$tree->item("state", "set", $item, "hasSubFolders");

		# find preconfigured driveStyle string in hash with drive type returned by win32API
		my $driveStyle=$driveTypeStylename{$driveType};
		if(not $driveStyle) {
			croak("Unknown drive type '$drive' (type found: $driveType) \n")
		}
		$tree->item("state", "set", $item, $driveStyle);

		my $osFsType = "\0" x 256;
		my $osVolName = "\0" x 256;
		my $ouFsFlags = 0;
		if ( Win32API::File::GetVolumeInformation($folderPath, $osVolName, 256, [], [], $ouFsFlags, $osFsType, 256 ) ) 
		{
		$itemText = "$osVolName ($drive)";
		}
		else {
			$itemText = "CD/DVD Drive ($drive)";
		}
	} else { # this is not a windows drive, but a normal directory
		$itemText=(File::Spec->splitdir( $folderPath ))[-1];
		
		my $dirFD;
		opendir($dirFD, $folderPath) || ( ERROR("Cannot open directory") and return);
	
		# Examine each entry in this folder to know how to display it
		foreach my $fileInDir (File::Spec->no_upwards(readdir($dirFD))) {
			my $fileInDirFullPath=File::Spec->catfile($folderPath, $fileInDir);
	
			# items has subFolders, so make it expandable
			if(-d $fileInDirFullPath) {
				$tree->item("configure", $item, -button => 'yes');
				$tree->item("collapse", $item);
				$tree->item("state", "set", $item, "hasSubFolders");
				DEBUG ("Found directory '$fileInDirFullPath'\n");
	#			$self->_createFolderItem;
			}elsif(-f $fileInDirFullPath) {
				print("File: ");
				DEBUG ("Found file '$fileInDirFullPath'\n");
	
				foreach my $mediaExtension ( @$mediaExtensions ) {
					$mediaExtension =~ s/([\\(){}[\]\^\$*+?.|])/\\$1/g;
					print("trying extension $mediaExtension\n");
					if($fileInDir =~ m/^.*${mediaExtension}$/i) {
						DEBUG("$folderPath contain $fileInDir media file");
						$tree->item("state", "set", $item, "hasMediaFile");
					}
					elsif($fileInDir =~ /^\.?mda.xml$/) {
						DEBUG("$folderPath contain '$fileInDir' MDA XML file");
						$tree->item("state", "set", $item, "hasMdaXmlFile");
					}
				}
			}else {
				WARN ("Directory entry '$fileInDirFullPath' isn't a directory nor a normal file\n");
			}
		}
	}
	$tree->item("text", $item, "folderColumn", $itemText );
	$tree->item("lastchild", $parentItem, $item);
print("XXXXXXXXXXXXXXXXXXX\n");
	return;
}

#	my $iter = File::Next::dirs( { file_filter => sub { print "File: ".$_."\n"; return 1; }, descend_filter => sub{print "Dir: ".$_."\n"; return 0} }, $folderPath );
#    while ( defined ( my $file = $iter->() ) ) {
#        # do something...
#        print $File::Next::dir." XX $file\n";
#    }
#my($f) = File::Util->new();
#foreach my $entry ($f->list_dir( $folderPath,'--no-fsdots' )) {
#	print("$entry  \n");
#}	
# Check the folder properties: 
# does it contains other folders
# does it contains music files
# does it contains .mda.xml
# if folder contains other folders, add a button
# if folder contains .mda.xml, use appli icon
# if folder contains music, use music icon
#		my $item=$tree->item("create", -button => 'yes');
#		$tree->item("collapse", $item);
#		$tree->item("lastchild", $treeRoot, $item);
#		$tree->item("text", $item, "folderTag", "$root" );



# Add parentWindow to object and create the tree associated with it
sub parentWindow {
	my $self = shift;
	my $parentWindow = shift;
	
	if (defined $parentWindow) {
		if(defined($self->{parentWindow})) {
			ERROR("ParentWindow already set, there's no need to reassociate it again (yet).");
			return $self->{parentWindow};
		}
		$self->{parentWindow} =  $parentWindow;
	}
	return $self->{parentWindow};
}

sub tree {
	my $self = shift;
	my $tree = shift;
	if (defined $tree) {
		$self->{tree} =  $tree;
	}
	return $self->{tree};
}

1;