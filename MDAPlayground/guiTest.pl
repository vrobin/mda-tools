#!/usr/local/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);
use Tkx;
#use Tk::DirSelect;
use Log::Log4perl qw(:easy);
use DirExplorerTree;
use Data::Dumper;


Tkx::package("require", "treectrl");
Tkx::package("require", "tile");
Tkx::package("require", "BWidget");
Tkx::package("require", "img::png");
Tkx::ttk__setTheme("winnative");


binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $conf = q(
        log4perl.logger                    = DEBUG, ScreenApp
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
#print Tkx::ttk__themes()."\n";
#print Tkx::i::call("ttk::themes")."\n";
#print Tkx::i::call("ttk::style", "theme", "names")."\n";
#print Tkx::ttk__style_theme_names()."\n";
#print Tkx::ttk__style("theme", "names")."\n";
#print Tkx::ttk__style_theme("names")."\n";
print Tkx::i::call("ttk::style", ("theme", "names"))."\n";

#print join "\n", (Tkx::SplitList(Tkx::set('auto_path'))), "\n"; 
#my $i = Tcl->new; 
#$i->Init; 
#print $i->call('info','patchlevel') ."\n";

# Create main window
my $mw = Tkx::widget->new(q{.});
$mw->m_configure(-menu => mk_menu($mw));

# invoke "wm title" method with "$mw" widget, wm is WindowManager interface of tcl
# see http://www.tcl.tk/man/tcl8.5/TkCmd/wm.htm#M49
$mw->g_wm_title("MDA Gui");
# This is the same as
#Tkx::wm("title", $mw, "test");
#Tkx::wm_title( $mw, "test");

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
$Tkx::TRACE='true';
#die Tkx::i::call("info", 'library');
my $dirTree=DirExplorerTree->new();
$dirTree->parentWindow($pw);
$dirTree->init();

#my $labx1 = $pw->new_ttk__label( -text => "Bapy", -foreground => "orange" , -background=>"black");

#my $dirTree = Tkx::tk___chooseDirectory(-initialdir => ".");
#my $dirTree = pw->new_tixDirList( -title=>"Test");
my $labx2 = $pw->new_ttk__label( -text => "Mojo", -foreground=> "white" , -background=>"red");

#$rightNotebookWindow->state('disabled');

#$pw->add($labx2, -weight  =>2);
#$pw->add($dirTree, -weight  =>2);

# my $rightLabelFrame = $pw->new_ttk__labelframe(-text=>'Toto', -name => 'labelFrame1');
# my $rightNotebookWindow = $rightLabelFrame->new_ttk__notebook();
# $rightNotebookWindow->g_pack(-fill => "both", -expand => "yes");
# $rightLabelFrame->g_pack(-fill => "both", -expand => "yes");

my $rightNotebookWindow = $pw->new_ttk__notebook();
createRightNotebookTabs($rightNotebookWindow);
$pw->add($dirTree->tree, -weight => 2);
$pw->add($rightNotebookWindow, -weight => 4);
# $pw->add($rightLabelFrame, -weight => 4);
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

sub createRightNotebookTabs {
	my %mdaSourcePanel;
	my @providers = ('cue', 'media_files', 'allmusic', 'amazon', 'arkivMusic','discogs');
	my $notebook = shift;
	$mdaSourcePanel{noMetaData}{rootFrameW} = $notebook->new_ttk__frame(-name => 'noMetaData');
	$mdaSourcePanel{noMetaData}{rootFrameW}->g_pack();
	$mdaSourcePanel{noMetaData}{rootFrame}{noMetaDataLabelW} = $mdaSourcePanel{noMetaData}{rootFrameW}->new_ttk__label( -text => 'No metadata found in this folder.');
	$mdaSourcePanel{noMetaData}{rootFrame}{noMetaDataLabelW}->g_pack(-anchor => 'center', -expand => 'true');
	$notebook->m_add($mdaSourcePanel{noMetaData}{rootFrameW}, -text => '...', -state => 'normal');
#	$notebook->m_add($notebook->new_ttk__frame(-name => 'default'), -text => 'default', -state => 'hidden');
#	die Dumper($notebook->new_ttk__frame());
	foreach my $provider (@providers) {
		$mdaSourcePanel{$provider}{rootFrameW} = $notebook->new_ttk__frame(-name => $provider);
		$notebook->m_add($mdaSourcePanel{$provider}{rootFrameW}, -text => $provider, -state => 'normal');
		$mdaSourcePanel{$provider}{rootFrame}{PagesManager} = {};
		my $providerPages = $mdaSourcePanel{$provider}{rootFrame}{PagesManager};
		my $providerRootFrame = $mdaSourcePanel{$provider}{rootFrame};
		my $providerRootFrameW = $mdaSourcePanel{$provider}{rootFrameW};
		#die Dumper $providerPages;
		$mdaSourcePanel{$provider}{rootFrame}{PagesManagerW} = $providerRootFrameW->new_PagesManager();
		my $providerPagesW = $mdaSourcePanel{$provider}{rootFrame}{PagesManagerW};
		$providerPagesW->configure(-background => '#0000FF', -width => 200, -height => 200);
		$providerPagesW->add("lookup");
		$providerPages->{lookupFrameW}=Tkx::widget->new($providerPagesW->getframe("lookup"));
		$providerPagesW->add("result");
		$providerPages->{resultFrameW}=Tkx::widget->new($providerPagesW->getframe("result"));
		$providerPagesW->add("input");
		$providerPages->{inputFrameW}=Tkx::widget->new($providerPagesW->getframe("input"));
		$providerPagesW->add("retrieved");
		$providerPages->{retrievedFrameW}=Tkx::widget->new($providerPagesW->getframe("retrieved"));

		$providerPagesW->raise("input");
		$providerPages->{retrievedFrameW}->configure(-background => "#00ff00");
		$providerPages->{retrievedFrame}{myLabel} = $providerPages->{retrievedFrameW}->new_ttk__label( -text => 'retrieved frame label');
		$providerPages->{retrievedFrame}{myLabel}->g_pack(-anchor => 'sw');
		$providerPages->{inputFrameW}->configure(-background => "#ff0000");
		$providerPages->{inputFrame}{myLabel} = $providerPages->{inputFrameW}->new_ttk__label( -text => 'input frame label');
		$providerPages->{inputFrame}{myLabel}->g_pack(-anchor => 'nw', -padx => 5, -pady => 2);

		#$providerPagesW->compute___size();
		$providerPagesW->g_pack(-anchor => 'nw',  -fill => 'both', -expand => 'true');
#		$providerPages->{inputFrameW}->g_pack();
#		$providerPages->{retrievedFrameW}->g_pack();
		
#		my $providerRootFrame = $mdaSourcePanel{$provider}{rootFrame};
#		my $providerRootFrameW = $mdaSourcePanel{$provider}{rootFrameW};
#		my $providerPagesW =$providerRootFrame->{PagesManagerW};
#		my $providerPages =$providerRootFrame->{PagesManager};
#		$providerPagesW = $providerRootFrameW->new_PagesManager();
#		$providerPagesW->add("lookup");
#		$providerPages->{lookupFrameW}=Tkx::widget->new($providerPagesW->getframe("lookup"));
#		$providerPagesW->add("result");
#		$providerPages->{resultFrameW}=Tkx::widget->new($providerPagesW->getframe("result"));
#		$providerPagesW->add("input");
#		$providerPages->{inputFrameW}=Tkx::widget->new($providerPagesW->getframe("input"));
#		$providerPagesW->add("retrieved");
#		$providerPages->{retrievedFrameW}=Tkx::widget->new($providerPagesW->getframe("retrieved"));
	}
#	die Dumper \%mdaSourcePanel;
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
