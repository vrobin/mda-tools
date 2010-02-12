
## use critic

use strict;
use utf8;

#use Data::Dumper;
use WWW::Mechanize;

my $mech = WWW::Mechanize->new();

$mech->get("http://www.google.com");

$mech->submit_form(
    form_name => 'f',
    fields    => { q => 'alfredo', }
);
die $mech->title();

#sub aze {
#    wantarray ? return (0) : return 0;
#}
#
#sub qsd {
#    wantarray ? return (0) : return 0;
#}


my $pouet = LWP::ConnCache->new;

#LWP::ConnCache::get_types()
#Win32::Exe;
#W
#require_ok ();
Dumper();
WWW::Mechanize::get();


aze();
qsd();

#die Dumper $mech->forms();
