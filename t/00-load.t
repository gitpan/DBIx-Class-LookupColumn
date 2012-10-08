#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::LookupColumn' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::LookupColumn $DBIx::Class::LookupColumn::VERSION, Perl $], $^X" );
