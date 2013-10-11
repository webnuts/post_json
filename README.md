# PostJson

Its a perfect match for Restful JSON API's.
Combining features from Ruby, ActiveRecord and PostgreSQL provide a great Document Database

(This readme is incomplete. The gem offers alot more than explained here!)

## Getting started
1. You can add it to the Rails `Gemfile` if you haven't yet:

        gem 'post_json'

2. At the command prompt, install the gem and migrate the necessary schema for PostgreSQL:

        bundle install
        rails g post_json:install
        rake db:migrate
        
That's it!

## Using it

You should feel home right away, if you already know `Active Record`. PostJson uses `Active Record` and we try hard to respect the API




## Dynamic Indexes

We have created a feature we call `Dynamic Index`. It will automatically create indexes on slow queries, so queries speed up considerably.

PostJson will measure the duration of each `SELECT` query and instruct PostgreSQL to create an Expression Index, if the query duration is above a specified threshold.

Each collection have attribute `use_dynamic_index` (default is `true`) and attribute `create_dynamic_index_milliseconds_threshold` (default is `50`).

Lets say that you execute the following query and the duration is above the threshold:

`PostJson::Document.collection("customers").where(name: "Jacob").count`

PostJson will create (unless it already exists) the following Expression Index:

`CREATE INDEX dyn_<collection_id>_name ON public.post_json_documents(json_selector('name', __doc__body)) WHERE __doc__collection_id = '<collection_id>'`

## Overriding the default settings for collections

You have 2 options.

The first option is perfect for deployment, where you want the settings override to be part of the deployment.

Open `config/initializers/post_json.rb` and setup the collection(s):

    PostJson::Collection.create_or_update({name: "customers"})

    # And later on you can easily add another collection:

    PostJson::Collection.create_or_update({name: "customers", use_timestamps: false},
                                          {name: "orders"})


The second option is perfect to everything else, where you want a fast way to override the settings at runtime.

## Requirements

- PostgreSQL 9.2 or 9.3
- PostgreSQL PLV8 extension.

## License

PostJson is released under the MIT License

## Want to contribute?

That's awesome, thank you!

Do you have an idea or suggestion? Please create an issue or send us an e-mail (hello@webnuts.com). We would be happy to implement (if we like the idea) right away.

You can also send us a pull request with your contribution.

<a href="http://www.webnuts.com" target="_blank">
  <img src="http://www.webnuts.com/logo/post_json/logo.png" alt="Webnuts.com">
</a>
##### Sponsored by Webnuts.com
