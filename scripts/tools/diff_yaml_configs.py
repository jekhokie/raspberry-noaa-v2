#!/usr/bin/env python3
#
# Purpose: Parse 2 yaml config files and return any 'missing' config
#          parameters in the first input file that exists in the second.
#
# Parameters:
#   1. Base file that should be considered complete/accurate
#   2. File to be checked
#
# Example:
#   ./diff_yaml_configs.py config/pristine.yml config/my_config.yml
import sys
import yaml
from os import path

def main():
  '''
  Main function to check for usage, accept arguments from command
  line, and load yaml files into dictionaries
  '''

  # check for correct usage
  if (len(sys.argv) != 3):
    print("Usage: ./diff_yaml_configs.py <path_to_pristine_config> <path_to_check_config>")
    exit(1)

  # input arguments
  pristine_config = sys.argv[1]
  check_config = sys.argv[2]

  # check that files specified exist/are accessible
  if (not path.exists(pristine_config)):
    print("ERROR: Pristine config file '%s' not found or inaccessible" % pristine_config)
    exit(1)

  # check that files specified exist/are accessible
  if (not path.exists(check_config)):
    print("ERROR: Check config file '%s' not found or inaccessible" % check_config)
    exit(1)

  pristine = yaml.load(open(pristine_config), Loader=yaml.SafeLoader)
  check = yaml.load(open(check_config), Loader=yaml.SafeLoader)

  # perform check and print any missing keys
  missing = set(pristine.keys()) - set(check.keys())
  if len(missing) > 0:
    delta  = "ERROR: Missing configs in '%s' that exist in '%s'\n\n" % (pristine_config, check_config)
    delta += "Below are a list of missing configs and their defaults in the pristine config.\n"
    for c in missing:
      delta += "  %s: %s\n" % (c, pristine[c])

    print(delta)
    exit(1)
  else:
    print("Configurations '%s' and '%s' aligned" % (pristine_config, check_config))
    exit(0)

if __name__ == '__main__':
  main()
