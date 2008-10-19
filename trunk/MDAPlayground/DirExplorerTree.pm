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


my @mediaExtensions = ('ape', 'wav', 'flac', 'mp3', 'wv', 'aiff');
my @folderItems;

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
    	"isTkTreeRoot",
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
	$pictos{myComputerPicto}{tkImage}, ["isTkTreeRoot"],
	$pictos{mdaAwarePicto}{tkImage}, ["hasMdaXmlFile"],
	$pictos{musicPicto}{tkImage},  ["hasMediaFile", "!hasMdaXmlFile"],
	$pictos{cdDrivePicto}{tkImage}, ["isCDROM"],
	$pictos{drivePicto}{tkImage}, ["isFixedDrive"],
	$pictos{folderPicto}{tkImage}, []
	]
	);
    
#	$tree->element("create", "myComputerFolderImage", "image", -image => $pictos{myComputerPicto}{tkImage});
#	$tree->element("create", "classicFolderImage", "image", -image => $pictos{folderPicto}{tkImage});
	$tree->element("create", "folderTxt", "text", -font => ['Tahoma 8'],
	-fill => ['SystemHighlightText', 'selected focus'],);

#   $T element create sel.e rect -fill [list $::SystemHighlight {selected focus} gray {selected !focus}] -open e -showfocus yes
	$tree->element("create", "sel.e", "rect", 
	-fill => ['SystemHighlight', 'selected focus', 'gray', 'selected !focus'],	
# same as:
#	-fill => ['SystemHighlight', ['selected', 'focus'], 'gray', ['selected', '!focus']],
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
	$tree->style("layout", "folderStyle",  "sel.e", -ipadx => '2', -union => ['folderTxt'], -iexpand => 'ns');
	
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

#	_addSubFolders($self, '1');
#bind .l <1> {tk_popup .popupMenu %X %Y} ButtonPress-1
my $tutu = $self->parentWindow();
	$tree->g_bind( "<ButtonPress-3>", [
		sub {
       	   my $t = shift;
           my $event = shift;
           my $detail = shift;
           my $absoluteX = shift;
           my $absoluteY = shift;
           my $relativeX = shift;
           my $relativeY = shift;
           #print("ITEMITEM: ".$tree->item("text", "nearest $relativeX $relativeY" ));
			$self->_selectNearestItem($relativeX, $relativeY);
#			print "BOUYAAAHHHH at ".Dumper($event)." - $t - e: $event - d: $detail  x: $absoluteX   y: $absoluteY\n";
          	Tkx::tk___popup($self->_buildFolderPopupMenu(), $absoluteX, $absoluteY);
			return;
       },    Tkx::Ev("%T", "%e", "%d", "%X", "%Y", "%x", "%y")]
	);
	
	$tree->m_notify("bind", $tree, "<Expand-before>", [
       sub {
       	   my $t = shift;
           my $i = shift;
           my $event = shift;
           my $detail = shift;
          print "Clicked at ".Dumper($i)." - $t - e: $event - d: $detail\n";
          $self->_addSubFolders($i);
          return $i;
       },    Tkx::Ev("%T", "%I", "%e", "%d")]);
	$tree->notify("bind", $tree, "<Expand-after>", [
       sub {
       	my $t = shift;
       	my $i = shift;
       	$tree->item("configure", $i, -button => 'yes');
       },    Tkx::Ev("%T", "%I")]);   
	$tree->m_notify("bind", $tree, "<Collapse-after>", [
       sub {
       	my $t = shift;
       	my $i = shift;
       	$tree->item("configure", $i, -button => 'yes');
       },    Tkx::Ev("%T", "%I")]); 

	return;
}


# The method is used to build the menu that popup when
# user right click on a folder item
sub _buildFolderPopupMenu {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	# use local $tree variable to prevent multiple tree getter calls
	my $tree=$self->tree();	
	#	my $tutu=$self->parentWindow()->new_menu();
	my $folderPopupMenu = $tree->new_menu();
	my $fileMenu = $folderPopupMenu->new_menu(
        -tearoff => 0,
    );
	$folderPopupMenu->add_cascade(
        -label => "File",
        -underline => 0,
        -menu => $fileMenu,
    );
	return $folderPopupMenu;
}

# Select the item near a X/Y relative coordinates
# used before poping up menu
sub _selectNearestItem {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	# use local $tree variable to prevent multiple tree getter calls
	my $tree=$self->tree();
	my $item = $tree->item("id", "nearest $x $y"); 
	$tree->selection("clear");
	$tree->selection("add", $item);
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
	$tree->item("state", "set", $treeRoot, "isTkTreeRoot" );
	$tree->item("tag", "add", $treeRoot, "isTkTreeRoot" );	

	foreach my $root (@roots) {		
		$self->_addFolder($treeRoot, $root);
	}
	#print Dumper \@folderItems;
	return;
}

