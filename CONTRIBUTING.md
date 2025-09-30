# Contributing to App-Devel-Todo

Thank you for your interest in contributing to App-Devel-Todo! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Release Process](#release-process)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in all interactions.

### Expected Behavior

- Be respectful of differing viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling or insulting/derogatory comments
- Publishing others' private information
- Any other conduct inappropriate in a professional setting

## Getting Started

### Prerequisites

- Perl 5.16 or higher
- cpanm (CPAN minus) for installing dependencies
- Git for version control
- A GitHub account

### Quick Start

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/App-Devel-Todo.git
   cd App-Devel-Todo
   ```

3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/ih8celery/App-Devel-Todo.git
   ```

4. Install dependencies:
   ```bash
   cpanm --installdeps .
   ```

5. Run tests to ensure everything works:
   ```bash
   prove -l t/
   ```

## Development Setup

### Using Perlbrew (Recommended)

Perlbrew allows you to manage multiple Perl installations:

```bash
# Install perlbrew
\curl -L https://install.perlbrew.pl | bash

# Install a recent Perl version
perlbrew install perl-5.38.0
perlbrew switch perl-5.38.0

# Install cpanm
perlbrew install-cpanm
```

### Installing Development Dependencies

```bash
# Core dependencies
cpanm Getopt::Long
cpanm YAML::XS
cpanm Mouse  # Will be replaced with Moo in modernization

# Testing dependencies
cpanm Test::More
cpanm Test::Output
cpanm File::Temp
cpanm Test::Exception
cpanm Test::Warnings

# Development tools
cpanm Perl::Critic
cpanm Perl::Tidy
cpanm Devel::Cover
```

### Editor Setup

#### VS Code
Install extensions:
- Perl Navigator
- Perl

Create `.vscode/settings.json`:
```json
{
  "perlnavigator.perltidyProfile": ".perltidyrc",
  "perlnavigator.perlcriticProfile": ".perlcriticrc",
  "perlnavigator.enableWarnings": true
}
```

#### Vim/Neovim
Use vim-perl plugin and ALE for linting:
```vim
Plug 'vim-perl/vim-perl'
Plug 'dense-analysis/ale'

let g:ale_linters = {'perl': ['perl', 'perlcritic']}
let g:ale_fixers = {'perl': ['perltidy']}
```

## Project Structure

```
App-Devel-Todo/
├── bin/
│   └── todo              # Executable entry point
├── lib/
│   ├── App/
│   │   └── TaskMaster.pm # Alternate architecture (incomplete)
│   ├── Project/
│   │   ├── Task.pm       # Base task class
│   │   └── Task/
│   │       ├── SimpleTask.pm  # Single task
│   │       └── ListTask.pm    # Task container
│   └── [TO BE CREATED]
│       ├── App/Devel/Todo.pm  # Main app logic
│       └── Devel/Todo.pm      # Core functionality
├── t/                    # Test files
│   ├── 00-use.t         # Module loading
│   ├── 10-lib-new.t     # Constructor tests
│   ├── 20-lib-add.t     # Add functionality
│   ├── 30-lib-show.t    # Show functionality
│   ├── 40-lib-edit.t    # Edit functionality
│   ├── 50-lib-delete.t  # Delete functionality
│   ├── 60-lib-util.t    # Utilities
│   └── 70-app-config.t  # Configuration
├── Build.PL             # Build configuration
├── META.yml            # Metadata
├── MANIFEST            # File list
├── README.md           # User documentation
├── LICENSE             # MIT License
├── ARCHITECTURE.md     # Architecture docs
├── CONTRIBUTING.md     # This file
└── MODERNIZATION_PLAN.md  # Modernization roadmap
```

## Coding Standards

### Perl Style Guide

We follow **Perl Best Practices** (PBP) with some modifications:

#### General Guidelines

1. **Always use strict and warnings**:
   ```perl
   use strict;
   use warnings;
   use v5.16;  # Or higher
   ```

2. **Indentation**: 2 spaces (not tabs)
   ```perl
   sub example {
     my ($self, $arg) = @_;
     
     if ($condition) {
       do_something();
     }
   }
   ```

3. **Line Length**: Maximum 100 characters

4. **Naming Conventions**:
   - Variables: `$lowercase_with_underscores`
   - Functions: `lowercase_with_underscores`
   - Packages: `CamelCase::With::Colons`
   - Constants: `UPPERCASE_WITH_UNDERSCORES`

#### Documentation

**Every module must have POD documentation**:

```perl
package My::Module;

use strict;
use warnings;

=head1 NAME

My::Module - Brief description

=head1 SYNOPSIS

  use My::Module;
  
  my $obj = My::Module->new();
  $obj->do_something();

=head1 DESCRIPTION

Detailed description of what this module does.

=head1 METHODS

=head2 new

Constructor.

=head2 do_something

Does something useful.

=cut

sub new {
  my ($class, %args) = @_;
  return bless \%args, $class;
}

sub do_something {
  my ($self) = @_;
  # Implementation
}

1;

=head1 AUTHOR

Your Name <your.email@example.com>

=head1 LICENSE

This software is Copyright (c) 2025 by Adam Marshall.

This is free software, licensed under the MIT License.

=cut
```

#### Error Handling

Use Try::Tiny and custom exceptions (post-modernization):

```perl
use Try::Tiny;
use App::Todo::Exception;

try {
  my $result = risky_operation();
}
catch {
  App::Todo::Exception->throw(
    message => "Operation failed",
    context => { input => $data }
  );
};
```

During transition, use `confess` from Carp:

```perl
use Carp qw/confess/;

confess "Parameter 'name' is required" unless defined $name;
```

#### Object-Oriented Code

Current (Mouse):
```perl
use Mouse;

has 'name' => (
  is  => 'rw',
  isa => 'Str',
  required => 1
);
```

Target (Moo):
```perl
use Moo;
use Types::Standard qw/Str/;

has name => (
  is  => 'rw',
  isa => Str,
  required => 1
);
```

### Perl::Critic

Code must pass Perl::Critic at severity 4:

```bash
perlcritic --severity 4 lib/
```

Common policies to follow:
- `RequireUseStrict`
- `RequireUseWarnings`
- `ProhibitBarewordFileHandles`
- `RequireCheckedSyscalls`

### Perltidy Configuration

Use the project's `.perltidyrc`:

```bash
perltidy -b lib/My/Module.pm  # -b creates backup
```

Format before committing:
```bash
find lib t bin -name '*.pm' -o -name '*.pl' -o -name 'todo' | xargs perltidy -b
```

## Testing

### Writing Tests

#### Test Structure

```perl
#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw/tempfile/;

# Test setup
plan tests => 5;

# Test cases
subtest 'constructor' => sub {
  my $obj = MyModule->new();
  isa_ok($obj, 'MyModule');
  can_ok($obj, qw/method1 method2/);
};

subtest 'basic functionality' => sub {
  my $obj = MyModule->new(name => 'test');
  is($obj->name, 'test', 'name attribute set');
  
  $obj->name('new_name');
  is($obj->name, 'new_name', 'name attribute changed');
};

subtest 'error handling' => sub {
  dies_ok { MyModule->new() } 'dies without required params';
  like(
    exception { MyModule->new() },
    qr/required/,
    'error message mentions required'
  );
};

done_testing();
```

#### Test Coverage

- **Minimum**: 80% line coverage
- **Target**: 90% line coverage

Check coverage:
```bash
perl -MDevel::Cover=-coverage,statement,branch,condition,subroutine \
  -Ilib t/10-lib-new.t

cover -report html
# Open cover_db/coverage.html in browser
```

### Running Tests

```bash
# Run all tests
prove -l t/

# Run specific test
prove -lv t/10-lib-new.t

# Run with coverage
perl -MDevel::Cover prove -l t/

# Run tests verbosely
prove -lv t/
```

### Test Categories

1. **Unit Tests** (`t/10-*.t` to `t/60-*.t`)
   - Test individual functions/methods
   - Use mocks/stubs for dependencies
   - Fast execution

2. **Integration Tests** (`t/70-*.t`)
   - Test module interactions
   - Use real dependencies
   - Test complete workflows

3. **Smoke Tests** (`t/00-*.t`)
   - Basic "does it load?" tests
   - Run first to catch critical issues

## Submitting Changes

### Branch Naming

- Feature: `feature/short-description`
- Bug fix: `bugfix/issue-number-description`
- Documentation: `docs/what-you-are-documenting`
- Refactor: `refactor/what-you-are-refactoring`

Examples:
```bash
git checkout -b feature/add-json-export
git checkout -b bugfix/123-fix-list-deletion
git checkout -b docs/update-api-documentation
```

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples**:

```
feat(cli): add JSON output format option

Implement --format=json flag to output todo lists as JSON.
This allows easier integration with other tools.

Closes #45
```

```
fix(ListTask): correct comparison operator in remove method

Change assignment operator (=) to comparison operator (==)
in line 96 of ListTask.pm. This bug prevented proper error
checking when removing items.

Fixes #123
```

### Pre-Commit Checklist

Before committing, ensure:

- [ ] Code follows style guidelines
- [ ] All tests pass: `prove -l t/`
- [ ] New code has tests (>80% coverage)
- [ ] Documentation updated (if needed)
- [ ] No perlcritic violations: `perlcritic --severity 4 lib/`
- [ ] Code formatted: `perltidy -b <changed-files>`
- [ ] POD documentation added for new methods
- [ ] CHANGELOG.md updated (for significant changes)

## Pull Request Process

### Before Creating PR

1. **Sync with upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run full test suite**:
   ```bash
   prove -l t/
   ```

3. **Check for issues**:
   ```bash
   perlcritic --severity 4 lib/
   ```

### Creating the PR

1. Push your branch:
   ```bash
   git push origin feature/your-feature
   ```

2. Go to GitHub and create Pull Request

3. Fill out the PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to break)
- [ ] Documentation update

