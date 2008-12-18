#!/usr/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

package Widgets::DataSourcesNotebook;
#package MDA::GUI::DirExplorerTree;

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);

use Carp;
use English;
use utf8;
use Data::Dumper;

use Widgets::DataSourceTab;
use Tkx;
use Log::Log4perl qw(:easy);

my $windows = 0;
if ($OSNAME =~ /^m?s?win/xmi) {
	$windows = 1;
	use Win32API::File; 
}

#	Tkx::ttk__style('configure', 'Black.TNotebook',	-background => 'black', -foreground => 'green', -relief => 'sunken');
#	Tkx::ttk__style('configure', 'Black.TFrame',	-background => 'black', -foreground => 'green', -relief => 'sunken');

sub new {
	my $class = shift;
	my $self = {
		widget => undef,
		parentWindow => undef,
		sources => undef
	};
	
	bless( $self, $class );
	return $self;
}

sub init {
	my $self = shift;
	$self->widget($self->{parentWindow}->new_ttk__notebook());
	#$rightNotebookWindow = $rightLabelFrame->new_ttk__notebook();
	Tkx::ttk__style('configure', 'TNotebook' , -tabposition => 'wn', -tabmargins => [2, 2, 0, 2]);
#	Tkx::ttk__style('configure', 'Notebook.Label' , -space=> 40, , -underline => 1); 
#	Tkx::ttk__style('configure', 'Notebook.label' , -space=> 40, , -underline => 1);
#	Tkx::ttk__style('configure', 'TNotebook.label' , -space=> 40, , -underline => 1);
#	Tkx::ttk__style('configure', 'TNotebook' , -space=> 40, , -underline => 1);
#	Tkx::ttk__style('configure', 'Notebook.TLabel' , -space=> 40, , -underline => 1);
#	Tkx::ttk__style('configure', 'Notebook.Tab' , -space=> 40, , -underline => 1);
#	Tkx::ttk__style('configure', 'Notebook.tab' , -space=> 40, , -underline => 1);
#	Tkx::ttk__style('configure', 'TNotebook.tab' , -space=> 40, , -underline => 1);
	Tkx::ttk__style('configure', 'TNotebook.Tab' , -space=> 180, , -underline => 1, -embossed => 1 );
	
	Tkx::ttk__style('configure', 'Blue.TFrame',	-background => 'blue', -foreground => 'black', -relief => 'solid');
	Tkx::ttk__style('configure', 'Blue.TLabel',	-background => 'blue', -foreground => 'yellow', -relief => 'flat');
	$self->{blankTabWidget} = $self->widget()->new_ttk__frame(-name => 'noMetaData', -style => 'Blue.TFrame');
	$self->{blankTab}{labelW} = $self->{blankTabWidget}->new_ttk__label( -text => 'No metadata found in this folder.', -style => 'Blue.TLabel');

	$self->{blankTab}{labelW}->g_pack(-anchor => 'center', -expand => 'true', -padx => 5);
	$self->{blankTabWidget}->g_pack(-fill => "both", -expand => "yes");
	$self->widget()->m_add($self->{blankTabWidget}, -text => '...', -state => 'normal');
	$self->widget()->g_pack(-fill => "both", -expand => "yes");

	foreach my $source (@{$self->sources()}) {
		my $sourceName = $source->providerName();
		my $providerTabId = lc($source->name()).'Tab';
		print $source->name(),"\n";
		my $tab = Widgets::DataSourceTab->new();
		$tab->parentWindow($self->widget());
		$tab->source($source);
		$tab->init();
		push @{$self->{tabs}}, $tab;
	}

# List elements children of notebook (contains tabs)
#	die(Dumper(Tkx::i::call('winfo', 'children', $self->widget())));
# Get tab list in real order
#	die(Dumper($self->widget()->m_tabs()));
}

sub parentWindow {
	my $self = shift;	# XXX: ignore calling class/object
	$self->{parentWindow} = shift if @_;
	return $self->{parentWindow};
}

sub widget {
	my $self = shift;	# XXX: ignore calling class/object
	$self->{widget} = shift if @_;
	return $self->{widget};
} 

sub sources {
	my $self = shift;	# XXX: ignore calling class/object
	$self->{sources} = shift if @_;
	return $self->{sources};
}

1;