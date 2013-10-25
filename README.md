# Welcome to PostJson

PostJson is everything you expect of ActiveRecord and PostgreSQL, with the added power and dynamic nature of a document database (Free as a bird! No schemas!). 

PostJson combines features of Ruby, ActiveRecord and PostgreSQL to provide a great document database by taking advantage of PostgreSQL 9.2+ support for JavaScript (Google's V8 engine). We started the work on PostJson, because we love document databases **and** PostgreSQL. 

- [Installation](#installation)
- [Usage](#usage)
    - [Model](#model)
    - [Validations](#validations)
    - [Querying](#querying)
    - [Accessing attributes](#accessing-attributes)
    - [Transformation with select](#transformation-with-select)
    - [Dates](#dates)
    - [Supported methods](#supported-methods)
- [Configuration Options](#configuration-options)
- [Performance](#performance)
- [Dynamic Indexes](#dynamic-indexes)
    - [Example](#example)
    - [Index configuration](#index-configuration)
    - [Manual creation of index](#manual-creation-of-index)
    - [List existing indexes](#list-existing-indexes)
    - [Destroying an index](#destroying-an-index)
    - [Warning](#warning)
- [Primary Keys](#primary-keys)
- [Migrating to PostJson](#migrating-to-postjson)
- [The future](#the-future)
- [Requirements](#requirements)
- [License](#license)
- [Want to contribute?](#want-to-contribute)

See example of how we use PostJson as part of [Jumpstarter](https://github.com/webnuts/jumpstarter).

## Installation

Add the gem to your `Gemfile`:

    gem 'post_json'

Then:

    $ bundle install

Run the generator and migrate the db:

    $ rails g post_json:install
    $ rake db:migrate
        
That's it!

(See POSTGRESQL_INSTALL.md if you need the install instructions for PostgreSQL with PLV8)

## Usage

PostJson also tries hard to respect the ActiveRecord API, so, if you have experience with ActiveRecord, the model methods work as you would expect.

### Model

All PostJson models represent a collection.

```ruby
class Person < PostJson::Collection["people"]
end
        
me = Person.create(name: "Jacob")
```

__Notice you don't have to define model attributes anywhere!__
        
As you can see, this is very similar to a standard ActiveRecord model. `PostJson::Collection["people"]` inherits from `PostJson::Base`, which, in turn, inherits from `ActiveRecord::Base`. This is part of the reason the `Person` model will seem so familiar.

You can also skip the creation of a class:

```ruby    
people = PostJson::Collection["people"]
me = people.create(name: "Jacob")
```

### Validations

Use standard `ActiveRecord` validations in your models:

```ruby
class Person < PostJson::Collection["people"]
  validates :name, presence: true
end
```

Read the <a href="http://guides.rubyonrails.org/active_record_validations.html" target="_blank">Rails guide about validation</a> if you need more information.

### Querying

```ruby
me = Person.create(name: "Jacob", details: {age: 33})

# PostJson supports filtering on nested attributes
also_me_1 = Person.where(details: {age: 33}).first
also_me_2 = Person.where("details.age" => 33).first

# It is possible to use a pure JavaScript function for selecting documents
also_me_3 = Person.where("function(doc) { return doc.details.age == 33; }").first

# It is also possible to write real SQL queries. Just prefix the JSON attributes with `json_`
also_me_4 = Person.where("json_details.age = ?", 33).first
```        

### Accessing attributes

```ruby
person = Person.create(name: "Jacob")
puts person.name            # => "Jacob"
puts person.name_was        # => "Jacob"
puts person.name_changed?   # => false
puts person.name_change     # => nil

person.name = "Martin"
        
puts person.name_was        # => "Jacob"
puts person.name            # => "Martin"
puts person.name_changed?   # => true
puts person.name_change     # => ["Jacob", "Martin"]
        
person.save

puts person.name            # => "Martin"
puts person.name_was        # => "Martin"
puts person.name_changed?   # => false
puts person.name_change     # => nil
```

### Transformation with `select`

The `select` method allows you to transform a collection of documents into an array of hashes that contain only the attributes you want. The hash passed to `select` maps keys to selectors of arbitrary depth. 

> In this example we only want the 'name' and 'age' attributes from the `Person` but 'age' is nested under 'details'.

```ruby
# create a person with age nested under details
me = Person.create(name: "Jacob", details: {age: 33})

# the dot (.) signifies that the selector is looking for a nested attribute
other_me = Person.limit(1).select({name: "name", age: "details.age"}).first

puts other_me   
# => {name: "Jacob", age: 33}
```

### Dates

Dates are not natively supported by JSON. This is why dates are persisted as strings.

```ruby
me = Person.create(name: "Jacob", nested: {now: Time.now})
puts me.attributes
# => {"name"=>"Jacob", "nested"=>{"now"=>2013-10-24 16:15:05 +0200}, "id"=>"fb9ef4bb-1441-4392-a95d-6402f72829db", "version"=>1, "created_at"=>Thu, 24 Oct 2013 14:15:05 UTC +00:00, "updated_at"=>Thu, 24 Oct 2013 14:15:05 UTC +00:00}
```

Lets reload it and see how it is stored:

```ruby
me.reload
puts me.attributes
# => {"name"=>"Jacob", "nested"=>{"now"=>"2013-10-24T14:15:05.783Z"}, "id"=>"fb9ef4bb-1441-4392-a95d-6402f72829db", "version"=>1, "created_at"=>"2013-10-24T14:15:05.831Z", "updated_at"=>"2013-10-24T14:15:05.831Z"}
```

PostJson will serialize Time and DateTime to format `strftime('%Y-%m-%dT%H:%M:%S.%LZ')` when persisting documents.

PostJson will also parse an attribute's value to a `DateTime` object, if the value is a string and matches the format.

### Supported methods

all, any?, blank?, count, delete, delete_all, destroy, destroy_all, each, empty?, except, exists?, find, find_by, 
find_by!, find_each, find_in_batches, first, first!, first_or_create, first_or_initialize, ids, last, limit, load, 
many?, offset, only, order, pluck, reorder, reverse_order, select, size, take, take!, to_a, to_sql, and where.
        
We also added `page(page, per_page)`, which translate into `offset((page-1)*per_page).limit(per_page)`.


## Configuration Options

```ruby
PostJson.setup "people" do |collection|
  collection.record_timestamps = true                           # default is 'true'
  collection.created_at_attribute_name = "created_at"           # default is 'created_at'
  collection.updated_at_attribute_name = "updated_at"           # default is 'updated_at'
  collection.include_version_number = true                      # default is 'true'
  collection.version_attribute_name = "version"                 # default is 'version'
  collection.use_dynamic_index = true                           # default is 'true'
  collection.create_dynamic_index_milliseconds_threshold = 50   # default is '50'
end
```

For a Rails project this configuration could go in an initializer (`config/initializers/post_json.rb`).

## Performance

On a virtual machine running on a 3 year old laptop we created 100.000 documents:

```ruby
test_model = PostJson::Collection["test"]
100000.times { test_model.create(content: SecureRandom.uuid) }
content = test_model.last.content
        
result = test_model.where(content: content).count
# Rails debug duration was 975.5ms
```

The duration was above 50ms as you can see.

PostJson has a feature called "Dynamic Index". It is enabled by default and works automatic behind the scene. It has now created an index on 'content'.
    
Now lets see how the performance will be on the second and future queries using 'content':

```ruby
result = test_model.where(content: content).count
# Rails debug duration was 1.5ms
```

It shows PostgreSQL as a document database combined with indexing has great performance out of the box.

See the next section about "Dynamic Indexes" for details.

## Dynamic Indexes

PostJson will measure the duration of each `SELECT` query and instruct PostgreSQL to create an index, 
if the query duration is above a specified threshold. This feature is called `Dynamic Index`. Since most 
applications perform the same queries over and over again we think you'll find this useful.

Each collection (like `PostJson::Collection["people"]` above) has two index attributes:

* **use_dynamic_index** (default: true) 
* **create_dynamic_index_milliseconds_threshold** (default: 50)

### Example

```ruby
PostJson::Collection["people"].where(name: "Jacob").count

# => query duration > 50ms
```

PostJson will check for an index on `name` and create it if it doesn't exist.

### Index configuration

```ruby
class Person < PostJson::Collection["people"]
  self.create_dynamic_index_milliseconds_threshold = 75
end
```

or:

```ruby
PostJson::Collection["people"].create_dynamic_index_milliseconds_threshold = 75
```

### Manual creation of index

```ruby
class Person < PostJson::Collection["people"]
  self.ensure_dynamic_index("name", "details.age")
end
```
 or:

```ruby
PostJson::Collection["people"].ensure_dynamic_index("name", "details.age")
```

### List existing indexes

```ruby
puts Person.existing_dynamic_indexes
# => ["name", "details.age"]
```

or:

```ruby
puts PostJson::Collection["people"].existing_dynamic_indexes
# => ["name", "details.age"]
```

### Destroying an index

```ruby
Person.destroy_dynamic_index("name")
```

or:

```ruby
PostJson::Collection["people"].destroy_dynamic_index("name")
```

### WARNING

Do not set the dynamic index threshold too low as PostJson will try to create an index for every query. A threshold of 1 millisecond would be less than the duration of almost all queries.

## Primary Keys

PostJson assigns UUID as primary key (id):

```ruby
me = Person.create(name: "Jacob")

puts me.id    
# => "297a2500-a456-459b-b3e9-e876f59602c2"
```

or you can set it directly:

```ruby
john_doe = Person.create(id: "John Doe")
```

The primary key is downcased when doing a query or finding records:

```ruby
found = Person.where(id: "JOhN DoE").first

puts found.attributes
# => {"id"=>"John Doe", "version"=>1, "created_at"=>"2013-10-22T10:42:26.190Z", "updated_at"=>"2013-10-22T10:42:26.190Z"}
        
found_again = Person.find("JOhN DoE")

puts found_again.attributes
# => {"id"=>"John Doe", "version"=>1, "created_at"=>"2013-10-22T10:42:26.190Z", "updated_at"=>"2013-10-22T10:42:26.190Z"}
```

## Migrating to PostJson

Lets say you have a model called `User`:

```ruby
class User < ActiveRecord::Base
  ...
end
```

Then you migrate:

```ruby
PostJson::Collection["users"].transaction do
  User.all.find_each do |user|
    PostJson::Collection["users"].create(user.attributes)
  end
end
```

Now replace `ActiveRecord::Base`:

```ruby
class User < PostJson::Collection["users"]
  ...
end
```

Users will have the exact same content, including their primary keys (id).

That's it!

## The future

A few things we will be working on:
- Versioning of documents with support for history, restore and rollback.
- Restore a copy of entire collection at a specific date.
- Copy a collection.
- Automatic deletion of dynamic indexes when unused for a period of time.
- Full text search. PostgreSQL has many great features.
- Bulk import.
- Whitelisting of attributes for models (strong attributes).
- Whitelisting of collection names.
- Support for files. Maybe as attachments to documents.
- Keep the similarities with ActiveRecord API, but it shouldn't depend on Rails or ActiveRecord. 
- Better performance and less complex code.

And please let us know what you think and what you need. 

## Requirements

- PostgreSQL 9.2 or 9.3
- PostgreSQL PLV8 extension.

## License

PostJson is released under the MIT License. See the MIT-LICENSE file.

## Want to contribute?

That's awesome, thank you!

Do you have an idea or suggestion? Please create an issue or send us an e-mail (hello@webnuts.com). We would be happy to implement right away.

You can also send us a pull request with your contribution.

<a href="http://www.webnuts.com" target="_blank">
  <img src="http://www.webnuts.com/logo/post_json/logo.png" alt="Webnuts.com">
</a>
##### Sponsored by Webnuts.com
