#!/usr/bin/env perl

package Devel::Todo;

use strict;
use warnings;
use v5.16;

use Carp qw/confess/;
use YAML::XS qw/LoadFile DumpFile/;

our $VERSION = '0.006000';

=head1 NAME

Devel::Todo - Core todo list management module

=head1 SYNOPSIS

  use Devel::Todo;
  
  my $config = {
      STATUS              => 'do',
      MOVE_ENABLED        => 1,
      STATUS_OPT          => '',
      PRIORITY_OPT        => '',
      DESCRIPTION_OPT     => '',
      DEFAULT_STATUS      => 'do',
      DEFAULT_PRIORITY    => 0,
      DEFAULT_DESCRIPTION => '',
      VERBOSE             => 0,
  };
  
  my $todo = Devel::Todo->new('.todos', $config);
  
  # Add items
  $todo->Add_Element(['write code', 'write tests']);
  
  # Show items
  $todo->Show_Element([]);
  
  # Edit items
  $todo->Edit_Element(['write code'], { status => 'did' });
  
  # Delete items
  $todo->Delete_Element(['write code']);
  
  # Check if item exists
  if ($todo->has_element('write code')) {
      print "Task exists\n";
  }

=head1 DESCRIPTION

Devel::Todo provides the core functionality for managing hierarchical todo lists
stored as YAML files. It supports adding, editing, deleting, and displaying todo
items with attributes like status, priority, and description.

=head1 METHODS

=head2 new($file, $config)

Constructor. Loads todo list from YAML file and initializes with configuration.

  my $todo = Devel::Todo->new('.todos', $config);

=cut

sub new {
  my ($class, $file, $config) = @_;
  
  confess 'file path required' unless defined $file;
  confess 'config hash required' unless defined $config && ref $config eq 'HASH';
  
  my $data = {};
  
  # Load existing file if it exists
  if (-e $file) {
    eval {
      $data = LoadFile($file);
    };
    if ($@) {
      confess "Failed to load todo file '$file': $@";
    }
  }
  else {
    # Create default structure
    $data = {
      name     => 'todos',
      contents => {}
    };
  }
  
  my $self = {
    file     => $file,
    config   => $config,
    data     => $data,
    modified => 0,
  };
  
  return bless $self, $class;
}

=head2 Add_Element($items)

Add one or more items to the todo list.

  $todo->Add_Element(['task1', 'task2']);
  $todo->Add_Element([ ['sublist', ['item1', 'item2']] ]);

=cut

sub Add_Element {
  my ($self, $items) = @_;
  
  confess 'items array reference required' unless defined $items && ref $items eq 'ARRAY';
  
  my $contents = $self->{data}{contents};
  
  foreach my $item (@$items) {
    if (ref $item eq 'ARRAY') {
      # This is a sublist: ['name', ['item1', 'item2']]
      my ($sublist_name, $sublist_items) = @$item;
      
      confess 'sublist name required' unless defined $sublist_name;
      confess 'sublist items must be array reference' unless ref $sublist_items eq 'ARRAY';
      
      # Create or get sublist
      if (!exists $contents->{$sublist_name}) {
        $contents->{$sublist_name} = { contents => {} };
      }
      
      # Add items to sublist
      my $sublist = $contents->{$sublist_name};
      confess "item '$sublist_name' exists but is not a sublist" 
        unless exists $sublist->{contents};
      
      foreach my $subitem (@$sublist_items) {
        my $status = $self->{config}{STATUS_OPT} || $self->{config}{DEFAULT_STATUS};
        $sublist->{contents}{$subitem} = $status;
      }
    }
    else {
      # Simple item
      my $status = $self->{config}{STATUS_OPT} || $self->{config}{DEFAULT_STATUS};
      
      # If MOVE_ENABLED and item exists elsewhere, move it
      if ($self->{config}{MOVE_ENABLED} && $self->_item_exists_anywhere($item)) {
        $self->_move_item($item, $status);
      }
      else {
        $contents->{$item} = $status;
      }
    }
  }
  
  $self->{modified} = 1;
  $self->Save();
}

=head2 Show_Element($path)

Display items from the list, optionally filtered by path and status.

  $todo->Show_Element([]);              # Show all items with current status
  $todo->Show_Element(['sublist']);     # Show items in sublist

=cut

