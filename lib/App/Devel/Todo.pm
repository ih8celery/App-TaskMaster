#!/usr/bin/env perl

package App::Devel::Todo;

use strict;
use warnings;
use v5.16;

use Carp qw/confess/;
use Getopt::Long qw/:config gnu_getopt no_ignore_case/;
use YAML::XS qw/LoadFile/;
use File::Basename qw/basename/;
use Cwd qw/getcwd/;

use Devel::Todo;

our $VERSION = '0.006000';

use Exporter qw/import/;
our @EXPORT_OK = qw/get_possible_subcommand process_args configure_app Run/;
our %EXPORT_TAGS = (
  tests => [qw/get_possible_subcommand process_args configure_app/],
  all   => \@EXPORT_OK,
);

=head1 NAME

App::Devel::Todo - Command-line application for managing project todo lists

=head1 SYNOPSIS

  use App::Devel::Todo;
  Run();

Or from command line:

  todo do "write code"
  todo do -S
  todo did
  todo want "learn Perl"

=head1 DESCRIPTION

App::Devel::Todo provides the command-line interface and application logic
for the todo list manager. It handles argument parsing, configuration management,
and coordinates between user input and the Devel::Todo core functionality.

=head1 FUNCTIONS

=head2 Run()

Main entry point for the application. Processes command-line arguments and
executes the appropriate todo operations.

=cut

sub Run {
  # Get subcommand
  my ($subcommand, $result) = get_possible_subcommand();
  
  $subcommand //= 'do';  # Default to 'do' if none provided
  
  # Parse options
  my %opts;
  my $config_file = $ENV{HOME} ? "$ENV{HOME}/.todorc.yml" : '.todorc.yml';
  my $todo_file = '.todos';
  
  GetOptions(
    'h|help'              => \$opts{help},
    'v|version'           => \$opts{version},
    'S|show'              => \$opts{show},
    'C|create'            => \$opts{create},
    'N|create-no-move'    => \$opts{create_no_move},
    'E|edit'              => \$opts{edit},
    'D|delete'            => \$opts{delete},
    's|use-status=s'      => \$opts{use_status},
    'd|use-description=s' => \$opts{use_description},
    'p|use-priority=i'    => \$opts{use_priority},
    'f|config-file=s'     => \$config_file,
    't|todo-file=s'       => \$todo_file,
  ) or die "Error parsing options. Use --help for usage.\n";
  
  # Handle help
  if ($opts{help}) {
    print_help($subcommand);
    exit 0;
  }
  
  # Handle version
  if ($opts{version}) {
    print "todo v$VERSION\n";
    exit 0;
  }
  
  # Initialize status hash
  my $stati = {
    'do'   => 1,
    'did'  => 1,
    'want' => 1,
    'all'  => 1,
  };
  
  # Load configuration
  my ($conf_result, $defaults) = configure_app($config_file, $stati);
  
  # Set up config for Devel::Todo
  my $config = {
    STATUS              => $subcommand,
    MOVE_ENABLED        => 1,
    STATUS_OPT          => $opts{use_status} // '',
    PRIORITY_OPT        => $opts{use_priority} // '',
    DESCRIPTION_OPT     => $opts{use_description} // '',
    DEFAULT_STATUS      => $defaults->{default_status} // 'do',
    DEFAULT_PRIORITY    => $defaults->{default_priority} // 0,
    DEFAULT_DESCRIPTION => $defaults->{default_description} // '',
    VERBOSE             => $defaults->{verbose} // 0,
  };
  
  # Override with create-no-move
  if ($opts{create_no_move}) {
    $config->{MOVE_ENABLED} = 0;
  }
  
  # Process remaining arguments
  my ($args, $args_result) = process_args();
  
  # Load todo list
  my $todo = Devel::Todo->new($todo_file, $config);
  
  # Determine operation
  my $operation = _determine_operation(\%opts, $args);
  
  # Execute operation
  if ($operation eq 'show') {
    $todo->Show_Element($args && @$args > 0 ? $args : []);
  }
  elsif ($operation eq 'create') {
    if ($args && @$args > 0) {
      $todo->Add_Element($args);
    }
    else {
      die "Error: No items specified for creation\n";
    }
  }
  elsif ($operation eq 'edit') {
    if ($args && @$args > 0) {
      my $attrs = {};
      $attrs->{status} = $opts{use_status} if defined $opts{use_status};
      $attrs->{description} = $opts{use_description} if defined $opts{use_description};
      $attrs->{priority} = $opts{use_priority} if defined $opts{use_priority};
      
      foreach my $item (@$args) {
        if (ref $item eq 'ARRAY') {
          # Handle sublist paths
          die "Error: Cannot edit sublists directly\n";
        }
        else {
          $todo->Edit_Element([$item], $attrs);
        }
      }
    }
    else {
      die "Error: No items specified for editing\n";
    }
  }
  elsif ($operation eq 'delete') {
    if ($args && @$args > 0) {
      foreach my $item (@$args) {
        if (ref $item eq 'ARRAY') {
          # Handle sublist deletion
          $todo->Delete_Element([$item]);
        }
        else {
          $todo->Delete_Element([$item]);
        }
      }
    }
    else {
      # Delete all matching at root
      $todo->Delete_Element([]);
    }
  }
  
  return 0;
}

sub _determine_operation {
  my ($opts, $args) = @_;
  
  # Explicit operations
  return 'show' if $opts->{show};
  return 'create' if $opts->{create} || $opts->{create_no_move};
  return 'edit' if $opts->{edit};
  return 'delete' if $opts->{delete};
  
  # Implicit: if args provided, create; otherwise show
  if ($args && @$args > 0) {
    return 'create';
  }
  else {
    return 'show';
  }
}

