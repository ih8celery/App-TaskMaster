# API Documentation

## Overview

This document describes the public API for App-Devel-Todo modules. It covers both the command-line interface and the programmatic Perl API for developers who want to integrate todo list functionality into their own applications.

---

## Command-Line Interface

### Synopsis

```bash
todo [subcommand] [options] [arguments]
```

### Subcommands

Subcommands determine which items are selected based on their status:

#### `do`
Select items with "do" status (things to be done).

```bash
todo do                    # Show all "do" items
todo do "write code"       # Add new "do" item
todo do -S                 # Show all "do" items (explicit)
```

#### `did`
Select items with "did" status (completed items).

```bash
todo did                   # Show all "did" items
todo did -S                # Show all "did" items (explicit)
```

#### `want`
Select items with "want" status (things you want to do).

```bash
todo want                  # Show all "want" items
todo want "learn Perl"     # Add new "want" item
```

#### `all`
Select all items regardless of status.

```bash
todo all                   # Show everything
todo all -S                # Show everything (explicit)
```

**Custom Subcommands**: You can define additional statuses in `~/.todorc.yml`.

### Global Options

#### `-h, --help`
Print help information.

```bash
todo -h                    # General help
todo do -h                 # Help for "do" subcommand
```

#### `-v, --version`
Print version information.

```bash
todo -v
# Output: todo v0.6.0
```

#### `-S, --show`
Display items from the current selection.

```bash
todo do -S                 # Show items with "do" status
todo all -S                # Show all items
```

#### `-C, --create`
Add new items to the list. Can move items from other statuses.

```bash
todo do -C "new task"
todo do -C code. docs tests   # Create sublist
```

#### `-N, --create-no-move`
Add new items without allowing moves from other statuses.

```bash
todo do -N "new task"
```

#### `-E, --edit`
Modify item attributes.

```bash
todo do -E "task name" -s want           # Change status
todo do -E "task name" -d "description"  # Add description
todo do -E "task name" -p 1              # Set priority
```

#### `-D, --delete`
Remove items from the list.

```bash
todo do -D "task name"
todo do -D code."subtask"      # Delete from sublist
```

#### `-s, --use-status`
Specify status when creating or editing items.

```bash
todo do -C "task" -s want      # Create with "want" status
```

#### `-d, --use-description`
Specify description when creating or editing items.

```bash
todo do -C "task" -d "This is what the task involves"
```

#### `-p, --use-priority`
Specify priority (integer) when creating or editing items.

```bash
todo do -C "task" -p 1         # Priority 1 (high)
todo do -C "task" -p 0         # Priority 0 (default)
```

#### `-f, --config-file`
Use alternative configuration file instead of `~/.todorc.yml`.

```bash
todo do -f ~/custom-config.yml
```

#### `-t, --todo-file`
Use alternative todo list file instead of `.todos`.

```bash
todo do -t ~/my-project/.custom-todos
```

### Arguments

Arguments identify items and specify operations:

#### Keys
End with `.` to indicate a sublist.

```bash
todo do project.           # Create/select "project" sublist
```

#### Values
Simple strings without `.` are item names.

```bash
todo do "write code"       # Add item "write code"
todo do task1 task2        # Add two items
```

#### Key-Value Pairs
Separated by `.` to add items to sublists.

```bash
todo do project."write tests"         # Add to "project" sublist
todo do project.task1="description"   # Add with description
```

#### Descriptions
Append `=` to add description inline.

```bash
todo do task="Task description here"
```

### Examples

#### Basic Usage

```bash
# Show what needs to be done
todo do

# Add a simple task
todo do "write documentation"

# Add multiple tasks
todo do "write code" "write tests"

# Show completed items
todo did
```

#### Working with Sublists

```bash
# Create sublist with items
todo do project. "design" "implement" "test"

# Show specific sublist
todo do -S project

# Add to existing sublist
todo do project."add feature"

# Delete from sublist
todo do -D project.design
```

#### Editing Items

```bash
# Change task status
todo do -E "write code" -s did

# Add description
todo do -E "write code" -d "Implement user authentication"

# Set priority
todo do -E "fix bug" -p 1

# Combined edit
todo do -E "task" -s want -d "description" -p 2
```

#### Configuration

```bash
# Use different config
todo do -f ~/.todorc-work.yml

# Use different todo file
todo do -t ~/projects/my-app/.todos
```

---

## Perl API

### Modules

#### `Devel::Todo`

Core module for managing todo lists.

