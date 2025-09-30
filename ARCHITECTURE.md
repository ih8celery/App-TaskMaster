# Architecture Documentation

## Overview

App-Devel-Todo is a command-line application for managing hierarchical todo lists stored as YAML files. The architecture follows a layered design with clear separation between CLI interface, application logic, and data models.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
├─────────────────────────────────────────────────────────────┤
│  bin/todo                                                    │
│  ├─ Entry point                                              │
│  └─ Delegates to App::Devel::Todo                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Application Logic Layer                    │
├─────────────────────────────────────────────────────────────┤
│  App::Devel::Todo                                            │
│  ├─ Command-line argument parsing                           │
│  ├─ Configuration management                                │
│  ├─ Subcommand routing (do/did/want/all)                   │
│  └─ Operations: Create, Show, Edit, Delete                  │
│                                                              │
│  lib/App/TaskMaster.pm (Alternate/Future Architecture)      │
│  └─ Mouse-based CLI app (currently incomplete)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Model Layer                      │
├─────────────────────────────────────────────────────────────┤
│  Devel::Todo                                                 │
│  ├─ Core todo list management                               │
│  ├─ YAML serialization/deserialization                      │
│  └─ Methods: Add_Element, Show_Element, Edit_Element, etc.  │
│                                                              │
│  Project::Task (Base Class)                                  │
│  ├─ name: Str                                                │
│  ├─ summary: Str                                             │
│  └─ taglist: HashRef                                         │
│                                                              │
│  Project::Task::SimpleTask                                   │
│  └─ Represents a single task item                           │
│                                                              │
│  Project::Task::ListTask                                     │
│  ├─ Represents a todo list containing tasks                 │
│  ├─ contents: ArrayRef                                       │
│  └─ Methods: find, insert, remove, loadfile, dumpfile       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Persistence Layer                   │
├─────────────────────────────────────────────────────────────┤
│  YAML::XS                                                    │
│  ├─ LoadFile() - Read YAML from disk                        │
│  └─ DumpFile() - Write YAML to disk                         │
│                                                              │
│  File Locations:                                             │
│  ├─ ~/.todorc.yml   - User configuration                    │
│  └─ .todos          - Project-specific todo list            │
└─────────────────────────────────────────────────────────────┘
```

## Module Responsibilities

### Core Modules

#### `App::Devel::Todo`
**Status**: To be implemented
**Purpose**: Main application controller and CLI interface
**Responsibilities**:
- Parse command-line arguments using Getopt::Long
- Handle subcommands (do, did, want, all)
- Manage configuration from `~/.todorc.yml`
- Coordinate between CLI input and Devel::Todo operations
- Format and display output

**Key Functions**:
- `get_possible_subcommand()` - Extract status subcommand from @ARGV
- `process_args()` - Parse remaining arguments into structured data
- `configure_app($file, $stati)` - Load and merge configuration
- `Run()` - Main entry point for application execution

#### `Devel::Todo`
**Status**: To be implemented
**Purpose**: Core business logic for todo list management
**Responsibilities**:
- Manage todo list items (add, remove, edit, show)
- Handle item attributes (status, priority, description)
- Support hierarchical lists (sublists)
- Serialize/deserialize to YAML format
- Filter items by status

**Key Methods**:
- `new($file, $conf)` - Constructor, loads todo list from file
- `Add_Element($items)` - Add one or more items to list
- `Show_Element($path)` - Display items, optionally filtered
- `Edit_Element($path, $attrs)` - Modify item attributes
- `Delete_Element($path)` - Remove item from list
- `has_element($name, ...)` - Check if item exists
- `Save()` - Persist changes to disk

**Configuration Hash**:
```perl
{
    STATUS              => 'do',        # Current filter status
    MOVE_ENABLED        => 1,           # Allow moving items between statuses
    STATUS_OPT          => '',          # Override status for operations
    PRIORITY_OPT        => '',          # Override priority
    DESCRIPTION_OPT     => '',          # Override description
    DEFAULT_STATUS      => 'do',        # Default for new items
    DEFAULT_PRIORITY    => 0,           # Default priority
    DEFAULT_DESCRIPTION => '',          # Default description
    VERBOSE             => 0,           # Show descriptions in output
}
```

### Task Hierarchy (Project::Task Family)

#### `Project::Task` (Base Class)
**Purpose**: Abstract base class for all task types
**Attributes**:
- `name` (Str) - Unique identifier for the task
- `summary` (Str) - Human-readable description
- `taglist` (HashRef) - Set of tags for categorization

**Methods**:
- `tag($tagname)` - Add a tag to the task
- `untag($tagname)` - Remove a tag
- `has_tag($tagname)` - Check if task has tag

#### `Project::Task::SimpleTask`
**Purpose**: Represents a single, atomic task
**Inherits**: Project::Task
**Methods**:
- `execute($action)` - Run an action callback or return task description

#### `Project::Task::ListTask`
**Purpose**: Represents a container of tasks (list of tasks)
**Inherits**: Project::Task
**Attributes**:
- `contents` (ArrayRef) - Array of SimpleTask or ListTask objects

**Methods**:
- `find(@path)` - Navigate task hierarchy by path
- `insert($childAttrs)` - Add new task to contents
- `remove($childName)` - Delete task from contents
- `execute($subtaskName)` - Execute task or all tasks in list
- `describe($subtaskName)` - Display task information
- `loadfile($file)` - Class method to deserialize from YAML
- `dumpfile($file)` - Serialize task tree to YAML

### Alternate Architecture (App::TaskMaster)

**Status**: Incomplete/Experimental
**Purpose**: Alternative implementation using CLI::CommandLineApp framework
**Notes**: This appears to be an abandoned attempt to refactor the application. Currently non-functional and references non-existent `CLI::CommandLineApp` module.

**Should be removed or completed in future refactoring.**

## Data Model

### YAML Structure

#### Simple Todo List
```yaml
---
name: today
contents:
  wake: did
  eat: want
  sleep: do
  code:
    status: do
    description: Work on todo app
    priority: 1
