#!/usr/bin/perl -w
package DataFile::Date;

use strict;
use utf8;
use Data::Dumper;
use Tools;
use Log::Log4perl qw(:easy);

sub new {
	my $class = shift;
	my $date  = {};
	bless( $date, $class );
	return $date;
}

#sub date {
#        my $self = shift;
#        if (@_) { $self = shift; }
#        return $self;
#}

sub deserialize{
	my $self = shift or return undef;
	if(exists($self->{normalized})  ) {
		unless(ref($self->{normalized}) eq 'ARRAY') {
			my $normalized=$self->{normalized};
			push @{$self->{normalized}=[]}, $normalized;
		}
	}
	#Tools::blessObject('DataFile::Date', $self->{activeDates});
}

sub rawData {
	my $self    = shift;
	my $rawData = shift;
	if ($rawData) { 
# old tweak to force rawData not to be an attribute, but content text
#		$self->{rawData}{forceText} = 'true';
		$self->{rawData}{content} = Tools::trim($rawData) }
	return $self->{rawData}{content};
}

sub normalized  {
	my $self = shift;
	my $normalized = shift;
	# print("QSD! ".ref($performances->[0])."\n"); >> QSD! DataFile::performance
	# print("QSD! ".ref($performances)."\n"); >> QSD! ARRAY
	# print("QSD! ".ref($performances)." - ".$#$performances."\n");
	
	# if no performances array ref is sent
	if(!defined($normalized)) {
		# if no performances array exists
		if(ref($self->{normalized}) ne 'ARRAY') {
			#create it
			$self->{normalized}=[];
			#WARN 'Initializing normalized date array'
		} # returning existing or initialized
		return ($self->{normalized});
	}
# Date debug code
#	print Dumper $self;
	if($#$normalized == -1) {
		#WARN "called album->performances with an empty array, truncating!";
	}
	$self->{normalized} = $normalized;
# Normalized should be an array... this {content} should be a bug...
#	$self->{normalized}{content} = $normalized;
}

sub meanYear {
	my $self = shift;
	my $normalized = shift;
	my $totalYears=0;
	foreach my $normalizedDate (@{$self->normalized}) {
		$totalYears+=substr($normalizedDate->{content}, 0, 4);
	}
	return( ($totalYears==0)?0:($totalYears/scalar(@{$self->normalized})) );
}

sub date {
	my $self = shift;
	my $date = shift;
	if ($date) {
		push( @{ $self->{date} }, Tools::trim($date) );
	}
	return $self->{date};
}



# Store the date(s) analyzed  in the string passed in parameter or if none are passed, the string contained in rawData 
sub normalizeAndSetDate{
	my $self = shift;
	my @normalizedDates=$self->normalizeDate(@_);
	# This undef seems obsolete/inneficient
	undef($self->{date});
	# replaced by this empty array, works nice to prevent normalized data accumulation 
	# when normalizeAndSetDate is called several times
	$self->{normalized}=[];
	foreach (@normalizedDates) { 
#		print "$_ \n";
		$self->addDate($_);
	}
}

