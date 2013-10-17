# Welcome to PostJson

PostJson is everything you expect of ActiveRecord and PostgreSQL, but with the dynamic nature of document databases 
(free as a bird - no schemas).

PostJson take full advantage of PostgreSQL 9.2+ support for JavaScript (Google's V8 engine). We started the work on 
PostJson, because we love document databases and PostgreSQL. PostJson combine features of Ruby, ActiveRecord and 
PostgreSQL to provide a great document database.

See example of how we use PostJSON as part of Jump... 


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

Also, __notice you don't have to define attributes anywhere!__

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
        also_me_3 = Person.where("json_details.age = ?", 33).first
        
   PostJson support filtering on nested attributes as you can see. The two first queries speak for themself.
   
   The third (and last) query is special and show it is possible to write real SQL queries. We just need to prefix 
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

We have created a feature we call `Dynamic Index`. It will automatically create indexes on slow queries, so queries 
speed up considerably.

PostJson will measure the duration of each `SELECT` query and instruct PostgreSQL to create an Expression Index, 
if the query duration is above a specified threshold.

Each collection (like PostJson::Collection["people"]) have attribute `use_dynamic_index` (which is true by default) and 
attribute `create_dynamic_index_milliseconds_threshold` (which is 50 by default).

Lets say that you execute the following query and the duration is above the threshold of 50 milliseconds:

`PostJson::Collection["people"].where(name: "Jacob").count`

PostJson will create (unless it already exists) an Expression Index on `name` behind the scenes. The next time 
you execute a query with `name` the performance will be much improved.

## Requirements

- PostgreSQL 9.2 or 9.3
- PostgreSQL PLV8 extension.

## License

PostJson is released under the MIT License. See the MIT-LICENSE file.

## Want to contribute?

That's awesome, thank you!

Do you have an idea or suggestion? Please create an issue or send us an e-mail (hello@webnuts.com). We would be happy to implement (if we like the idea) right away.

You can also send us a pull request with your contribution.

<a href="http://www.webnuts.com" target="_blank">
  <img src="http://www.webnuts.com/logo/post_json/logo.png" alt="Webnuts.com">
</a>
##### Sponsored by Webnuts.com
