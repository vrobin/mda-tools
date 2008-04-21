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
use Win32API::File;

my $mediaExtensions = [ '.cue', '.ape', '.wav', '.flac', '.mp3', '.wv', 'aiff'];
my $windows = 0;
if ($^O =~ /^m?s?win/i) {
	$windows = 1;
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
	
	$tree->state("define", "hasSubFolders");
	$tree->state("define", "hasMediaFile");
	$tree->state("define", "hasMdaXmlFile");

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
	#$folderPath="\\";

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

# TODO: handle windows drive roots (floppy, hard drive, removable, disk, network)

	my $dirFD;
	opendir($dirFD, $folderPath) || ( ERROR("Cannot open directory") and return);

#	my $item=$tree->item("create", -button => 'yes');
#	$tree->item("state", "set", $item, "hasMediaFile");
#	$tree->item("lastchild", $parentItem, $item);
	# We have a real folder in parameter, so create the corresponding item
	my $item=$tree->item("create");
	# The text of the item is the name of the folder we're adding (or else, it could be a drive or a root)
	my $itemText = ( (File::Spec->splitdir( $folderPath ))[-1]);
	if ($itemText =~ /^$/) {
		$itemText = ( (File::Spec->splitdir( $folderPath ))[-2]);
	}


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
# TODO: escape dot in extension check (media extension .mp3 is used with dot unescaped)
			foreach my $mediaExtension ( @$mediaExtensions ) {
				print("trying extension $mediaExtension\n");
				if($fileInDir =~ /^.*${mediaExtension}$/) {
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
	$tree->item("text", $item, "folderTag", $itemText );
	$tree->item("lastchild", $parentItem, $item);
#	my $iter = File::Next::dirs( { file_filter => sub { print "File: ".$_."\n"; return 1; }, descend_filter => sub{print "Dir: ".$_."\n"; return 0} }, $folderPath );
#    while ( defined ( my $file = $iter->() ) ) {
#        # do something...
#        print $File::Next::dir." XX $file\n";
#    }
#my($f) = File::Util->new();
#foreach my $entry ($f->list_dir( $folderPath,'--no-fsdots' )) {
#	print("$entry  \n");
#}	
print("XXXXXXXXXXXXXXXXXXX\n");
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
}
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