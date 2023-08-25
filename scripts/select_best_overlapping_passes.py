#!/usr/bin/env python3

import sqlite3
from datetime import datetime
import os
import sys

def delete_job(target_datetime_str):
    # Convert the target datetime string to a datetime object
    target_datetime = datetime.fromtimestamp(int(target_datetime_str))

    # Get the list of at jobs
    atq_output = os.popen("atq").read().strip()
    atq_lines = atq_output.split("\n")

    # Loop through the at jobs and find the ones scheduled around the target datetime
    for line in atq_lines:
        job_id, job_datetime = line.split(None, 1)

        # Extract the full date and time string
        job_datetime = " ".join(job_datetime.split()[:5])
        job_datetime_obj = datetime.strptime(job_datetime, "%a %b %d %H:%M:%S %Y")

        if job_datetime_obj == target_datetime:
            print(f"Removing job with ID: {job_id}")
            os.system("atrm {}".format(job_id))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: {} <database_path>".format(sys.argv[0]))
        sys.exit(1)

    database_path = os.path.expanduser(sys.argv[1])
    conn = sqlite3.connect(database_path)
    cursor = conn.cursor()

    cursor.execute("SELECT sat_name, pass_start, pass_end, max_elev, is_active, pass_start_azimuth, direction, azimuth_at_max, at_job_id FROM predict_passes ORDER BY pass_start")
    passes = cursor.fetchall()

    for i in range(len(passes) - 1):
        pass_start_curr, pass_end_curr, max_elev_curr, sat_name_curr, at_job_id_curr = passes[i][1], passes[i][2], passes[i][3], passes[i][0], passes[i][8]
        pass_start_next, max_elev_next, sat_name_next, at_job_id_next = passes[i + 1][1], passes[i + 1][3], passes[i + 1][0], passes[i + 1][8]

        if pass_start_curr < pass_start_next and pass_start_next < pass_end_curr:
            if "METEOR" in sat_name_curr or "METEOR" in sat_name_next:
                if "METEOR" in sat_name_curr and "METEOR" not in sat_name_next:
                    if at_job_id_next != 0:
                        delete_job(str(pass_start_next))
                        cursor.execute("DELETE FROM predict_passes WHERE pass_start = ?", (pass_start_next,))
                elif "METEOR" in sat_name_next and "METEOR" not in sat_name_curr:
                    if at_job_id_curr != 0:
                        delete_job(str(pass_start_curr))
                        cursor.execute("DELETE FROM predict_passes WHERE pass_start = ?", (pass_start_curr,))
                elif "METEOR" in sat_name_curr and "METEOR" in sat_name_next:
                    if max_elev_curr > max_elev_next:
                        if at_job_id_next != 0:
                            delete_job(str(pass_start_next))
                            cursor.execute("DELETE FROM predict_passes WHERE pass_start = ?", (pass_start_next,))
                    else:
                        if at_job_id_curr != 0:
                            delete_job(str(pass_start_curr))
                            cursor.execute("DELETE FROM predict_passes WHERE pass_start = ?", (pass_start_curr,))
            else:
                if max_elev_curr > max_elev_next:
                    if at_job_id_next != 0:
                        delete_job(str(pass_start_next))
                        cursor.execute("DELETE FROM predict_passes WHERE pass_start = ?", (pass_start_next,))
                else:
                    if at_job_id_curr != 0:
                        delete_job(str(pass_start_curr))
                        cursor.execute("DELETE FROM predict_passes WHERE pass_start = ?", (pass_start_curr,))

        conn.commit()

    conn.close()
    print("Finished comparing and deleting rows based on max_elev and sat_name")
