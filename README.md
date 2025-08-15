
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
        print "ID: ", $row->{id}, ", Name: ", $row->{name}, "\n";
    }
    
    $dbh->disconnect;

# DESCRIPTION

DBD::libsql is a DBI driver for libsql databases. libsql is a fork of SQLite that 
supports both local and remote database connections, including Turso's hosted 
database service.

This driver provides a standard DBI interface to libsql databases, allowing you 
to use familiar Perl DBI methods to interact with both local SQLite-compatible 
files and remote libsql database instances.

# AUTHOR

ytnobody <ytnobody@gmail.com>

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
