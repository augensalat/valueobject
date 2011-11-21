#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ValueObject' ) || print "Bail out!\n";
}

diag( "Testing ValueObject $ValueObject::VERSION, Perl $], $^X" );
