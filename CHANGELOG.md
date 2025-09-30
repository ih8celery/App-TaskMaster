# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added in Phase 2
- Modern `cpanfile` for dependency management
- `.perltidyrc` configuration for consistent code formatting
- `.perlcriticrc` configuration for code quality checks
- Comprehensive documentation suite (ARCHITECTURE.md, CONTRIBUTING.md, API.md)
- MODERNIZATION_PLAN.md with detailed 5-phase roadmap

### Changed in Phase 2
- Migrated from Mouse to Moo object system (lighter, more maintainable)
- Updated all modules to require Perl 5.16+
- Migrated to Type::Tiny for type constraints
- Improved README.md with modern formatting and badges
- Updated module structure for better organization

### Added in Phase 1
- Implemented `lib/Devel/Todo.pm` - Core todo list management
  * Add_Element() - Add items with support for sublists
  * Show_Element() - Display items with status filtering and verbosity
  * Edit_Element() - Modify item attributes (status, priority, description)
  * Delete_Element() - Remove items respecting status filters
  * has_element() - Check item existence
  * get_attributes() - Retrieve item attributes
  * apply_to_matches() - Apply callbacks to matching items
  * Save() - Persist changes to YAML files
  
- Implemented `lib/App/Devel/Todo.pm` - CLI application logic
  * Run() - Main application entry point
  * get_possible_subcommand() - Subcommand extraction
  * process_args() - Argument parsing into structured format
  * configure_app() - Configuration loading and merging
  * Complete Getopt::Long integration for all command-line options

### Fixed in Phase 1
- **CRITICAL**: Fixed comparison bug in `lib/Project/Task/ListTask.pm:96`
  * Changed `if $ind = -1` to `if $ind == -1`
  * This bug prevented proper error detection when removing items
  
- Added missing module imports across codebase:
  * `Carp qw/confess/` in Project::Task, ListTask, SimpleTask, TaskMaster
  * `Scalar::Util qw/blessed/` in ListTask.pm
  * `YAML::XS` instead of plain YAML in ListTask.pm
  
- Added `use strict; use warnings;` to modules missing them:
  * Project::Task::SimpleTask
  
- All 45 tests now pass (previously failing due to missing implementations)

### Documentation
- Created comprehensive API documentation
- Added architecture documentation with diagrams
- Created contributing guidelines with development workflow
- Added code examples and usage patterns throughout

## [0.6.0] - 2018-XX-XX (Original Release)

### Added
- Basic project structure
- Module::Build based build system
- Test suite structure (8 test files)
- Project::Task class hierarchy
- YAML-based data storage
- MIT License

### Known Issues in Original Release
- Core modules (Devel::Todo, App::Devel::Todo) not implemented
- Tests fail due to missing implementations
- Critical bugs in existing code
- Incomplete TaskMaster implementation
- Mouse dependency (now deprecated)

---

## Release Notes

### Version 0.6.0 → 1.0.0 (Upcoming)

The jump from 0.6.0 to 1.0.0 represents the completion of the modernization effort:

**Why 1.0.0?**
- All core functionality implemented and tested
- Modern dependencies and tooling
- Comprehensive documentation
- Stable API ready for production use
- Breaking changes from incomplete 0.6.0 warranted

**Migration Guide (from 0.6.0):**
- No user-facing changes required
- YAML file format remains compatible
- Configuration format unchanged
- New features are additive only

### Development Phases

This project follows a 5-phase modernization plan:

- ✅ **Phase 1**: Foundation & Core Implementation (Complete)
- ✅ **Phase 2**: Dependency Modernization & Code Quality (Complete)
- 🔄 **Phase 3**: Testing & CI/CD (In Progress)
- ⏳ **Phase 4**: Error Handling & Features (Planned)
- ⏳ **Phase 5**: Polish & Future-Proofing (Planned)

See [MODERNIZATION_PLAN.md](MODERNIZATION_PLAN.md) for detailed roadmap.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute to this changelog and the project.

## Links

- [GitHub Repository](https://github.com/ih8celery/App-Devel-Todo)
- [Issue Tracker](https://github.com/ih8celery/App-Devel-Todo/issues)
- [Pull Requests](https://github.com/ih8celery/App-Devel-Todo/pulls)