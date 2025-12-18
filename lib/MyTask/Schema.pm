package MyTask::Schema;

use strict;
use warnings;
use Exporter 'import';
use Path::Tiny;
use JSON::Schema::Modern;
use JSON::MaybeXS qw(decode_json);

our @EXPORT_OK = qw(
  validate_task_file
  get_task_schema
);

# Cache for the validator instance and schema data
my $validator;
my $schema_data;

# Load JSON Schema from file (source of truth)
sub _load_schema {
  return ($validator, $schema_data) if $validator;

  my $schema_file = path(__FILE__)->parent->parent->parent
    ->child('docs')->child('schema')->child('task-file-schema.json');
  
  unless ($schema_file->exists) {
    die "Schema file not found: $schema_file";
  }

  $validator = JSON::Schema::Modern->new;
  $schema_data = decode_json($schema_file->slurp);
  
  return ($validator, $schema_data);
}

# Get the schema as a Perl data structure
# Reads from the JSON Schema file (source of truth)
sub get_task_schema {
  my ($v, $schema) = _load_schema();
  return $schema;
}

# Main validation function
# Uses JSON::Schema::Modern for validation against the JSON Schema file
sub validate_task_file {
  my ($data) = @_;

  return (0, "Data must be a hash reference") unless ref($data) eq 'HASH';

  my ($v, $schema) = _load_schema();
  
  # Validate against JSON Schema
  my $result = $v->evaluate($data, $schema);
  
  unless ($result->valid) {
    # Format error messages
    # JSON::Schema::Modern returns error objects with ->error and ->instance_location methods
    my @errors = $result->errors;
    my $error_msg = join('; ', map { 
      my $msg = eval { $_->error } || '';
      my $path = eval { $_->instance_location } || '';
      $path ? "$path: $msg" : ($msg || 'validation error');
    } @errors);
    return (0, $error_msg);
  }

  # Additional cross-field validations (not expressible in JSON Schema)
  if (exists $data->{meta}{created} && exists $data->{meta}{modified}) {
    if ($data->{meta}{modified} lt $data->{meta}{created}) {
      return (0, "modified timestamp must be >= created timestamp");
    }
  }

  return (1, "");
}

1;

