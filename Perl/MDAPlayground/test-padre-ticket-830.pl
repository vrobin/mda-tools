use strict;

use Getopt::Long;

my $man = 0;
my $help = 0;
my $exporterName;
my $albumDir; 

GetOptions(				'help|?' => \$help, 
					'man' => \$man,
					'album-dir|d=s' => \$albumDir,
					'data-exporter|de=s' => \$exporterName
					) azeazeafdf; 
