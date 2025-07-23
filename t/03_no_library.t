use strict;
use warnings;
use Test::More 0.98;

# Test that the module works without actual libsql library
use_ok 'DBD::libsql';

# Test internal classes can be instantiated
{
    # Test DBD::libsql::db->new
    my $db = DBD::libsql::db->new("test.db", "", "", {});
    isa_ok $db, 'DBD::libsql::db';
    
    # Test basic methods
    ok $db->set_autocommit(1), 'set_autocommit works';
    is $db->get_autocommit(), 1, 'get_autocommit works';
    
    ok $db->_commit(), '_commit works';
    ok $db->_rollback(), '_rollback works';
    ok $db->_disconnect(), '_disconnect works';
}

# Test statement class
{
    my $db = DBD::libsql::db->new("test.db", "", "", {});
    my $st = DBD::libsql::st->new($db, "SELECT 1", {});
    isa_ok $st, 'DBD::libsql::st';
    
    # Test basic statement methods
    ok $st->bind_param(1, "test"), 'bind_param works';
    ok defined $st->execute(), 'execute works';
    is $st->rows(), 1, 'rows works';
    ok $st->finish(), 'finish works';
    
    # Test fetch methods (should return undef for now)
    is $st->fetchrow_arrayref(), undef, 'fetchrow_arrayref returns undef';
    is $st->fetchrow_hashref(), undef, 'fetchrow_hashref returns undef';
}

done_testing;