```

#### Hierarchical Todo List
```yaml
---
name: project
contents:
  documentation:
    status: do
    contents:
      write README: did
      write API docs: do
  testing:
    status: want
    contents:
      unit tests: do
      integration tests: want
```

#### Configuration File (~/.todorc.yml)
```yaml
---
verbose: 1
statuses:
  maybe: "consider doing this later"
  blocked: "waiting on external dependency"
default_status: do
default_priority: 0
```

### Object Model

```
Project::Task (Abstract)
  ├─ name: String
  ├─ summary: String
  └─ taglist: { tag1 => 1, tag2 => 1 }

Project::Task::SimpleTask extends Project::Task
  └─ (no additional attributes)

Project::Task::ListTask extends Project::Task
  └─ contents: [
       Project::Task::SimpleTask { name => "task1", ... },
       Project::Task::ListTask { 
         name => "sublist",
         contents => [ ... ]
       }
     ]
```

## Control Flow

### Adding an Item

```
User: todo do "write code"
  │
  ├─> bin/todo
  │     └─> App::Devel::Todo::Run()
  │           ├─> get_possible_subcommand()  # Returns "do"
  │           ├─> process_args()              # Returns ["write code"]
  │           └─> Devel::Todo->new($file, $conf)
  │                 ├─> Load YAML from .todos
  │                 └─> Add_Element(["write code"])
  │                       ├─> Create item with status "do"
  │                       ├─> Add to contents hash
  │                       └─> Save() to disk
  │
  └─> Output: (none on success)
```

### Showing Items

```
User: todo do -S
  │
  ├─> bin/todo
  │     └─> App::Devel::Todo::Run()
  │           ├─> get_possible_subcommand()  # Returns "do"
  │           ├─> Parse -S flag              # Show operation
  │           └─> Devel::Todo->new($file, $conf)
  │                 ├─> Load YAML from .todos
  │                 └─> Show_Element([])
  │                       ├─> Filter by STATUS="do"
  │                       ├─> Format output
  │                       └─> Print to stdout
  │
  └─> Output: sleep\neat\ncode\n
```

### Creating Sublist

```
User: todo do code. "write tests" "write docs"
  │
  ├─> bin/todo
  │     └─> App::Devel::Todo::Run()
  │           ├─> get_possible_subcommand()  # Returns "do"
  │           ├─> process_args()
  │           │     └─> Returns: [ ["code", ["write tests", "write docs"]] ]
  │           └─> Devel::Todo->new($file, $conf)
  │                 ├─> Load YAML from .todos
  │                 └─> Add_Element([ ["code", [...]] ])
  │                       ├─> Create "code" as sublist
  │                       ├─> Add "write tests" to code.contents
  │                       ├─> Add "write docs" to code.contents
  │                       └─> Save() to disk
  │
  └─> Output: (none on success)
```

## Design Patterns

### Patterns Used

1. **Template Method**: `Project::Task::execute()` can take optional action callback
2. **Composite**: `ListTask` can contain `SimpleTask` or other `ListTask` objects
3. **Serializer**: `loadfile()`/`dumpfile()` handle object persistence
4. **Command**: Subcommands (do/did/want) encapsulate operations
5. **Strategy**: Status filtering behavior can be configured

### Anti-Patterns to Address

1. **God Object**: `Devel::Todo` may become too large (needs refactoring)
2. **Magic Numbers**: Status strings hardcoded ("do", "did", "want")
3. **Error Handling**: Uses `confess` instead of structured exceptions
4. **Tight Coupling**: Hard dependency on YAML format

## Configuration Management

### Configuration Hierarchy

1. **Built-in defaults** (in code)
2. **User config** `~/.todorc.yml` (overrides defaults)
3. **Command-line options** (overrides all)

### Configuration Loading

```perl
# Built-in defaults
my $defaults = {
    STATUS              => 'do',
    DEFAULT_STATUS      => 'do',
    DEFAULT_PRIORITY    => 0,
    DEFAULT_DESCRIPTION => '',
    VERBOSE             => 0,
};

