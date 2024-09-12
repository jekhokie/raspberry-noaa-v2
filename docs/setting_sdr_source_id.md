![Raspberry NOAA](../assets/header_1600_v2.png)

# Setting SDR Device ID

Good news - If you are using more than 1 SDR Dongle in your RN2 configuration and you wish to assign a particular SDR Dongle/Antenna pair to a satellite, you can!

  Work flow:

    #1 - Assign a unique serial # to each RTL-SDR Dongle that you wish to specitically assign to a satellite  
    #2 - Update settings.yml 
    #3 - Execute install_and_upgrade.sh
    #4 - After the scheduled job executes for the satellite you assigned a unique device id to, confirm correct device ID was used.

  These example instructions are for RTL-SDR Dongles. 

  Step #1 - Assign a unique serial # to each RTL-SDR Dongle

     RTL Serial# programmed into the SDR and the sdr_device_id in settings.yml must not have any leading ZERO's.  
     The serial number must be no more than 8 characters and it must be an integer and must not have any leading ZERO's.
     
For example it can be **0** or it can be set as high as **99999999**     It cannot have leading ZERO's **00007777**


Check currect serial# of installed SDR Dongle's

	rtl_test -t
	Found 2 device(s):
  	0:  RTLSDRBlog, Blog V4, SN: 00000001
  	1:  RTLSDRBlog, Blog V4, SN: 00000001

Change the SDR serial #, when prompted, select 'y' to change
Since our SDR Device ID's must fall between 0-99999999  For this example we will update both SDR Dongles with serial #'s 1 & 2,
so remove all but the one of the SDR's whose serial # you want to update before running rtl_eeprom utility.

	rtl_eeprom -s 1
	Found 1 device(s):
	  0:  Generic RTL2832U OEM

	Using device 0: Generic RTL2832U OEM
	Found Rafael Micro R828D tuner
	RTL-SDR Blog V4 Detected

	Current configuration:
	__________________________________
	Vendor ID:              0x0bda
	Product ID:             0x2838
	Manufacturer:           RTLSDRBlog
	Product:                Blog V4
	Serial number:          00000001
	Serial number enabled:  yes
	IR endpoint enabled:    yes
	Remote wakeup enabled:  no
 	__________________________________

	New configuration:
	__________________________________
	Vendor ID:              0x0bda
	Product ID:             0x2838
	Manufacturer:           RTLSDRBlog
	Product:                Blog V4
	Serial number:          1
	Serial number enabled:  yes
	IR endpoint enabled:    yes
	Remote wakeup enabled:  no
	__________________________________
	Write new configuration to device [y/n]? y

	Configuration successfully written.
	Please replug the device for changes to take effect.
	

After removing and reinstalling the SDR Dongle, Confirm the serial #1 written is correct

	rtl_test
	Found 1 device(s):
	  0:  RTLSDRBlog, Blog V4, SN: 1

Now remove that SDR Dongle and insert the second SDR Dongle which we will assign serial #2 

	rtl_eeprom -s 2
	Found 1 device(s):
	  0:  Generic RTL2832U OEM

	Using device 0: Generic RTL2832U OEM
	Found Rafael Micro R828D tuner
	RTL-SDR Blog V4 Detected

	Current configuration:
	__________________________________________
	Vendor ID:              0x0bda
	Product ID:             0x2838
	Manufacturer:           RTLSDRBlog
	Product:                Blog V4
	Serial number:          00000001
	Serial number enabled:  yes
	IR endpoint enabled:    yes
	Remote wakeup enabled:  no
	__________________________________________

	New configuration:
	__________________________________________
	Vendor ID:              0x0bda
	Product ID:             0x2838
	Manufacturer:           RTLSDRBlog
	Product:                Blog V4
	Serial number:          2
	Serial number enabled:  yes
	IR endpoint enabled:    yes
	Remote wakeup enabled:  no
	__________________________________________
	Write new configuration to device [y/n]? y

	Configuration successfully written.
	Please replug the device for changes to take effect.