##### Constructor

```perl
my $todo = Devel::Todo->new($file, $config);
```

**Parameters**:
- `$file` (String): Path to YAML todo list file
- `$config` (HashRef): Configuration options

**Configuration Hash**:
```perl
{
    STATUS              => 'do',        # Current filter status
    MOVE_ENABLED        => 1,           # Allow moving items between statuses
    STATUS_OPT          => '',          # Status override for operations
    PRIORITY_OPT        => '',          # Priority override
    DESCRIPTION_OPT     => '',          # Description override
    DEFAULT_STATUS      => 'do',        # Default for new items
    DEFAULT_PRIORITY    => 0,           # Default priority
    DEFAULT_DESCRIPTION => '',          # Default description
    VERBOSE             => 0,           # Show descriptions in output
}
```

**Returns**: `Devel::Todo` object

**Example**:
```perl
use Devel::Todo;

my $config = {
    STATUS         => 'do',
    MOVE_ENABLED   => 1,
    DEFAULT_STATUS => 'do',
    VERBOSE        => 0,
};

my $todo = Devel::Todo->new('.todos', $config);
```

##### Methods

###### `Add_Element($items)`

Add one or more items to the todo list.

**Parameters**:
- `$items` (ArrayRef): Array of items to add

**Item Formats**:
- Simple string: `"task name"`
- With sublist: `["sublist_name", ["item1", "item2"]]`

**Returns**: Nothing

**Example**:
```perl
# Add single item
$todo->Add_Element(['write code']);

# Add multiple items
$todo->Add_Element(['task1', 'task2', 'task3']);

# Add sublist with items
$todo->Add_Element([
    ['project', ['design', 'implement', 'test']]
]);
```

###### `Show_Element($path)`

Display items, optionally filtered by path and status.

**Parameters**:
- `$path` (ArrayRef): Path to sublist (empty for root)

**Returns**: Nothing (prints to STDOUT)

**Output Format**:
- Non-verbose: Item names only
- Verbose: `item_name (description)`
- Sublists: Indented with `:` after name

**Example**:
```perl
# Show all items with current status
$todo->Show_Element([]);

# Show specific sublist
$todo->Show_Element(['project']);

# Verbose output
$config->{VERBOSE} = 1;
$todo->Show_Element([]);
```

###### `Edit_Element($path, $attributes)`

Modify attributes of an existing item.

**Parameters**:
- `$path` (ArrayRef): Path to item
- `$attributes` (HashRef): Attributes to change

**Attributes**:
```perl
{
    status      => 'want',           # New status
    description => 'New description',
    priority    => 2,                # New priority
}
```

**Returns**: Nothing

**Example**:
```perl
# Change status
$todo->Edit_Element(['task name'], { status => 'did' });

# Change multiple attributes
$todo->Edit_Element(['task name'], {
    status      => 'want',
    description => 'Updated description',
    priority    => 1,
});
```

###### `Delete_Element($path)`

Remove an item from the todo list.

**Parameters**:
- `$path` (ArrayRef): Path to item

**Returns**: Nothing

**Example**:
```perl
# Delete root-level item
$todo->Delete_Element(['task name']);

# Delete from sublist
$todo->Delete_Element(['project', 'subtask']);
```

###### `has_element($name, ...)`

Check if item exists in the list.

**Parameters**:
- `$name` (String): Item name at current level
- Additional path elements (optional)

**Returns**: Boolean

**Example**:
```perl
# Check root level
if ($todo->has_element('task name')) {
    print "Task exists\n";
}

# Check in sublist
if ($todo->has_element('project', 'subtask')) {
    print "Subtask exists\n";
}
```

###### `Save()`

Persist changes to disk.

**Parameters**: None

**Returns**: Nothing

**Example**:
```perl
$todo->Add_Element(['new task']);
$todo->Save();  # Write to file
```

---

#### `Project::Task`

Base class for task objects. Not typically instantiated directly.

##### Attributes

```perl
has 'name'    => (is => 'rw', isa => 'Str');
has 'summary' => (is => 'rw', isa => 'Str');
has 'taglist' => (is => 'bare', isa => 'HashRef');
```

##### Methods

###### `tag($tagname)`

Add a tag to the task.

**Parameters**:
- `$tagname` (String): Tag to add

**Returns**: Nothing

**Example**:
```perl
$task->tag('urgent');
$task->tag('work');
```

###### `untag($tagname)`

Remove a tag from the task.

