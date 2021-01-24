![Raspberry NOAA](header_1600.png)

# Reception
First thing we need to test is reception. It's the way to be sure the antenna, reception line, reception hardware and software are working properly. There is a [test_reception.sh](test_reception.sh) script that makes testing easy, just tune a broadcast FM near you and listen to the audio, then make the proper adjustments to improve reception.

Open a SSH connection to your Raspberry PI and execute `test_reception.sh <tune frequency>`. 

```bash
cd raspberry-noaa/
./test_reception.sh 90.3
```

Now open a terminal on your Linux/Mac/(And maybe windows?) computer and run

```bash
ncat your.raspberry.pi.ip 8073 | play -t mp3 -
```
where `your.raspberry.pi.ip` is your Raspberry PI IP address. Now you should listen to the frequency tuned before

# Schedule
This project uses [crontab](https://crontab.guru/) to schedule the scheduler (funny huh?). Running

```bash
crontab -l
```

This will show the schedule entry for `schedule.sh`, the script that downloads the kepler elements from Internet and creates [at](https://linux.die.net/man/1/at) jobs for each pass.

```bash
atq
```

Will show the scheduled jobs for today, each job can be described using `at -c <job_id>`.

# Images
Images are saved in the web server's directory, so you can access your received images at http://your.raspberry.pi.ip/, where `your.raspberry.pi.ip` is your Raspberry PI IP address.

# Pruning
Run `prune.sh` to delete old images. By default it deletes the 10 oldest images from the disk and the database. If you want to schedule this task, run

```bash
cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa/prune.sh") | crontab -
```