# Load user config
my $user_config = load_yaml("$HOME/.todorc.yml");

# Merge configurations
my $config = { %$defaults, %$user_config };

# Apply command-line overrides
$config->{VERBOSE} = 1 if $opts{verbose};
```

## Extensibility Points

### Custom Statuses
Users can define new statuses in `~/.todorc.yml`:
```yaml
statuses:
  review: "needs code review"
  testing: "in QA testing"
```

### Custom Attributes
The YAML structure supports arbitrary attributes:
```yaml
my_task:
  status: do
  priority: 1
  description: "Do something"
  due_date: "2025-12-31"    # Custom attribute
  assigned_to: "alice"       # Custom attribute
```

### Argument Syntax
The flexible argument parser supports:
- Values: `"eat something"`
- Keys: `code.` (starts sublist)
- Key-value pairs: `code."write tests"`
- Descriptions: `code="Write some code"`

## Testing Strategy

### Unit Tests
- `00-use.t` - Module loading
- `10-lib-new.t` - Constructor tests
- `20-lib-add.t` - Adding elements
- `30-lib-show.t` - Displaying elements
- `40-lib-edit.t` - Editing elements
- `50-lib-delete.t` - Removing elements
- `60-lib-util.t` - Utility functions
- `70-app-config.t` - Configuration management

### Test Data
Tests use `File::Temp` to create temporary YAML files, ensuring isolation.

### Test Coverage Goals
- Line coverage: >80%
- Branch coverage: >70%
- Function coverage: >90%

## Known Issues

### Bugs
1. **Line 96 in ListTask.pm**: Assignment instead of comparison
   ```perl
   # BUG:
   if $ind = -1;
   # SHOULD BE:
   if $ind == -1;
   ```

2. **Missing import in ListTask.pm**: `blessed()` used but not imported
   ```perl
   # Need to add:
   use Scalar::Util qw/blessed/;
   ```

3. **Missing confess import**: Used without importing from Carp

### Incomplete Features
- TaskMaster architecture is non-functional
- Missing App::Devel::Todo implementation
- Missing Devel::Todo implementation
- No move functionality between statuses
- No priority-based sorting

## Dependencies

### Core Dependencies
- **Getopt::Long** (>2.24) - Command-line parsing
- **YAML::XS** - YAML serialization
- **Cwd** - Directory operations
- **File::Basename** - Path manipulation

### Development Dependencies
- **Mouse** - Object system (should migrate to Moo)
- **Test::More** (>0.9) - Test framework
- **Test::Output** - Testing STDOUT/STDERR
- **File::Temp** (>0.2) - Temporary file creation

### Build Dependencies
- **Module::Build** (>0.2) - Build system (deprecated)

## Performance Considerations

### File I/O
- YAML files loaded on every operation
- No caching of parsed data
- For large lists (>1000 items), consider:
  - SQLite backend
  - Incremental loading
  - In-memory caching

### Memory Usage
- Entire todo list loaded into memory
- Recursive data structures (sublists) may grow large
- Mouse object overhead

### Scalability Limits
- Single YAML file per project
- No concurrent access protection
- File locking should be implemented

## Security Considerations

### Input Validation
- No sanitization of user input
- YAML parsing could be vulnerable to malicious input
- File paths not validated

### File Permissions
- Config files should be user-readable only: `chmod 600 ~/.todorc.yml`
- Project files inherit directory permissions

### Recommendations
1. Validate file paths before operations
2. Set restrictive permissions on config files
3. Use LoadFile with safe mode
4. Implement file locking for concurrent access

## Future Architecture Considerations

### Potential Improvements

1. **Plugin System**
   - Allow custom commands
   - Custom output formats
   - Custom storage backends

2. **Database Backend**
   - SQLite for large lists
   - Full-text search
   - Better concurrent access

3. **API Layer**
   - REST API for web/mobile clients
   - WebSocket for real-time sync

4. **Event System**
   - Hooks for item changes
   - Integration with external tools
   - Notifications

## Conclusion

The current architecture is simple and functional for small to medium todo lists. The main areas needing improvement are:
1. Complete missing implementations
2. Improve error handling
3. Add proper logging
4. Modernize dependencies
5. Implement file locking
6. Add comprehensive input validation

The dual architecture (Devel::Todo and Project::Task families) suggests an incomplete refactoring. Decision needed: complete the refactoring or consolidate into a single architecture.