**Parameters**:
- `$tagname` (String): Tag to remove

**Returns**: Nothing

**Example**:
```perl
$task->untag('urgent');
```

###### `has_tag($tagname)`

Check if task has a specific tag.

**Parameters**:
- `$tagname` (String): Tag to check

**Returns**: Boolean

**Example**:
```perl
if ($task->has_tag('urgent')) {
    print "This is urgent!\n";
}
```

---

#### `Project::Task::SimpleTask`

Represents a single, atomic task.

##### Constructor

```perl
my $task = Project::Task::SimpleTask->new(
    name    => 'task name',
    summary => 'Task description',
    taglist => { urgent => 1 }
);
```

##### Methods

###### `execute($action)`

Execute the task or return its description.

**Parameters**:
- `$action` (CodeRef, optional): Callback to execute

**Returns**: String (task description) or result of callback

**Example**:
```perl
# Get description
my $desc = $task->execute();

# Execute with callback
$task->execute(sub {
    my ($task) = @_;
    print "Executing: " . $task->name . "\n";
    # Do something
    return "Done";
});
```

---

#### `Project::Task::ListTask`

Represents a container of tasks (list).

##### Constructor

```perl
my $list = Project::Task::ListTask->new(
    name     => 'project',
    summary  => 'Project tasks',
    contents => []
);
```

##### Attributes

```perl
has 'contents' => (is => 'rw', isa => 'ArrayRef');
```

##### Methods

###### `find(@path)`

Navigate task hierarchy by path.

**Parameters**:
- `@path` (Array): List of task names forming path

**Returns**: `ListTask` object or `undef`

**Example**:
```perl
# Find sublist
my $sublist = $list->find('project', 'subtasks');

# Find at root
my $root = $list->find();
```

###### `insert($childAttrs)`

Add new task to the list.

**Parameters**:
- `$childAttrs` (HashRef): Task attributes

**Required Attributes**:
```perl
{
    name    => 'task name',     # Required
    summary => 'Description',   # Optional
    taglist => { ... },         # Optional
    contents => [...]           # Optional (makes it a ListTask)
}
```

**Returns**: Nothing

**Example**:
```perl
# Add simple task
$list->insert({
    name    => 'new task',
    summary => 'Task description'
});

# Add sublist
$list->insert({
    name     => 'sublist',
    summary  => 'Sublist description',
    contents => []
});
```

###### `remove($childName)`

Delete task from the list.

**Parameters**:
- `$childName` (String): Name of task to remove

**Returns**: Nothing

**Throws**: Exception if task doesn't exist

**Example**:
```perl
$list->remove('task name');
```

###### `execute($subtaskName)`

Execute a specific subtask or all subtasks.

**Parameters**:
- `$subtaskName` (String, optional): Name of specific subtask

**Returns**: Nothing (prints output)

**Example**:
```perl
# Execute specific subtask
$list->execute('task1');

# Execute all subtasks
$list->execute();
```

###### `describe($subtaskName)`

Print task description(s).

**Parameters**:
- `$subtaskName` (String, optional): Name of specific subtask

**Returns**: Nothing (prints output)

**Example**:
```perl
# Describe specific subtask
$list->describe('task1');

# Describe all subtasks
$list->describe();
```

###### `loadfile($file)` (Class Method)

Load task hierarchy from YAML file.

**Parameters**:
- `$file` (String): Path to YAML file

**Returns**: `ListTask` object

**Example**:
```perl
my $list = Project::Task::ListTask->loadfile('.tasks.yml');
```

###### `dumpfile($file)`

Save task hierarchy to YAML file.

**Parameters**:
- `$file` (String): Path to YAML file

**Returns**: Nothing

**Example**:
```perl
$list->dumpfile('.tasks.yml');
```

---

#### `App::Devel::Todo`

Application-level functions (exported when using `:tests` tag).

##### Functions

###### `get_possible_subcommand()`

Extract potential subcommand from `@ARGV`.

**Parameters**: None (uses global `@ARGV`)

**Returns**: 
- `($subcommand, $result)` where `$result` is success boolean

**Side Effects**: Shifts `@ARGV` if subcommand found

**Example**:
```perl
use App::Devel::Todo qw/:tests/;

local @ARGV = ('do', 'task1', 'task2');
my ($sub, $result) = get_possible_subcommand();
# $sub = 'do'
# @ARGV = ('task1', 'task2')
```

###### `process_args()`

Parse remaining arguments into structured data.

**Parameters**: None (uses global `@ARGV`)

