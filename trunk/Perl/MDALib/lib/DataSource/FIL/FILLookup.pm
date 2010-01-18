#!/usr/bin/perl -w

package DataSource::FIL::FILLookup;
use base qw( DataFile::LookupData );

use DataSource::FIL::FILReader;

use strict;
use utf8;
use version; our $VERSION = qw('0.1.0);


our $DataSourceName = $DataSource::FIL::FILReader::DataSourceName;
our $DataSourceVer = '0.1';
our $providerName = $DataSource::FIL::FILReader::providerName;
our $providerUrl = $DataSource::FIL::FILReader::providerUrl;
our $readerClass = 'DataSource::FIL::FILReader';

our $supportedLookupItems = [
	{ # cue is a "directory" only DataSource
	  # mdaFileDirectory name items will be mapped to current directory in GUI
				   type => 'retrieval',
		targetElement => 'album',
		  displayName => 'Album directory',
				   name => 'mdaFileDirectory'  
	},
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
