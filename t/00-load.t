#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Heckle' ) || print "Bail out!
";
}

diag( "Testing Heckle $Heckle::VERSION, Perl $], $^X" );
