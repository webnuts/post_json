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
        - [Warning](#warning)
    - [Manual creation of index](#manual-creation-of-index)
    - [List existing indexes](#list-existing-indexes)
    - [Destroying an index](#destroying-an-index)
- [Primary Keys](#primary-keys)
- [Migrating to PostJson](#migrating-to-postjson)
- [Roadmap](#roadmap)
  - [version 2.0: Reboot of PostJson - Even closer to the metal](#version-20-reboot-of-postjson---even-closer-to-the-metal)
  - [version 2.1: JavaScript bindings to collection methods for queries and find methods](#version-21-javascript-bindings-to-collection-methods-for-queries-and-find-methods)
  - [version 2.2: Relations](#version-22-relations)
  - [version 2.3: Versioning](#version-23-versioning)
  - [version 2.4: Bulk Import](#version-24-bulk-import)
  - [version 2.5: Export as CSV and HTML](#version-25-export-as-csv-and-html)
  - [version 2.6: Support for Files](#version-26-support-for-files)
  - [version 2.7: Automatic Deletion of Unused Dynamic Indexes](#version-27-automatic-deletion-of-unused-dynamic-indexes)
  - [version 3.x: Full Text Search](#version-3x-full-text-search)
- [The future](#the-future)
- [Requirements](#requirements)
- [License](#license)
- [Want to contribute?](#want-to-contribute)

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

###### WARNING

Do not set the dynamic index threshold too low as PostJson will try to create an index for every query. A threshold of 1 millisecond would be less than the duration of almost all queries.

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

## Roadmap

Please note the roadmap might change as we move forward.

#### version 2.0: Reboot of PostJson - Even closer to the metal
We have decided to reboot PostJson and move the implementation even closer to the metal. PostJson should be an add-on and not a replacement.

PostJson will be splitted into more components and concerns, so its possible to include as much as possible in existing models based directly on ActiveRecord::Base.

An example could be PostJson::Attributes:

```ruby
class Person < ActiveRecord::Base
  include PostJson::Attributes
  self.document_hash_column = "__dynamic_attributes"
end
```

PostJson::Attributes will take care of hiding the column assigned to `document_hash_column` and including the dynamic attributes in results like `to_json`.  
Lets see how far we can take it to make everything re-usable in existing applications!

Version 1.x store all documents in a table called `post_json_documents`. In version 2 each collection will have its own table. The table name will be the collection name. Each collection's metadata (title, settings etc.) will be stored as a record of a dedicated table.

#### version 2.1: JavaScript bindings to collection methods for queries and find methods
PostJson should support JavaScript bindings to its collection methods for query and find. These methods are immutable and have no side-effects.

This will allow seamless integration with rich JavaScript clients.

PostJson will integrate the `therubyracer` gem and use it to translate JavaScript queries to ActiveRecord queries.

Imagine a Rails controller's index method:

```ruby
def index
  js_query = params[:query]
  puts js_query
  # => function(people) { return people.limit(10).where({'gender': 'male'}); }

  result = PostJson::Collection['people'].eval_js_query(js_query)
  render json: result
end
```

#### version 2.2: Relations
PostJson should support relations between collections (like has_many, has_one and belongs_to) as persistable queries being able to work as dependent associations.

Relations should not be tied to class definitions. This will allow creation of relations from client software. It also allows relations to be copied / included in backup and migrations.

Imagine we have two collection: 'customers' and 'orders'.

Declaring 'has_one :order' on 'customers' will by default read an attribute named 'order_id' from the current customer document, and look-up a collection named 'orders' and find the correct order document using 'order_id' from the customer.

has_one will support override of foreign_key ('order_id'), collection_name ('orders') and mark dependent as ':delete' or ':destroy'. It will also support alias with ':as', readonly and a -> { ... } block for specializing.

Declaring 'has_many :orders' on 'customers' will by default read an attribute named 'order_ids' from the current customer document, and look-up a collection named 'orders' and query using where(id: order_ids).

has_many will support override of foreign_keys ('order_ids'), collection_name ('orders') and mark dependent as ':delete_all' or ':destroy_all'. It will also support alias with ':as', readonly and a -> { ... } block for specializing.

Declaring 'belongs_to :customer' on 'orders' will by default look-up a collection named 'customers' and find a customer document with an attribute named 'order_id' set to current order document's primary key value.

belongs_to will support override of foreign_key ('order_id'), collection_name ('customers') and mark dependent as ':delete' or ':destroy'. It will also support alias with ':as', readonly and a -> { ... } block for specializing.

PostJson will use ActiveSupport::Inflector to implement the naming conventions.

PostJson will serialize lambda (-> { ... } block for specializing) as part of the collection definitions.

#### version 2.3: Versioning
The history of data has great potential. It should be as easy as possible to get a view of the past. PostJson should be able to store the history of each document, including the possibility of restoring a document's previous state as a new document, roll back a document to its previous state and view the changes for each version of a document.

This should also count for an entire collection. PostJson should be able to create a new collection from an existing collection's previous state. It should also be possible to query and view the previous state of a collection, without restoring it to a new collection first.

#### version 2.4: Bulk Import
Importing data can often be boring and troublesome, if the source is a legacy database of some obscure format.
PostJson should be make it easy to setup a transformation. PostJson should also bulk inserts to improve performance.

#### version 2.5: Export as CSV and HTML
PostJson should be able to return results as CSV and HTML.

PostJson already support transformation with `select`.

CSV store tabular data and is not compatible with JSON. PostJson will flatten the data: {parent: {child: 123}} will be converted to {"parent.child" => 123}.

HTML will be rendered by templates. PostJson will support Mutache and store templates in the database. This will allow PostgreSQL to do the rendering and return results as strings.

#### version 2.6: Support for Files
PostJson should be able to store files in a specialized 'files' collection, since there are cases where it do make sense to store files in the database.

Files can be attached to other collections by using a has_one or has_many relation.

#### version 2.7: Automatic Deletion of Unused Dynamic Indexes
PostJson should provide automatic deletion of unused dynamic indexes as an optional feature.

#### version 3.x: Full Text Search
PostgreSQL has many great features to support Full Text Search.

## The future

We would love to hear new ideas or random thoughts about PostJson.

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
