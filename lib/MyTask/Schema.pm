package MyTask::Schema;

use strict;
use warnings;
use Exporter 'import';
use Carp             qw(croak);
use Path::Tiny       qw(path);
use Params::Validate qw(validate_pos HASHREF);
use JSON::Schema::Modern;
use JSON::MaybeXS qw(decode_json);

## no critic (CodeLayout::TabIndentSpaceAlign)

our @EXPORT_OK = qw(
  validate_task_file
  get_task_schema
);

# Cache for the validator instance and schema data
my $validator;
my $schema_data;

sub _schema_path {
  my $root = path(__FILE__)->parent->parent->parent;
  return $root->child('docs/schema/task-file-schema.json');
}

# Load JSON Schema from file (source of truth)
sub _load_schema {
  my @args = @_;
  validate_pos(@args);
  return ( $validator, $schema_data ) if $validator;

  my $schema_file = _schema_path();

  if ( !$schema_file->exists ) {
    ## no critic (ErrorHandling::RequireUseOfExceptions)
    croak "Schema file not found: $schema_file";
    ## use critic
  }

  $validator   = JSON::Schema::Modern->new;
  $schema_data = decode_json( $schema_file->slurp );

  return ( $validator, $schema_data );
} ## end sub _load_schema

# Get the schema as a Perl data structure
# Reads from the JSON Schema file (source of truth)
sub get_task_schema {
  my @args = @_;
  validate_pos(@args);
  my ( undef, $schema ) = _load_schema();
  return $schema;
}

# Main validation function
# Uses JSON::Schema::Modern for validation against the JSON Schema file
sub validate_task_file {
  my @args = @_;
  validate_pos( @args, { 'type' => HASHREF } );
  my ($task_data) = @args;

  my ( $v, $schema ) = _load_schema();

  # Validate against JSON Schema
  my $result = $v->evaluate( $task_data, $schema );

  if ( !$result->valid ) {

    # Format error messages
    # JSON::Schema::Modern returns error objects with ->error and ->instance_location methods
    my @errors = $result->errors;
    my @messages;
    for my $err (@errors) {
      my $msg  = eval { $err->error }             || '';
      my $path = eval { $err->instance_location } || '';
      push @messages, $path ? "$path: $msg" : ( $msg || 'validation error' );
    }
    my $error_msg = join '; ', @messages;
    return ( 0, $error_msg );
  }

  # Additional cross-field validations (not expressible in JSON Schema)
  ## no critic (ValuesAndExpressions::ProhibitAccessOfPrivateData CodeLayout::TabIndentSpaceAlign CodeLayout::ProhibitSpaceIndentation)
  if ( exists $task_data->{'meta'}{'created'} && exists $task_data->{'meta'}{'modified'} ) {
    my $created  = $task_data->{'meta'}{'created'};
    my $modified = $task_data->{'meta'}{'modified'};
    if ( $modified lt $created ) {
      return ( 0, "modified timestamp must be >= created timestamp" );
    }
  }
  ## use critic

  return ( 1, undef );
} ## end sub validate_task_file

1;
