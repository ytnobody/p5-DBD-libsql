requires 'perl', '5.008001';
requires 'DBI', '1.631';
requires 'FFI::Platypus', '2.00';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'DBD::SQLite', '1.66';  # for testing comparison
};