sub addDate{
	my $self = shift  or return(undef);
	my $date = shift or return(undef);
	push(@{$self->normalized()}, $date);
}
# Normalize a date in the form 1980 or 09/30/1980 in 1980-00-00 or 1980-09-30
# 1873-1874  		1973-74 		circa 1870 		09/30/1980			1980  09/30/1980
# if several dates are detected, returns a tab with all dates
# if no string is passed, tries to analyze the rawData string
sub normalizeDate {
	my $self = shift;
	my $dateString = shift;
	
	# If we don't have a parameter, just try to normalize rawData content
	unless ($dateString) { 
		$dateString = $self->rawData();
	#	print "Trying to get rawData".$self->rawData();
	}
	#$dateString = '1873-1874  973-74  1654.45  circa 1870  09.30.1980   1981   09-24-1982 01-1-1984  1923-25';
	my @longdates;
	my @normalizedDates;

# ([0-9]{1,2})[\.\/\-]([0-9]{1,2})[\.\/\-]([0-9]{2,4})  =>09/30/1980 09.30.1980 09-30-1980
# ([0-9]{4})[\.\/\-]([0-9]{2,4})  =>1980-1990  1980-90
# ([0-9]{2,4}) => 1980

	# Before decoding, replace abbreviated characters month by numbers (amg style)
	# could be one of: 
#		Jun 10, 1955,Jun 14, 1955
#		Jul 29, 1957-Aug 1, 1957
#		Jan 1971-Feb 1971
#		Apr 5, 1980
	# Begin with month style: (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ([0-9]*)
# Date debug code
#	print("\nWWW: $dateString \n");
	if($dateString =~ m/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]*/) {
		$dateString =~ s/Jan ([0-9]*)/01-$1/g;
		$dateString =~ s/Feb ([0-9]*)/02-$1/g;
		$dateString =~ s/Mar ([0-9]*)/03-$1/g;
		$dateString =~ s/Apr ([0-9]*)/04-$1/g;
		$dateString =~ s/May ([0-9]*)/05-$1/g;
		$dateString =~ s/Jun ([0-9]*)/06-$1/g;
		$dateString =~ s/Jul ([0-9]*)/07-$1/g;
		$dateString =~ s/Aug ([0-9]*)/08-$1/g;
		$dateString =~ s/Sep ([0-9]*)/09-$1/g;
		$dateString =~ s/Oct ([0-9]*)/10-$1/g;
		$dateString =~ s/Nov ([0-9]*)/11-$1/g;
		$dateString =~ s/Dec ([0-9]*)/12-$1/g;
		$dateString =~ s/, /-/g; # Apr 11, 1957,Apr 30, 1957  replacing comma+space between day of the month and year
		$dateString =~ s/([0-9]{4})-([0-9]{1,2})/$1,$2/g; # prevent problem with Jan 1971-Feb 1971 that became 01-1971-02-1971
		#ERROR("DATRESTRING AFTER CONV: $dateString") # debugging purposes
		#Dec 15, 2000,Dec 16, 2000
	}
# Date debug code
#	print("XXX: $dateString \n\n");
	
	# Discogs stores year at the beginning instead of the end, this confuses this function
	# move year to the end if the format looks like a DOG date format YYYY-MM-DD
	$dateString =~ s/(?:^|[^0-9])([0-9]{3,4})-([0-9]{1,2})-([0-9]{1,2})(?:$|[^0-9])/$2-$3-$1/g;
# Date debug code
#	print("YYY: $dateString \n\n");
	# Handling longest format mm?dd?yyyy
	@longdates =
	  ( $dateString =~ /([0-9]{1,2})[\.\/\-]([0-9]{1,2})[\.\/\-]([0-9]{2,4})/g );	
# version with boundary detection caused problem with multiple long dates like "Jan 31, 1797,Nov 19, 1828"
# problems may remain :(
#	  ( $dateString =~ /(?:^|[^0-9])([0-9]{1,2})[\.\/\-]([0-9]{1,2})[\.\/\-]([0-9]{2,4})(?:$|[^0-9])/g );
#	  ( $dateString =~ /[^0-9]?([0-9]{1,2})[\.\/\-]([0-9]{1,2})[\.\/\-]([0-9]{2,4})/g );
# Date debug code
#	print Dumper @longdates;
	while (@longdates) {
		my ( $month, $day, $year ) = splice @longdates, 0, 3;

		if ( $month > 12 ) {
			if ( $day <= 12 ) {
				WARN("Inverting Day $day <->Month $month");
				( $month, $day ) = ( $day, $month );
			}
			else {
				ERROR("Date error Day $day / Month $month");
			}
		}

	#	printf "Date: %04d-%02d-%02d\n", $year, $month, $day;
		push @normalizedDates, sprintf( '%04d-%02d-%02d', $year, $month, $day );
	}

	# Remove handled tokens from analyzed string
# version with boundary detection caused problem with multiple long dates like "Jan 31, 1797,Nov 19, 1828"
# problems may remain :(
#	$dateString =~ s/(?:^|[^0-9])([0-9]{1,2})[\.\/\-]([0-9]{1,2})[\.\/\-]([0-9]{2,4})(?:$|[^0-9])//g;
	$dateString =~ s/([0-9]{1,2})[\.\/\-]([0-9]{1,2})[\.\/\-]([0-9]{2,4})//g;
	#print "dateString: $dateString\n";

	# Handling shorter format yyyy?yy or yyyy?yyyy
	@longdates = ( $dateString =~ /([0-9]{3,4})[\.\/\-]([0-9]{2,4})/g );
	while (@longdates) {
		my ($year) = shift @longdates;

		#		printf "Date before: %04d\n", $year;
		# our year is a two string year
		if ( length($year) == 2 ) {
			my $lastDate = $normalizedDates[$#normalizedDates];
			$year = substr( $lastDate, 0, 2 ) . $year;

			#	 		printf "Date: %04d LastDate: %s\n", $year,$lastDate;
		}
		elsif ( length($year) != 4 && length($year) != 3 ) {
			ERROR("Unexpected year length : $year from string $dateString");
		}
	#	printf( "Date: %04d-%02d-%02d\n", $year, 0, 0 );
		push @normalizedDates, sprintf( '%04d-%02d-%02d', $year, 0, 0 );
	}	
	# Remove handled tokens from analyzed string
	$dateString =~ s/([0-9]{3,4})[\.\/\-]([0-9]{2,4})//g;
	#print "dateString: $dateString\n";


	# Handling  format mm?yyyy or mm?yyyy
	@longdates = ( $dateString =~ /([0-9]{1,2})[\.\/\-]([0-9]{3,4})/g );
	while (@longdates) {
		my ( $month, $year ) = splice @longdates, 0, 2;

		if ( $month > 12 ) {
				ERROR("Date error Month $month");
		}
		#printf( "Date: %04d-%02d-%02d\n", $year,  $month, 0 );
		push @normalizedDates, sprintf( '%04d-%02d-%02d', $year, $month, 0 );
	}
	# Remove handled tokens from analyzed string
	$dateString =~ s/([0-9]{1,2})[\.\/\-]([0-9]{3,4})//g;
	#print "dateString: $dateString\n";	
	
	# Try to get rid of 10?? 9?? year format
	$dateString =~ s/([0-9]{1,2})\?\?/${1}50/g;
	
	# Handling shorter format yyyy or yyy
	@longdates = ( $dateString =~ /([0-9]{3,4})/g );
	while (@longdates) {
		my ($year) = shift @longdates;

	#	printf( "Date: %04d-%02d-%02d\n", $year, 0, 0 );
		push @normalizedDates, sprintf( '%04d-%02d-%02d', $year, 0, 0 );
	}
	# Remove handled tokens from analyzed string
	$dateString =~ s/([0-9]{3,4})//g;

	# Removed known tokens from analyzed string
	$dateString =~ s/circa//g;
	$dateString =~ s/by//g;
	$dateString =~ s/after//g;
	$dateString =~ s/before//g;
	$dateString =~ s/,//g;  # Apr 11, 1957,Apr 30, 1957 (the middle comma)
	$dateString =~ s/s//g; # Written: 1560s; England 
	$dateString =~ s/\?//g; # Written: ?1795; Vienna, Austria 
	
	#TODO: Not handled  "18th Century" patterns 
	#TODO: Not handled ""Written: ?1824-6; France ""
	#TODO: Not handled (Bug with) <rawData>Dec 15, 2000,Dec 16, 2000</rawData>
	# Gives:    <normalized>2000-12-15</normalized>
	#           <normalized>2000-16-00</normalized>
							
	
	#print 'dateString length: '.length($dateString).'\n';	

	# Removing spaces from the string
	$dateString= Tools::trim($dateString);

	# To issue a warning in case of remaining caracters (to improve the method)	
	if($dateString and length($dateString)!=0) {
		WARN  "Unknown remaining token in date string  $dateString\n";
	}	
	return @normalizedDates;

	# TODO: tester la fonction sur le module AKMReader
	# TODO: manque les traitements du genre 1980s, 172X, 172?, late 1900, seasons, months, etc.

}

END { }    # module clean-up code here (global destructor)
1;