sub Show_Element {
  my ($self, $path) = @_;
  
  confess 'path array reference required' unless defined $path && ref $path eq 'ARRAY';
  
  my $contents = $self->_navigate_to_path($path);
  my $status = $self->{config}{STATUS};
  my $verbose = $self->{config}{VERBOSE};
  
  # If path provided, print the sublist name first
  if (@$path > 0) {
    print $path->[-1], ":\n";
    $self->_show_contents($contents, $status, $verbose, 1);
  }
  else {
    $self->_show_contents($contents, $status, $verbose, 0);
  }
}

sub _show_contents {
  my ($self, $contents, $status, $verbose, $indent) = @_;
  
  return unless defined $contents && ref $contents eq 'HASH';
  
  my $indent_str = '  ' x $indent;
  
  foreach my $key (sort keys %$contents) {
    my $value = $contents->{$key};
    
    if (ref $value eq 'HASH') {
      # This is a sublist or item with attributes
      if (exists $value->{contents}) {
        # It's a sublist
        my $item_status = $value->{status} // '';
        
        # Only show if status matches (or showing all)
        if ($status eq 'all' || $item_status eq $status || 
            $self->_sublist_has_matching_status($value->{contents}, $status)) {
          print "${indent_str}${key}:\n";
          $self->_show_contents($value->{contents}, $status, $verbose, $indent + 1);
        }
      }
      else {
        # Item with attributes
        my $item_status = $value->{status} // '';
        
        if ($status eq 'all' || $item_status eq $status) {
          if ($verbose && defined $value->{description}) {
            print "${indent_str}${key} ($value->{description})\n";
          }
          else {
            print "${indent_str}${key}\n";
          }
        }
      }
    }
    else {
      # Simple item (value is status string)
      if ($status eq 'all' || $value eq $status) {
        print "${indent_str}${key}\n";
      }
    }
  }
}

sub _sublist_has_matching_status {
  my ($self, $contents, $status) = @_;
  
  return 1 if $status eq 'all';
  
  foreach my $key (keys %$contents) {
    my $value = $contents->{$key};
    
    if (ref $value eq 'HASH') {
      if (exists $value->{contents}) {
        return 1 if $self->_sublist_has_matching_status($value->{contents}, $status);
      }
      else {
        my $item_status = $value->{status} // '';
        return 1 if $item_status eq $status;
      }
    }
    else {
      return 1 if $value eq $status;
    }
  }
  
  return 0;
}

=head2 Edit_Element($path, $attributes)

Modify attributes of an existing item.

  $todo->Edit_Element(['task'], { status => 'did' });
  $todo->Edit_Element(['task'], { 
      status => 'want',
      description => 'Updated description',
      priority => 1 
  });

If attributes parameter is omitted, uses values from config (STATUS_OPT, etc).

=cut

