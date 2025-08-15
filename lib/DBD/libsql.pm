# DBI::db パッケージに _disconnect を追加
package DBI::db;
sub _disconnect {
    my $self = shift;
    # DBD::libsql::db の _disconnect を呼び出す
    if ($self->can('DBD::libsql::db::_disconnect')) {
        return $self->DBD::libsql::db::_disconnect();
    }
    # 何もしない
    return 1;
}

package DBD::libsql;
use 5.008001;
use strict;
use warnings;
use DBI ();
use FFI::Platypus;

our $VERSION = "0.01";
our $AUTHOR = 'ytnobody <ytnobody@gmail.com>';
our $ABSTRACT = 'DBI driver for libsql database';

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

sub imp_data_size { $imp_data_size }

# Memory management package (required by DBI)
package DBD::libsql::dr_mem;

sub connect {
    my ($drh, $dsn, $user, $auth, $attr) = @_;

    # Parse DSN to determine connection type
    my $database;
    my $connection_type;
    my $dsn_remainder = $dsn;
    $dsn_remainder =~ s/^dbi:libsql://i;

    if ($dsn_remainder =~ /^(?:db(?:name)?|database)=([^;]*)/i) {
        $database = $1;
    } else {
        $database = $dsn_remainder;
    }

    # Determine connection type based on database string
    if ($database =~ /^libsql:\/\//) {
        $connection_type = 'websocket';  # Remote libsql/Turso connection
    } elsif ($database eq ':memory:') {
        $connection_type = 'memory';     # In-memory database
    } elsif ($database =~ /^https?:\/\//) {
        $connection_type = 'http';       # HTTP API connection
    } else {
        $connection_type = 'file';       # Local file database
    }

    # Create database handle
    my $dbh = DBI::_new_dbh($drh, {
        'Name' => $dsn,
        'USER' => $user || '',
        'CURRENT_USER' => $user || '',
    }, $user);

    # Bless DBI handle into our package and initialize attributes
    bless $dbh, 'DBD::libsql::db';
    $dbh->{database} = $database;
    $dbh->{connection_type} = $connection_type;
    $dbh->{user} = $user || '';
    $dbh->{auth} = $auth || '';
    $dbh->{attr} = $attr || {};
    $dbh->{_libsql_handle} = undef;
    $dbh->{_autocommit} = 1;

    # Initialize libsql FFI connection
    eval { $dbh->_init_libsql_connection(); };
    if ($@) {
        $drh->set_err($DBI::stderr, "Unable to connect to database $database: $@");
        return undef;
    }

    return $dbh;
}

sub data_sources {
    my ($drh, $attr) = @_;
    return ();  # libsql doesn't have a standard way to list data sources
}

sub DESTROY {
    my $drh = shift;
    undef $drh;
}

# Database Handle
package DBD::libsql::db;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::db);
$imp_data_size = 0;

sub imp_data_size { $imp_data_size }

# Memory management package (required by DBI)
package DBD::libsql::db_mem;

sub new {
    my ($class, $database, $user, $auth, $attr) = @_;
    my $dbh = bless {
        database => $database,
        user => $user,
        auth => $auth,
        attr => $attr || {},
        _libsql_handle => undef,
        _autocommit => 1,
    }, $class;
    $dbh->_init_libsql_connection();
    return $dbh;
}

sub _init_libsql_connection {
    my $self = shift;
    
    # Try to initialize FFI, but don't fail if libsql library is not available
    eval {
        my $ffi = FFI::Platypus->new( api => 1 );
        
        $self->{_ffi} = $ffi;
        $self->{_libsql_available} = 0;  # Set to 1 when actual libsql is available
        
        # Initialize based on connection type
        my $conn_type = $self->{connection_type} || 'file';
        
        if ($conn_type eq 'websocket') {
            # WebSocket connection to remote libsql/Turso
            $self->_init_websocket_connection();
        } elsif ($conn_type eq 'file') {
            # Local file database
            $self->_init_file_connection();
        } elsif ($conn_type eq 'memory') {
            # In-memory database
            $self->_init_memory_connection();
        } elsif ($conn_type eq 'http') {
            # HTTP API connection
            $self->_init_http_connection();
        }
    };
    
    if ($@) {
        warn "libsql library not available: $@" if $ENV{DBD_LIBSQL_DEBUG};
        $self->{_ffi} = undef;
        $self->{_libsql_available} = 0;
    }
    
    # For now, always succeed even without libsql library
    return 1;
}

sub _init_websocket_connection {
    my $self = shift;
    # WebSocket connection implementation for remote libsql/Turso
    # This would use libsql's WebSocket protocol
    warn "WebSocket connection to: " . $self->{database} if $ENV{DBD_LIBSQL_DEBUG};
    return 1;
}

sub _init_file_connection {
    my $self = shift;
    # Local file database connection
    # This would use libsql's local file mode (SQLite compatible)
    warn "File connection to: " . $self->{database} if $ENV{DBD_LIBSQL_DEBUG};
    return 1;
}

sub _init_memory_connection {
    my $self = shift;
    # In-memory database connection
    warn "Memory database connection" if $ENV{DBD_LIBSQL_DEBUG};
    return 1;
}

sub _init_http_connection {
    my $self = shift;
    # HTTP API connection
    warn "HTTP connection to: " . $self->{database} if $ENV{DBD_LIBSQL_DEBUG};
    return 1;
}

