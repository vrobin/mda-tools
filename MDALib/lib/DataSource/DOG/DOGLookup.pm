#!/usr/bin/perl -w

package DataSource::DOG::DOGLookup;
use base qw( DataFile::LookupData );

use DataSource::DOG::DOGReader;

use strict;
use utf8;
use version; our $VERSION = qw('0.1.0);

our $DataSourceName = $DataSource::DOG::DOGReader::DataSourceName;
our $DataSourceVer = '0.1';
our $providerName = $DataSource::DOG::DOGReader::providerName;
our $providerUrl = $DataSource::DOG::DOGReader::providerUrl;

our $supportedLookupItems = [
#	albumId => {
#		type 	=> 'id',
#		target 	=> 'album',
#		name 	=> 'albumSqlId',
#		displayName => 'Album Id'
#	}
	{
		type 	=> 'retrieval',
		targetElement 	=> 'album',
		displayName => 'Album Id',
		name => 'albumId'
	},
	{
		type 	=> 'retrieval',
		targetElement 	=> 'album',
		displayName => 'Album Url',
		name => 'albumUrl'
	}
];

sub new {
	my $class  = shift;
	my $lookupData;
	my $params;
	if (@_) {
		$params = shift();
	}
	
	$params->{name} = $DataSourceName;
	$params->{version} = $DataSourceVer;
	$params->{providerName}= $providerName;
	$params->{providerUrl}= $providerUrl;

	$lookupData = $class->SUPER::new($params);	

	bless( $lookupData, $class );
	
	$lookupData->class( __PACKAGE__ );
		
	if (defined $params) {
#		if ( defined( $params{version} ) ) {
#			$dataSource->version( $params{version} );
#		}
#		if ( defined( $params{name} ) ) {
#			$dataSource->name( $params{name} );
#		}
#		if ( defined( $params{providerName} ) ) {
#			$dataSource->providerName( $params{providerName} );
#		}
##		if ( defined( $params{reader} ) ) {
##			$dataSource->reader( $params{reader} );
##		}
#		if ( defined( $params{providerUrl} ) ) {
#			$dataSource->providerUrl( $params{providerUrl} );
#		}
	}

	return $lookupData;
}




1;