# Welcome to PostJson

PostJson is everything you expect of ActiveRecord and PostgreSQL, but with the dynamic nature of document databases 
(free as a bird - no schemas).

PostJson take full advantage of PostgreSQL 9.2+ support for JavaScript (Google's V8 engine). We started the work on 
PostJson, because we love document databases and PostgreSQL. PostJson combine features of Ruby, ActiveRecord and 
PostgreSQL to provide a great document database.

See example of how we use PostJson as part of <a href="https://github.com/webnuts/jumpstarter">Jumpstarter</a>.


## Getting started
1. Add the gem to your Ruby on Rails application `Gemfile`:

        gem 'post_json'
        
2. At the command prompt, install the gem:

        bundle install
        rails g post_json:install
        rake db:migrate
        
That's it!

(See POSTGRESQL_INSTALL.md if you need the install instructions for PostgreSQL with PLV8)

## Using it

You should feel home right away, if you already know ActiveRecord. PostJson try hard to respect the ActiveRecord 
API, so methods work and do as you would expect from ActiveRecord.

PostJson is all about collections. All models represent a collection.

Also, __notice you don't have to define model attributes anywhere!__

1. Lets create your first model.

        class Person < PostJson::Collection["people"]
        end
        
        me = Person.create(name: "Jacob")

    As you can see it look the same as ActiveRecord, except you define `PostJson::Collection["people"]` instead of 
    `ActiveRecord::Base`.
    
    `Person` can do the same as any model class inheriting `ActiveRecord::Base`.
    
    You can also skip the creation of a class:
    
        people = PostJson::Collection["people"]
        me = people.create(name: "Jacob")

2. Adding some validation:

        class Person < PostJson::Collection["people"]
          validates :name, presence: true
        end

    PostJson::Collection["people"] returns a class, which is based on `PostJson::Base`, which is based on 
    `ActiveRecord::Base`. So its the exact same validation as you may know.
    
    Read the <a href="http://guides.rubyonrails.org/active_record_validations.html" target="_blank">Rails guide about validation</a> 
    if you need more information.

3. Lets create a more complex document and do a query:

        me = Person.create(name: "Jacob", details: {age: 33})
        
    Now we can make a query and get the document:
    
        also_me_1 = Person.where(details: {age: 33}).first
        also_me_2 = Person.where("details.age" => 33).first
        also_me_3 = Person.where("function(doc) { return doc.details.age == 33; }").first
        also_me_4 = Person.where("json_details.age = ?", 33).first
        
   PostJson support filtering on nested attributes as you can see. The two first queries speak for themself.
   
   The third query is special and show it is possible to use a pure JavaScript function for selecting documents.

   The last query is also special and show it is possible to write real SQL queries. We just need to prefix 
   the JSON attributes with `json_`.

4. Accessing attributes:

        person = Person.create(name: "Jacob")
        puts person.name            # "Jacob"
        puts person.name_was        # "Jacob"
        puts person.name_changed?   # false
        puts person.name_change     # nil

        person.name = "Martin"
        
        puts person.name_was        # "Jacob"
        puts person.name            # "Martin"
        puts person.name_changed?   # true
        puts person.name_change     # ["Jacob", "Martin"]
        
        person.save

        puts person.name            # "Martin"
        puts person.name_was        # "Martin"
        puts person.name_changed?   # false
        puts person.name_change     # nil
        
    Like you would expect with ActiveRecord.

5. Introduction to select and selectors.

    Sometimes we need a transformed version of documents. This is very easy with `select`

        me = Person.create(name: "Jacob", details: {age: 33})

        other_me = Person.limit(1).select({name: "name", age: "details.age"}).first
        puts other_me               # {name: "Jacob", age: 33}

    `select` takes a hash as argument and return an array of hashes. The value of each key/value pair in the hash argument is a selector. Selectors can point at attributes at root level, but also nested attributes. Each level of attributes is seperated with a dot (.).

#### All of the following methods are supported

        except
        limit
        offset
        page(page, per_page) # translate to `offset((page-1)*per_page).limit(per_page)`
        only
        order
        reorder
        reverse_order
        where
        
    And ...
        
        all
        any?
        blank?
        count
        delete
        delete_all
        destroy
        destroy_all
        empty?
        exists?
        find
        find_by
        find_by!
        find_each
        find_in_batches
        first
        first!
        first_or_create
        first_or_initialize
        ids
        last
        load
        many?
        pluck
        select
        size
        take
        take!
        to_a
        to_sql
        
        
## Dynamic Indexes

Most applications do the same queries over and over again. This is why we think it is useful, if PostJson create indexes on slow queries.

So we have created a feature we call `Dynamic Index`. It will automatically create indexes on slow queries, 
so queries speed up considerably.

PostJson will measure the duration of each `SELECT` query and instruct PostgreSQL to create an Index, 
if the query duration is above a specified threshold.

Each collection (like PostJson::Collection["people"]) have attribute `use_dynamic_index` (which is true by default) and 
attribute `create_dynamic_index_milliseconds_threshold` (which is 50 by default).

Lets say that you execute the following query and the duration is above the threshold of 50 milliseconds:

`PostJson::Collection["people"].where(name: "Jacob").count`

PostJson will create (unless it already exists) an Index on `name` behind the scenes. The next time 
you execute a query with `name` the performance will be much improved.

You can adjust the settings:

        class Person < PostJson::Collection["people"]
          self.create_dynamic_index_milliseconds_threshold = 75
        end

        # Or you can do:

        PostJson::Collection["people"].create_dynamic_index_milliseconds_threshold = 75

        # Now indexes are only created if queries are slower than 75 milliseconds.


You might already know this about User Interfaces, but it is usual considered good practice if auto-complete responses are served to the user within 100 milliseconds. Other results are usual okay within 500 milliseconds. So leave room for application processing and network delay.

Do not set create_dynamic_index_milliseconds_threshold too low as PostJson will try to create an index for every query performance. Like a threshold of 1 millisecond will be less than almost all query durations.

## The future

A few things we will be working on:
- Versioning of documents with support for history, restore and rollback.
- Restore a copy of entire collection at a specific date.
- Copy a collection.
- Automatic deletion of indexes when unused for a period of time.
- Bulk import.
- Support for files. Maybe as attachments to documents.
- Better performance and less complex code.

And please let us know what you think and what you need. You can create an issue or send an e-mail.

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
