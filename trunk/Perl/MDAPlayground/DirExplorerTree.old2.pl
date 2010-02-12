#!/usr/bin/perl -w
package MDA::GUI::DirExplorerTree;

use strict;
use utf8;
use Data::Dumper;
use Log::Log4perl qw(:easy);

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
					-showroot => 'no',
					-showrootbutton => 'no', 
					-showbuttons => 'no',
					-showlines => 'no',
					-xscrollincrement => 20);
					
	my $folderPicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/folder.png");
	my $homePicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/house.png");
	my $musicPicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/music.png");
	my $mdaAwarePicto=Tkx::image("create", "photo", -format => "png", -file => "graphics/folder_star.png");
	
	my $column = $tree->column("create", -text=>"taper sur", -image => $folderPicto, -tags =>"folder");
	$tree->configure(-treecolumn => 'folder');
	my $column2 = $tree->column("create", -text=>"âàèé");
	
	$tree->element("create", "folderImg", "image", -image => $folderPicto);
	$tree->element("create", "folderTxt", "text");
	
	my $style1=$tree->style("create", "s1");
	#my $style2=$tree->style("create", "s2");
	$tree->style('elements', $style1, 'folderImg folderTxt');
	#$tree->style('elements', $style2, 'folderImg folderTxt');
	$tree->style("layout", $style1,  "folderImg", -expand=>'ns');
	$tree->style("layout", $style1,  "folderTxt", -padx => '2 6', -squeeze=>'x', -expand=>'ns');
	
	$tree->column('configure', 'folder', -itemstyle => 's1');
	
	my $root = $tree->item("id", "root");
	print $root;
	my $itemfils=$tree->item("create");
	my $itemfils2=$tree->item("create");
	$tree->item("lastchild", $root, $itemfils);
	$tree->item("lastchild", $itemfils, $itemfils2);
	
	$tree->item("text", $itemfils, "folder", "Allo?" );
	$tree->item("text", $itemfils2, "folder", "A l'huile!" );
	
	print $tree->item("create", -count => 5);	
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