#Amazon EB deployment for Wercker.com


[![wercker status](https://app.wercker.com/status/dd1f2ea0b8e654bd31801e1c14ead515/m "wercker status")](https://app.wercker.com/project/bykey/dd1f2ea0b8e654bd31801e1c14ead515)

> Please note: This requires you to have an already existing Elastic Beanstalk application and environment in place, it will not run a startup procedure.

* `key` (required) Credentials key provided by amazon.
* `secret` (required) Credentials key secret provided by amazon
* `app_name` (required) Name of the application.
* `env_name` (required) Name of the application environment you wish to deploy to.
* `region` (required) Region that your elastic beanstalk instance lives in, defaults to us-west-2.
* `sc` (optional) Source code repository


```yml
deploy:
    steps:
        - mrono/elastic-beanstalk-deploy:
            key: $AMAZON_KEY
            secret: $AMAZON_SECRET_KEY
            app_name: My Application
            env_name: production
            region: us-west-2
            sc: git
```
