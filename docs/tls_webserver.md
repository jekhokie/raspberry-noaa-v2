![Raspberry NOAA](../assets/header_1600_v2.png)

**NOTE**: Exposing the raspberry-noaa-v2 framework to the public internet is *NOT* recommended. This frameowrk has
not been penetration or otherwise security tested for vulnerabilities and dangerous attack vectors. Exposing the
webpanel to the public internet is done at your own risk and should be assumed to have no reasonable safeguards that
can protect you from malicious actors. At a minimum, ensure your Raspberry Pi is residing on an isolated VLAN that
has no access into your other networks (completely isolated) to help reduce the blast radius of a break-in, and follow
the general guidance of providing reasonable security for your Pi instance (changing default `pi` user password, etc.).
Again, even in doing these things, it should be assumed that you can and potentially will be hacked at some point due
to the lack of security testing/analysis performed on this framework.

## TLS-Enabling Your Webpanel

This framework includes the ability to run your web server using TLS for encryption using certificates signed by the Let's Encrypt and `certbot` apt package.
This minimal configuration enables the ability to do things such as
password-protect the Admin endpoint of the webpanel when TLS is enabled in order to help prevent (but not eliminate)
the possibility of password sniffing.

To install TLS certificate on your website, first make sure you have a public IP address and open ports 80 and 443 on your router. Forward external port 80 to your setup running raspberry-noaa-v2 and port used by the non-TLS webserver (default is port 80).
Then, open `settings.yml` file and set:
```bash
enable_non_tls: true
enable_tls: false
```

After that, run the `./install_and_upgrade.sh` script. Then, run this command while replacing `YOUR_DOMAIN_NAME` with the domain name pointing to your IP address of your website:

```bash
sudo certbot certonly --webroot -w /var/www/wx-new/public -d YOUR_DOMAIN_NAME
```

After that, open `settings.yml` file and set:
```bash
enable_tls: true
```
After that, close port 80 on your router and run the install script. TLS certificates will be updated automatically.
That's it!

***NOTE***: You can optionally set `enable_non_tls: false` as the TLS website will be running.

## Password Protecting Admin Page

The Admin page in the webpanel allows for destructive activities such as deleting previous captures. In order to
protect this page, you may elect to enable basic auth with a simple username/password scheme. The method used for
this implementation is a VERY basic PHP code implementation that forces client authentication according to
[this post](https://www.php.net/manual/en/features.http-auth.php).

**WARNING**: Only enable this functionality if you are solely running a TLS-enabled web server. Enabling auth
without having the web server TLS-enabled means that when credentials are entered in the browser, they are sent
in clear text (non-encrypted), heightening the chances of being seen and stolen. Again (see all warnings above), while
TLS-enabling your web server should still not be considered "sufficient" for exposing this framework on the public
internet, you should definitely NOT enable auth on the Admin page *without* at least having TLS enabled.

To enable protection of the admin page, update the following parameters in your `config/settings.yml` file (see the
`config/settings.yml.sample` file for details on each of the parameters):

```bash
lock_admin_page: true
admin_username: 'admin'
admin_password: 'secretpass'
```

Obviously update the `admin_username` and `admin_password` to be the credentials you wish to use in order to access
the page. For the password, ensure you use a reasonably complex password that is hard to guess (and also hard to
hack via brute-force, rainbow lists, or other means).

Once you've updated the configs appropriately, re-run the `install_and_upgrade.sh` script, at which point a visit to
your Admin page in the webpanel should prompt you for a username and password. Enter the credentials you specified
in the above configs and you should be logged in.

As a note - the credentials establish a session for the user on first login. This session does not have an expiry
unless the session details are removed from the browser or the server is restarted. Different browsers have different
implementations of expiry and credential handling so there is no easy way to articulate each and every variant. If you
are wondering whether your Admin page is still secured, you can open an "Incognito" window in a Chrome browser and
attempt to access the page, which should prompt you for the username and password since incognito sessions do not
use session variables.
