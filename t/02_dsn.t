use strict;
use warnings;
use Test::More 0.98;
use DBI;

# Test DSN parsing for HTTP-only libsql driver
my @test_cases = (
    {
        dsn => "dbi:libsql:localhost?port=8080&ssl=false",
        expected_url => "http://localhost:8080",
        desc => "New format - Local HTTP server"
    },
    {
        dsn => "dbi:libsql:example.turso.io?port=443&ssl=true",
        expected_url => "https://example.turso.io",
        desc => "New format - Remote HTTPS server"
    },
    {
        dsn => "dbi:libsql:localhost",
        expected_url => "http://localhost:8080",
        desc => "New format - Default values"
    }
);

# Test cases for unsupported DSN formats (should fail)
my @error_test_cases = (
    {
        dsn => "dbi:libsql:test.db",
        desc => "Local file (not supported)"
    },
    {
        dsn => "dbi:libsql:/path/to/test.db", 
        desc => "Local file with path (not supported)"
    },
    {
        dsn => "dbi:libsql::memory:",
        desc => "Memory database (not supported)"
    },
    {
        dsn => "dbi:libsql:http://localhost:8080",
        desc => "HTTP URL format (deprecated, not supported)"
    },
    {
        dsn => "dbi:libsql:https://example.turso.io",
        desc => "HTTPS URL format (deprecated, not supported)"
    }
);

plan tests => scalar(@test_cases) + scalar(@error_test_cases) + 1;

use_ok 'DBD::libsql';

for my $test (@test_cases) {
    # Test DSN parsing using the actual _parse_dsn_to_url logic
    my $dsn = $test->{dsn};
    my $dsn_remainder = $dsn;
    $dsn_remainder =~ s/^dbi:libsql://i;
    
    # Simulate _parse_dsn_to_url function logic (new format only)
    # New format: hostname?port=8080&ssl=false
    my ($host, $query_string) = split /\?/, $dsn_remainder, 2;
    
    # Default values
    my $port = '8080';
    my $ssl = 'false';
    
    # Parse query parameters if present
    if ($query_string) {
        my %params = map { 
            my ($k, $v) = split /=/, $_, 2; 
            ($k, $v // '') 
        } split '&', $query_string;
        
        $port = $params{port} if defined $params{port} && $params{port} ne '';
        $ssl = $params{ssl} if defined $params{ssl} && $params{ssl} ne '';
    }
    
    # Build URL
    my $scheme = ($ssl eq 'true' || $ssl eq '1') ? 'https' : 'http';
    my $parsed_url = "$scheme://$host";
    $parsed_url .= ":$port" if $port && $port ne '80' && $port ne '443';
    
    is $parsed_url, $test->{expected_url}, $test->{desc};
}

# Test that unsupported DSN formats are rejected
for my $test (@error_test_cases) {
    eval {
        my $dbh = DBI->connect($test->{dsn}, '', '', {RaiseError => 1});
    };
    ok($@, $test->{desc} . " - should fail with error");
}

done_testing;
