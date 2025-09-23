package DBD::libsql;

use strict;
use warnings;
use DBI ();

our $VERSION = '0.01';

# Driver registration
sub driver {
    return $DBD::libsql::drh ||= DBI::_new_drh('DBD::libsql::dr', {
        'Name' => 'libsql',
        'Version' => $VERSION,
        'Err' => \(my $err = 0),
        'Errstr' => \(my $errstr = ''),
        'State' => \(my $state = ''),
        'Attribution' => 'DBD::libsql by ytnobody',
    });
}

# Driver Handle
package DBD::libsql::dr;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::dr);
$imp_data_size = 0;

sub connect {
    my ($drh, $dsn, $user, $password, $attr) = @_;
    
    my $dbh = DBI::_new_dbh($drh, {
        'Name' => $dsn,
    });

    bless $dbh, 'DBD::libsql::db';
    return $dbh;
}

sub data_sources {
    return ();
}

# Database Handle
package DBD::libsql::db;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::db);
$imp_data_size = 0;

# Statement Handle
package DBD::libsql::st;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::st);
$imp_data_size = 0;

1;

__END__

=head1 NAME

DBD::libsql - DBI driver for libsql database

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect("dbi:libsql:database.db", $user, $password);

=head1 DESCRIPTION

This is a DBI driver for libsql database.

=cut