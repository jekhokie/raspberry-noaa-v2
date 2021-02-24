![Raspberry NOAA](../assets/header_1600_v2.png)

If you want to update the annotation that exists on the images, the process is fairly straightforward.
Simply edit the file `config/annotation/annotation.html.j2` following the instructions in the file
and the next pass captures you receive should have the images overlaid with the new annotation format.

Note that hte `annotation.html.j2` template uses the
[Jinja2 template specification](https://jinja.palletsprojects.com/en/2.11.x/). Simply speaking, this means any
variables you wish replaced should be wrapped in double curly braces (`{{ my_var }}`), and in general, any
Jinja2 template syntax should work. However, it's recommended that you keep the template as pure to variable
replacement without complex conditionals as possible as this will keep the template easier to debug.

To have additional resources included in the HTML rendering of the annotation (images, etc.), simply place
the referenced images in the same directory alonside the template file (`config/annotation/`).

## Testing

If you want to iterate on your annotation without needing to wait for a new pass, you can make modifications
to the `config/annotation/annotation.html.j2` file and then run the `scripts/testing/produce_annotation_image.sh`,
passing an output file to write the annotation image to for inspection. This script will inject parameters
in the same way a typical pass would, allowing you to view your HTML-driven annotation with similar parameters
that you would see during a pass capture. For example, run the following command:

```bash
./scripts/testing/produce_annotation_image.sh /tmp/output.png
```

After running the above command, open the file `/tmp/output.png` to see what your HTML-driven annotation would
look like. You can go about this in a couple different ways, but below are a couple helpful methods depending on your
scenario:

1. If you are on a remote Linix-based machine, you can copy the file from your remote Raspberry Pi instance to your
local machine via executing (from your local machine) `scp pi@<your_pi_ip_address>:/tmp/output.png`, where
`<your_pi_ip_address>` is the IP or hostname of your remote Pi instance. This will place the file `output.png` in the
local directory on your local machine where you ran the command from.
2. If you're running on a Windows-based machine, you can hack around needing any kind of FTP-based transfer by copying
the file into the assets directory of the webpanel on your Raspberry Pi, and then viewing it from your local machine
browser. Copy the file to the asset directory using `cp output.png /var/www/wx-new/public/assets/` and then open
a browser on your local machine pointed to the webpanel on your remote Pi at this address:
`http://<your_pi_ip_or_hostname>/assets/output.png`.

This is the image that will be overlaid in the location specified on your capture images. Note that
the background is by default transparent to ensure that the image does not block any more of the capture image
than it needs to.
