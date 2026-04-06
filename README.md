# Code is a Liability

Too much code slows you down, creates risks, increases maintainability burdens, confuses AI. So let's commit less of it.

With just _one dev dependency_, you get

- Rid of all the **platform-specific code**
- Strict **linting**
- Cleaner templates
- Cleaner repositories
- Proper app ID, name, copyright statements, etc.

## Get Started

For convenience, setup an alias

```sh
$ alias fltr='flutter pub global run fltr'
```

Create your app

```sh
$ fltr create app -t riddance_env your_app_name
```

Start your app

```sh
$ cd your_app_name
$ fltr run
```

This with only five files in git.
