#!/usr/bin/perl -w
package DataFile::Credit;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

sub new {
	my $class  = shift;
	my $credit = {};
	my %params;
	if (@_) {
		%params = %{ shift() };
	}
	
	bless( $credit, $class );
	if (%params) {
		if ( defined( $params{id} ) ) {
			$credit->id( $params{id} );
		}
		if ( defined( $params{name} ) ) {
			$credit->name( $params{name} );
		}
		if ( defined( $params{role} ) ) {
			$credit->role( $params{role} );
		}
		if ( defined( $params{character} ) ) {
			$credit->character( $params{character} );
		}
		if ( defined( $params{roleId} ) ) {
			$credit->roleId( $params{roleId} );
		}
		if ( defined( $params{url} ) ) {
			$credit->url( $params{url} );
		}
		if ( defined( $params{relativeUrl} ) ) {
			$credit->relativeUrl( $params{relativeUrl} );
		}
		if ( defined( $params{baseUrl} ) ) {
			$credit->baseUrl( $params{baseUrl} );
		}
		if ( defined( $params{rawData} ) ) {
			$credit->rawData( $params{rawData} );
		}
	}
	return $credit;
}

sub rawData {
	my $self = shift;
	my $rawData   = shift;
	if ($rawData) {
# old tweak to force rawData not to be an attribute, but content text
#		$self->{rawData}{forceText} = 'true';
		$self->{rawData}{content} = Tools::trim($rawData) 
	}
	return $self->{rawData}{content};
}

sub roleId {
	my $self = shift;
	my $roleId   = shift;
	if ($roleId) { $self->{roleId} = Tools::trim($roleId) }
	return $self->{roleId};
}

sub character {
	my $self = shift;
	my $character   = shift;
	if ($character) { $self->{character} = Tools::trim($character) }
	return $self->{character};
}

sub role {
	my $self = shift;
	my $role   = shift;
	if ($role) { $self->{role} = Tools::trim($role) }
	return $self->{role};
}

sub name {
	my $self = shift;
	my $name   = shift;
	if ($name) { $self->{name} = Tools::trim($name) }
	return $self->{name};
}

sub url {
	my $self = shift;
	
	my $url   = shift;
	if ($url) { $self->{url} = Tools::trim($url) }
	return $self->{url};
}

sub alias  {
	my $self = shift;
	my $alias = shift;
	
	# if no performances array ref is sent
	if(!defined($alias)) {
		# if no performances array exists
		if(ref($self->{alias}) ne 'ARRAY') {
			#create it
			$self->{alias}=[];
			#WARN 'Initializing alias date array'
		} # returning existing or initialized
		return ($self->{alias});
	}

	if($#$alias == -1) {
		#WARN "called credit->alias with an empty array, truncating!";
	}

	$self->{alias} = $alias;
}

sub addAlias{
	my $self = shift  or return(undef);
	my $alias = shift or return(undef);
	push(@{$self->alias()}, Tools::trim($alias));
}

sub deserialize{
	my $self = shift or return undef;
#	die Dumper($self);
	if(exists($self->{alias})  ) {
		unless(ref($self->{alias}) eq 'ARRAY') {
			my $alias=$self->{alias};
			push @{$self->{alias}=[]}, $alias;
		}
	}
	#Tools::blessObject('DataFile::Date', $self->{activeDates});
}

sub baseUrl {
	my $self = shift;
	
	my $baseUrl   = shift;
	if ($baseUrl) { $self->{baseUrl} = Tools::trim($baseUrl) }
	return $self->{baseUrl};
}

sub relativeUrl {
	my $self = shift;

	my $relativeUrl   = shift;
	if ($relativeUrl) { $self->{relativeUrl} = Tools::trim($relativeUrl) }
	return $self->{relativeUrl};
}

sub id {
	my $self = shift;
	my $id   = shift;
	if ($id) { $self->{id} = Tools::trim($id) }
	return $self->{id};
}


# forgotten cut and paste ?
#sub work {
#	my $self = shift;
#	if (@_) { $self = shift; }
#	return $self;
#}

END { }    # module clean-up code here (global destructor)
1;