sub _junkToFold {
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
#	my $item=$tree->item("create", -button => 'yes');
#	$tree->item("state", "set", $item, "hasMediaFile");
#	$tree->item("lastchild", $parentItem, $item);
	# We have a real folder in parameter, so create the corresponding item
	
	# The text of the item is the name of the folder we're adding (or else, it could be a drive or a root)
#	my $itemText = ( (File::Spec->splitdir( $folderPath ))[-1]);
#	if ($itemText =~ /^$/) {
#		$itemText = ( (File::Spec->splitdir( $folderPath ))[-2]);
#	}
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

#	if( length($drive) ) { print Dumper($drive).  "drive $drive found\n"}
#	if( length($dirs) ) { print length($didrs)." dirs $dirs found\n"}
#	if( length($file) ) { print "file $file found\n"}
#	if( $dirs =~ m/^${rootDir}$/) { print "dir  $dirs is a root\n"}
#	die;
#	.t configure -itemtagexpr false
#.t item delete "tag a&&b"
#	$tree->item("tag",  $item, -tag => ["monpaf" , 'ben oit&&jul,i|e||n&toutseul']);
#	$tree->item($folderPath);
#	print Dumper($tree->item("tag", "expr", $parentItem, 'pouet||subFoldersAdded' ));
# return '1'
#	print Dumper($tree->item("tag", "expr", $parentItem, "subFoldersAddeAAAd"));
# return '0'
          #Tkx::update();
#           my $item=$tree->item("create", -button => 'yes');
#				#$tree->item("collapse", $item);
#				$tree->item("text", $item, "folderTag", "TEST" );           
#				$tree->item("lastchild", $i, $item);
#				$tree->item("collapse", $item);
#          Tkx::update("idletasks");
#          Tkx::update();
#          Tkx::update();
}

sub _addSubFolders {
	my $self = shift;
	my $parentItem = shift;
	my $folderPath = $folderItems[$parentItem]{folderPath};
	my $tree=$self->tree();	

	# don't do anything if item already has its subfolders:
	if( $tree->item("tag", "expr", $parentItem, 'pouet||subFoldersAdded' ) ) {
		return;
	}
	# TODO: add some code to refresh the item content
	
	my $dirFD;
	opendir($dirFD, $folderPath) || ( ERROR("Cannot open directory") and return $parentItem);

	# Examine each entry in this folder to know how to display it
	foreach my $fileInDir (File::Spec->no_upwards(readdir($dirFD))) {
		my $fileInDirFullPath=File::Spec->catfile($folderPath, $fileInDir);
		# items has subFolders, so make it expandable
		if(-d $fileInDirFullPath) {
			$self->_addFolder($parentItem, $fileInDirFullPath);
		}
	}
	$tree->item("tag", "add", $parentItem, "subFoldersAdded");
	return;
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

	# Detect drive and dirs
	my ($drive, $dirs, $file) = File::Spec->splitpath( $folderPath, 1 );

	# prepare a test for "root directory guessing"
	my $item;
	my $itemText;
	my $escapedRootDir = File::Spec->rootdir;
	#print("YYYYYYYYYYYY $escapedRootDir xxxxxxxxxx\n");
	#$rootDir =~ s/([\\(){}[\]\^\$*+?.|])/\\$1/g;
	# escape root folder so it can be used in a regexp
	$escapedRootDir =~ s{ ( [\\(){}[\]\^\$*+?.|] ) }{\\$1}xg;

	#print("XXXXXXXXXXX $escapedRootDir xxxxxxxxxx\n");

	# The path is the path of a windows system drive root
#	if($windows and length($drive) and ($dirs =~ m/^${rootDir}$/) ) {
	if($windows and length($drive) and ($dirs =~ m{^ $escapedRootDir $}x) ) {
		$item = $self->_createWindowsDriveItemWithText($drive);
	} 
	else { # this is not a windows drive, but a normal directory
		$item = $self->_createFolderItemWithText($folderPath);
	}
	# save the path of the folder associated with the tree item 
	$folderItems[$item]{folderPath} =  $folderPath;
	
	$item = $self->_findAndSetFolderItemProperties($item);
	
	# add the new item to the parent item
	$tree->item("lastchild", $parentItem, $item);
	
	return;
}

