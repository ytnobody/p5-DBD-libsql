# Extended Testing (xt/)

This directory contains extended tests that require external dependencies or specific runtime environments.

## Quick Start

1. **Install turso CLI** (recommended via Alien::Turso::CLI):
   ```bash
   # Option 1: Use Alien::Turso::CLI (recommended for development)
   cpanm Alien::Turso::CLI
   
   # Option 2: Manual installation
   curl -sSfL https://get.tur.so/install.sh | bash
   ```

2. **Install development dependencies**:
   ```bash
   cpanm --installdeps --with-develop .
   ```

2. **Start turso dev server**:
   ```bash
   # Start in background
   turso dev --port 8080 &
   
   # Or start in separate terminal
   turso dev
   ```

3. **Run the tests**:
   ```bash
   # All developer tests
   prove -Ilib xt/
   
   # Specific tests
   prove -Ilib xt/01_integration.t
   prove -Ilib xt/02_smoke.t
   ```

## Test Files

- **`01_integration.t`** - Full integration test suite with libsql server
- **`02_smoke.t`** - Quick smoke test for basic functionality

## Test Requirements

- turso CLI installed and in PATH
- Network access to localhost:8080
- Perl modules: LWP::UserAgent, JSON, Protocol::WebSocket

## Troubleshooting

### turso dev not starting
```bash
# Check if port is in use
lsof -i :8080

# Try different port
turso dev --port 8081
```

### Tests failing with connection errors
```bash
# Verify server is running
curl http://127.0.0.1:8080/health

# Check server logs
turso dev --verbose
```

### Missing dependencies
```bash
# Install missing Perl modules
cpanm --installdeps .
```

## Test Coverage

The integration tests cover:

- ✅ Hrana protocol communication
- ✅ DBI connection management
- ✅ SQL operations (CREATE, INSERT, SELECT, UPDATE, DELETE)
- ✅ Parameter binding
- ✅ Transaction support
- ✅ Data fetching (arrayref, hashref)
- ✅ Error handling
- ✅ Memory database support
- ✅ Connection cleanup

## Development Workflow

1. Make changes to `lib/DBD/libsql.pm` or `lib/DBD/libsql/Hrana.pm`
2. Start `turso dev` if not running
3. Run smoke test: `prove -Ilib xt/02_smoke.t`
4. If smoke test passes, run full suite: `prove -Ilib xt/`
5. Verify regular tests still pass: `prove -Ilib t/`

## Notes

- Tests use temporary tables and clean up after themselves
- The `01_integration.t` can auto-start turso dev server if needed
- All tests handle graceful failures when server is unavailable
- Tests verify HTTP-only libsql server communication