![Raspberry NOAA](../assets/header_1600_v2.png)

In `config/settings.yml`, setting `enable_email_push: true` and configuring an `email_push_address` will enable pushing all
captured, processed images to a destination email address. This is useful when configuring services such as If This Then That
(IFTTT) to accept the email with the subject and email attachment and post it to services such as Facebook, Twitter, or other
locations to store your images. Below outlines how to accomplish this, with this framework installing a basic
`/home/{{ target_user }}/.msmtprc` file that enables configuring a gmail account to email images with.

**Note**: You need an existing email address that you have full access to in order to configure sending - this configuration
will use that email address credentials for sending emails from your receiver device.

**WARNING**: MAKE SURE YOU KEEP THE CONFIG FILE LOCKED DOWN! This file (`/home/{{ target_user }}/.msmtprc`) will contain your email credentials,
and is by default written to the file system as read/write only by the `pi` user. This is why it's extremely important to not
expose your Pi to the public internet unless you absolutely know what you're doing when it comes to security, and at a minimum,
absolutely change the `pi` user default password to something HIGHTLY complex and hard to hack!

## Configure Settings and Update

To enable this functionality, first update your `config/settings.yml` to set `enable_email_push: true` and set an email
address to forward images to as `email push address`. Then, re-run the installer script `./install_and_upgrade.sh`, which will
align your environment to install dependencies and requirements, including a `/home/{{ target_user }}/.msmtprc` file that has defaults for
configuring a gmail account to send emails.

## Configure Email Settings

Once the installer has been run, you should see a settings file in your `pi` user home directory named `/home/{{ target_user }}/.msmtprc`.
Edit this file for your email settings, including adding your gmail credentials for the email address you wish to use to send
the image emails to your target address.

**Note**: that if you are running Multi-Factor Authentication (sometimes known as 2-Step Verification), you will need to obtain
an App Password for your account and use this in place of your login credentials in order to allow the `mpack` binary to
'bypass' Multi-Factor Authentication when sending emails autonomously. Follow the instructions in
[this article](https://support.google.com/mail/answer/185833?hl=en#app-passwords) to configure an app password for your setup
and use this within the `/home/{{ target_user }}/.msmtprc` file for the `password` setting.

**Note**: This file defaults to a template to configure a gmail email account to send images. If you want to know more about
how to configure this file for additional account types, see the [msmtp](https://wiki.debian.org/msmtp) documentation.

Since May 2022 Google have enforced 2FA. You need to setup 2FA in your Google Account setup, and then obtain an 'App Password' 
This app password is then used INSTEAD OF your gmail account's normal password in the '''./msmtprc''' file. 
Follow this video for the process of obtaining the app password: 
[https://www.youtube.com/watch?v=Jp9B0rY6Fxk&t=138s](https://www.youtube.com/watch?v=Jp9B0rY6Fxk&t=138s)

## Testing (Optional)

If you'd like to see whether the configurations you've set are working, you can run a quick test from the command line using
an exsting image (or any image for that matter). Simply run the following below, replacing `<DEST_EMAIL>` with an email
address you want to send the email to (such as the one configured in your `config/settings.yml` file, for example):

```bash
mpack -s "This is a test" /srv/images/NOAA-18-20210211-205249-MCIR.jpg <DEST_EMAIL>
```

If all goes well, an email will be sent to `<DEST_EMAIL>` with the subject "This is a test" and the body of the email
containing the image specified as an attachment. This indicates your configuration is ready to go and all new images should
successfully be emailed to this destination!

## Profit

Once the above have been performed, simply wait until your next capture occurs and you should then see an email show up
in your target email address. If this is a destination service such as IFTTT that is configured to post images to a Facebook
page, for example, the image should be posted to the page with text from the annotation that is built alongside the capture!

## Troubleshooting

If you are not receiving emails at the destination configured, inspect the `/var/log/msmtp/output.log` file for errors that
might be occurring. This file is also good to consult in general as it contains information about emails being sent that were
successful.
