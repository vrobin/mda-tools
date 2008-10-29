#!/usr/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

package DataSourceTab;
#package MDA::GUI::DirExplorerTree;

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);

use Carp;
use English;
use utf8;
use Data::Dumper;

use Tkx;
use Log::Log4perl qw(:easy);

my $windows = 0;
if ($OSNAME =~ /^m?s?win/xmi) {
	$windows = 1;
	use Win32API::File; 
}

sub new {
	my $class = shift;
	my $self = {
		widget => undef,
		parentWindow => undef
	};
	bless( $self, $class );
	return $self;
}

sub init {
	my $self = shift;
	my $tabName = $self->source()->providerName();
	my $tabId = lc($self->source()->name()).'Tab';
	$self->widget( $self->parentWindow()->new_ttk__frame(-name => $tabId));
	$self->parentWindow()->m_add($self->widget(), -text => $tabName, -state => 'normal');
	
	# sub frames
	$self->{lookupFrameW}=$self->widget()->new_ttk__frame();
	$self->{resultFrameW}=$self->widget()->new_ttk__frame();
	$self->{inputFrameW}=$self->widget()->new_ttk__frame();
	$self->{retrievedFrameW}=$self->widget()->new_ttk__frame(-style => 'Yellow.TFrame');

	# labels on two frames
	$self->{retrievedFrame}{myLabel} = $self->{retrievedFrameW}->new_ttk__label(-style =>'Black.TLabel', -text => 'retrieved frame label');
	$self->{retrievedFrame}{myLabel}->g_pack(-anchor => 'sw');
	$self->{inputFrame}{myLabel} = $self->{inputFrameW}->new_ttk__label( -text => 'input frame label');
	$self->{inputFrame}{myLabel}->g_pack(-anchor => 'nw', -padx => 5, -pady => 2);

	# two buttons to switch frames
	my $bouton = $self->widget()->new_ttk__button(-text => "Input", 
			-command => sub { 
							Tkx::grid("remove", $self->{retrievedFrameW});
							$self->{inputFrameW}->g_grid(-columnspan => 2, -row=>0, -column=>0,  -sticky => 'nesw'); 
						}
			);
	my $bouton2 = $self->widget()->new_ttk__button(-text => "Retrieved", 
			-command => sub { 
							Tkx::grid("remove", $self->{inputFrameW});
							$self->{retrievedFrameW}->g_grid(-columnspan => 2, -row=>0, -column=>0,  -sticky => 'nesw'); 
						}
			);

	Tkx::grid("columnconfigure", $self->widget(), 0, -weight => 1);
	Tkx::grid("columnconfigure", $self->widget(), 1, -weight => 1);
	Tkx::grid("rowconfigure", $self->widget(), 0, -weight => 1);

	$self->{retrievedFrameW}->g_grid(-columnspan => 2, -sticky => 'nsew');
	$bouton->g_grid(-row=>1, -column=>0);
	$bouton2->g_grid(-row=>1, -column=>1);

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

sub source {
	my $self = shift;	# XXX: ignore calling class/object
	$self->{source} = shift if @_;
	return $self->{source};
}

# Old version of the tab with multi frame handled by BWidget::PagesManager
#sub createRightNotebookTabs {
#	my %mdaSourcePanel;
##	my @providers = ('cue', 'media_files', 'allmusic', 'amazon', 'arkivMusic','discogs');
#	my $notebook = shift;
#	my @providers = @_;
#	$mdaSourcePanel{noMetaData}{rootFrameW} = $notebook->new_ttk__frame(-name => 'noMetaData');
#	$mdaSourcePanel{noMetaData}{rootFrameW}->g_pack();
#	$mdaSourcePanel{noMetaData}{rootFrame}{noMetaDataLabelW} = $mdaSourcePanel{noMetaData}{rootFrameW}->new_ttk__label( -text => 'No metadata found in this folder.');
#	$mdaSourcePanel{noMetaData}{rootFrame}{noMetaDataLabelW}->g_pack(-anchor => 'center', -expand => 'true');
#	$notebook->m_add($mdaSourcePanel{noMetaData}{rootFrameW}, -text => '...', -state => 'normal');
##	$notebook->m_add($notebook->new_ttk__frame(-name => 'default'), -text => 'default', -state => 'hidden');
##	die Dumper($notebook->new_ttk__frame());
#	foreach my $providerDataSource (@providers) {
#		my $provider = $providerDataSource->name();
#		$mdaSourcePanel{$provider}{rootFrameW} = $notebook->new_ttk__frame(-name => '_'.$provider);
#		$notebook->m_add($mdaSourcePanel{$provider}{rootFrameW}, -text => $provider, -state => 'normal');
#		$mdaSourcePanel{$provider}{rootFrame}{PagesManager} = {};
#		my $providerPages = $mdaSourcePanel{$provider}{rootFrame}{PagesManager};
#		my $providerRootFrame = $mdaSourcePanel{$provider}{rootFrame};
#		my $providerRootFrameW = $mdaSourcePanel{$provider}{rootFrameW};
#		#die Dumper $providerPages;
#		$mdaSourcePanel{$provider}{rootFrame}{PagesManagerW} = $providerRootFrameW->new_PagesManager();
#		my $providerPagesW = $mdaSourcePanel{$provider}{rootFrame}{PagesManagerW};
#		$providerPagesW->configure(-background => '#0000FF', -width => 200, -height => 200);
#		$providerPagesW->add("lookup");
#		$providerPages->{lookupFrameW}=Tkx::widget->new($providerPagesW->getframe("lookup"));
#		$providerPagesW->add("result");
#		$providerPages->{resultFrameW}=Tkx::widget->new($providerPagesW->getframe("result"));
#		$providerPagesW->add("input");
#		$providerPages->{inputFrameW}=Tkx::widget->new($providerPagesW->getframe("input"));
#		$providerPagesW->add("retrieved");
#		$providerPages->{retrievedFrameW}=Tkx::widget->new($providerPagesW->getframe("retrieved"));
#
#		$providerPagesW->raise("input");
#		$providerPages->{retrievedFrameW}->configure(-background => "#00ff00");
#		$providerPages->{retrievedFrame}{myLabel} = $providerPages->{retrievedFrameW}->new_ttk__label( -text => 'retrieved frame label');
#		$providerPages->{retrievedFrame}{myLabel}->g_pack(-anchor => 'sw');
#		$providerPages->{inputFrameW}->configure(-background => "#ff0000");
#		$providerPages->{inputFrame}{myLabel} = $providerPages->{inputFrameW}->new_ttk__label( -text => 'input frame label');
#		$providerPages->{inputFrame}{myLabel}->g_pack(-anchor => 'nw', -padx => 5, -pady => 2);
#
#		$providerPagesW->raise("retrieved");
#		#$providerPagesW->compute___size();
#		$providerPagesW->g_pack(-anchor => 'nw',  -fill => 'both', -expand => 'true');
#		$providerPagesW->raise("input");
#		$providerPagesW->g_pack(-anchor => 'nw',  -fill => 'both', -expand => 'true');
##		$providerPages->{inputFrameW}->g_pack();
##		$providerPages->{retrievedFrameW}->g_pack();
#		
##		my $providerRootFrame = $mdaSourcePanel{$provider}{rootFrame};
##		my $providerRootFrameW = $mdaSourcePanel{$provider}{rootFrameW};
##		my $providerPagesW =$providerRootFrame->{PagesManagerW};
##		my $providerPages =$providerRootFrame->{PagesManager};
##		$providerPagesW = $providerRootFrameW->new_PagesManager();
##		$providerPagesW->add("lookup");
##		$providerPages->{lookupFrameW}=Tkx::widget->new($providerPagesW->getframe("lookup"));
##		$providerPagesW->add("result");
##		$providerPages->{resultFrameW}=Tkx::widget->new($providerPagesW->getframe("result"));
##		$providerPagesW->add("input");
##		$providerPages->{inputFrameW}=Tkx::widget->new($providerPagesW->getframe("input"));
##		$providerPagesW->add("retrieved");
##		$providerPages->{retrievedFrameW}=Tkx::widget->new($providerPagesW->getframe("retrieved"));
#	}
##	die Dumper \%mdaSourcePanel;
#}


1;