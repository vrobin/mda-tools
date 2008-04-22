#!/usr/bin/perl -w

#package MDA::GUI::DirExplorerTree;
package DirExplorerTree;

use strict;
use utf8;

use Data::Dumper;
#use File::Find;
#use File::Next;
use File::Spec;
#use File::Util;
use Log::Log4perl qw(:easy);


my $mediaExtensions = [ '.cue', '.ape', '.wav', '.flac', '.mp3', '.wv', 'aiff'];
my $windows = 0;
if ($^O =~ /^m?s?win/i) {
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
	# use local $tree variable to prevent multiple tree getter calls
	my $tree=$self->tree();

	$tree->configure(-selectmode => 'browse',
					-showroot => 'yes',
					-showrootbutton => 'no', 
					-showbuttons => 'yes',
					-showlines => 'yes',
					-xscrollincrement => 20);
					
	my $folderPicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/folder.png");
	my $myComputerPicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/computer.png");
	my $homePicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/house.png");
	my $musicPicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/music.png");
	my $mdaAwarePicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/folder_star.png");
	
	my $column = $tree->column("create", -text=>"taper sur", -image => $folderPicto, -tags =>"folderTag");
	$tree->configure(-treecolumn => 'folderTag');
	my $column2 = $tree->column("create", -text=>"âàèé");
	
	# Declare the different state of an item in the treectrl
	# first the different known folders type
	$tree->state("define", "hasSubFolders");
	$tree->state("define", "hasMediaFile");
	$tree->state("define", "hasMdaXmlFile");
	# specific states for "drives" in windows
	$tree->state("define", "isFixedDrive");
	$tree->state("define", "isRemovableDrive");
	$tree->state("define", "isNetworkDrive");
	$tree->state("define", "isCDROM");
	$tree->state("define", "isOther"); # other can be no root, unknown or ramdisk

    $tree->element("create", "elemImg", "image",  -image => [
	$mdaAwarePicto, ["hasMdaXmlFile"],
	$musicPicto,  ["hasMediaFile", "!hasMdaXmlFile"],
	$folderPicto, []
	]
	);
    
	$tree->element("create", "myComputerFolderImage", "image", -image => $myComputerPicto);
	$tree->element("create", "classicFolderImage", "image", -image => $folderPicto);
	$tree->element("create", "folderTxt", "text");
	
	my $styleFolder=$tree->style("create", "sf");
	my $styleClassicFolder=$tree->style("create", "scf");
	my $styleMyComputerFolder = $tree->style("create", "srf");
	
	
	#my $style2=$tree->style("create", "s2");
	$tree->style('elements', $styleFolder, 'elemImg folderTxt');
	$tree->style('elements', $styleClassicFolder, 'classicFolderImage folderTxt');
	$tree->style('elements', $styleMyComputerFolder, 'myComputerFolderImage folderTxt');
	#$tree->style('elements', $style2, 'folderImg folderTxt');
	
	$tree->style("layout", $styleClassicFolder,  "classicFolderImage", -expand=>'ns');
	$tree->style("layout", $styleClassicFolder,  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');

	$tree->style("layout", $styleMyComputerFolder,  "myComputerFolderImage", -expand=>'ns');
	$tree->style("layout", $styleMyComputerFolder,  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');

	
	$tree->column('configure', 'folderTag', -itemstyle => 'sf');
	
	my $treeRoot = $tree->item("id", "root");
	print "XXX: ".$treeRoot."\n";
	
	my @roots;
	if($windows) {
		@roots = Win32API::File::getLogicalDrives();
	}else {
		push @roots, "/";
	}
	$tree->item("configure", $treeRoot, -button => 'yes');
	$tree->item("style", "set", $treeRoot, $column, $styleMyComputerFolder);
	$tree->item("text", $treeRoot, "folderTag", "My Computer" );
	foreach my $root (@roots) {
		
		$self->_addFolder($treeRoot, $root);

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
	}
	
	$tree->notify("bind", $tree, "<Expand-before>", [
       sub {
       	   my $t = shift;
           my $i = shift;
#           my $item=$tree->item("create", -button => 'yes');
#				#$tree->item("collapse", $item);
#				$tree->item("text", $item, "folderTag", "TEST" );           
#				$tree->item("lastchild", $i, $item);
#				$tree->item("collapse", $item);
          # print "Clicked at $i\n";
          #Tkx::update("idletasks");
          return $i;
       },    Tkx::Ev("%T", "%I")]);
	$tree->notify("bind", $tree, "<Expand-after>", [
       sub {
       	my $t = shift;
       	my $i = shift;
       	$tree->item("configure", $i, -button => 'yes');
          #Tkx::update();
       },    Tkx::Ev("%T", "%I")]);   
	$tree->notify("bind", $tree, "<Collapse-after>", [
       sub {
       	my $t = shift;
       	my $i = shift;
       	$tree->item("configure", $i, -button => 'yes');
          #Tkx::update();
       },    Tkx::Ev("%T", "%I")]); 

#	die;
#	my $itemfils=$tree->item("create");
#	my $itemfils2=$tree->item("create");
#	$tree->item("lastchild", $treeRoot, $itemfils);
#	$tree->item("lastchild", $itemfils, $itemfils2);
#	
#	$tree->item("text", $itemfils, "folder", "Allo?" );
#	$tree->item("text", $itemfils2, "folder", "A l'huile!" );
#	print $tree->item("create", -count => 5);	
}

# create a folder item (for tktreectrl) from the full dirname
# create it folder or not, and whith the good item tag 
# (music dir, mda.xml dir or normal dir)
sub _createFolderItem {
	my $self = shift;
	my $parentItem = shift;
	unless(defined $parentItem){
		ERROR("Missing input parameter: directory name");
		die;
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
	unless(defined $parentItem){
		ERROR("Missing input parameter: parent item");
		die;
	}

	unless(defined $folderPath){
		ERROR("Missing input parameter: folder path");
		die;
	}

	unless (-d $folderPath) {
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
#	if( length($dirs) ) { print length($dirs)." dirs $dirs found\n"}
#	if( length($file) ) { print "file $file found\n"}

	# prepare a test for "root directory guessing"
	my $itemText;
	my $rootDir = File::Spec->rootdir;
	$rootDir =~ s/([\\(){}[\]\^\$*+?.|])/\\$1/g;
	
#	if( $dirs =~ m/^${rootDir}$/) { print "dir  $dirs is a root\n"}
#	die;

	# The path is the path of a windows system drive root
	if($windows and length($drive) and ($dirs =~ m/^${rootDir}$/) ) {
		# define the drive type and associate the item with this state
		my $driveType = Win32API::File::GetDriveType( $folderPath );
		$tree->item("configure", $item, -button => 'yes');
		$tree->item("collapse", $item);
		$tree->item("state", "set", $item, "hasSubFolders");
		if($driveType==Win32API::File::DRIVE_FIXED){
			$tree->item("state", "set", $item, "isFixedDrive");
			DEBUG ("Found fixed drive '$drive'\n");
		}elsif($driveType==Win32API::File::DRIVE_REMOTE) {
			$tree->item("state", "set", $item, "isNetworkDrive");
			DEBUG ("Found network drive '$drive'\n");
		}elsif($driveType==Win32API::File::DRIVE_REMOVABLE) {
			$tree->item("state", "set", $item, "isRemovableDrive");
			DEBUG ("Found removable drive '$drive'\n");
		}elsif($driveType==Win32API::File::DRIVE_CDROM) {
			$tree->item("state", "set", $item, "isCDROM");
			DEBUG ("Found cdrom drive '$drive'\n");
		}elsif($driveType==Win32API::File::DRIVE_NO_ROOT_DIR) {
			$tree->item("state", "set", $item, "isOther");
			DEBUG ("Found no rooted drive '$drive'\n");
		}elsif($driveType==Win32API::File::DRIVE_RAMDISK) {
			$tree->item("state", "set", $item, "isOther");
			DEBUG ("Found ramdisk drive '$drive'\n");
		}elsif($driveType==Win32API::File::DRIVE_UNKNOWN) {
			$tree->item("state", "set", $item, "isOther");
			DEBUG ("Found unknown drive '$drive'\n");
		}else {
			ERROR("Unknown drive type '$drive'");
			die;
		}

		my $osFsType = "\0"x256;
		my $osVolName = "\0"x256;
		my $ouFsFlags = 0;
		Win32API::File::GetVolumeInformation($folderPath, $osVolName, 256, [], [], $ouFsFlags, $osFsType, 256 );
		$itemText = "$osVolName ($drive)";
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
	$tree->item("text", $item, "folderTag", $itemText );
	$tree->item("lastchild", $parentItem, $item);
print("XXXXXXXXXXXXXXXXXXX\n");
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
	
	if ($parentWindow) {
		if(defined($self->{parentWindow})) {
			ERROR("ParentWindow already set, there's no need to reassociate it again (yet).");
			return $self->{parentWindow};
		}
		$self->{parentWindow} =  $parentWindow;
		$self->{tree} = $parentWindow->new_treectrl();
	}
	return $self->{parentWindow};
}

sub tree {
	my $self = shift;
	return $self->{tree};
}

1;