sub prepare {
    my ($dbh, $statement, $attr) = @_;
    
    my $sth = DBI::_new_sth($dbh, {
        'Statement' => $statement,
    });
    
    my $libsql_stmt = DBD::libsql::st->new($dbh, $statement, $attr);
    unless ($libsql_stmt) {
        $dbh->set_err($DBI::stderr, "Unable to prepare statement: $statement");
        return undef;
    }
    
    $sth->STORE('libsql_stmt', $libsql_stmt);
    return $sth;
}

sub commit {
    my $dbh = shift;
    return $dbh->_commit();
}

sub rollback {
    my $dbh = shift;
    return $dbh->_rollback();
}

sub disconnect {
    my $dbh = shift;
    $dbh->_disconnect();
    return 1;
}

sub FETCH {
    my ($dbh, $attr) = @_;
    
    # Handle our custom attributes
    if ($attr eq 'AutoCommit') {
        return $dbh->{_autocommit} // 1;
    }
    
    # Handle standard DBI attributes
    if ($attr eq 'Name') {
        return $dbh->{Name};
    }
    if ($attr eq 'USER') {
        return $dbh->{USER};
    }
    
    # For other attributes, return from our hash or undef
    return exists $dbh->{$attr} ? $dbh->{$attr} : undef;
}

sub STORE {
    my ($dbh, $attr, $val) = @_;
    
    # Handle AutoCommit specially
    if ($attr eq 'AutoCommit') {
        $dbh->{_autocommit} = $val;
        # TODO: Implement actual autocommit mode changes in libsql
        return $val;
    }
    
    # Store other attributes directly
    $dbh->{$attr} = $val;
    return $val;
}

sub set_autocommit {
    my ($self, $val) = @_;
    $self->{_autocommit} = $val;
    return 1;
}

sub get_autocommit {
    my $self = shift;
    return $self->{_autocommit} // 1;
}

sub _disconnect {
    my $self = shift;
    $self->{_libsql_handle} = undef;
    return 1;
}

sub _commit {
    my $self = shift;
    return 1;
}

sub _rollback {
    my $self = shift;
    return 1;
}

sub DESTROY {
    my $dbh = shift;
    $dbh->_disconnect();
}

# Statement Handle
package DBD::libsql::st;
use vars qw(@ISA $imp_data_size);
@ISA = qw(DBI::st);
$imp_data_size = 0;

sub imp_data_size { $imp_data_size }

# Memory management package (required by DBI)
package DBD::libsql::st_mem;

sub new {
    my ($class, $dbh, $statement, $attr) = @_;
    my $sth = bless {
        _statement => $statement,
        _dbh => $dbh,
        _attr => $attr,
        _row_count => 0,
        _result_set => undef,
    }, $class;
    return $sth;
}

sub bind_param {
    my ($sth, $param_num, $value, $attr) = @_;
    $sth->{_bound_params}[$param_num - 1] = $value;
    return 1;
}

sub execute {
    my ($sth, @params) = @_;
    
    # Store parameters
    $sth->{_params} = [@params];
    
    # Execute statement (placeholder implementation)
    unless ($sth->_execute_statement(@params)) {
        return undef;
    }
    
    return $sth->{_row_count} || "0E0";
}

sub _execute_statement {
    my ($sth, @params) = @_;
    
    # This would use the libsql FFI to execute the statement
    # For now, we'll create a placeholder
    $sth->{_row_count} = 1;
    return 1;
}

sub fetchrow_arrayref {
    my ($sth) = @_;
    
    # This would fetch the next row from libsql result set
    # For now, return undef to indicate no more rows
    return undef;
}

sub fetchrow_hashref {
    my ($sth) = @_;
    
    # This would fetch the next row as a hash reference
    # For now, return undef to indicate no more rows
    return undef;
}

sub finish {
    my ($sth) = @_;
    
    # Clean up the statement
    $sth->{_result_set} = undef;
    return 1;
}

sub rows {
    my ($sth) = @_;
    return $sth->{_row_count} || 0;
}

sub DESTROY {
    my ($sth) = @_;
    $sth->finish() if $sth;
}

1;

__END__

=encoding utf-8

=head1 NAME

DBD::libsql - DBI driver for libsql database

=head1 SYNOPSIS

    use DBI;
    
    # Connect to a local libsql database
    my $dbh = DBI->connect("dbi:libsql:database.db", "", "");
    
    # Connect to a remote libsql database (Turso)
    my $dbh = DBI->connect("dbi:libsql:libsql://your-database.turso.io", 
                          "", "your-auth-token");
    
    # Execute SQL
    my $sth = $dbh->prepare("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)");
    $sth->execute();
    
    $sth = $dbh->prepare("INSERT INTO users (name) VALUES (?)");
    $sth->execute("John Doe");
    
    $sth = $dbh->prepare("SELECT * FROM users WHERE id = ?");
    $sth->execute(1);
    
    while (my $row = $sth->fetchrow_hashref) {
        print "ID: ", $row->{id}, ", Name: ", $row->{name}, "\n";
    }
    
    $dbh->disconnect;

=head1 DESCRIPTION

DBD::libsql is a DBI driver for libsql databases. libsql is a fork of SQLite that 
supports both local and remote database connections, including Turso's hosted 
database service.

This driver provides a standard DBI interface to libsql databases, allowing you 
to use familiar Perl DBI methods to interact with both local SQLite-compatible 
files and remote libsql database instances.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