=head2 get_possible_subcommand()

Extract potential subcommand from @ARGV. If first argument looks like a status
subcommand, removes it from @ARGV and returns it.

  my ($subcommand, $result) = get_possible_subcommand();

Returns: ($subcommand, $success)

=cut

sub get_possible_subcommand {
  # Check if first arg looks like a subcommand (alphanumeric, no special chars)
  if (@ARGV > 0 && $ARGV[0] =~ /^[a-zA-Z][a-zA-Z0-9_]*$/ && $ARGV[0] !~ /^-/) {
    my $sub = shift @ARGV;
    return ($sub, 1);
  }
  
  return (undef, 0);
}

=head2 process_args()

Parse remaining arguments from @ARGV into structured data format.

Arguments can be:
- Simple strings: "task name"
- Keys ending with '.': "list." (starts a sublist)
- Key-value pairs: "list.item" or "item=description"

Returns: ($args_arrayref, $success)

=cut

sub process_args {
  my @processed;
  my @current_sublist_items;
  my $current_sublist_name;
  
  foreach my $arg (@ARGV) {
    # Check if it's a key (ends with .)
    if ($arg =~ /^(.+)\.$/) {
      # Save previous sublist if any
      if (defined $current_sublist_name) {
        push @processed, [$current_sublist_name, [@current_sublist_items]];
        @current_sublist_items = ();
      }
      
      $current_sublist_name = $1;
    }
    # Check if it's a key-value pair (contains . but doesn't end with it)
    elsif ($arg =~ /^([^.]+)\.(.+)$/) {
      my ($key, $value) = ($1, $2);
      
      # Save previous sublist if any
      if (defined $current_sublist_name) {
        push @processed, [$current_sublist_name, [@current_sublist_items]];
        @current_sublist_items = ();
        $current_sublist_name = undef;
      }
      
      # Create a single-item sublist
      push @processed, [$key, [$value]];
    }
    else {
      # Regular value
      if (defined $current_sublist_name) {
        push @current_sublist_items, $arg;
      }
      else {
        push @processed, $arg;
      }
    }
  }
  
  # Save final sublist if any
  if (defined $current_sublist_name) {
    push @processed, [$current_sublist_name, [@current_sublist_items]];
  }
  
  return (\@processed, 1);
}

=head2 configure_app($file, $stati)

Load configuration from file and merge with defaults.

  my ($result, $defaults) = configure_app('~/.todorc.yml', $stati_hashref);

Returns: ($success, $defaults_hashref)

=cut

sub configure_app {
  my ($file, $stati) = @_;
  
  my $defaults = {
    verbose          => 0,
    default_status   => 'do',
    default_priority => 0,
  };
  
  return (1, $defaults) unless -e $file;
  
  my $config;
  eval {
    $config = LoadFile($file);
  };
  if ($@) {
    warn "Warning: Could not load config file '$file': $@\n";
    return (0, $defaults);
  }
  
  # Merge config into defaults
  if (ref $config eq 'HASH') {
    $defaults->{verbose} = $config->{verbose} if defined $config->{verbose};
    $defaults->{default_status} = $config->{default_status} if defined $config->{default_status};
    $defaults->{default_priority} = $config->{default_priority} if defined $config->{default_priority};
    $defaults->{default_description} = $config->{default_description} if defined $config->{default_description};
    
    # Add custom statuses
    if (exists $config->{statuses} && ref $config->{statuses} eq 'HASH') {
      foreach my $status (keys %{$config->{statuses}}) {
        $stati->{$status} = $config->{statuses}{$status};
      }
    }
  }
  
  return (1, $defaults);
}

sub print_help {
  my ($subcommand) = @_;
  
  print <<"HELP";
todo - manage your todo list

USAGE:
    todo [subcommand] [options] [arguments]

SUBCOMMANDS:
    do          Select items with "do" status (default)
    did         Select items with "did" status
    want        Select items with "want" status
    all         Select all items regardless of status

OPTIONS:
    -h, --help              Print this help message
    -v, --version           Print version information
    -S, --show              Show items from the list
    -C, --create            Add new items to the list
    -N, --create-no-move    Add new items without moving from other statuses
    -E, --edit              Edit item attributes
    -D, --delete            Remove items from the list
    -s, --use-status=STR    Specify status for create/edit operations
    -d, --use-description=STR  Specify description for create/edit operations
    -p, --use-priority=INT  Specify priority for create/edit operations
    -f, --config-file=FILE  Use alternative config file (default: ~/.todorc.yml)
    -t, --todo-file=FILE    Use alternative todo file (default: .todos)

ARGUMENTS:
    Arguments identify items and specify operations:
    
    - Simple values:     "task name"
    - Keys (sublists):   "project."
    - Key-value pairs:   "project.task"
    - With description:  "task=description"

EXAMPLES:
    todo do                          # Show all "do" items
    todo do "write code"             # Add new "do" item
    todo do project. docs tests      # Create sublist with items
    todo did -S                      # Show completed items
    todo do -E "task" -s did         # Mark task as done
    todo do -D "task"                # Delete task
    
For more information, see README.md

HELP
}

1;

=head1 AUTHOR

Adam Marshall

=head1 LICENSE

This software is Copyright (c) 2018 by Adam Marshall.

This is free software, licensed under the MIT License.

=cut