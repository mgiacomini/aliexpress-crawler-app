# Aliexpress Buying Crawler

* Main branch: master
* Ruby version: 2.3.1
* Rails version: 4.2.7
* PG version: ~> 0.18

## Installation / Getting Started

To install (development environment) on your machine, just follow the tips above:

    % git clone git@github.com:patrickemuller/aliexpress-crawler.git

It assumes you have a machine equipped with Ruby, Postgres, etc. If not, set up
your machine with [this script](https://github.com/COSMITdev/env-setup)
After setting up, you can run the application using:

    % bin/rails server

For default we use THIN as development server, but you can use [Heroku Local](https://devcenter.heroku.com/articles/heroku-local) to simulate production
environment on your local machine.

## Running Specs

* **Create Test DB and run migrations**

```bin/rake db:create db:migrate RAILS_ENV=test```

* **Run Specs**

```bundle exec rspec .```

## Contributing

The nomenclature of the feature branch is composite by `{name initials}-{feature name || description}`, and probably will be something like that: `pm-review-typo` or `pm-create-users`.

Also, always keep you branch up-to-date with master, and keep master updated too. To do this, always run `git checkout master && git pull origin master`

Now, to create the feature branch just run `git checkout master && git checkout -b
[name-of-branch]`.

## Openning a Pull Request

After you finish the implementations what you did on your branch, you can up this to Github and open a Pull Request. This way other persons of the project can available your things and propose improvements. Just create the PR when you have confidence you create everything you need to like views, controllers, specs...
