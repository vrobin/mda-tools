#!/usr/bin/perl -w

#package MDA::GUI::DirExplorerTree;
package DirExplorerTree;

use strict;
use utf8;

use Data::Dumper;
use File::Spec;
use Log::Log4perl qw(:easy);
use Win32API::File;

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
	
	$tree->element("create", "myComputerFolderImage", "image", -image => $myComputerPicto);
	$tree->element("create", "classicFolderImage", "image", -image => $folderPicto);
	$tree->element("create", "folderTxt", "text");
	
	my $styleClassicFolder=$tree->style("create", "scf");
	my $styleMyComputerFolder = $tree->style("create", "srf");
	
	
	#my $style2=$tree->style("create", "s2");
	$tree->style('elements', $styleClassicFolder, 'classicFolderImage folderTxt');
	$tree->style('elements', $styleMyComputerFolder, 'myComputerFolderImage folderTxt');
	#$tree->style('elements', $style2, 'folderImg folderTxt');
	
	$tree->style("layout", $styleClassicFolder,  "classicFolderImage", -expand=>'ns');
	$tree->style("layout", $styleClassicFolder,  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');

	$tree->style("layout", $styleMyComputerFolder,  "myComputerFolderImage", -expand=>'ns');
	$tree->style("layout", $styleMyComputerFolder,  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');

	
	$tree->column('configure', 'folderTag', -itemstyle => 'scf');
	
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
		print "$root"."\n";
		my $item=$tree->item("create", -button => 'yes');
		$tree->item("collapse", $item);
		$tree->item("lastchild", $treeRoot, $item);
		$tree->item("text", $item, "folderTag", "$root" );
		my $itemC1=$tree->item("create", -button => 'no');
		$tree->item("collapse", $itemC1);
		$tree->item("lastchild", $item, $itemC1);
		$tree->item("text", $itemC1, "folderTag", "itemC2" );
		my $itemC2=$tree->item("create", -button => 'no');
		$tree->item("collapse", $itemC2);
		$tree->item("lastchild", $item, $itemC2);
		$tree->item("text", $itemC2, "folderTag", "itemC2" );
		my $itemC3=$tree->item("create", -button => 'no');
		$tree->item("collapse", $itemC3);
		$tree->item("lastchild", $item, $itemC3);
		$tree->item("text", $itemC3, "folderTag", "itemC3" );	}
	
	$tree->notify("bind", $tree, "<Expand-before>", [
       sub {
       	   my $t = shift;
           my $i = shift;
           my $item=$tree->item("create", -button => 'yes');
				#$tree->item("collapse", $item);
				$tree->item("text", $item, "folderTag", "TEST" );           
				$tree->item("lastchild", $i, $item);
				$tree->item("collapse", $item);
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