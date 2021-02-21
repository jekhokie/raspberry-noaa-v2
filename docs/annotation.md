![Raspberry NOAA](../assets/header_1600_v2.png)

If you want to update the annotation that exists on the images, the process is fairly straightforward.
Simply edit the file `config/annotation/annotation.html.j2` following the instructions in the file
and the next pass captures you receive should have the images overlaid with the new annotation format.

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
look like. This is the image that will be overlaid in the location specified on your capture images. Note that
the background is by default transparent to ensure that the image does not block any more of the capture image
than it needs to.