## Testing
- [ ] All existing tests pass
- [ ] Added new tests for changes
- [ ] Manual testing performed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] CHANGELOG.md updated (if applicable)

## Related Issues
Closes #123
Related to #456
```

### PR Review Process

1. **Automated Checks**: CI must pass (tests, linting)
2. **Code Review**: At least one maintainer approval required
3. **Revisions**: Address reviewer feedback
4. **Merge**: Squash merge to keep history clean

### After Merge

1. Delete your branch:
   ```bash
   git branch -d feature/your-feature
   git push origin --delete feature/your-feature
   ```

2. Update your local main:
   ```bash
   git checkout main
   git pull upstream main
   ```

## Issue Guidelines

### Reporting Bugs

Use the bug report template:

```markdown
**Describe the bug**
Clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Run command '...'
2. See error

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Environment**
- OS: [e.g., Linux, macOS, Windows]
- Perl version: [e.g., 5.38.0]
- App-Devel-Todo version: [e.g., 0.6.0]

**Additional context**
Any other relevant information.
```

### Requesting Features

Use the feature request template:

```markdown
**Is your feature request related to a problem?**
Clear description of the problem.

**Describe the solution you'd like**
Clear description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features.

**Additional context**
Any other relevant information, mockups, examples.
```

### Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed
- `wontfix`: This will not be worked on
- `duplicate`: This issue already exists

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

Examples:
- `0.6.0` → `0.6.1` (bug fix)
- `0.6.1` → `0.7.0` (new feature)
- `0.7.0` → `1.0.0` (breaking change or first stable release)

### Release Checklist

For maintainers:

1. Update version in:
   - `Build.PL`
   - `META.yml`
   - All module `$VERSION` variables

2. Update `CHANGELOG.md`:
   ```markdown
   ## [0.7.0] - 2025-10-15
   
   ### Added
   - JSON export functionality
   
   ### Fixed
   - ListTask removal bug
   
   ### Changed
   - Migrated from Mouse to Moo
   ```

3. Commit version bump:
   ```bash
   git commit -am "chore: bump version to 0.7.0"
   ```

4. Tag release:
   ```bash
   git tag -a v0.7.0 -m "Release version 0.7.0"
   git push upstream main --tags
   ```

5. Create GitHub Release with changelog excerpt

6. Upload to CPAN (if applicable):
   ```bash
   perl Build.PL
   ./Build dist
   cpan-upload App-Devel-Todo-0.7.0.tar.gz
   ```

## Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: General questions, ideas
- **Email**: maintainer@example.com

### Resources

- [Perl Documentation](https://perldoc.perl.org/)
- [Modern Perl Book](http://modernperlbooks.com/)
- [Perl Best Practices](https://www.oreilly.com/library/view/perl-best-practices/0596001738/)
- [Project Architecture](ARCHITECTURE.md)
- [Modernization Plan](MODERNIZATION_PLAN.md)

## Recognition

### Contributors

All contributors will be recognized in:
- `AUTHORS` file
- GitHub contributors page
- Release notes (for significant contributions)

### Types of Contributions

We value all contributions:
- Code (features, bug fixes)
- Documentation
- Testing
- Bug reports
- Feature suggestions
- Code reviews
- Spreading the word

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to App-Devel-Todo! Your efforts help make this project better for everyone.