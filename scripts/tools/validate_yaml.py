#!/usr/bin/env python3
#
# Purpose: Validate the contents of a YAML file against a given JSON-schema.
#          Note that this does NOT account for missing properties.
#
# Inputs:
#   1. YAML file to validate.
#   2. JSON-schema to use for validation
#
# Example:
#   ./validate_yaml.py config/settings.yml config/settings_schema.json

import sys
import yaml
from jsonschema import validate, Draft7Validator
from os import path

def main():
  '''
  Main function to check for usage, accept arguments from command
  line, and compare yaml against given schema
  '''

  # check for correct usage
  if (len(sys.argv) != 3):
    print("Usage: ./validate_yaml.py <path_to_yaml_config> <path_to_json_schema>")
    exit(1)

  # input arguments
  config_file = sys.argv[1]
  schema_file = sys.argv[2]

  # check that files specified exist/are accessible
  if (not path.exists(config_file)):
    print("ERROR: YAML config '%s' not found or inaccessible" % config_file)
    exit(1)

  if (not path.exists(schema_file)):
    print("ERROR: JSON schema '%s' not found or inaccessible" % schema_file)
    exit(1)

  # load the yaml config and schema
  yaml_config = yaml.load(open(config_file), Loader=yaml.SafeLoader)
  json_schema = yaml.load(open(schema_file), Loader=yaml.SafeLoader)

  # perform validation and output results
  v = Draft7Validator(json_schema)
  valid=True
  errors = v.iter_errors(yaml_config)
  if sum(1 for _ in errors) > 0:
    print("ERROR: The configuration %s does not conform to the expected schema - see below for errors..." % config_file)
    for error in sorted(v.iter_errors(yaml_config), key=str):
      if len(error.path) > 0:
        print("  - %s: %s" % (error.path[0], error.message))
      else:
        print("  - %s" % (error.message))
    exit(1)
  else:
    print("SUCCESS: The configuration %s conforms to the expected schema!" % config_file)
    exit(0)

if __name__ == '__main__':
  main()
