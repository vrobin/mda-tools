#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Data::Dumper;

use Win32::GuiTest
  qw( FindWindowLike GetWindowText SetForegroundWindow SendKeys PushChildButton 
  WMGetText GetMenu GetMenuItemCount GetMenuItemInfo GetSubMenu MenuSelect 
  GetListText WMSetText GetListContents GetListViewContents);

my @whnds = FindWindowLike( undef, "^Collectorz" );

if ( !@whnds ) {
    die "Cannot find window with title/caption Calculator\n";
}
else {
    my $whnd = $whnds[0];
    printf( "Window handle of calculator application is %x\n", $whnd );

    
    my @edit = FindWindowLike( $whnd, undef, "^TCollectorzListView"); #,  397964 );
    if( !@edit ){
        die "Cannot find window handle for Edit control\n";
    }else{
        printf( "Edit window handle is %x\n", $edit[ 0 ] );
        
        foreach my $id (@edit) { #790799
        
            #my $result = WMGetText( $id );
            #WMSetText( $id, "WAZAA!" );
            
            my @items = GetListViewContents( $id );
            #my $result = GetListText( $items[4], 2 );
            print  $items[4], ' | ', $id, ' | nbitems ', $#items,"\n";
            die Dumper \@items;
        };
	#die Dumper \$result;
    }    

}


__END__

=head 
    
my @whnds = FindWindowLike( undef, "^Exact Audio Copy" );

if ( !@whnds ) {
    die "Cannot find window with title/caption Calculator\n";
}
else {
    my $whnd = $whnds[0];
    printf( "Window handle of calculator application is %x\n", $whnd );
    my $hmenu = GetMenu( $whnd );
    my $mcount = GetMenuItemCount( $hmenu );
    for ( my $i = 0; $i<$mcount; $i++ ) {
        my %info = GetMenuItemInfo( $hmenu, $i );
        #print Dumper \%info;
        if(exists($info{text})) {
		print $info{text}, "\n";
	} 
        my $hsubmenu = GetSubMenu( $hmenu, $i );
        my $submenucount = GetMenuItemCount( $hsubmenu );
        for ( my $j = 0; $j < $submenucount; $j++ ) {
		my %info = GetMenuItemInfo( $hsubmenu, $j );
		if(exists($info{text})) {
			print "\t", $info{text}, "\n";#Dumper \%info;
		}
        }
        print("============================\n");
    }
    #MenuSelect( "&Help|&About EAC...", $whnd, $hmenu );
    MenuSelect( "&Tools|Co&mpression Queue Control Center", $whnd, $hmenu );
    
    die $mcount;
}



================== Calculatrice

my @whnds = FindWindowLike( undef, "^Calculat" );

if ( !@whnds ) {
    die "Cannot find window with title/caption Calculator\n";
}
else {
    printf( "Window handle of calculator application is %x\n", $whnds[0] );
    SetForegroundWindow(@whnds);

    SendKeys("5{+}5{ENTER}");

    PushChildButton ($whnds[0], 136);
    PushChildButton ($whnds[0], 93);
    PushChildButton ($whnds[0], 139);
    PushChildButton ($whnds[0], 121);

    my $edit_ctrl_id = 150; #Edit window, 193 Hex

    my @edit = FindWindowLike( $whnds[ 0 ], undef, "^Static", $edit_ctrl_id );
    if( !@edit ){
        die "Cannot find window handle for Edit control\n";
    }else{
        printf( "Edit window handle is %x\n", $edit[ 0 ] );
    }
    #die Dumper \@edit;
    my $result = WMGetText( $edit[ 0 ] );
    die Dumper \$result;
        if( $result != 15 ){
        print "Test failed. The result is $result and expected value was 15\n";
    }else{
        print "Success. The result is $result, which is as expected\n";
    }
}
