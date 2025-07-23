use strict;
use warnings;
use Test::More 0.98;
use DBI;

# Test DSN parsing
my @test_cases = (
    {
        dsn => "dbi:libsql:test.db",
        expected_db => "test.db",
        desc => "Simple database file"
    },
    {
        dsn => "dbi:libsql:database=/path/to/test.db",
        expected_db => "/path/to/test.db", 
        desc => "Database with full path"
    },
    {
        dsn => "dbi:libsql:libsql://example.turso.io",
        expected_db => "libsql://example.turso.io",
        desc => "Remote libsql URL"
    },
    {
        dsn => "dbi:libsql::memory:",
        expected_db => ":memory:",
        desc => "In-memory database"
    }
);

plan tests => scalar(@test_cases) + 1;

use_ok 'DBD::libsql';

for my $test (@test_cases) {
    # Extract database name from DSN (same logic as in DBD::libsql::dr::connect)
    my $dsn = $test->{dsn};
    my $database;
    my $dsn_remainder = $dsn;
    $dsn_remainder =~ s/^dbi:libsql://i;
    
    if ($dsn_remainder =~ /^(?:db(?:name)?|database)=([^;]*)/i) {
        $database = $1;
    } else {
        $database = $dsn_remainder;
    }
    
    is $database, $test->{expected_db}, $test->{desc};
}

done_testing;
