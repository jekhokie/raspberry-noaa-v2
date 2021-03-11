![Raspberry NOAA](../assets/header_1600_v2.png)

In `config/settings.yml`, setting `enable_discord_push: true` and configuring an `discord_webhook_url` will enable pushing all
captured, processed images to a destination Discord webhook.

## Create Discord Webhook

First, determine which Discord channel you wish to post the images to (or create one). Next, set up a webhook in a Discord server
by navigating to "Server Settings" -> "Integrations". Select "View Webhooks" and click "New Webhook". Specify a name that the
webhook will post the message as (the 'user'), and the associated channel you want images posted to, and then click "Save" and
"Copy Webhook URL" to copy the URL. We will need this in the next step.

## Configure Settings and Update

Update your `config/settings.yml` to set `enable_discord_push: true` and paste the webhook URL copied in the previous step/section
into the `discord_webhook_url` parameter. Then, re-run the installer script `./install_and_upgrade.sh`, which will align your
environment.

## Testing (Optional)

If you'd like to see whether the configurations you've set are working, you can run a quick test from the command line using
an exsting image (or any image for that matter). Simply run the following below, replacing `<PATH_TO_IMAGE>` with the fully-qualified
path to an image on the local file system:

```bash
./scripts/push_processors/push_discord.sh <PATH_TO_IMAGE> "Test\nTest2"
```

If all goes well, you should see a message and associated image show up on your Discord channel!

## Profit

Once the above have been performed, simply wait until your next capture occurs and you should then see messages pop up in your Discord
channel with annotations indicating the satellite, pass, etc. (similar annotation to the image annotation).