After removing and reinstalling the second SDR Dongle, Confirm the serial #2 written is correct

	rtl_test
	Found 1 device(s):
	  0:  RTLSDRBlog, Blog V4, SN: 2


Now insert all the SDR dongles and ensure they show up as Serial #1 & #2

	rtl_test
	Found 2 device(s):
	  0:  RTLSDRBlog, Blog V4, SN: 1
	  1:  RTLSDRBlog, Blog V4, SN: 2


  Step #2 - Update settings.yml 

Make a backup before changing settings.yml, just in case...

	cp -p ${HOME}/raspberry-noaa-v2/config/settings.yml ${HOME}/raspberry-noaa-v2/config/settings.yml.pre_device_id_change

In settings.yml you must to enable use_device_string

	use_device_string: true

For each satellite that you want to assign a specific device id for, you must update its respective value. 

	Example only...
 	noaa_15_sdr_device_id: 1
	noaa_18_sdr_device_id: 1
	noaa_19_sdr_device_id: 1

	meteor_m2_3_sdr_device_id: 2
	meteor_m2_4_sdr_device_id: 2
 

  Step #3 - Execute install_and_upgrade.sh

	cd ${HOME}/raspberry-noaa-v2
	./install_and_upgrade.sh

  Step #4 - After the scheduled job executes for the satellite you assigned a unique device id to, confirm that the correct device ID was used.

       
	view /var/log/raspberry-noaa-v2/output.log

Search for source_id by typing `/source_id`   with each repeating forward `/` you type it should search through the file for occurances.

Here you can see satdump saw both serial #1 & serial #2, since I set NOAA 15 to use Serial #1, that is what it used for source_id : "1"

	[15:24:52 - 12/08/2024] ^[[36m(D) Device RTLSDRBlog Blog V4 #1
	[15:24:52 - 12/08/2024] ^[[36m(D) Device RTLSDRBlog Blog V4 #2
	[15:24:52 - 12/08/2024] ^[[36m(D) Device RTL-TCP
	[15:24:52 - 12/08/2024] ^[[36m(D) Device SDR++ Server
	[15:24:52 - 12/08/2024] ^[[36m(D) Device SpyServer
	Found Rafael Micro R828D tuner
	RTL-SDR Blog V4 Detected
	[15:24:53 - 12/08/2024] ^[[36m(D) Set RTL-SDR samplerate to 1024000
	[15:24:53 - 12/08/2024] ^[[36m(D) Set RTL-SDR frequency to 137620000
	[15:24:53 - 12/08/2024] ^[[36m(D) Set RTL-SDR Bias to 0
	[15:24:53 - 12/08/2024] ^[[36m(D) Set RTL-SDR AGC to 0
	[15:24:53 - 12/08/2024] ^[[36m(D) Set RTL-SDR Gain to 49
	[15:24:53 - 12/08/2024] ^[[36m(D) Set RTL-SDR PPM Correction to -3
	[15:24:53 - 12/08/2024] ^[[36m(D) Parameters :
	[15:24:53 - 12/08/2024] ^[[36m(D)    - autocrop_wedges : true
	[15:24:53 - 12/08/2024] ^[[36m(D)    - baseband_format : "cf32"
	[15:24:53 - 12/08/2024] ^[[36m(D)    - buffer_size : 1000000
	[15:24:53 - 12/08/2024] ^[[36m(D)    - frequency : 137620000
	[15:24:53 - 12/08/2024] ^[[36m(D)    - gain : 49.6
	[15:24:53 - 12/08/2024] ^[[36m(D)    - ppm_correction : -3
	[15:24:53 - 12/08/2024] ^[[36m(D)    - samplerate : 1024000
	[15:24:53 - 12/08/2024] ^[[36m(D)    - satellite_number : 15
	[15:24:53 - 12/08/2024] ^[[36m(D)    - save_wav : true
	[15:24:53 - 12/08/2024] ^[[36m(D)    - sdrpp_noise_reduction : true
	[15:24:53 - 12/08/2024] ^[[36m(D)    - source : "rtlsdr"
	[15:24:53 - 12/08/2024] ^[[36m(D)    - source_id : "1"
      
Good luck!

