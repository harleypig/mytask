#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use TOML::Tiny;

BEGIN {
  eval { require MyTask::Schema; 1 } or do {
    plan skip_all => 'MyTask::Schema not available';
  };
}

use MyTask::Schema qw(validate_task_file get_task_schema);

# Test schema definition
subtest "Schema definition" => sub {
  my $schema = get_task_schema();
  ok($schema, "Schema definition exists");
  ok(exists $schema->{required}, "Has required sections");
  ok(exists $schema->{properties}, "Has properties definition");
  ok(exists $schema->{properties}{task}, "Has task section schema");
  ok(exists $schema->{properties}{meta}, "Has meta section schema");
};

# Test valid example files
subtest "Valid example files" => sub {
  my $examples_dir = path('docs/examples');
  my @files = qw(
    simple-task.toml
    task-with-notes.toml
    task-with-due-date.toml
    completed-task.toml
    deleted-task.toml
    task-with-alias.toml
  );

  for my $filename (@files) {
    my $file = $examples_dir->child($filename);
    my $content = $file->slurp;
    my $data = TOML::Tiny->new->decode($content);

    my ($valid, $error) = validate_task_file($data);
    ok($valid, "$filename validates against schema") or diag("Error: $error");
  }
};

# Test edge cases - missing required fields
subtest "Missing required fields" => sub {
  my %test_cases = (
    "missing task section" => {
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
    "missing meta section" => {
      task => { description => "Test", status => "pending" },
    },
    "missing description" => {
      task => { status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
    "missing status" => {
      task => { description => "Test" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
    "missing id" => {
      task => { description => "Test", status => "pending" },
      meta => { created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
  );

  for my $case (keys %test_cases) {
    my ($valid, $error) = validate_task_file($test_cases{$case});
    ok(!$valid, "$case should fail validation");
    like($error, qr/required|missing/i, "$case error mentions missing field");
  }
};

# Test edge cases - invalid field values
subtest "Invalid field values" => sub {
  my %test_cases = (
    "invalid status" => {
      task => { description => "Test", status => "invalid" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
    "invalid UUID format" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "not-a-uuid", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
    "invalid UUID version" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "6ba7b810-9dad-11d1-80b4-00c04fd430c8", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
    "invalid timestamp format" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "invalid-date", modified => "2024-01-15T10:30:00Z" },
    },
    "empty description" => {
      task => { description => "", status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
    },
    "modified before created" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-14T10:30:00Z" },
    },
  );

  for my $case (keys %test_cases) {
    my ($valid, $error) = validate_task_file($test_cases{$case});
    ok(!$valid, "$case should fail validation");
    ok($error, "$case provides error message");
  }
};

# Test edge cases - notes validation
subtest "Notes validation" => sub {
  my %test_cases = (
    "note without timestamp" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
      notes => [{ entry => "Test note" }],
    },
    "note without entry" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
      notes => [{ timestamp => "2024-01-15T10:30:00Z" }],
    },
    "note with invalid type" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
      notes => [{ timestamp => "2024-01-15T10:30:00Z", entry => "Test", type => "invalid" }],
    },
    "valid notes" => {
      task => { description => "Test", status => "pending" },
      meta => { id => "550e8400-e29b-41d4-a716-446655440000", created => "2024-01-15T10:30:00Z", modified => "2024-01-15T10:30:00Z" },
      notes => [
        { timestamp => "2024-01-15T10:30:00Z", entry => "Test note" },
        { timestamp => "2024-01-16T10:30:00Z", entry => "Another note", type => "log" },
      ],
    },
  );

  for my $case (keys %test_cases) {
    my ($valid, $error) = validate_task_file($test_cases{$case});
    if ($case eq "valid notes") {
      ok($valid, "$case should pass validation");
    } else {
      ok(!$valid, "$case should fail validation");
    }
  }
};

# Test edge cases - special characters
subtest "Special characters in fields" => sub {
  my $valid_task = {
    task => {
      description => "Test with special chars: \"quotes\", 'apostrophes', \n newlines, unicode: 测试 🎉",
      status => "pending",
    },
    meta => {
      id => "550e8400-e29b-41d4-a716-446655440000",
      created => "2024-01-15T10:30:00Z",
      modified => "2024-01-15T10:30:00Z",
    },
  };

  my ($valid, $error) = validate_task_file($valid_task);
  ok($valid, "Special characters in description are allowed");
};

done_testing;