**Returns**: 
- `($args, $result)` where `$args` is ArrayRef of parsed arguments

**Argument Parsing**:
- `"task"` → `"task"`
- `"list."` starts sublist
- Following items go into sublist until another `.`

**Example**:
```perl
local @ARGV = ('task1', 'list.', 'item1', 'item2');
my ($args, $result) = process_args();
# $args = ['task1', ['list', ['item1', 'item2']]]
```

###### `configure_app($file, $stati)`

Load configuration from file and merge with defaults.

**Parameters**:
- `$file` (String): Path to config file
- `$stati` (HashRef): Hash of valid statuses

**Returns**: 
- `($result, $defaults)` where `$defaults` is merged config

**Configuration Options**:
```yaml
# ~/.todorc.yml
verbose: 1
statuses:
  maybe: "consider later"
  blocked: "blocked by dependencies"
default_status: do
default_priority: 0
```

**Example**:
```perl
my $stati = { do => 1, did => 1, want => 1 };
my ($result, $config) = configure_app('~/.todorc.yml', $stati);

# $stati now includes custom statuses
# $config contains merged defaults
```

---

## Data Formats

### YAML Todo List Format

```yaml
---
name: project_name
contents:
  simple_task: do
  
  task_with_details:
    status: want
    description: Detailed description here
    priority: 1
  
  sublist:
    contents:
      subtask1: do
      subtask2: did
```

### Configuration File Format

```yaml
---
verbose: 1
statuses:
  maybe: "consider doing this later"
  blocked: "waiting on external dependency"
  review: "needs code review"
default_status: do
default_priority: 0
```

---

## Error Handling

### Exceptions

Currently, errors are thrown using `confess` from `Carp`:

```perl
use Carp qw/confess/;

confess "Parameter 'name' is required" unless defined $name;
```

### Common Errors

#### File Not Found
```
Error: Cannot load file '.todos': No such file or directory
```

**Solution**: Create todo file or specify correct path with `-t`

#### Invalid YAML
```
Error: YAML syntax error in '.todos' at line 5
```

**Solution**: Check YAML syntax, ensure proper indentation

#### Item Not Found
```
Error: Task 'nonexistent' does not exist in list
```

**Solution**: Verify item name, check spelling

#### Duplicate Item
```
Error: Task name must not already be present in ListTask
```

**Solution**: Use unique names or edit existing item

---

## Complete Examples

### Example 1: Basic Todo Management

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Devel::Todo;

my $config = {
    STATUS         => 'do',
    DEFAULT_STATUS => 'do',
    VERBOSE        => 0,
};

my $todo = Devel::Todo->new('.todos', $config);

# Add tasks
$todo->Add_Element(['write code', 'write tests', 'write docs']);

# Show tasks
$todo->Show_Element([]);

# Mark task as done
$todo->Edit_Element(['write code'], { status => 'did' });

# Save changes
$todo->Save();
```

### Example 2: Working with Projects

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Devel::Todo;

my $config = {
    STATUS         => 'do',
    DEFAULT_STATUS => 'do',
    VERBOSE        => 1,  # Show descriptions
};

my $todo = Devel::Todo->new('.todos', $config);

# Create project with subtasks
$todo->Add_Element([
    ['web_app', [
        'design UI',
        'implement backend',
        'write tests',
        'deploy'
    ]]
]);

# Add details to subtask
$todo->Edit_Element(['web_app', 'design UI'], {
    description => 'Create mockups and wireframes',
    priority    => 1
});

# Show project tasks
$todo->Show_Element(['web_app']);

$todo->Save();
```

### Example 3: Using Task Objects Directly

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Project::Task::ListTask;
use Project::Task::SimpleTask;

# Create task hierarchy
my $project = Project::Task::ListTask->new(
    name    => 'my_project',
    summary => 'My awesome project'
);

# Add tasks
$project->insert({
    name    => 'task1',
    summary => 'First task'
});

$project->insert({
    name    => 'task2',
    summary => 'Second task'
});

# Save to file
$project->dumpfile('.tasks.yml');

# Load from file
my $loaded = Project::Task::ListTask->loadfile('.tasks.yml');

# Execute all tasks
$loaded->execute();
```

---

## Version History

- **0.6.0**: Current version
- **1.0.0**: Planned stable release after modernization

---

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines
- [MODERNIZATION_PLAN.md](MODERNIZATION_PLAN.md) - Roadmap
- [README.md](README.md) - User guide