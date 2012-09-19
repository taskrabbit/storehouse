# Storehouse

Storehouse provides a cache layer that wraps Rails' page caching strategy. It provides a middleware that returns content from a centralized cache store and writes files to your local machine on-demand, allowing distribution to multiple servers. Cache stores can be easily defined by using or creating an adapter.

## Installation

**Storehouse is compatible and tested in both Rails 2 (2.3.14) and 3 (3.2.6)**

Add this line to your application's Gemfile:

    gem 'storehouse'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install storehouse

## Usage

Create an initializer to configure your storehouse integration:

    # config/intializers/storehouse.rb
    Storehouse.configure do
      adapter = 'Riak'                                          # the adapter to use
      adapter_options = {:bucket => '_page_cached_content'}     # pass options that are provided to the adapter instance
      continue_writing_filesystem = true                        # should storehouse allow rails to continue writing to the filesystem?
      ignore_query_params = false                               # should storehouse ignore query params when choosing a cached object?

      distribute = ['/tos', '/privacy', /^\/pages\//]           # patterns or paths to match against when determining if content should be distributed
      distribute!(/\/users/[\d]+/)                              # append the provided value(s) to the 'distribution' array

      except = ['/dynamic_page']                                # opt out of caching this page using storehouse
      except!('/tos')                                           # append the provided value(s) to the 'except' array
      ignore!('/about')                                         # alias for c.except!

      only = ['/tos', '/privacy']                               # only cache these pages or patterns in storehouse
      only!('/about')                                           # append the provided value(s) to the 'only' array

      hook_controllers!                                         # hook ActionController::Base's expire_page and cache_page with storehouse
    end

Include the middleware into your app:

    # application.rb or environment.rb

    config.middleware.use 'Storehouse::Middleware'

Now you're ready to go.

## Advanced Configuration

For more flexibility you can also provide Storehouse's configuration with an array containing a path and a function or a hash containing paths as the keys and functions as the values. The function will be given the path at runtime and should return true or false.

    # config/initializers/storehouse.rb
    Storehouse.configure do |c|
      only! '/tos', {/\/pages\// => lambda{|path| path.length == 12 }}
      except! '/privacy', [/\/pages\//, lambda{|path| path.ends_with?('t') }]
    end

Pointless examples, but the ability to configure is there. The `function` just needs to respond to `call()` so you can use whatever you want there.

## Adapters

The following cache store adapters are provided:

  -   Memcache
  -   Dalli
  -   Redis
  -   Riak
  -   S3

To create your own adapter inherit from `Storehouse::Adapter::Base` and implement the following methods:
    
  - read(path)
  - write(path, content)
  - delete(path)
  - clear!

## Distributed Cache

When you're quickly developing an application you don't always want to deal with centralizing your cached content, which makes Storehouse a viable solution. That said, it does require the Rack stack to be invoked to access the centralized cache store which is obviously not as fast as, say, nginx. For this reason Storehouse allows on-demand distribution. You must opt into this solution since expiration would have to be done on each server. Generally, this is a solution that works well for truly static content that's expired on deploy. Let's look at an example:

If I have 2 servers, **A** and **B**. A request comes into **A** which looks like:

    GET [A]/terms-of-service

Normally, Rails would drop a file in your cache directory on server **A**. If server **B** receives the same request, Rails must do the same on that server, completely ignorant of server **A**'s content.

With Storehouse enabled and `/terms-of-service` in the config's distribution array, requesting:

    GET [B]/terms-of-service

would request `/terms-of-service` from the Storehouse cache store, retrieve the cached content, and lay down a new file on server **B**. Now, when `/terms-of-service` is requested on either server the content on the filesystem will be served, completely bypassing the application stack.

## Clearing the Cache

Many times when you deploy new code you want to clear your cache. To do so in Storehouse you'll want to clear the files dropped on the server (if any) then call `Storehouse.clear!`. Each adapter makes sure that all the existing keys in the cache namespace are cleared.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
