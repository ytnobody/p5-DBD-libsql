
# NAME

DBD::libsql - DBI driver for libsql database

# SYNOPSIS

    use DBI;
    
    # Connect to a local libsql database via turso dev
    my $dbh = DBI->connect("dbi:libsql:http://127.0.0.1:8080", "", "");
    
    # Connect to a remote libsql database (Turso)
    my $dbh = DBI->connect("dbi:libsql:libsql://your-database.turso.io", 
                          "", "your-auth-token");
    
    # Connect to memory database
    my $dbh = DBI->connect("dbi:libsql::memory:", "", "");
    
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

This driver provides a standard DBI interface to libsql databases using the Hrana 
protocol over HTTP/WebSocket, allowing you to use familiar Perl DBI methods to 
interact with both local libsql servers (via `turso dev`) and remote libsql 
database instances.

## Architecture

- **Protocol**: Hrana (libsql's native protocol)
- **Transport**: HTTP/HTTPS with WebSocket support
- **Local Development**: `turso dev` server
- **Remote Databases**: Turso and compatible services
- **Compatibility**: Standard DBI interface

## Getting Started

### Local Development

1. Install turso CLI:
   ```bash
   curl -sSfL https://get.tur.so/install.sh | bash
   ```

2. Start local libsql server:
   ```bash
   turso dev
   ```

3. Connect using DBD::libsql:
   ```perl
   my $dbh = DBI->connect("dbi:libsql:http://127.0.0.1:8080", "", "");
   ```

### Remote Databases

1. Create a Turso database
2. Get your database URL and auth token
3. Connect:
   ```perl
   my $dbh = DBI->connect("dbi:libsql:libsql://your-db.turso.io", "", "your-token");
   ```

## Development

For local development and testing, you can use the developer test suite in the `xt/` directory:

```bash
# Install development dependencies (includes Alien::Turso::CLI)
cpanm --installdeps --with-develop .

# Run developer tests with auto-managed turso dev server
prove -Ilib xt/
```

The test suite automatically manages a local `turso dev` server for integration testing.

# AUTHOR

ytnobody <ytnobody@gmail.com>

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