sub Edit_Element {
  my ($self, $path, $attributes) = @_;
  
  confess 'path array reference required' unless defined $path && ref $path eq 'ARRAY';
  confess 'path must contain at least one element' unless @$path > 0;
  
  # If attributes not provided, use config options
  if (!defined $attributes) {
    $attributes = {};
    $attributes->{status} = $self->{config}{STATUS_OPT} 
      if defined $self->{config}{STATUS_OPT} && $self->{config}{STATUS_OPT} ne '';
    $attributes->{priority} = $self->{config}{PRIORITY_OPT}
      if defined $self->{config}{PRIORITY_OPT} && $self->{config}{PRIORITY_OPT} ne '';
    $attributes->{description} = $self->{config}{DESCRIPTION_OPT}
      if defined $self->{config}{DESCRIPTION_OPT} && $self->{config}{DESCRIPTION_OPT} ne '';
  }
  
  my $item_name = $path->[-1];
  my $parent_path = [@$path[0 .. $#$path - 1]];
  
  my $parent = $self->_navigate_to_path($parent_path);
  
  confess "item '$item_name' not found" unless exists $parent->{$item_name};
  
  my $item = $parent->{$item_name};
  
  # Convert simple status string to hash if needed
  if (!ref $item) {
    $item = { status => $item };
    $parent->{$item_name} = $item;
  }
  
  # Apply attributes
  foreach my $attr (keys %$attributes) {
    $item->{$attr} = $attributes->{$attr};
  }
  
  $self->{modified} = 1;
  $self->Save();
}

=head2 Delete_Element($path)

Remove item(s) from the list. Only deletes items matching current STATUS.

  $todo->Delete_Element(['task']);
  $todo->Delete_Element([]);  # Delete all matching items at root
  $todo->Delete_Element([ ['sublist', ['item']] ]);  # Delete from sublist

=cut

sub Delete_Element {
  my ($self, $path) = @_;
  
  confess 'path array reference required' unless defined $path && ref $path eq 'ARRAY';
  
  if (@$path == 0) {
    # Delete all items with matching status at root
    $self->_delete_matching_items($self->{data}{contents});
  }
  elsif (@$path == 1 && ref $path->[0] eq 'ARRAY') {
    # Nested delete: [ ['sublist', ['item1', 'item2']] ]
    my ($sublist_name, $items) = @{$path->[0]};
    
    # Navigate to parent of sublist
    my $parent_path = [];
    my $parent = $self->_navigate_to_path($parent_path);
    
    # Get the sublist
    if (exists $parent->{$sublist_name} && ref $parent->{$sublist_name} eq 'HASH' && 
        exists $parent->{$sublist_name}{contents}) {
      my $sublist_contents = $parent->{$sublist_name}{contents};
      
      foreach my $item (@$items) {
        $self->_delete_single_item($sublist_contents, $item);
      }
    }
  }
  else {
    # Delete single item or sublist
    my $item_name = $path->[-1];
    my $parent_path = [@$path[0 .. $#$path - 1]];
    my $parent = $self->_navigate_to_path($parent_path);
    
    $self->_delete_single_item($parent, $item_name);
  }
  
  $self->{modified} = 1;
  $self->Save();
}

sub _delete_single_item {
  my ($self, $parent, $item_name) = @_;
  
  return unless exists $parent->{$item_name};
  
  my $item = $parent->{$item_name};
  my $status = $self->{config}{STATUS};
  
  if (ref $item eq 'HASH') {
    if (exists $item->{contents}) {
      # It's a sublist - delete matching items from it
      $self->_delete_matching_items($item->{contents});
    }
    else {
      # Item with attributes
      my $item_status = $item->{status} // '';
      if ($status eq 'all' || $item_status eq $status) {
        delete $parent->{$item_name};
      }
    }
  }
  else {
    # Simple item
    if ($status eq 'all' || $item eq $status) {
      delete $parent->{$item_name};
    }
  }
}

sub _delete_matching_items {
  my ($self, $contents) = @_;
  
  my $status = $self->{config}{STATUS};
  my @to_delete;
  
  foreach my $key (keys %$contents) {
    my $value = $contents->{$key};
    
    if (ref $value eq 'HASH') {
      if (exists $value->{contents}) {
        # Sublist - recursively delete from it
        $self->_delete_matching_items($value->{contents});
      }
      else {
        # Item with attributes
        my $item_status = $value->{status} // '';
        if ($status eq 'all' || $item_status eq $status) {
          push @to_delete, $key;
        }
      }
    }
    else {
      # Simple item
      if ($status eq 'all' || $value eq $status) {
        push @to_delete, $key;
      }
    }
  }
  
  delete $contents->{$_} for @to_delete;
}

=head2 has_element($name, ...)

Check if an item exists in the list.

  $todo->has_element('task');              # Check at root
  $todo->has_element('sublist', 'task');   # Check in sublist

=cut

sub has_element {
  my ($self, @path) = @_;
  
  confess 'at least one element name required' unless @path > 0;
  
  my $item;
  eval {
    $item = $self->_navigate_to_item(@path);
  };
  
  return 0 if $@;
  return defined $item;
}

=head2 get_attributes($name)

Get attributes hash for an item.

  my $attrs = $todo->get_attributes('task');
  # Returns: { status => 'do', priority => 1, description => 'text' }

=cut

sub get_attributes {
  my ($self, $name) = @_;
  
  confess 'item name required' unless defined $name;
  
  my $contents = $self->{data}{contents};
  
  confess "item '$name' not found" unless exists $contents->{$name};
  
  my $item = $contents->{$name};
  
  if (ref $item eq 'HASH' && !exists $item->{contents}) {
    # Item with attributes
    return { %$item };  # Return copy
  }
  elsif (!ref $item) {
    # Simple status string
    return { status => $item };
  }
  elsif (ref $item eq 'HASH' && exists $item->{contents}) {
    # Sublist
    return { 
      status => $item->{status} // '',
      contents => 1  # Indicator that it's a sublist
    };
  }
  
  return {};
}

=head2 apply_to_matches($callback, @args)

Apply a callback function to items matching certain criteria.

  $todo->apply_to_matches(\&callback, 'arg1', 'arg2');

=cut

sub apply_to_matches {
  my ($self, $callback, @args) = @_;
  
  confess 'callback code reference required' unless defined $callback && ref $callback eq 'CODE';
  
  # If first arg looks like an item name (not a ref), use it as filter
  my $filter_name = (@args > 0 && !ref $args[0]) ? $args[0] : undef;
  
  my $contents = $self->{data}{contents};
  my $status = $self->{config}{STATUS};
  
  $self->_apply_to_contents($callback, $contents, $status, $filter_name, @args);
}

sub _apply_to_contents {
  my ($self, $callback, $contents, $status, $filter_name, @args) = @_;
  
  foreach my $key (sort keys %$contents) {
    my $value = $contents->{$key};
    
    # Skip if filter specified and doesn't match
    if (defined $filter_name && $key ne $filter_name) {
      # But still recurse into sublists
      if (ref $value eq 'HASH' && exists $value->{contents}) {
        $self->_apply_to_contents($callback, $value->{contents}, $status, $filter_name, @args);
      }
      next;
    }
    
    my $should_apply = 0;
    
    if (ref $value eq 'HASH') {
      if (exists $value->{contents}) {
        # Sublist - recurse
        $self->_apply_to_contents($callback, $value->{contents}, $status, $filter_name, @args);
        next;
      }
      else {
        my $item_status = $value->{status} // '';
        $should_apply = ($status eq 'all' || $item_status eq $status);
      }
    }
    else {
      $should_apply = ($status eq 'all' || $value eq $status);
    }
    
    if ($should_apply) {
      $callback->($self, $key, @args);
    }
  }
}

=head2 Save()

Persist changes to disk.

  $todo->Save();

=cut

sub Save {
  my ($self) = @_;
  
  return unless $self->{modified};
  
  eval {
    DumpFile($self->{file}, $self->{data});
  };
  if ($@) {
    confess "Failed to save todo file '$self->{file}': $@";
  }
  
  $self->{modified} = 0;
}

# Private helper methods

sub _navigate_to_path {
  my ($self, $path) = @_;
  
  my $current = $self->{data}{contents};
  
  foreach my $segment (@$path) {
    confess "path segment '$segment' not found" unless exists $current->{$segment};
    
    my $item = $current->{$segment};
    
    if (ref $item eq 'HASH' && exists $item->{contents}) {
      $current = $item->{contents};
    }
    else {
      confess "path segment '$segment' is not a sublist";
    }
  }
  
  return $current;
}

sub _navigate_to_item {
  my ($self, @path) = @_;
  
  my $item_name = pop @path;
  my $parent = $self->_navigate_to_path(\@path);
  
  return undef unless exists $parent->{$item_name};
  return $parent->{$item_name};
}

sub _item_exists_anywhere {
  my ($self, $item_name) = @_;
  
  return $self->_search_contents($self->{data}{contents}, $item_name);
}

sub _search_contents {
  my ($self, $contents, $item_name) = @_;
  
  return 0 unless defined $contents && ref $contents eq 'HASH';
  
  return 1 if exists $contents->{$item_name};
  
  foreach my $key (keys %$contents) {
    my $value = $contents->{$key};
    
    if (ref $value eq 'HASH' && exists $value->{contents}) {
      return 1 if $self->_search_contents($value->{contents}, $item_name);
    }
  }
  
  return 0;
}

sub _move_item {
  my ($self, $item_name, $new_status) = @_;
  
  # Find and remove item from old location
  my $item_data = $self->_find_and_remove_item($self->{data}{contents}, $item_name);
  
  if (defined $item_data) {
    # Add back with new status
    if (ref $item_data eq 'HASH') {
      $item_data->{status} = $new_status;
      $self->{data}{contents}{$item_name} = $item_data;
    }
    else {
      $self->{data}{contents}{$item_name} = $new_status;
    }
  }
}

sub _find_and_remove_item {
  my ($self, $contents, $item_name) = @_;
  
  if (exists $contents->{$item_name}) {
    my $item = $contents->{$item_name};
    delete $contents->{$item_name};
    return $item;
  }
  
  foreach my $key (keys %$contents) {
    my $value = $contents->{$key};
    
    if (ref $value eq 'HASH' && exists $value->{contents}) {
      my $item = $self->_find_and_remove_item($value->{contents}, $item_name);
      return $item if defined $item;
    }
  }
  
  return undef;
}

1;

=head1 AUTHOR

Adam Marshall

=head1 LICENSE

This software is Copyright (c) 2018 by Adam Marshall.

This is free software, licensed under the MIT License.

=cut