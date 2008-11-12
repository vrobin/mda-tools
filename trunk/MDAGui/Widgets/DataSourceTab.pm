#!/usr/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

package Widgets::DataSourceTab;
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

sub showSubFrame {
	my $self = shift;
	my $frameToShowName =  shift;
	# name of the hash key is <frameName>FrameW where 'W' stands for Widget
	#print(Tkx::grid('info', $self->{retrievedFrameW}), "\n");
	foreach my $subFrameName ( @{$self->{subFramesNames}} ) {
		if(Tkx::grid('info', $self->subFrame($subFrameName)) ) {
#			print $subFrameName, "\n";
			Tkx::grid('remove', $self->subFrame($subFrameName));
		}
	}
#	print($frameName, "\n");
#	return;
#	my $frameHashKey =  shift().'FrameW';
#	Tkx::grid("remove", $self->{$frameHashKey});
	$self->subFrame($frameToShowName)->g_grid(-columnspan => 2, -row=>1, -column=>0,  -sticky => 'nesw'); 
}


# subFrame (frame widget) accessor
# input: the frameName (retrieved, input, etc.)
sub subFrame {
	my $self = shift;
	my $frameName =  shift;
	# name of the hash key is <frameName>FrameW where 'W' stands for Widget
	my $frameHashKey =  lc($frameName).'FrameW';
	return $self->{$frameHashKey};
}

# Add a new subFrame inside the main tab frame
sub addSubFrame {
	my $self = shift;
	my $frameName =  shift;

	# name of the hash key is <frameName>FrameW where 'W' stands for Widget
	my $frameHashKey =  lc($frameName).'FrameW';
	$self->{$frameHashKey}=$self->widget()->new_ttk__frame();
	
	return $self->{$frameHashKey};
}

# subFrameContent (hashref containing widgets) accessor,
# input: the frameName (retrieved, input, etc.)
sub subFrameContent {
	my $self = shift;
	my $frameName =  shift;
	# name of the hash key is <frameName>Frame
	my $frameContentHashKey = lc($frameName).'Frame';
	#$frameContentHashKey =~ s/ / /g;
	if(not exists($self->{$frameContentHashKey})) {
		$self->{$frameContentHashKey} = {};
	}
	return $self->{$frameContentHashKey};
}

# Create all elements of the radio panel inside the frame + the separator
sub createRadioPanel {
	my $self = shift;

	$self->{radioButtonValue} = '';
	Tkx::ttk__style('configure', 'Blue.TFrame',	-background => 'blue', -foreground => 'black', -relief => 'solid');
	$self->{radioButtonFrameW} = $self->widget()->new_ttk__frame(-style => 'Blue.TFrame' );
	
	$self->{radioButtonFrame}{separatorW}=$self->{radioButtonFrameW}->new_ttk__separator( -orient => 'horizontal');
	$self->{radioButtonFrame}{separatorW}->g_pack(-side => 'bottom', -fill => 'x', -expand => 'true' );

	foreach my $subFrameName ( @{$self->{subFramesNames}} ) {
		$self->{radioButtonFrame}{$subFrameName.'radiobuttonW'} = 
					$self->{radioButtonFrameW}->new_ttk__radiobutton( 
							-text => $subFrameName,
							-value => lc($subFrameName),
							-variable =>  \$self->{radioButtonValue},
							-command => sub { $self->showSubFrame($self->{radioButtonValue}), "\n"; }
					);
		$self->{radioButtonFrame}{$subFrameName.'radiobuttonW'}->g_pack(-side => 'left' );
	}

	return $self->{radioButtonFrameW};
}

#	$self->{resultFrameW}=$self->widget()->new_ttk__frame();
#	$self->{inputFrameW}=$self->widget()->new_ttk__frame();
#	$self->{retrievedFrameW}=$self->widget()->new_ttk__frame(-style => 'Yellow.TFrame');
#	die Dumper(\$self);


