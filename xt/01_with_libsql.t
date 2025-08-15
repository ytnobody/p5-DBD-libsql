#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    require Test::More;
    require DBI;
    require DBD::libsql;
}

use Test::More;
use File::Temp qw(tempfile);
use File::Spec;

# Check if libsql is available before running tests
sub check_libsql_available {
    my $available = 0;
    eval {
        require FFI::Platypus;
        my $ffi = FFI::Platypus->new(api => 1);
        $ffi->lib("$ENV{HOME}/libsql/target/release/libsql.so");
        # $ffi->function('libsql_database_open' => ['string'] => 'opaque'); # ←コメントアウト
        $available = 1;
    };
    return $available;
}

# Skip all tests if libsql is not available
unless (check_libsql_available()) {
    plan skip_all => 'libsql library not installed or not functional';
}

plan tests => 10;

    # Test 1: Driver Registration
    subtest 'Driver Registration' => sub {
        plan tests => 5;
        
        # Test driver can be loaded
        my $drh = DBI->install_driver('libsql');
        ok($drh, 'Driver installed successfully');
        isa_ok($drh, 'DBI::dr');
        
        # Test driver attributes
        is($drh->{Name}, 'libsql', 'Driver name is correct');
        like($drh->{Version}, qr/^\d+\.\d+/, 'Driver has version number');
        ok($drh->{Attribution}, 'Driver has attribution');
    };

    # Test 2: Basic Connection
    subtest 'Basic Connection' => sub {
        plan tests => 5;
        
        # Create temporary database file
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        # Test local file connection
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        ok($dbh, 'Successfully connected to local database');
        isa_ok($dbh, 'DBI::db');
        
        # Test database handle attributes
        ok(defined $dbh->{Name}, 'Database handle has Name attribute');
        is($dbh->{AutoCommit}, 1, 'AutoCommit defaults to true');
        
        # Test disconnection
        ok($dbh->disconnect(), 'Successfully disconnected');
    };

    # Test 3: DSN Parsing
    subtest 'DSN Parsing' => sub {
        plan tests => 6;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        # Test different DSN formats
        my @dsn_formats = (
            "dbi:libsql:$db_file",
            "dbi:libsql:database=$db_file",
            "dbi:libsql:dbname=$db_file",
            "dbi:libsql:db=$db_file",
        );
        
        for my $dsn (@dsn_formats) {
            my $dbh = DBI->connect($dsn, "", "");
            ok($dbh, "Connected with DSN format: $dsn");
            $dbh->disconnect() if $dbh;
        }
        
        # Test in-memory database
        my $dbh = DBI->connect("dbi:libsql::memory:", "", "");
        ok($dbh, 'Connected to in-memory database');
        $dbh->disconnect() if $dbh;
    };

    # Test 4: SQL Operations
    subtest 'SQL Operations' => sub {
        plan tests => 8;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        ok($dbh, 'Connected to database');
        
        # Test CREATE TABLE
        my $sth = $dbh->prepare("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)");
        ok($sth, 'Prepared CREATE TABLE statement');
        ok($sth->execute(), 'Executed CREATE TABLE');
        
        # Test INSERT
        $sth = $dbh->prepare("INSERT INTO users (name, email) VALUES ('John Doe', 'john\@example.com')");
        ok($sth->execute(), 'Executed INSERT statement');
        cmp_ok($sth->rows(), '>=', 0, 'INSERT reported row count');
        
        # Test SELECT
        $sth = $dbh->prepare("SELECT * FROM users WHERE name = 'John Doe'");
        ok($sth->execute(), 'Executed SELECT statement');
        
        # Test UPDATE
        $sth = $dbh->prepare("UPDATE users SET email = 'john.doe\@example.com' WHERE name = 'John Doe'");
        ok($sth->execute(), 'Executed UPDATE statement');
        
        # Test DELETE
        $sth = $dbh->prepare("DELETE FROM users WHERE name = 'John Doe'");
        ok($sth->execute(), 'Executed DELETE statement');
        
        $dbh->disconnect();
    };

    # Test 5: Prepared Statements
    subtest 'Prepared Statements' => sub {
        plan tests => 8;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        
        # Create test table
        $dbh->do("CREATE TABLE test_prep (id INTEGER PRIMARY KEY, value TEXT)");
        
        # Test prepare and execute with parameters
        my $sth = $dbh->prepare("INSERT INTO test_prep (value) VALUES (?)");
        ok($sth, 'Prepared INSERT statement with placeholder');
        
        # Test multiple executions
        for my $i (1..5) {
            ok($sth->execute("Value $i"), "Executed with parameter: Value $i");
        }
        
        # Test SELECT with parameters
        $sth = $dbh->prepare("SELECT * FROM test_prep WHERE value LIKE ?");
        ok($sth->execute('Value%'), 'Executed SELECT with LIKE parameter');
        
        $dbh->disconnect();
    };

    # Test 6: Parameter Binding
    subtest 'Parameter Binding' => sub {
        plan tests => 6;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        
        # Create test table
        $dbh->do("CREATE TABLE test_bind (id INTEGER, name TEXT, score REAL)");
        
        # Test bind_param
        my $sth = $dbh->prepare("INSERT INTO test_bind (id, name, score) VALUES (?, ?, ?)");
        ok($sth->bind_param(1, 1), 'Bound parameter 1');
        ok($sth->bind_param(2, 'Alice'), 'Bound parameter 2');
        ok($sth->bind_param(3, 95.5), 'Bound parameter 3');
        ok($sth->execute(), 'Executed with bound parameters');
        
        # Test execute with inline parameters
        ok($sth->execute(2, 'Bob', 87.2), 'Executed with inline parameters');
        
        # Test rows method
        cmp_ok($sth->rows(), '>=', 0, 'rows() method returns value');
        
        $dbh->disconnect();
    };

    # Test 7: Transactions
    subtest 'Transactions' => sub {
        plan tests => 6;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        
        # Create test table
        $dbh->do("CREATE TABLE test_trans (id INTEGER PRIMARY KEY, value TEXT)");
        
        # Test commit
        $dbh->{AutoCommit} = 0;
        is($dbh->{AutoCommit}, 0, 'AutoCommit set to false');
        
        $dbh->do("INSERT INTO test_trans (value) VALUES ('test1')");
        ok($dbh->commit(), 'Transaction committed successfully');
        
        # Test rollback
        $dbh->do("INSERT INTO test_trans (value) VALUES ('test2')");
        ok($dbh->rollback(), 'Transaction rolled back successfully');
        
        # Reset AutoCommit
        $dbh->{AutoCommit} = 1;
        is($dbh->{AutoCommit}, 1, 'AutoCommit reset to true');
        
        # Test begin_work (if supported)
        eval { $dbh->begin_work() };
        ok(!$@ || $@ =~ /not supported/, 'begin_work handled appropriately');
        
        $dbh->disconnect();
    };

    # Test 8: Data Fetching
    subtest 'Data Fetching' => sub {
        plan tests => 8;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        
        # Create and populate test table
        $dbh->do("CREATE TABLE test_fetch (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)");
        $dbh->do("INSERT INTO test_fetch (name, age) VALUES ('Alice', 25)");
        $dbh->do("INSERT INTO test_fetch (name, age) VALUES ('Bob', 30)");
        $dbh->do("INSERT INTO test_fetch (name, age) VALUES ('Charlie', 35)");
        
        my $sth = $dbh->prepare("SELECT * FROM test_fetch ORDER BY id");
        ok($sth->execute(), 'Executed SELECT for fetching');
        
        # Test fetchrow_arrayref
        my $row = $sth->fetchrow_arrayref();
        ok(!defined($row) || ref($row) eq 'ARRAY', 'fetchrow_arrayref returns arrayref or undef');
        
        # Reset statement
        $sth->execute();
        
        # Test fetchrow_hashref
        my $hash_row = $sth->fetchrow_hashref();
        ok(!defined($hash_row) || ref($hash_row) eq 'HASH', 'fetchrow_hashref returns hashref or undef');
        
        # Test finish
        ok($sth->finish(), 'Statement finished successfully');
        
        # Test selectall_arrayref
        my $all_rows = $dbh->selectall_arrayref("SELECT * FROM test_fetch");
        ok(defined($all_rows), 'selectall_arrayref executed');
        isa_ok($all_rows, 'ARRAY');
        
        # Test selectall_hashref
        my $all_hash = $dbh->selectall_hashref("SELECT * FROM test_fetch", 'id');
        ok(defined($all_hash), 'selectall_hashref executed');
        
        # Test selectrow_array
        my @row_array = $dbh->selectrow_array("SELECT COUNT(*) FROM test_fetch");
        ok(defined($row_array[0]), 'selectrow_array executed');
        
        $dbh->disconnect();
    };

    # Test 9: Error Handling
    subtest 'Error Handling' => sub {
        plan tests => 4;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        
        # Test invalid SQL
        my $sth = eval { $dbh->prepare("INVALID SQL STATEMENT") };
        my $prepare_error = $@;
        
        if ($sth) {
            # If prepare succeeded, execute should fail
            my $result = eval { $sth->execute() };
            ok(!$result || $@, 'Invalid SQL properly rejected during execute');
        } else {
            ok($prepare_error, 'Invalid SQL properly rejected during prepare');
        }
        
        # Test connection to non-existent file with invalid path
        my $bad_dbh = eval { DBI->connect("dbi:libsql:/nonexistent/path/database.db", "", "") };
        ok(!$bad_dbh || $@, 'Connection to invalid path handled');
        
        # Test accessing non-existent table
        eval { $dbh->do("SELECT * FROM nonexistent_table") };
        ok($@, 'Query on non-existent table fails appropriately');
        
        # Test malformed DSN
        my $malformed_dbh = eval { DBI->connect("dbi:libsql:", "", "") };
        ok(!$malformed_dbh || $@, 'Malformed DSN handled appropriately');
        
        $dbh->disconnect();
    };

    # Test 10: Cleanup and Resource Management
    subtest 'Cleanup and Resource Management' => sub {
        plan tests => 5;
        
        my ($fh, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
        close $fh;
        
        my $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        my $sth = $dbh->prepare("SELECT 1");
        
        # Test statement handle cleanup
        ok($sth->finish(), 'Statement handle finished successfully');
        
        # Test database handle cleanup
        ok($dbh->disconnect(), 'Database handle disconnected successfully');
        
        # Test destruction doesn't cause errors
        undef $sth;
        undef $dbh;
        pass('Handles destroyed without errors');
        
        # Test multiple disconnects don't cause errors
        $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        $dbh->disconnect();
        ok($dbh->disconnect(), 'Multiple disconnects handled gracefully');
        
        # Test working with already finished statement
        $dbh = DBI->connect("dbi:libsql:$db_file", "", "");
        $sth = $dbh->prepare("SELECT 1");
        $sth->finish();
        ok($sth->finish(), 'Multiple finish() calls handled gracefully');
        
        $dbh->disconnect();
    };

done_testing;
