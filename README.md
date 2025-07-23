
# NAME

DBD::libsql - DBI driver for libsql database

# SYNOPSIS

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
        print "ID: $row->{id}, Name: $row->{name}\n";
    }
    
    $dbh->disconnect;

# DESCRIPTION

DBD::libsql is a DBI driver for libsql databases. libsql is a fork of SQLite that 
supports both local and remote database connections, including Turso's hosted 
database service.

This driver provides a standard DBI interface to libsql databases, allowing you 
to use familiar Perl DBI methods to interact with both local SQLite-compatible 
files and remote libsql database instances.

# CONNECTION

The DSN (Data Source Name) format for DBD::libsql connections:

- Local database file

        dbi:libsql:/path/to/database.db
        dbi:libsql:database.db

- Remote libsql database (Turso)

        dbi:libsql:libsql://your-database.turso.io

- In-memory database

        dbi:libsql::memory:

# AUTHENTICATION

For remote databases, you'll typically need to provide an authentication token:

    my $dbh = DBI->connect(
        "dbi:libsql:libsql://your-database.turso.io",
        "",  # username (usually empty for libsql)
        "your-auth-token"  # password/token
    );

# SUPPORTED FEATURES

- Standard DBI methods (prepare, execute, fetchrow\_\*, etc.)
- Local SQLite-compatible database files
- Remote libsql database connections
- Transactions (commit, rollback)
- Prepared statements with parameter binding
- AutoCommit mode control

# LIMITATIONS

This is an initial implementation. Some advanced features may not be fully 
implemented yet:

- Limited error handling and reporting
- Some DBI attributes may not be fully supported
- Performance optimizations are ongoing

# DEPENDENCIES

- DBI 1.631 or higher
- FFI::Platypus 2.00 or higher
- libsql C library (must be installed separately)

# INSTALLATION

Before installing this module, you need to install the libsql C library. 
Please refer to the libsql documentation for installation instructions:

    https://github.com/tursodatabase/libsql

Then install this Perl module:

    cpanm DBD::libsql

# SEE ALSO

- [DBI](https://metacpan.org/pod/DBI) - Database independent interface for Perl
- [DBD::SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite) - Similar driver for SQLite
- [https://turso.tech/](https://turso.tech/) - Turso database service
- [https://github.com/tursodatabase/libsql](https://github.com/tursodatabase/libsql) - libsql project

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
