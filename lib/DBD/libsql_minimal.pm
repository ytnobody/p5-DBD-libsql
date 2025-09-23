package DBD::libsql;
use 5.008001;
use strict;
use warnings;
use DBI ();

our $VERSION = "0.01";

# DBD Driver Registration
our $drh = undef;

sub driver {
    return $drh if $drh;
    my ($class, $attr) = @_;
    
    $class .= "::dr";
    $drh = DBI::_new_drh($class, {
        'Name'        => 'libsql',
        'Version'     => $VERSION,
        'Attribution' => 'DBD::libsql by ytnobody',
    });
    
    return $drh;
}

# Driver Handle
package DBD::libsql::dr;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::dr);
$imp_data_size = 0;

sub connect {
    my ($drh, $dsn, $user, $auth, $attr) = @_;

    # Create database handle
    my $dbh = DBI::_new_dbh($drh, {
        'Name' => $dsn,
        'USER' => $user || '',
        'CURRENT_USER' => $user || '',
    });

    # Bless into our package
    bless $dbh, 'DBD::libsql::db';
    
    return $dbh;
}

# Database Handle
package DBD::libsql::db;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::db);
$imp_data_size = 0;

sub prepare {
    my ($dbh, $statement, $attr) = @_;
    
    my $sth = DBI::_new_sth($dbh, {
        'Statement' => $statement,
    });
    
    bless $sth, 'DBD::libsql::st';
    return $sth;
}

sub disconnect {
    return 1;
}

sub FETCH {
    my ($dbh, $attr) = @_;
    return 1 if $attr eq 'AutoCommit';
    return '';
}

sub STORE {
    my ($dbh, $attr, $val) = @_;
    return $val;
}

# Statement Handle
package DBD::libsql::st;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::st);
$imp_data_size = 0;

sub execute {
    my $sth = shift;
    $sth->{NUM_OF_FIELDS} = 1;
    $sth->{NAME} = ['test'];
    return 1;
}

sub fetchrow_arrayref {
    return undef;
}

sub FETCH {
    my ($sth, $attr) = @_;
    return $sth->{$attr};
}

sub STORE {
    my ($sth, $attr, $val) = @_;
    $sth->{$attr} = $val;
    return $val;
}

1;