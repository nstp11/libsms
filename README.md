# libsms
Pure bash SMS library for [GIGAS's SMS API](https://sms.gigas.com/api/3.0/docs/).

# Dependencies
This library depends on the following packages:

- https://github.com/stedolan/jq

# Usage
Configure your `API_KEY` by updating `settings.sh`, then run:

```
/usr/bin/bash main.sh "google.com,17,34666666666,34777777777" "google.com,16,34666666666,34777777777"
```
