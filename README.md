[![Actions Status](https://github.com/ytnobody/p5-DBD-libsql/actions/workflows/test.yml/badge.svg)](https://github.com/ytnobody/p5-DBD-libsql/actions)
# NAME

DBD::libsql - DBI driver for libsql databases

# SYNOPSIS

    use DBI;
    
    # Connect to a libsql server
    my $dbh = DBI->connect('dbi:libsql:localhost', '', '', {
        RaiseError => 1,
        AutoCommit => 1,
    });
    
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

The Data Source Name (DSN) format for DBD::libsql uses smart defaults for easy configuration:

    dbi:libsql:hostname
    dbi:libsql:hostname?schema=https&port=8443

## Smart Defaults

The driver automatically detects the appropriate protocol and port based on the hostname:

- **Turso databases** (.turso.io domains) - Uses HTTPS on port 443
- **Localhost** - Uses HTTP on port 8080
- **Other hosts** - Uses HTTPS on port 443

## Examples

    # Turso Database (auto-detected: HTTPS, port 443)
    dbi:libsql:hono-prisma-ytnobody.aws-ap-northeast-1.turso.io
    
    # Local development server (auto-detected: HTTP, port 8080) 
    dbi:libsql:localhost
    
    # Custom configuration
    dbi:libsql:localhost?schema=http&port=3000
    dbi:libsql:api.example.com?schema=https&port=8443

# CONNECTION ATTRIBUTES

Standard DBI connection attributes are supported:

- RaiseError - Enable/disable automatic error raising
- AutoCommit - Enable/disable automatic transaction commit
- PrintError - Enable/disable error printing

# TURSO INTEGRATION

DBD::libsql provides seamless integration with Turso, the managed libsql service.

## Authentication

For Turso databases, authentication can be provided via:

- 1. Environment Variables (recommended)

        export TURSO_DATABASE_URL="libsql://my-db.aws-us-east-1.turso.io"
        export TURSO_DATABASE_TOKEN="your_auth_token"
        
        my $dbh = DBI->connect("dbi:libsql:my-db.aws-us-east-1.turso.io");

- 2. Connection Attributes

        my $dbh = DBI->connect(
            "dbi:libsql:my-db.aws-us-east-1.turso.io",
            "", "",
            {
                turso_token => "your_auth_token",
                RaiseError => 1,
            }
        );

## Getting Turso Credentials

1\. Install the Turso CLI: [https://docs.turso.tech/reference/turso-cli](https://docs.turso.tech/reference/turso-cli)
2\. Create a database: `turso db create my-database`
3\. Get the URL: `turso db show --url my-database`
4\. Create a token: `turso db tokens create my-database`

# DEVELOPMENT AND TESTING

## Running Tests

Basic tests (no external dependencies):

    prove -lv t/

Extended tests (requires turso CLI):

    # Install turso CLI first
    curl -sSfL https://get.tur.so/install.sh | bash
    
    # Start local turso dev server
    turso dev --port 8080 &
    
    # Run integration tests
    prove -lv xt/01_integration.t xt/02_smoke.t

Live Turso tests (optional):

    export TURSO_DATABASE_URL="libsql://your-db.region.turso.io"
    export TURSO_DATABASE_TOKEN="your_token"
    prove -lv xt/03_turso_live.t

## Test Coverage

The test suite covers:

- Hrana protocol communication
- DBI connection management  
- SQL operations (CREATE, INSERT, SELECT, UPDATE, DELETE)
- Parameter binding and prepared statements
- Transaction support (BEGIN, COMMIT, ROLLBACK)
- Data fetching (fetchrow\_arrayref, fetchrow\_hashref, fetchrow\_array)
- Error handling and graceful failures
- Turso authentication and live database operations

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
