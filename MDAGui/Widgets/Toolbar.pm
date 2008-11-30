#!/usr/bin/perl -w
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$

package Widgets::Toolbar;

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


our $toolbarFrame = {};
our $toolbarFrameW;

sub new {
	my $class = shift;
	my $self = {
		widget => undef,
		parentWindow => undef
	};
	bless( $self, $class );
	return $self;
}

# Create the content of the toolbarFrame
sub init {
	my $self = shift;
	
	# Creation of the main frame called "<lc_sourceName>Tab" (ex: .p.n.amgTab )
	$self->widget( $self->parentWindow()->new_ttk__frame(-name => 'toolbar'));

	# object contains for each type of picto, the path of the picto
	my @toolbarPictos = (
           { name => 'save',    path => "graphics/page_save.png" },
           { name => 'add',     path => "graphics/page_add.png" },
           { name => 'separator' },
           { name => 'refresh', path => "graphics/page_refresh.png" },
           { name =>  'music',  path => "graphics/music.png" },
	);
	

	Tkx::ttk__style('configure', 'Toolbar.Toolbutton', -padding=>2); 
	
	# for each of these picto, create a tkImage reference, a grayed version of the image and construct
	foreach my $picto(@toolbarPictos) {
#		print("$picto", "=> ", $pictos{$picto}{path},"\n");

		if($picto->{name} eq 'separator') {
			$self->widget()->new_ttk__separator( -orient => 'vertical')->g_pack(-side => 'left', -fill => 'y', -pady => 3);
			next;
		}
		
		$self->{$picto->{name}.'Image'} = Tkx::image("create", "photo", -file => $picto->{path});
		my $grayedImage = Tkx::i::call($self->{$picto->{name}.'Image'} , 'data', '-grayscale', -format => 'png');
		$self->{$picto->{name}.'GrayedImage'} = Tkx::image("create", "photo", -format => 'png', -data => $grayedImage );

		$self->{$picto->{name}.'ButtonW'} = $self->widget()->new_ttk__button(
			-image => [ $self->{$picto->{name}.'Image'}, 
						'disabled', $self->{$picto->{name}.'GrayedImage'}, 
						'active', $self->{$picto->{name}.'GrayedImage'} ], 
			-style => 'Toolbar.Toolbutton', 
			-command => sub {print($picto->{name}."\n");}
		);
		$self->{$picto->{name}.'ButtonW'}->g_pack(-side => 'left');	
	}
	
#die (Tkx::ttk__style('element', 'options', 'Toolbutton.label'));
# Code to dump element/option values
#	foreach my $element ( ('Button.border','Button.padding', 'Button.label') ) {
#		foreach my $option ( split( / /, Tkx::ttk__style('element', 'options', $element) ) ) {
#			print($element." ".$option.' '.Tkx::ttk__style('lookup', 'Button', $option)."\n");
#			
#		}
#	}
#	Tkx::ttk__style('configure', 'Toolbar.Toolbutton', -padding=>2, -stipple=> 'gray25', -relief => 'flat');
#
# Fun with buttons!
#	Tkx::ttk__style('configure', 'Toolbar.Toolbutton', -padding=>2, -stipple=> 'gray25', 
#					 
#	);
#	Tkx::ttk__style('map', 'Toolbar.Toolbutton', 
#		#-background => ['!disabled !active', 'yellow', 'active', 'black'],
#		-relief => [ 'pressed', 'raised', 'active', 'groove']
#	);
#
#die Tkx::ttk__style('lookup', 'Toolbutton', '-font');
#	$self->{refreshButtonW} = $self->widget()->new_ttk__button(
#		-image => [ $self->{'refreshImage'}, 
#					'disabled', $self->{'refreshGrayedImage'}, 
#					'active', $self->{'refreshGrayedImage'} ], 
#		-style => 'Toolbar.Toolbutton', 
#		-command => sub {submitForm();}
#	);
#	#die;
#	$self->{saveButtonW} = $self->widget()->new_ttk__button(
#		-state => 'disabled', 
#		-image => $self->{'saveImage'}, 
#		-style => 'Toolbar.Toolbutton', 
#		-command => sub {submitForm();}
#	);

	# Configure main tab frame row/column expansion for show/hide of subframes
#	Tkx::grid("columnconfigure", $self->widget(), 0, -weight => 1);
#	Tkx::grid("rowconfigure", $self->widget(), 1, -weight => 1);
	$self->{widget}->g_pack(-anchor => 'nw', -expand => 'false', -fill=>'x');

}

sub widget {
	my $self = shift;	# XXX: ignore calling class/object
	$self->{widget} = shift if @_;
	return $self->{widget};
}

sub parentWindow {
	my $self = shift;	# XXX: ignore calling class/object
	$self->{parentWindow} = shift if @_;
	return $self->{parentWindow};
}

1;