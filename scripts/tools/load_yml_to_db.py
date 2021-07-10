#!/usr/bin/env python3
#
# Purpose: Read configuration file and inject settings if the key is not
#          yet in the database.
#
# Inputs:
#   1. YAML file (full path) to load into the database as simple key/value pairs.
#
# Example:
#   ./load_yml_to_db.py config/settings.yml

import os.path
import sqlite3
import sys
import yaml

def displayUsage():
  print("Usage: ./load_yml_to_db.py <yaml_file>")
  exit(1)

def main():
  '''
  Load command line arguments, validate them, and load the key/value
  configurations to the database if they do not yet exist.
  '''

  # parse input arguments
  if len(sys.argv) != 2:
    displayUsage()

  input_yml = sys.argv[1]

  if not os.path.exists(input_yml):
    print("Could not locate or access file '{}'".format(input_yml))
    sys.exit(1)

  # load user-defined configurations
  try:
    print("Loading configuration file {}".format(input_yml))

    with open(input_yml, "r") as stream:
      yml_config = yaml.load(stream, Loader=yaml.SafeLoader)
  except Exception as e:
    print("Error loading yml file '{}'".format(input_yml))
    print(e)
    sys.exit(1)

  # connect to database
  try:
    print("Connecting to database...")
    sqldb = sqlite3.connect("db/panel.db")
    cursor = sqldb.cursor()
    print("Successfully connected to database")
  except Exception as e:
    print("Error connecting to database")
    print(e)
    sys.exit(1)

  # parse and inject each key/value if the key does not already exist
  for k,v in yml_config.items():
    try:
      sql = '''INSERT INTO configurations (config_key, config_val)
               SELECT '{}', '{}' WHERE NOT EXISTS
                 (SELECT 1 FROM configurations WHERE config_key='{}')'''.format(k, v, k)
      sql_inject = cursor.execute(sql)
      sqldb.commit()
  
      print("Handled '{}': '{}'".format(k, v))
    except sqlite3.Error as error:
      print("Failed to inject record {}|{} into database: {}".format(k, v, error))

  # close the db connection if still open
  if sqldb:
    sqldb.close()
    print("DB connection closed")

if __name__ == '__main__':
  main()
