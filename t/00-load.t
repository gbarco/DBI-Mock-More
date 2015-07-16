#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::DBIMock::More' ) || print "Bail out!\n";
}

diag( "Testing Test::DBIMock::More $Test::DBIMock::More::VERSION, Perl $], $^X" );
