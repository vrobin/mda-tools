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
use Module::Find;
use DataSourcesNotebook;

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

# Set widget theme used
use DataSource::AKM::AKMLookup;
my $lookup = DataSource::AKM::AKMLookup->new();
#die Dumper($lookup->retrievalParamsByCriteriasAndValuesHashRef( {target => 'album', type => 'Url'} ));

# Print the list of available themes: 
# xpnative clam alt classic default winnative
#print Tkx::ttk__themes()."\n";
#print Tkx::i::call("ttk::themes")."\n";
#print Tkx::i::call("ttk::style", "theme", "names")."\n";
#print Tkx::ttk__style_theme_names()."\n";
#print Tkx::ttk__style("theme", "names")."\n";
#print Tkx::ttk__style_theme("names")."\n";
print Tkx::i::call("ttk::style", ("theme", "names"))."\n";

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
my $panedWindow = $mw->new_ttk__panedwindow(
     -orient => "horizontal"
);

# Create a useless button, for switching horizontal/vertical split of the 
# PanedWindow (no more working with tkx because orientation is read only)
my $button = $mw->new_ttk__button(
     -text => "h/v",
     -command => sub {$panedWindow->g_pack(-fill => "both", -expand => "yes");
     	Tkx::update(); return;
        $panedWindow->config(
            -orient => ($panedWindow->cget(-orient) eq "horizontal")?"vertical":"horizontal") }
);

## in class # my $tree = $panedWindow->new_treectrl();
$Tkx::TRACE='true';
#die Tkx::i::call("info", 'library');
my $dirTree=DirExplorerTree->new();
$dirTree->parentWindow($panedWindow);
$dirTree->init();


my $labx2 = $panedWindow->new_ttk__label( -text => "Mojo", -foreground=> "white" , -background=>"red");


# TODO: find the best way to deal with this method (maybe put it in Tools)
sub findMDAReaderModules{
	my @MDAReaderModules;
	foreach my $myModule(findallmod DataSource) {
		if($myModule =~ /.*Reader/ ) {
			eval("use $myModule");
			push @MDAReaderModules, $myModule->new();
		}
	}
	return @MDAReaderModules;
}

my @MDAReaderModules = findMDAReaderModules();

my $dsNotebook = DataSourcesNotebook->new();
$dsNotebook->parentWindow( $panedWindow );
$dsNotebook->sources(\@MDAReaderModules);
$dsNotebook->init();
# TODO: clean this call, transform this method in specific object
#createRightNotebookTabs($rightNotebookWindow, @MDAReaderModules);
#createRightNotebookTabsGridForget($rightNotebookWindow, @MDAReaderModules);
$panedWindow->add($dirTree->tree, -weight => 2);
$panedWindow->add($dsNotebook->widget, -weight => 4);
# $panedWindow->add($rightLabelFrame, -weight => 4);
$panedWindow->g_pack(-fill => "both", -expand => "yes");
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

