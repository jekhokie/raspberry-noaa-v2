#!/usr/bin/env python3
#
# Purpose: Render a Jinja template and save it to a resulting file.
#
# Inputs:
#    1. Jinja2 template to use
#    2. Configuration yaml to use for parameter injection (string)
#    3. Output file
#
# Example
#    ./render_jinja2.py /path/to/file.html.j2 "satellite_name: test" /path/to/file.html

import jinja2
import sys
import yaml
from os import path

def main():
  '''
  Main function to check for usage, accept arguments from command
  line, and render/store template in target location
  '''

  # check for correct usage
  if (len(sys.argv) != 4):
    print("Usage: ./jinja2_to_file.py <path_to_j2_template> <config_yml> <path_to_output_file>")
    exit(1)

  # input arguments
  j2_template = sys.argv[1]
  yml_config = sys.argv[2]
  out_file = sys.argv[3]

  # check that files specified exist/are accessible
  if (not path.exists(j2_template)):
    print("ERROR: Jinja2 template '%s' not found or inaccessible" % j2_template)
    exit(1)

  # load configs to make them available
  try:
    configs = yaml.load(yml_config, Loader=yaml.SafeLoader)
  except:
    e = sys.exc_info()[0]
    print("ERROR: Could not load YAML | '%s'" % e)
    exit(1)

  # render template and save to temp html file
  env = jinja2.Environment(loader=jinja2.FileSystemLoader(path.dirname(j2_template)), trim_blocks=True)
  t = env.get_template(path.basename(j2_template))
  with open(out_file, "w+") as fh:
    fh.write(t.render(**configs))

if __name__ == '__main__':
  main()
