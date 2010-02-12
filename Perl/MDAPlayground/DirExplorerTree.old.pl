#!/usr/bin/perl -w
package MDA::GUI::ExplorerTree;

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