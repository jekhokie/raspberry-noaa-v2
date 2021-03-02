![Raspberry NOAA](../assets/header_1600_v2.png)

## TLS-Enabling Your Webpanel

This framework includes the ability to run your web server using TLS for encryption using self-signed certificates.
In a future revision, this may be enhanced to support "bring your own" certificates as self-signed certificates
are not "security approved" per-se, but this minimal configuration enables the ability to do things such as
password-protect the Admin endpoint of the webpanel when TLS is enabled in order to help prevent (but not eliminate)
the possibility of password sniffing.

However, some web browsers such as Google Chrome do not allow access to servers with self-signed certificates by
default. In these browsers, there is usually a warning when attempting to visit the page, sometimes with an option
to "Continue anyways". In some cases (again, such as Google Chrome) this option is unavailable, but there is a
workaround. If you attempt to visit your web server on the TLS-enabled port in Google Chrome but are blocked from
doing so, when you visit the page in the browser, click anywhere with your mouse and type one of the following
words on your keyboard (note, nothing will show up when typing this, but if you type the word correctly, Chrome
should automatically forward you to the site). This should only be needed the very first time you visit the
TLS-enabled site (or when certificates are rotated):

* Chrome Version 65: Type the word `thisisunsafe`
* Chrome Versions 62-64: Type the word `badidea`
* Older Versions: Type the word `danger`

Note that the above are know to work at the time of this article being written but may change, and are obviously
not applicable for other browsers. See the browser documentation for the browser you are using in order to figure
out how to access the site with the self-signed certificate.

## TLS Certificate Rotation

By default, the configuration parameter `cert_valid_days` is set to `365` unless configured differently in your
`config/settings.yml` file. This is the number of days the TLS certificate will be valid for before expiring.
Once a certificate expires, a browser will very likely (and rightfully so) block you from accessing the webpanel.
If this occurs, re-run the `./install_and_upgrade.sh` script which has the ability to detect an expired (or expiring
within the next 24-hours) certificate and re-generate a new certificate/install it for use and automatically
restart your webpanel services.
