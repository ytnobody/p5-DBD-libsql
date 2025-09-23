use strict;
use warnings;
use Test::More 0.98;

# Test that the module works without actual libsql library
use_ok 'DBD::libsql';

# Skip direct instantiation tests - use DBI interface instead
SKIP: {
    skip "Direct instantiation no longer supported - use DBI interface", 6;
}

# Test statement class - also skip for now
SKIP: {
    skip "Direct statement instantiation no longer supported", 7;
}

done_testing;
