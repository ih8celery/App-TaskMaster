# Project Modernization Plan

## Executive Summary

This document outlines a comprehensive modernization strategy for the App-Devel-Todo project, a Perl-based command-line todo list manager. The project currently uses outdated practices and has incomplete implementation. This plan provides a phased approach to modernize the codebase, improve maintainability, and align with current Perl best practices.

**Project Status:** Legacy Perl project (circa 2018) with incomplete implementation
**Target:** Modern, maintainable Perl application with CI/CD and comprehensive testing

---

## Current State Analysis

### Strengths
- Clear conceptual design with hierarchical todo list support
- MIT licensed (permissive)
- Basic test coverage structure in place
- Uses YAML for data storage (human-readable)
- Modular architecture with separation of concerns

### Critical Issues
1. **Missing Core Modules**: `Devel::Todo` and `App::Devel::Todo` modules are referenced but not implemented
2. **Outdated Dependencies**: Uses Mouse instead of modern Moo/Moose
3. **Incomplete Implementation**: Test files reference non-existent functionality
4. **No CI/CD**: No automated testing or deployment pipeline
5. **Legacy Build System**: Uses Module::Build (deprecated in favor of ExtUtils::MakeMaker or Dist::Zilla)
6. **Inconsistent Code Style**: Mixed coding conventions
7. **Limited Error Handling**: Bugs in error checking (e.g., `if $ind = -1` should be `==`)
8. **No Logging**: No structured logging mechanism
9. **Missing Documentation**: No architecture docs, contributing guidelines, or API documentation
10. **Project/Task classes appear abandoned**: New TaskMaster architecture started but incomplete

### Technical Debt
- Mouse is largely unmaintained; should migrate to Moo
- Module::Build is discouraged; move to modern tools
- No perltidy/perlcritic configuration
- No dependency version pinning
- Inconsistent use of `confess` without proper error classes

---

## Modernization Roadmap

### Phase 1: Foundation & Documentation (Week 1)
**Objective**: Establish clear documentation and fix critical bugs

#### PR1: Core Module Implementation & Bug Fixes
- **Priority**: CRITICAL
- **Scope**:
  - Implement missing `lib/Devel/Todo.pm` module based on test expectations
  - Implement missing `lib/App/Devel/Todo.pm` module
  - Fix bug in `ListTask.pm` line 96: `if $ind = -1` → `if $ind == -1`
  - Fix missing `blessed` import in `ListTask.pm`
  - Add missing `confess` imports where used
  - Ensure all tests pass

#### PR2: Documentation Suite
- **Priority**: HIGH
- **Scope**:
  - Create `ARCHITECTURE.md` - System design and module relationships
  - Create `CONTRIBUTING.md` - Development guidelines
  - Create `API.md` - Public API documentation
  - Update `README.md` - Modern formatting, badges, quick start
  - Add inline POD documentation to all modules
  - Create `CHANGELOG.md` following Keep a Changelog format

### Phase 2: Code Modernization (Week 2)
**Objective**: Upgrade to modern Perl practices

#### PR3: Dependency Modernization
- **Priority**: HIGH
- **Scope**:
  - Replace Mouse with Moo (lighter, actively maintained)
  - Create `cpanfile` for modern dependency management
  - Pin all dependency versions
  - Update minimum Perl version requirement (5.16+ recommended)
  - Remove deprecated Module::Build configuration

#### PR4: Code Quality & Style
- **Priority**: MEDIUM
- **Scope**:
  - Add `.perltidyrc` configuration
  - Add `.perlcriticrc` with severity 4 policies
  - Apply perltidy to all Perl files
  - Fix all perlcritic violations (or document exceptions)
  - Add `use strict; use warnings;` to all files consistently
  - Add `use v5.16;` or higher for modern features

### Phase 3: Testing & CI/CD (Week 3)
**Objective**: Ensure code quality through automation

#### PR5: Enhanced Testing Infrastructure
- **Priority**: HIGH
- **Scope**:
  - Add Test::Exception for better error testing
  - Add Test::Warnings to catch unexpected warnings
  - Increase test coverage to >80%
  - Add integration tests for full workflows
  - Add performance/benchmark tests
  - Document testing approach in `t/README.md`

#### PR6: CI/CD Pipeline
- **Priority**: HIGH
- **Scope**:
  - Create `.github/workflows/test.yml` - Run tests on multiple Perl versions (5.16, 5.30, 5.38)
  - Create `.github/workflows/lint.yml` - Run perlcritic and perltidy checks
  - Create `.github/workflows/coverage.yml` - Track code coverage with Devel::Cover
  - Add status badges to README
  - Set up automated releases with GitHub Actions

### Phase 4: Architecture & Features (Week 4)
**Objective**: Improve error handling and add modern features

#### PR7: Error Handling & Logging
- **Priority**: MEDIUM
- **Scope**:
  - Implement custom exception classes using Throwable
  - Replace `confess` with structured exceptions
  - Add Log::Log4perl for structured logging
  - Add `--verbose` and `--debug` flags
  - Log to `~/.todo/logs/` by default
  - Add proper error messages with context

#### PR8: Configuration Management
- **Priority**: MEDIUM
- **Scope**:
  - Use Config::Tiny or similar for config parsing
  - Support JSON config in addition to YAML
  - Add config validation
  - Support XDG Base Directory specification
  - Add `todo config` subcommand to manage settings

### Phase 5: Polish & Future-Proofing (Week 5)
**Objective**: Add nice-to-have features and prepare for future growth

