![Raspberry NOAA](../assets/header_1600_v2.png)

# Auto-Post Images to Twitter

If you want all captured images to automatically upload to your twitter feed, you can configure this fairly
easily. First, navigate to the [Twitter Developer site](http://developer.twitter.com/) and apply for a developer
account. Once you've obtained the account, edit the `$HOME/.tweepy.conf` file on the Raspberry Pi instance under
the `pi` user account to specify the various variables seen below:

```bash
export CONSUMER_KEY = ''
export CONSUMER_SECRET = ''
export ACCESS_TOKEN_KEY = ''
export ACCESS_TOKEN_SECRET = ''
```

Once you specify a valid `CONSUMER_KEY`, any/all future captures will automatically post to your Twitter feed!
