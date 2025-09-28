[![Actions Status](https://github.com/ytnobody/p5-DBD-libsql/actions/workflows/test.yml/badge.svg)](https://github.com/ytnobody/p5-DBD-libsql/actions)
# NAME

DBD::libsql - DBI driver for libsql databases

# SYNOPSIS

    use DBI;
    
    # Connect to a libsql server (new format)
    my $dbh = DBI->connect('dbi:libsql:localhost?port=8080&ssl=false', '', '', {
        RaiseError => 1,
        AutoCommit => 1,
    });
    
    # Backward compatibility - HTTP URLs still supported
    # my $dbh = DBI->connect('dbi:libsql:http://localhost:8080', '', '', {
    #     RaiseError => 1,
    #     AutoCommit => 1,
    # });
    
    # Create a table
    $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)");
    
    # Insert data
    $dbh->do("INSERT INTO users (name) VALUES (?)", undef, 'Alice');
    
    # Query data
    my $sth = $dbh->prepare("SELECT * FROM users WHERE name = ?");
    $sth->execute('Alice');
    while (my $row = $sth->fetchrow_hashref) {
        print "ID: $row->{id}, Name: $row->{name}\n";
    }
    
    $dbh->disconnect;

# DESCRIPTION

DBD::libsql is a DBI driver that provides access to libsql databases via HTTP.
libsql is a fork of SQLite that supports server-side deployment and remote access.

This driver communicates with libsql servers using the Hrana protocol over HTTP,
providing full SQL functionality including transactions, prepared statements, and
parameter binding.

# FEATURES

- HTTP-only communication with libsql servers
- Full transaction support (BEGIN, COMMIT, ROLLBACK)
- Prepared statements with parameter binding
- Session management using baton tokens
- Proper error handling with Hrana protocol responses
- Support for all standard DBI methods

# DSN FORMAT

The Data Source Name (DSN) format for DBD::libsql is:

    dbi:libsql:hostname?port=8080&ssl=false

Examples:

    # Local development server (HTTP)
    dbi:libsql:localhost?port=8080&ssl=false
    
    # Remote libsql server (HTTPS)
    dbi:libsql:mydb.turso.io?port=443&ssl=true
    
    # Backward compatibility - HTTP URLs still supported
    dbi:libsql:http://localhost:8080
    dbi:libsql:https://mydb.turso.io

# CONNECTION ATTRIBUTES

Standard DBI connection attributes are supported:

- RaiseError - Enable/disable automatic error raising
- AutoCommit - Enable/disable automatic transaction commit
- PrintError - Enable/disable error printing

# LIMITATIONS

- Only HTTP-based libsql servers are supported
- Local file databases are not supported
- In-memory databases are not supported

# DEPENDENCIES

This module requires the following Perl modules:

- DBI
- LWP::UserAgent
- HTTP::Request
- JSON

# AUTHOR

ytnobody <ytnobody@gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

- [DBI](https://metacpan.org/pod/DBI)
- [DBD::SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite)
- libsql documentation: [https://docs.turso.tech/](https://docs.turso.tech/)
