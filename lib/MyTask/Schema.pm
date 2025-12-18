package MyTask::Schema;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
  validate_task_file
  get_task_schema
  validate_field
  validate_structure
);

# Schema definition as Perl data structure
# This mirrors the JSON Schema in docs/schema/task-file-schema.json
sub get_task_schema {
  return {
    required => [qw(task meta)],
    properties => {
      task => {
        required => [qw(description status)],
        properties => {
          description => {
            type => 'string',
            min_length => 1,
            description => 'Short, human-readable description',
          },
          status => {
            type => 'enum',
            values => [qw(pending done deleted archived)],
            description => 'Current state of the task',
          },
          alias => {
            type => 'string',
            min_length => 1,
            optional => 1,
            description => 'Optional short identifier',
          },
          due => {
            type => 'string',
            pattern => qr/^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?)?$/,
            optional => 1,
            description => 'Due date (ISO 8601)',
          },
          scheduled => {
            type => 'string',
            pattern => qr/^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?)?$/,
            optional => 1,
            description => 'Scheduled date (ISO 8601)',
          },
        },
      },
      meta => {
        required => [qw(id created modified)],
        properties => {
          id => {
            type => 'string',
            pattern => qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
            description => 'Unique identifier (UUID v4)',
          },
          created => {
            type => 'string',
            pattern => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?$/,
            description => 'Creation timestamp (ISO 8601)',
          },
          modified => {
            type => 'string',
            pattern => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?$/,
            description => 'Modification timestamp (ISO 8601)',
          },
        },
      },
      notes => {
        type => 'array',
        optional => 1,
        items => {
          required => [qw(timestamp entry)],
          properties => {
            timestamp => {
              type => 'string',
              pattern => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?$/,
              description => 'Entry timestamp (ISO 8601)',
            },
            entry => {
              type => 'string',
              min_length => 1,
              description => 'Entry content',
            },
            type => {
              type => 'enum',
              values => [qw(note log comment status-change)],
              optional => 1,
              description => 'Entry type',
            },
          },
        },
      },
    },
  };
}

# Validate a single field against its schema definition
sub validate_field {
  my ($value, $field_schema) = @_;

  return (0, "Field schema required") unless $field_schema;
  return (0, "Field type required") unless exists $field_schema->{type};

  my $type = $field_schema->{type};

  # Check type
  if ($type eq 'string') {
    return (0, "Value must be a string") unless defined $value && !ref($value);

    if (exists $field_schema->{min_length}) {
      return (0, "String too short (min: $field_schema->{min_length})")
        if length($value) < $field_schema->{min_length};
    }

    if (exists $field_schema->{pattern}) {
      return (0, "Value does not match required pattern")
        unless $value =~ $field_schema->{pattern};
    }
  }
  elsif ($type eq 'enum') {
    return (0, "Enum values required") unless exists $field_schema->{values};
    my %valid_values = map { $_ => 1 } @{$field_schema->{values}};
    return (0, "Value must be one of: " . join(', ', @{$field_schema->{values}}))
      unless defined $value && $valid_values{$value};
  }
  elsif ($type eq 'array') {
    return (0, "Value must be an array") unless ref($value) eq 'ARRAY';

    if (exists $field_schema->{items}) {
      for my $i (0 .. $#{$value}) {
        my ($valid, $error) = validate_structure($value->[$i], $field_schema->{items});
        return (0, "Item[$i]: $error") unless $valid;
      }
    }
  }

  return (1, "");
}

# Validate a structure (section or nested object) against its schema
sub validate_structure {
  my ($data, $schema) = @_;

  return (0, "Data must be a hash reference") unless ref($data) eq 'HASH';
  return (0, "Schema required") unless $schema;

  # Check required fields
  if (exists $schema->{required}) {
    for my $field (@{$schema->{required}}) {
      return (0, "Required field '$field' is missing")
        unless exists $data->{$field};
    }
  }

  # Validate each field that exists in the data
  for my $field (keys %{$data}) {
    next unless exists $schema->{properties}{$field};

    my $field_schema = $schema->{properties}{$field};
    
    # If field schema has 'properties', it's a nested structure (object)
    if (exists $field_schema->{properties}) {
      my ($valid, $error) = validate_structure($data->{$field}, $field_schema);
      return (0, "Field '$field': $error") unless $valid;
    }
    # Otherwise, it's a simple field (string, enum, array, etc.)
    else {
      # Skip validation if field is optional and value is undefined/empty
      next if $field_schema->{optional} && !defined $data->{$field};

      my ($valid, $error) = validate_field($data->{$field}, $field_schema);
      return (0, "Field '$field': $error") unless $valid;
    }
  }

  # Check for unknown fields (if additionalProperties is false)
  if (exists $schema->{additionalProperties} && !$schema->{additionalProperties}) {
    my %allowed = map { $_ => 1 } keys %{$schema->{properties}};
    for my $field (keys %{$data}) {
      return (0, "Unknown field '$field'") unless $allowed{$field};
    }
  }

  return (1, "");
}

# Main validation function
sub validate_task_file {
  my ($data) = @_;

  return (0, "Data must be a hash reference") unless ref($data) eq 'HASH';

  my $schema = get_task_schema();
  my ($valid, $error) = validate_structure($data, $schema);

  # Additional cross-field validations
  if ($valid && exists $data->{meta}{created} && exists $data->{meta}{modified}) {
    if ($data->{meta}{modified} lt $data->{meta}{created}) {
      return (0, "modified timestamp must be >= created timestamp");
    }
  }

  return ($valid, $error);
}

1;

