package DBD::libsql::FFI;
use strict;
use warnings;
use FFI::Platypus 2.00;
use Carp;

# FFI bindings for libsql
our $ffi;

sub new {
    my ($class, %options) = @_;
    
    my $self = bless {
        ffi => undef,
        lib_path => $options{lib_path},
    }, $class;
    
    $self->_init_ffi();
    return $self;
}

sub _init_ffi {
    my $self = shift;
    
    $ffi = FFI::Platypus->new( api => 2 );
    
    # Try to find and load libsql library
    my @lib_paths = (
        'libsql',           # System library
        './libsql.so',      # Local shared library  
        './libsql.dylib',   # macOS
        './libsql.dll',     # Windows
        $self->{lib_path},  # User specified path
    );
    
    my $loaded = 0;
    for my $lib_path (@lib_paths) {
        next unless defined $lib_path;
        eval {
            $ffi->lib($lib_path);
            $loaded = 1;
        };
        last if $loaded;
    }
    
    unless ($loaded) {
        croak "Could not load libsql library. Please ensure libsql is installed and accessible.";
    }
    
    # Define FFI function signatures
    $self->_define_functions();
    $self->{ffi} = $ffi;
}

sub _define_functions {
    my $self = shift;
    
    # Database functions
    eval {
        $ffi->attach( 'libsql_database_open' => ['string'] => 'opaque' );
        $ffi->attach( 'libsql_database_close' => ['opaque'] => 'void' );
        
        # Connection functions  
        $ffi->attach( 'libsql_database_connect' => ['opaque'] => 'opaque' );
        $ffi->attach( 'libsql_connection_close' => ['opaque'] => 'void' );
        
        # Statement functions
        $ffi->attach( 'libsql_connection_prepare' => ['opaque', 'string'] => 'opaque' );
        $ffi->attach( 'libsql_statement_finalize' => ['opaque'] => 'void' );
        $ffi->attach( 'libsql_statement_step' => ['opaque'] => 'int' );
        $ffi->attach( 'libsql_statement_reset' => ['opaque'] => 'void' );
        
        # Parameter binding
        $ffi->attach( 'libsql_statement_bind_text' => ['opaque', 'int', 'string'] => 'int' );
        $ffi->attach( 'libsql_statement_bind_int' => ['opaque', 'int', 'int'] => 'int' );
        $ffi->attach( 'libsql_statement_bind_double' => ['opaque', 'int', 'double'] => 'int' );
        $ffi->attach( 'libsql_statement_bind_null' => ['opaque', 'int'] => 'int' );
        
        # Result retrieval
        $ffi->attach( 'libsql_statement_column_count' => ['opaque'] => 'int' );
        $ffi->attach( 'libsql_statement_column_name' => ['opaque', 'int'] => 'string' );
        $ffi->attach( 'libsql_statement_column_text' => ['opaque', 'int'] => 'string' );
        $ffi->attach( 'libsql_statement_column_int' => ['opaque', 'int'] => 'int' );
        $ffi->attach( 'libsql_statement_column_double' => ['opaque', 'int'] => 'double' );
        $ffi->attach( 'libsql_statement_column_type' => ['opaque', 'int'] => 'int' );
        
        # Transaction functions
        $ffi->attach( 'libsql_connection_execute' => ['opaque', 'string'] => 'int' );
    };
    
    if ($@) {
        warn "Some FFI functions could not be attached: $@";
    }
}

# Wrapper methods for easier use
sub open_database {
    my ($self, $path) = @_;
    return libsql_database_open($path);
}

sub connect_database {
    my ($self, $db_handle) = @_;
    return libsql_database_connect($db_handle);
}

sub prepare_statement {
    my ($self, $conn_handle, $sql) = @_;
    return libsql_connection_prepare($conn_handle, $sql);
}

sub execute_sql {
    my ($self, $conn_handle, $sql) = @_;
    return libsql_connection_execute($conn_handle, $sql);
}

sub step_statement {
    my ($self, $stmt_handle) = @_;
    return libsql_statement_step($stmt_handle);
}

sub bind_text {
    my ($self, $stmt_handle, $index, $value) = @_;
    return libsql_statement_bind_text($stmt_handle, $index, $value);
}

sub bind_int {
    my ($self, $stmt_handle, $index, $value) = @_;
    return libsql_statement_bind_int($stmt_handle, $index, $value);
}

sub bind_double {
    my ($self, $stmt_handle, $index, $value) = @_;
    return libsql_statement_bind_double($stmt_handle, $index, $value);
}

sub bind_null {
    my ($self, $stmt_handle, $index) = @_;
    return libsql_statement_bind_null($stmt_handle, $index);
}

sub column_count {
    my ($self, $stmt_handle) = @_;
    return libsql_statement_column_count($stmt_handle);
}

sub column_name {
    my ($self, $stmt_handle, $index) = @_;
    return libsql_statement_column_name($stmt_handle, $index);
}

sub column_text {
    my ($self, $stmt_handle, $index) = @_;
    return libsql_statement_column_text($stmt_handle, $index);
}

sub column_int {
    my ($self, $stmt_handle, $index) = @_;
    return libsql_statement_column_int($stmt_handle, $index);
}

sub column_double {
    my ($self, $stmt_handle, $index) = @_;
    return libsql_statement_column_double($stmt_handle, $index);
}

sub column_type {
    my ($self, $stmt_handle, $index) = @_;
    return libsql_statement_column_type($stmt_handle, $index);
}

# Constants
use constant {
    LIBSQL_ROW => 100,
    LIBSQL_DONE => 101,
    LIBSQL_OK => 0,
    
    # Column types
    LIBSQL_INTEGER => 1,
    LIBSQL_FLOAT => 2,
    LIBSQL_TEXT => 3,
    LIBSQL_BLOB => 4,
    LIBSQL_NULL => 5,
};

1;

__END__

=head1 NAME

DBD::libsql::FFI - FFI bindings for libsql C library

=head1 DESCRIPTION

This module provides FFI (Foreign Function Interface) bindings to the libsql 
C library for use by DBD::libsql.

=head1 METHODS

=head2 new(%options)

Creates a new FFI instance and loads the libsql library.

=head2 open_database($path)

Opens a libsql database at the specified path.

=head2 connect_database($db_handle)

Creates a connection to an opened database.

=head2 prepare_statement($conn_handle, $sql)

Prepares an SQL statement for execution.

=head2 execute_sql($conn_handle, $sql)

Executes an SQL statement directly.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut
