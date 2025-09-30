#!/usr/bin/env perl

package Project::Task::SimpleTask;

use strict;
use warnings;

use Mouse;
extends qw/Project::Task/;

sub execute {
  my ($self, $action) = @_;

  if (defined $action) {
    return $action->($self);
  }
  else return "$self->name: $self->summary";
}