sub createRightNotebook {
	
}
sub createRightNotebookTabsGridForget {
	my %mdaSourcePanel;
#	my @providers = ('cue', 'media_files', 'allmusic', 'amazon', 'arkivMusic','discogs');
	my $notebook = shift;
	my @providers = @_;
	$mdaSourcePanel{noMetaData}{rootFrameW} = $notebook->new_ttk__frame(-name => 'noMetaData');
	$mdaSourcePanel{noMetaData}{rootFrameW}->g_pack();
	$mdaSourcePanel{noMetaData}{rootFrame}{noMetaDataLabelW} = $mdaSourcePanel{noMetaData}{rootFrameW}->new_ttk__label(  -text => 'No metadata found in this folder.');
	$mdaSourcePanel{noMetaData}{rootFrame}{noMetaDataLabelW}->g_pack(-anchor => 'center', -expand => 'true');
	$notebook->m_add($mdaSourcePanel{noMetaData}{rootFrameW}, -text => '...', -state => 'normal');
	
	print "class XXX: ", Tkx::winfo("class", ".p.n"), "\n";
	print "layout YYY: ", Tkx::style("layout", "TButton"), "\n";
	print("ZZZ:", Tkx::style("lookup", "TNotebook", ""), "\n");
#	$notebook->m_add($notebook->new_ttk__frame(-name => 'default'), -text => 'default', -state => 'hidden');
#	die Dumper($notebook->new_ttk__frame());
		Tkx::ttk__style('configure', 'Yellow.TFrame',	-background => 'yellow', -foreground => 'black', -relief => 'flat');
		Tkx::ttk__style('configure', 'Blue.TFrame',	-background => 'blue', -foreground => 'black', -relief => 'raised');
		Tkx::ttk__style('configure', 'Black.TLabel',	-background => 'black', -foreground => 'green', -relief => 'sunken');

	foreach my $providerDataSource (@providers) {
		my $provider = $providerDataSource->providerName();
		my $providerTabName = lc($providerDataSource->name()).'Tab';
		$mdaSourcePanel{$provider}{rootFrameW} = $notebook->new_ttk__frame(-name => $providerTabName);
		$notebook->m_add($mdaSourcePanel{$provider}{rootFrameW}, -text => $provider, -state => 'normal');
		$mdaSourcePanel{$provider}{rootFrame}{gridFrame} = {};
		my $providerPages = $mdaSourcePanel{$provider}{rootFrame}{gridFrame};
		my $providerRootFrame = $mdaSourcePanel{$provider}{rootFrame};
		my $providerRootFrameW = $mdaSourcePanel{$provider}{rootFrameW};

		#die Dumper $providerPages;
		$mdaSourcePanel{$provider}{rootFrame}{gridFrameW} = $providerRootFrameW->new_ttk__frame(-style => 'Blue.TFrame');
		my $gridFrameW = $mdaSourcePanel{$provider}{rootFrame}{gridFrameW};
		
#		$gridFrameW->configure(-background => '#0000FF', -width => 200, -height => 200);
#		$gridFrameW->configure(-width => 200, -height => 200);
#		$gridFrameW->add("lookup");
		$providerPages->{lookupFrameW}=$providerRootFrameW->new_ttk__frame();
#		$gridFrameW->add("result");
		$providerPages->{resultFrameW}=$providerRootFrameW->new_ttk__frame();
#		$gridFrameW->add("input");
		$providerPages->{inputFrameW}=$providerRootFrameW->new_ttk__frame();
#		$gridFrameW->add("retrieved");
		$providerPages->{retrievedFrameW}=$providerRootFrameW->new_ttk__frame(-style => 'Yellow.TFrame');
#		die Tkx::ttk__style('layout', 'TFrame');
#		die $providerPages->{retrievedFrameW}->cget('-style');
# Retrieve class name (and default style)

		print "class: ", Tkx::winfo("class", $providerPages->{retrievedFrameW}), "\n";
		print "layout tframe: ",Tkx::style("layout", 'TFrame'), "\n";
		print "layout tutu.tframe: ",Tkx::style("layout", 'Tutu.TFrame'), "\n";
		print Tkx::style("element", 'options', 'TFrame');
		
		$providerPages->{retrievedFrame}{myLabel} = $providerPages->{retrievedFrameW}->new_ttk__label(-style =>'Black.TLabel', -text => 'retrieved frame label');
		$providerPages->{retrievedFrame}{myLabel}->g_pack(-anchor => 'sw');
#		$providerPages->{inputFrameW}->configure(-background => "#ff0000");
		$providerPages->{inputFrame}{myLabel} = $providerPages->{inputFrameW}->new_ttk__label( -text => 'input frame label');
		$providerPages->{inputFrame}{myLabel}->g_pack(-anchor => 'nw', -padx => 5, -pady => 2);
		my $bouton = $providerRootFrameW->new_ttk__button(-text => "Input", 
				-command => sub { 
								Tkx::grid("remove", $providerPages->{retrievedFrameW});
								$providerPages->{inputFrameW}->g_grid(-columnspan => 2, -row=>0, -column=>0,  -sticky => 'nesw'); 
							}
				);
		my $bouton2 = $providerRootFrameW->new_ttk__button(-text => "Retrieved", 
				-command => sub { 
								Tkx::grid("remove", $providerPages->{inputFrameW});
								$providerPages->{retrievedFrameW}->g_grid(-columnspan => 2, -row=>0, -column=>0,  -sticky => 'nesw'); 
							}
				);
		#$providerPagesW->compute___size();
Tkx::grid("columnconfigure", $providerRootFrameW, 0, -weight => 1);
Tkx::grid("columnconfigure", $providerRootFrameW, 1, -weight => 1);
Tkx::grid("rowconfigure", $providerRootFrameW, 0, -weight => 1);
#Tkx::grid("columnconfigure", $gridFrameW, 1, -weight => 1);
#Tkx::grid("rowconfigure", $providerRootFrameW, 1, -weight => 1);
		$providerPages->{retrievedFrameW}->g_grid(-columnspan => 2, -sticky => 'nsew');
#		Tkx::grid("remove", $providerPages->{retrievedFrameW});
#		$providerPages->{inputFrameW}->g_grid(  -sticky => 'nesw');
#		Tkx::grid("remove", $providerPages->{inputFrameW});
#		$providerPages->{retrievedFrameW}->g_grid(-sticky => 'nsew');
		$bouton->g_grid(-row=>1, -column=>0);
		$bouton2->g_grid(-row=>1, -column=>1);
#		$providerPages->{retrievedFrameW}->g_grid($providerPages->{inputFrameW}, -sticky => 'nesw', -in => $gridFrameW);
#$providerRootFrameW->g_pack(-fill => 'both', -expand => 'true');

#		$gridFrameW->g_grid(-row=>0, -column=>0, -sticky => 'nsew', -ipadx=>50, -padx=>50);
#		$gridFrameW->g_pack(-fill => 'both', -expand => 'true' );
#		die $gridFrameW->g_pack('info');
		#$gridFrameW->{inputFrameW}->g_grid(-anchor => 'nw',  -fill => 'both', -expand => 'true');
#		$providerPagesW->g_pack(-anchor => 'nw',  -fill => 'both', -expand => 'true');
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





###############################
### Junk code graveyard #######
###############################
#my $labx1 = $panedWindow->new_ttk__label( -text => "Bapy", -foreground => "orange" , -background=>"black");

#my $dirTree = Tkx::tk___chooseDirectory(-initialdir => ".");
#my $dirTree = pw->new_tixDirList( -title=>"Test");
#$rightNotebookWindow->state('disabled');

#$panedWindow->add($labx2, -weight  =>2);
#$panedWindow->add($dirTree, -weight  =>2);

# my $rightLabelFrame = $panedWindow->new_ttk__labelframe(-text=>'Toto', -name => 'labelFrame1');
# my $rightNotebookWindow = $rightLabelFrame->new_ttk__notebook();
# $rightNotebookWindow->g_pack(-fill => "both", -expand => "yes");
# $rightLabelFrame->g_pack(-fill => "both", -expand => "yes");

#use DataSource::DOG::DOGReader;
#my $toto='DOG';
#die eval '${DataSource::'.${toto}.'::DOGReader::providerName}';
#			my $dataSource = $dataSourceClass->new();
#			$albumFile->addDataSource($dataSource);
#			$albumFile->dataSource($dsName)->retrieve();

#use DataSource::AKM::AKMReader;

#Tkx::package("require", "tile");
#Tkx::package("require", "Tktable");
#Tkx::package("require", "BWidget");
#Tkx::package("require", "snit");
#Tkx::package("require", "tooltip");
#print join "\n", (Tkx::SplitList(Tkx::set('auto_path'))), "\n"; 
#my $i = Tcl->new; 
#$i->Init; 
#print $i->call('info','patchlevel') ."\n";