#!/usr/local/bin/perl

use strict;
use Tkx;
#use Tk::DirSelect;
use Log::Log4perl qw(:easy);
use DirExplorerTree;

Tkx::package("require", "treectrl");
Tkx::package("require", "tile");
Tkx::package("require", "img::png");
Tkx::ttk__setTheme("xpnative");


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


#Tkx::package("require", "tile");
#Tkx::package("require", "Tktable");
#Tkx::package("require", "BWidget");
#Tkx::package("require", "snit");
#Tkx::package("require", "tooltip");


# Set widget theme used


# Print the list of available themes: 
# xpnative clam alt classic default winnative
print Tkx::ttk__themes()."\n";

#print join "\n", (Tkx::SplitList(Tkx::set('auto_path'))), "\n"; 
#my $i = Tcl->new; 
#$i->Init; 
#print $i->call('info','patchlevel') ."\n";

# Create main window
my $mw = Tkx::widget->new(".");
$mw->configure(-menu => mk_menu($mw));
Tkx::wm("title", $mw, "test");

# Create PanedWindow (tree on the left, content on the right part)
my $pw = $mw->new_ttk__panedwindow(
     -orient => "horizontal"
);

# Create a useless button, for switching horizontal/vertical split of the 
# PanedWindow (no more working with tkx because orientation is read only)
my $button = $mw->new_ttk__button(
     -text => "h/v",
     -command => sub {$pw->g_pack(-fill => "both", -expand => "yes");
     	Tkx::update(); return;
        $pw->config(
            -orient => ($pw->cget(-orient) eq "horizontal")?"vertical":"horizontal") }
);

## in class # my $tree = $pw->new_treectrl();

my $dirTree=DirExplorerTree->new();
$dirTree->parentWindow($pw);
$dirTree->init();

#my $labx1 = $pw->new_ttk__label( -text => "Bapy", -foreground => "orange" , -background=>"black");

#my $dirTree = Tkx::tk___chooseDirectory(-initialdir => ".");
#my $dirTree = pw->new_tixDirList( -title=>"Test");
my $labx2 = $pw->new_ttk__label( -text => "Mojo", -foreground=> "white" , -background=>"red");
#$pw->add($labx1, -weight  =>2);
#$pw->add($dirTree, -weight  =>2);
$pw->add($dirTree->tree, -weight  =>2);
#$pw->add($labx2, -weight  =>2);
$pw->g_pack(-fill => "both", -expand => "yes");
$button->g_pack( -expand => "no");




#$tree->item("element", "configure", 5, -text  => "hello");
(my $progname = $0) =~ s,.*[\\/],,;
my $IS_AQUA = Tkx::tk_windowingsystem() eq "aqua";



# mk_menu: create a tk menu object and return it for adding it to the main window
sub mk_menu {
    my $mw = shift;
    my $menu = $mw->new_menu;

    my $file = $menu->new_menu(
        -tearoff => 0,
    );
    $menu->add_cascade(
        -label => "File",
        -underline => 0,
        -menu => $file,
    );
    
    $file->add_command(
        -label => "New",
        -underline => 0,
        -accelerator => "Ctrl+N",
        -command => \&new,
    );
    $mw->g_bind("<Control-n>", \&new);
    $file->add_command(
        -label   => "Exit",
        -underline => 1,
        -command => [\&Tkx::destroy, $mw],
    ) unless $IS_AQUA;

    my $help = $menu->new_menu(
        -name => "help",
        -tearoff => 0,
    );
    $menu->add_cascade(
        -label => "Help",
        -underline => 0,
        -menu => $help,
    );
    $help->add_command(
        -label => "\u$progname Manual",
        -command => \&show_manual,
    );

    my $about_menu = $help;
    if ($IS_AQUA) {
        # On Mac OS we want about box to appear in the application
        # menu.  Anything added to a menu with the name "apple" will
        # appear in this menu.
        $about_menu = $menu->new_menu(
            -name => "apple",
        );
        $menu->add_cascade(
            -menu => $about_menu,
        );
    }
    $about_menu->add_command(
        -label => "About \u$progname",
        -command => \&about,
    );

    return $menu;
}


sub changeDirectory {
	
}

# about: create the about box of the program, called from Help->about menu
sub about {
	Tkx::tk___messageBox(
		-parent => $mw,
		-title => "About \u$progname",
		-type => "ok",
		-icon => "info",
		-message => "MDA Gui v0.0a\n" .
		"Copyright 2008 vRobin. " .
		"All lefts preserved.\n". "http://www.ratp.fr"
	);
}
    
Tkx::MainLoop();
