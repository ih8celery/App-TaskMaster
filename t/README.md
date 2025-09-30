# Test Suite Documentation

This directory contains the test suite for App-Devel-Todo.

## Test Files

### Smoke Tests
- **00-use.t** - Module loading tests
  - Verifies all modules can be loaded without errors
  - Checks basic compilation

### Unit Tests

- **10-lib-new.t** - Constructor tests
  - Tests `Devel::Todo->new()` constructor
  - Verifies object creation with configuration
  - Tests with temporary YAML files

- **20-lib-add.t** - Add element functionality
  - Tests `Add_Element()` method
  - Single item addition
  - Multiple items at once
  - Sublist creation with items
  - Tests `has_element()` for verification

- **30-lib-show.t** - Display functionality
  - Tests `Show_Element()` method
  - Non-verbose output
  - Verbose output (with descriptions)
  - Status filtering
  - Sublist display

- **40-lib-edit.t** - Edit functionality
  - Tests `Edit_Element()` method
  - Tests `get_attributes()` method
  - Status modification
  - Priority setting
  - Description updates

- **50-lib-delete.t** - Delete functionality
  - Tests `Delete_Element()` method
  - Single item deletion
  - Status-based filtering (only deletes matching status)
  - Sublist item deletion
  - Bulk deletion with status filtering

- **60-lib-util.t** - Utility functions
  - Tests `has_element()` with various paths
  - Case sensitivity checking
  - Tests `apply_to_matches()` callback mechanism
  - Sublist element checking

### Integration Tests

- **70-app-config.t** - Application configuration
  - Tests `get_possible_subcommand()`
  - Tests `process_args()` argument parsing
  - Tests `configure_app()` configuration loading
  - Custom status definition
  - Configuration merging

## Running Tests

### All Tests
```bash
prove -l t/
```

### Specific Test
```bash
perl -Ilib t/10-lib-new.t
```

### With Verbosity
```bash
prove -lv t/
```

### With Coverage
```bash
cover -test -ignore_re '^t/'
cover -report html
```

## Test Data

Tests use `File::Temp` to create temporary YAML files, ensuring:
- Test isolation
- No side effects
- Clean automatic cleanup

## Test Coverage

Target coverage metrics:
- **Line coverage**: >80%
- **Branch coverage**: >70%
- **Function coverage**: >90%

Current coverage: Run `cover -test && cover -report text` to see current metrics.

## Writing New Tests

When adding new tests:

1. Follow the existing naming convention: `NN-category-feature.t`
2. Use `Test::More` for assertions
3. Use `File::Temp` for temporary files
4. Clean up resources in test
5. Document what the test covers
6. Add to this README

### Test Template

```perl
#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw/tempfile/;
use YAML::XS qw/DumpFile/;

use Devel::Todo;

plan tests => N;  # Or use done_testing()

# Test setup
my ($fh, $file) = tempfile();
close $fh;

my $yaml = {
  name     => 'test',
  contents => {
    item => 'do'
  }
};

DumpFile($file, $yaml);

my $config = {
    STATUS              => 'do',
    MOVE_ENABLED        => 1,
    DEFAULT_STATUS      => 'do',
    DEFAULT_PRIORITY    => 0,
    DEFAULT_DESCRIPTION => '',
    VERBOSE             => 0,
};

my $todo = Devel::Todo->new($file, $config);

# Tests
ok($todo->has_element('item'), 'test description');

done_testing();
```

## Continuous Integration

Tests run automatically on:
- Push to main/master/develop branches
- Pull requests
- Multiple Perl versions (5.16 - 5.38)

See `.github/workflows/test.yml` for CI configuration.

## Debugging Tests

### Verbose Output
```bash
prove -lv t/10-lib-new.t
```

### With Debugger
```bash
perl -d -Ilib t/10-lib-new.t
```

### Show Test Output
```bash
perl -Ilib t/10-lib-new.t
```

## Test Dependencies

Required for testing:
- Test::More >0.96
- Test::Output
- File::Temp >0.22
- YAML::XS

Optional for enhanced testing:
- Test::Exception
- Test::Warnings
- Devel::Cover (for coverage reports)

## Known Issues

None currently. Report issues at:
https://github.com/ih8celery/App-Devel-Todo/issues