# Take a
sub _findAndSetFolderItemProperties {
	my $self = shift;
	my $item = shift;
	my $tree=$self->tree();
	my $folderPath = $folderItems[$item]{folderPath};
	my $itemText;

	if(not defined $item){
		ERROR("Missing input parameter: tree item");
		croak;
	}
	if(not defined $folderPath){
		ERROR("Missing directory name or path found is not a folder (${folderPath})");
		croak;
	}

	my $dirFD;
	opendir($dirFD, $folderPath) || ( ERROR("Cannot open directory") and return $item);

	# Examine each entry in this folder to know how to display it
	foreach my $fileInDir (File::Spec->no_upwards(readdir($dirFD))) {
		#print ("xxxx: $fileInDir");
		my $fileInDirFullPath=File::Spec->catfile($folderPath, $fileInDir);

		# items has subFolders, so make it expandable
		if(-d $fileInDirFullPath) {
			$tree->item("configure", $item, -button => 'yes');
			$tree->item("collapse", $item);
			$tree->item("state", "set", $item, "hasSubFolders");
			DEBUG ("Found directory '$fileInDirFullPath'\n");
#			$self->_createFolderItem;
		}elsif(-f $fileInDirFullPath) {
			#print("File: ");
			DEBUG ("Found file '$fileInDirFullPath'\n");

			foreach my $mediaExtension ( @mediaExtensions ) {
#				print("avant: $mediaExtension  - ".Dumper($mediaExtension));
#				$mediaExtension =~ s{ ([\\(){}[\]\^\$*+?.|]) }{\\$1}xg;#
#				print("apres: $mediaExtension  \n");
#				print("trying extension $mediaExtension\n");
				if($fileInDir =~ m/^.*\.${mediaExtension}$/i) {
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
	return $item;
}

# create a folder item (for tktreectrl) from the full dirname
# with the name of the folder in the item text 
sub _createFolderItemWithText {
	my $self = shift;
	my $folderPath = shift;
	my $tree=$self->tree();
	my $item=$tree->item("create");
	my $itemText;

	if(not defined $folderPath){
		ERROR("Missing input parameter: directory name");
		croak;
	}
	
	$itemText=(File::Spec->splitdir( $folderPath ))[-1];
	$tree->item("text", $item, "folderColumn", $itemText );
	return $item;	
}

# Take a drive name string in parameter and return a tree item with 
# the the state correspondig to type and volume name (when possible)
# in: string (like "d:", "c:", etc.)
sub _createWindowsDriveItemWithText {
	my $self = shift;
	my $drive = shift;
	my $tree=$self->tree();
	my $item=$tree->item("create");
	my $itemText;
	my %driveTypeStylename = (
		    Win32API::File::DRIVE_UNKNOWN => "isOther",
		Win32API::File::DRIVE_NO_ROOT_DIR => "isOther",
		  Win32API::File::DRIVE_REMOVABLE => "isRemovableDrive",
	          Win32API::File::DRIVE_FIXED => "isFixedDrive",
	         Win32API::File::DRIVE_REMOTE => "isNetworkDrive",
		      Win32API::File::DRIVE_CDROM => "isCDROM",
	        Win32API::File::DRIVE_RAMDISK => "isOther"
	);

	# define the drive type and associate the item with this state
	my $driveType = Win32API::File::GetDriveType( $drive );
# commented because it will be set by generic method _findAndSetFolderItemProperties
#	$tree->item("configure", $item, -button => 'yes');
	$tree->item("collapse", $item);
# commented because it will be set by generic method _findAndSetFolderItemProperties
#	$tree->item("state", "set", $item, "hasSubFolders");

	# find preconfigured driveStyle string in hash with drive type returned by win32API
	my $driveStyle=$driveTypeStylename{$driveType};
	if(not $driveStyle) {
		croak("Unknown drive type '$drive' (type found: $driveType) \n")
	}
	$tree->item("state", "set", $item, $driveStyle);

	my $osFsType = "\0" x 256;
	my $osVolName = "\0" x 256;
	my $ouFsFlags = 0;
	# I had to add '\\' because drive D: (and only this one) refused to work anymore ?!?!
	if ( Win32API::File::GetVolumeInformation($drive.'\\', $osVolName, 256, [], [], $ouFsFlags, $osFsType, 256 ) ) 
	{
		$itemText = "$osVolName ($drive)";
	}
	else {
		$itemText = "CD/DVD Drive ($drive)";
	}
	$tree->item("text", $item, "folderColumn", $itemText );
	return $item;
}

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