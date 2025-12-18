#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;

# Check if TOML::Tiny is available
BEGIN {
  eval { require TOML::Tiny; 1 } or plan skip_all => 'TOML::Tiny not available';
}

# Use done_testing instead of fixed plan to handle dynamic test counts
# plan tests => 50;  # Adjust count as needed

my $examples_dir = path('docs/examples');
ok($examples_dir->exists, "Examples directory exists");

# List of example files to test
my @example_files = qw(
  simple-task.toml
  task-with-notes.toml
  task-with-due-date.toml
  completed-task.toml
  deleted-task.toml
  task-with-alias.toml
);

# Test each example file
for my $filename (@example_files) {
  my $file = $examples_dir->child($filename);
  
  subtest "Testing $filename" => sub {
    # File exists
    ok($file->exists, "$filename exists");
    
    # Read and parse TOML
    my $content = eval { $file->slurp };
    ok($content, "Can read $filename") or diag("Error: $@");
    
    my $data = eval { TOML::Tiny->new->decode($content) };
    ok($data, "$filename is valid TOML") or diag("Parse error: $@");
    next unless $data;
    
    # Validate three-section structure
    ok(exists $data->{task}, "$filename has [task] section");
    ok(exists $data->{meta}, "$filename has [meta] section");
    
    # Validate [task] section required fields
    if (exists $data->{task}) {
      ok(exists $data->{task}{description}, 
         "$filename has description in [task] section");
      ok(exists $data->{task}{status}, 
         "$filename has status in [task] section");
      
      # Validate description is non-empty
      if (exists $data->{task}{description}) {
        ok(length($data->{task}{description}) > 0, 
           "$filename description is non-empty");
      }
      
      # Validate status is one of allowed values
      if (exists $data->{task}{status}) {
        like($data->{task}{status}, qr/^(pending|done|deleted|archived)$/,
             "$filename status is valid");
      }
    }
    
    # Validate [meta] section required fields
    if (exists $data->{meta}) {
      ok(exists $data->{meta}{id}, 
         "$filename has id in [meta] section");
      ok(exists $data->{meta}{created}, 
         "$filename has created in [meta] section");
      ok(exists $data->{meta}{modified}, 
         "$filename has modified in [meta] section");
      
      # Validate UUID format
      if (exists $data->{meta}{id}) {
        like($data->{meta}{id}, 
             qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
             "$filename id is valid UUID v4");
      }
      
      # Validate timestamp formats
      if (exists $data->{meta}{created}) {
        like($data->{meta}{created}, 
             qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/,
             "$filename created timestamp is ISO 8601 format");
      }
      
      if (exists $data->{meta}{modified}) {
        like($data->{meta}{modified}, 
             qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/,
             "$filename modified timestamp is ISO 8601 format");
      }
      
      # Validate modified >= created (if both exist)
      if (exists $data->{meta}{created} && exists $data->{meta}{modified}) {
        my $created = $data->{meta}{created};
        my $modified = $data->{meta}{modified};
        ok($modified ge $created, 
           "$filename modified >= created");
      }
    }
    
    # Validate [[notes]] section if present
    if (exists $data->{notes}) {
      ok(ref($data->{notes}) eq 'ARRAY', 
         "$filename notes is an array");
      
      if (ref($data->{notes}) eq 'ARRAY') {
        for my $i (0 .. $#{$data->{notes}}) {
          my $note = $data->{notes}[$i];
          ok(exists $note->{timestamp}, 
             "$filename note[$i] has timestamp");
          ok(exists $note->{entry}, 
             "$filename note[$i] has entry");
          
          if (exists $note->{timestamp}) {
            like($note->{timestamp}, 
                 qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/,
                 "$filename note[$i] timestamp is ISO 8601 format");
          }
          
          if (exists $note->{entry}) {
            ok(length($note->{entry}) > 0, 
               "$filename note[$i] entry is non-empty");
          }
          
          # Validate type if present
          if (exists $note->{type}) {
            like($note->{type}, qr/^(note|log|comment|status-change)$/,
                 "$filename note[$i] type is valid");
          }
        }
      }
    }
  };
}

# Test specific example files for their unique features
subtest "simple-task.toml - minimal fields" => sub {
  my $file = $examples_dir->child('simple-task.toml');
  my $data = TOML::Tiny->new->decode($file->slurp);
  
  ok(!exists $data->{task}{due}, "No due date");
  ok(!exists $data->{task}{alias}, "No alias");
  ok(!exists $data->{notes}, "No notes section");
};

subtest "task-with-notes.toml - journal entries" => sub {
  my $file = $examples_dir->child('task-with-notes.toml');
  my $data = TOML::Tiny->new->decode($file->slurp);
  
  ok(exists $data->{notes}, "Has notes section");
  ok(@{$data->{notes}} >= 2, "Has multiple note entries");
  
  # Check for app log entry
  my $has_log = grep { exists $_->{type} && $_->{type} eq 'log' } @{$data->{notes}};
  ok($has_log, "Has at least one log entry");
};

subtest "completed-task.toml - done status" => sub {
  my $file = $examples_dir->child('completed-task.toml');
  my $data = TOML::Tiny->new->decode($file->slurp);
  
  is($data->{task}{status}, 'done', "Status is 'done'");
};

subtest "deleted-task.toml - deleted status" => sub {
  my $file = $examples_dir->child('deleted-task.toml');
  my $data = TOML::Tiny->new->decode($file->slurp);
  
  is($data->{task}{status}, 'deleted', "Status is 'deleted'");
};

subtest "task-with-alias.toml - alias field" => sub {
  my $file = $examples_dir->child('task-with-alias.toml');
  my $data = TOML::Tiny->new->decode($file->slurp);
  
  ok(exists $data->{task}{alias}, "Has alias field");
  ok(length($data->{task}{alias}) > 0, "Alias is non-empty");
};

done_testing;
