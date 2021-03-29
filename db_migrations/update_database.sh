#!/bin/bash
#
# Applies migrations to the database schema that have not yet been applied.
#
# Note: it is assumed that 00_seed_schema.sql is automatically applied as
#       part of the database creation done by Ansible, but will handle this
#       check nonetheless.
#
# TODO: DRY this script up a bit - likely better handled with some structs that
#       can map each script to a check for whether an item exists already, then
#       loop over that struct.

. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

SQL_CMD=/usr/bin/sqlite3
log "Applying any schema updates..." "INFO"

script="00_seed_schema.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema decoded_passes")
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="01_add_spectrogram_bool.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema decoded_passes" | grep 'has_spectrogram')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="02_add_noaa_pristine_bool.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema decoded_passes" | grep 'has_pristine')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="03_add_pass_azimuth_direction.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema predict_passes" | grep 'pass_start_azimuth')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="04_add_capture_gain.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema decoded_passes" | grep 'gain')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="05_add_pass_azimuth_at_max.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema predict_passes" | grep 'azimuth_at_max')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="06_add_polar_az_el_bool.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema decoded_passes" | grep 'has_polar_az_el')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="07_add_polar_direction_bool.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema decoded_passes" | grep 'has_polar_direction')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="08_add_histogram_bool.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema decoded_passes" | grep 'has_histogram')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

script="09_add_at_job_id.sql"
check=$($SQL_CMD $NOAA_HOME/db/panel.db ".schema predict_passes" | grep 'at_job_id')
if [ -z "${check}" ]; then
  log "  - applying ${script}" "INFO"
  $SQL_CMD $NOAA_HOME/db/panel.db < $NOAA_HOME/db_migrations/$script
else
  log "  - ${script} already applied" "INFO"
fi

log "Schema updates complete!" "INFO"