# Create the content of a DataSource Tab
sub init {
	my $self = shift;
	my $tabName = $self->source()->providerName();
	my $tabId = lc($self->source()->name()).'Tab';
	
	# Creation of the main frame called "<lc_sourceName>Tab" (ex: .p.n.amgTab )
	$self->widget( $self->parentWindow()->new_ttk__frame(-name => $tabId));
	$self->parentWindow()->m_add($self->widget(), -text => $tabName, -state => 'normal');
	
#	$self->{actions} = {
#		setSearchParams  =>  { name => 'Search', method=>'', paramList=>'' },
#		viewSearchResults  =>  {name => 'Results', method=>'', paramList=>''},
#		setRetrieveParams =>  {name => 'Force', method=>'', paramList=>''},
#		viewRetrieveParams =>  {name => '', method=>'', paramList=>''}
#	};

	# create sub frames
	$self->{subFramesNames} = ['Lookup', 'Result', 'Retrieval Input', 'Retrieved'];
	foreach my $subFrameName ( @{$self->{subFramesNames}} ) {
		$self->addSubFrame($subFrameName);
	}

	# create labels on two frames
	$self->subFrameContent('retrieved')->{myLabel} = $self->subFrame('retrieved')->new_ttk__label(-style =>'Black.TLabel', -text => 'retrieved frame label');
	$self->subFrameContent('retrieved')->{myLabel}->g_pack(-anchor => 'sw');
	
#	$self->subFrameContent('Retrieval Input')->{myLabel} = $self->subFrame('Retrieval Input')->new_ttk__label( -text => 'input frame label');
#	$self->subFrameContent('Retrieval Input')->{myLabel}->g_pack(-anchor => 'nw', -padx => 5, -pady => 2);
	$self->createInputSubFrameContent('Retrieval Input');

	# Radio buttons and separator with the enclosing frame
	$self->createRadioPanel();
	
	# Configure main tab frame row/column expansion for show/hide of subframes
	Tkx::grid("columnconfigure", $self->widget(), 0, -weight => 1);
	Tkx::grid("rowconfigure", $self->widget(), 1, -weight => 1);

	$self->{radioButtonFrameW}->g_grid(-row=>0, -column=>0,  -sticky => 'nesw');
	$self->{retrievedFrameW}->g_grid(-columnspan => 2, -row=>1, -column=>0,  -sticky => 'nesw');

}

# Create the content of the input subFrame
# input: the name of the subFrame
sub createInputSubFrameContent {
	my $self = shift;
	my $frameName = shift;
	
	# the subFrame widget
	my $widget = $self->subFrame('Retrieval Input');
	 
	# the widget content HashRef
	my $content = $self->subFrameContent('Retrieval Input');
	
	my $retrievalItems = $self->source->getSupportedLookupItemsByCriteriasAndValuesHashRef( { type => 'retrieval', targetElement => 'album',});
	foreach my $item (@{$retrievalItems}) {
		$content->{$item->{name}.'LabelW'} = $widget->new_ttk__label( -text => $item->{displayName}.':');
		$content->{$item->{name}.'LabelW'}->g_pack(-anchor => 'nw', -padx => 0, -pady => 0);
		$content->{$item->{name}.'EntryW'} = $widget->new_ttk__entry( -textvariable => \$content->{$item->{name}.'Value'});
		$content->{$item->{name}.'EntryW'}->g_pack(-anchor => 'nw', -padx => 0, -pady => 0, -fill => 'x');
	} 
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


#	Tkx::grid("columnconfigure", $self->widget(), 1, -weight => 1);
#	my $bouton = $self->widget()->new_ttk__button(-text => "Input", 
#			-command => sub { 
#							Tkx::grid("remove", $self->{retrievedFrameW});
#							$self->{inputFrameW}->g_grid(-columnspan => 2, -row=>1, -column=>0,  -sticky => 'nesw'); 
#						}
#			);
#	my $bouton2 = $self->widget()->new_ttk__button(-text => "Retrieved", 
#			-command => sub { 
#							Tkx::grid("remove", $self->{inputFrameW});
#							$self->{retrievedFrameW}->g_grid(-columnspan => 2, -row=>1, -column=>0,  -sticky => 'nesw'); 
#						}
#			);
#	$radio1->g_grid(-row=>0, -column=>2);
#	$radio2->g_grid(-row=>0, -column=>3);
#	$radio3->g_grid(-row=>0, -column=>4);
#	$bouton->g_grid(-row=>0, -column=>0);
#	$bouton2->g_grid(-row=>0, -column=>1);
#
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