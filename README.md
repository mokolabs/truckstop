# Trucker
Use Trucker to migrate legacy data into your Rails app.

Trucker is designed to help you quickly and repeatedly extract legacy data from an older database. To make this possible, Trucker creates a new database connection that points to your legacy data and then creates optional legacy models which are designed to pair with an existing model in your app.

Let's say you have an existing `Post` model and you need to migrate older blog posts into your model. Just create a truck for posts by running `rails g truck:post`. This will create a `LegacyPost` model which can load data into your `Post` model.

Once you've got `LegacyPost` configured correctly, you can start running the `rake db:migrate:posts` rake task that Trucker created for you to import your legacy content into your new app.

The best part is you don't have to run this migration just once. You can run it again and again in development until you're sure that you've got a rock solid way to import content (and potentially clean it up).

## Installation
1. Add the trucker gem in to your Gemfile:
    ```ruby
    gem 'trucker'
    ```

2. Bundle install:
    ```bash
    bundle install
    ```

3. Create a truck for your model:
    ```bash
    rails generate truck:model
    ```

    Important: when running this command, make sure you replace `model` with the singular, lowercase name of your *new* model where content will be imported.

    So, if you new model is named `Post`, you should run this command:

    ```bash
    rails generate truck:post
    ```

    This will do the following things:
    - Add legacy database connection to `database.yml`
    - Add `app/models/legacy` directory
    - Add `app/models/legacy` to `autoload_paths` in `application.rb`
    - Add `app/models/legacy/legacy_base.rb` (from which legacy models will inherit)
    - Add `app/models/legacy/legacy_post.rb` (for your `LegacyPost` model)
    - Add `lib/tasks/legacy_post.rake` (to migrate legacy posts)

    With Trucker, a new model is always paired with a legacy model that has a matching name. `Post` is matched to `LegacyPost`. `Product` to `LegacyProduct`. And so on.

    To keep things simple, Trucker purposely ignores whatever your model was called in its original location -- because it's very likely that the original database table was not named using Rails conventions so there's not much benefit in trying to name the legacy model to match table names.

    Instead, once the legacy model is created, we can just tweak the model `table_name` inside the model so that it matches the exact table in the legacy database.

4. Update the legacy database connection in `database.yml` with your legacy database information:

    ```yaml
    legacy:
      adapter:
      encoding:
      database:
      username:
      password:
    ```

    #### Adapter

    By default, Rails can support connecting to PostgreSQL, MySQL, and SQL Lite databases. If your legacy data is stored in another format like Oracle or SQL Server, you can use a third-party ActiveRecord adapter gem to connect to those data sources.

    #### Encoding

    Rails defaults to `unicode` encoding when connecting to PostgreSQL databases, but be aware that different databases may use alternative encodings like `utf8`, `utf8mb4`, and so on. You can often review your data dump or schema to discover which encoding is being used.

    #### Database

    In Rails development, databases often use the same short name as the app itself and then add a suffix to indicate the environment in which a database should be used. This helps to keep databases organized when you're actively working on a lot of apps. So, if your app is named `avengers`, you could use `avengers_legacy` for your legacy database name.

    However, on the other hand, if you can't easily change your legacy database name, just use the existing name and update the name in your legacy database connection accordingly.

    #### Username and Password

    In development, depending on how you installed your database, you may not need to use a username and password. But, if you do, you can edit these settings.

5. If the legacy database doesn't already exist, add it.
    ```bash
    rake db:create:all
    ```

6. Import your legacy data into the legacy database.

    This step will really depend on where your legacy data lives. You may need to connect to a live external database. Or you may need to acquire a database dump and then import that into your database system of choice. It really depends.

7. Tweak your legacy models.
    ```ruby
    class LegacyPost < LegacyBase
      self.table_name =  "LEGACY_TABLE_NAME_GOES_HERE"
    end
    ```

    Since you're migrating data from an old database, your table names may not
    follow Rails conventions for database table naming. If so, you will need to
    set the `self.table_name = ` value for each of your legacy models to match the
    name of table from which you will be importing data.

    For instance, in the example above, if your old posts were stored in an
    `articles` table, here's how you would custom the `table_name`:

    ```ruby
    class LegacyPost < LegacyBase
      self.table_name =  "articles"
    end
    ```

8. Update legacy model field mappings.

    ```ruby
    class LegacyPost < LegacyBase
      self.table_name =  "LEGACY_TABLE_NAME_GOES_HERE"

      def map
        {
          :headline => self.title.squish,
          :body => self.long_text.squish
        }
      end
    end
    ```

    This is where you will connect your old database attributes with your new ones.
    The map method is really just a hash which uses your new model attribute names
    as keys and your legacy model attributes as values.

    (aka `:new_field => self.legacy_field`)

    Note: make sure to add `self.` to each legacy attribute name.