#### PR9: Developer Experience
- **Priority**: LOW
- **Scope**:
  - Add `Makefile.PL` with ExtUtils::MakeMaker
  - Add Docker support for development
  - Create development environment setup script
  - Add EditorConfig for consistent formatting
  - Add pre-commit hooks with Git::Hooks

#### PR10: Feature Enhancements
- **Priority**: LOW
- **Scope**:
  - Add JSON output format option
  - Add color output with Term::ANSIColor
  - Add bash/zsh completion scripts
  - Add `todo search` functionality
  - Add due dates and reminders
  - Export to different formats (markdown, org-mode)

---

## Technology Stack Upgrades

### Current → Proposed

| Component | Current | Proposed | Reason |
|-----------|---------|----------|--------|
| Object System | Mouse | Moo | Actively maintained, lighter, no XS required |
| Build System | Module::Build | ExtUtils::MakeMaker + cpanfile | Industry standard, better toolchain support |
| YAML Parser | YAML::XS | YAML::XS | Keep (fast and reliable) |
| Testing | Test::More | Test2::Suite | Modern test framework with better diagnostics |
| CLI Parsing | Getopt::Long | Getopt::Long | Keep (stable and sufficient) |
| Error Handling | confess | Throwable + Try::Tiny | Structured exceptions |
| Logging | None | Log::Log4perl | Industry standard logging |

---

## Implementation Guidelines

### Code Standards
1. **Perl Version**: Minimum 5.16 (released 2012)
2. **Style Guide**: Follow Perl Best Practices (PBP) where practical
3. **Documentation**: All public methods must have POD documentation
4. **Testing**: All new code must have tests (aim for >80% coverage)
5. **Error Messages**: Must be actionable and include context

### Git Workflow
1. Create feature branch from `main`: `git checkout -b feature/pr1-core-modules`
2. Make atomic commits with descriptive messages
3. Run tests locally before pushing: `prove -l t/`
4. Create PR with description referencing this plan
5. Require CI passing before merge
6. Squash merge to keep history clean

### Version Numbering
- Follow Semantic Versioning (semver.org)
- Current: 0.006000 → Convert to 0.6.0
- Next release after modernization: 1.0.0

---

## Risk Assessment

### High Risk
- **Breaking API Changes**: Modernization may break existing user configs
  - **Mitigation**: Provide migration script, maintain backward compatibility where possible
  
### Medium Risk
- **Test Failures**: Existing tests may need significant updates
  - **Mitigation**: Fix tests incrementally, document test expectations

### Low Risk
- **Dependency Conflicts**: New dependencies may conflict with user environments
  - **Mitigation**: Use minimal, well-maintained dependencies; test on multiple Perl versions

---

## Success Metrics

### Phase 1
- [ ] All existing tests pass
- [ ] Documentation coverage: 100% of modules
- [ ] Zero critical bugs

### Phase 2
- [ ] All dependencies modern and actively maintained
- [ ] Perlcritic severity 4 or higher: zero violations
- [ ] Code formatted consistently

### Phase 3
- [ ] CI/CD pipeline functioning on 3+ Perl versions
- [ ] Test coverage: >80%
- [ ] Automated release process working

### Phase 4
- [ ] Zero uses of bare `die` or `confess`
- [ ] All errors are actionable
- [ ] Logging implemented in all modules

### Phase 5
- [ ] Developer onboarding time: <15 minutes
- [ ] At least 2 new features implemented
- [ ] User documentation complete

---

## Timeline Summary

| Phase | Duration | PRs | Completion Criteria |
|-------|----------|-----|---------------------|
| Phase 1 | Week 1 | PR1-2 | Docs complete, tests pass |
| Phase 2 | Week 2 | PR3-4 | Modern dependencies, clean code |
| Phase 3 | Week 3 | PR5-6 | CI/CD running, >80% coverage |
| Phase 4 | Week 4 | PR7-8 | Proper error handling, logging |
| Phase 5 | Week 5 | PR9-10 | Dev tools, new features |

**Total Estimated Time**: 5 weeks

---

## Post-Modernization Maintenance

### Ongoing Tasks
1. **Dependencies**: Review and update quarterly
2. **Security**: Monitor CVEs, update vulnerable dependencies immediately
3. **Testing**: Maintain >80% coverage
4. **Documentation**: Keep in sync with code changes
5. **Community**: Respond to issues within 1 week

### Future Considerations
1. Web interface using Mojolicious
2. Mobile app with REST API backend
3. Sync capabilities across devices
4. Plugin system for extensibility
5. Database backend option (SQLite) as alternative to YAML

---

## Resources

### Documentation
- Perl Best Practices: https://www.oreilly.com/library/view/perl-best-practices/0596001738/
- Modern Perl: http://modernperlbooks.com/books/modern_perl_2016/
- CPAN Modules: https://metacpan.org/

### Tools
- Perlbrew: Manage multiple Perl versions
- cpanm: Modern CPAN client
- Devel::Cover: Code coverage analysis
- Perl::Critic: Static code analysis

### Communities
- #perl on irc.perl.org
- /r/perl on Reddit
- PerlMonks: https://perlmonks.org/

---

## Conclusion

This modernization plan transforms App-Devel-Todo from a legacy, incomplete project into a modern, maintainable Perl application. The phased approach allows for incremental progress while maintaining functionality. Each PR is scoped to be independently valuable and reviewable.

The plan prioritizes critical fixes first (Phase 1), then modernization (Phase 2-3), and finally enhancements (Phase 4-5). This ensures the project reaches a stable, usable state quickly while laying groundwork for future improvements.

**Next Steps**: Begin Phase 1, PR1 - Implement missing core modules and fix critical bugs.