9. Need to tweak some data? Just add some core ruby methods or add a helper method.

    ```ruby
    class LegacyPost < LegacyBase
      self.table_name = "NAME_OF_TABLE_WHERE_POST_MODEL_DATA_IS_STORED"

      def map
        {
          :headline => self.title.squish.capitalize, # <= Added capitalize method
          :body => tweak_body(self.long_text.squish) # <= Added tweak_body method
        }
      end

      # Insert helper methods as needed
      def tweak_body(body)
        body = body.gsub(/<br \//,"\n") # <= Convert break tags into normal line breaks
        body = body.gsub(/teh/, "the")  # <= Fix common typos
      end
    end
    ```

10. Start migrating!
    ```bash
    rake db:migrate:posts
    ```

## Migration command line options
Trucker supports a few command line options when migrating records:

  ```bash
  rake db:migrate:posts limit=100 (migrates 100 records)
  rake db:migrate:posts limit=100 offset=100 (migrates 100 records, but skip the first 100 records)
  ```

## Custom migration labels
You can tweak the default migration output generated by Trucker by using the `:label` option.

  ```bash
  rake db:migrate:posts
  => Migrating posts

  rake db:migrate:posts, :label => "blog posts"
  => Migrating blog posts
  ```

## Custom helpers
Trucker works great for migrating data from many legacy data sources such as apps built with PHP, Perl, Python, or even older versions of Rails (where upgrading an existing Rails code base is not practical). But, if you're migrating data from a large enterprise system, Trucker may not be your best choice.

That said, if you need to pull off a complex migration for a model, you can use a custom helper method to override Trucker's default migrate method in your rake task.

```ruby
namespace :db do
  namespace :migrate do
    ...
    desc 'Migrate pain_in_the_ass model'
    task :pain_in_the_ass => :environment do
      Trucker.migrate :pain_in_the_ass, :helper => pain_in_the_ass_migration
    end
  end
end

def pain_in_the_ass_migration
  # Custom code goes here
end
```

If you don't want to write your custom migration method from scratch, you can copy trucker's migrate method method from [lib/trucker.rb](https://github.com/mokolabs/trucker/blob/master/lib/trucker.rb) and tweak accordingly.

As an example, here's a custom helper used to migrate join tables on a bunch of models.

```ruby
namespace :db do
  namespace :migrate do

    desc 'Migrates join tables'
    task :joins => :environment do
      migrate :joins, :helper => :migrate_joins
    end

  end
end

def migrate_joins
  puts "Migrating #{number_of_records || "all"} joins #{"after #{offset_for_records}" if offset_for_records}"

  ["chain", "firm", "function", "style", "website"].each do |model|

    # Start migration
    puts "Migrating theaters_#{model.pluralize}"

    # Delete existing joins
    ActiveRecord::Base.connection.execute("TRUNCATE table theaters_#{model.pluralize}")

    # Tweak model ids and foreign keys to match model syntax
    if model == 'website'
      model_id = "url_id"
      send_foreign_key = "url_id".to_sym
    else
      model_id = "#{model}_id"
      send_foreign_key = "#{model}_id".to_sym
    end

    # Create join object class
    join = Object.const_set("Theaters#{model.classify}", Class.new(ActiveRecord::Base))

    # Set model foreign key
    model_foreign_key = "#{model}_id".to_sym

    # Migrate join (unless duplicate)
    "LegacyTheater#{model.classify}".constantize.find(:all, with(:order => model_id)).each do |record|

      unless join.find(:first, :conditions => {:theater_id => record.theater_id, model_foreign_key => record.send(send_foreign_key)})
        attributes = {
          model_foreign_key => record.send(send_foreign_key),
          :theater_id => record.theater_id
        }

        # Check if theater chain is current
        attributes[:is_current] = {'Yes' => 1, 'No' => 0, '' => 0}[record.current] if model == 'chain'

        # Migrate join
        join.create(attributes)
      end
    end
  end
end
```

## Sample application
Check out the [Trucker sample app](http://github.com/mokolabs/trucker_sample_app) for a working example of Trucker-based legacy data migration. (Note: this app has not been updated to work with trucker 4.0 and above. It should only be used with trucker 0.5.1 and below.)


## Background
Trucker is based on a migration technique using legacy models first pioneered by Dave Thomas:
http://pragdave.blogs.pragprog.com/pragdave/2006/01/sharing_externa.html


## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/mokolabs/trucker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

The following folks have made significant contributions to trucker:

- [Patrick Crowley](https://github.com/mokolabs/)
- [Rob Kaufman](https://github.com/notch8/)
- [Jordan Fowler](https://github.com/thebreeze/)
- [Roel Bondoc](https://github.com/roelbondoc/)
- [Olivier Lacan](https://github.com/olivierlacan/)
- [Nick Schwaderer](https://github.com/Schwad)


## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Code of Conduct
Everyone interacting in the Trucker project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mokolabs/trucker/blob/master/CODE_OF_CONDUCT.md).