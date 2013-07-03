# Storehouse

[![Build Status](https://secure.travis-ci.org/taskrabbit/storehouse.png)](http://travis-ci.org/taskrabbit/storehouse)


Storehouse is a rack middleware which provides read and write access to a centralized page cache store. The store itself is up to you, we've used Redis and Riak in production without issue. Storehouse aims to be a lightweight and simple middleware which relies solely on simple configuration files.


## Installation

Add storehouse to your Gemfile:

```ruby
gem 'storehouse', :git => 'git@github.com:taskrabbit/storehouse.git', :tag => 'v0.1.8'
```


If you're running a railtie enabled version of rails, you're all set. For all other rack apps you'll have to add the Storehouse::Middleware:

```ruby
config.middleware.add 'Storehouse::Middleware'
```

## Invoking the Middleware

Tell Storehouse to cache the page by adding a header (or two). The first header of interest is `X-Storehouse`. `X-Storehouse` should be given the string value of `'1'`. This will tell the middleware to cache the current response in the backend of your choice.

```ruby
response.headers['X-Storehouse'] = '1' if cache_page?
```

Optionally, you can pass an expiration time for the content: 

```ruby
response.headers['X-Storehouse-Expires-At'] = (Time.now + 600).to_i.to_s
```

You can also tell Storehouse to distribute the content:

```ruby
response.headers['X-Storehouse-Distribute'] = '1'
```

These headers will never reach your end user as they are always stripped out.


## Distribution

Distribution is a great way to share cached resources on a multi-server setup. Let's take an example system with 3 servers (A, B, and C). If server A receives a request at `/about-us` and the app provides the response headers:
  
```ruby
response.headers['X-Storehouse'] = '1'
response.headers['X-Storehouse-Expires-At'] = (Time.now + 600).to_i.to_s
response.headers['X-Storehouse-Distribute'] = '1'
```

Then before finalizing the request, storehouse will do two things 1) store that content in the backend of your choice 2) write that content to disk so you can serve it directly from the filesystem the next time this server is hit.

## Configuration

Storehouse uses a config file `storehouse.yml` to set itself up. The core of the config file is the following:

    development:
      enabled: true
      backend: redis
      connections:
        host: 127.0.0.1
        port: 6379

With this simple config you'll be up and running. The rest of the options are shown below. Please read the appropriate section for detailed usage:

    development:
      enabled: true                          # include this line to enable storehouse
      backend: redis                         # choose the backend your app will use
      namespace: myappprod                   # the namespace which all keys should be prefixed by
      connections:                           # the connection information passed to the backend
        host: 10.0.0.1
        port: 6380

      reheat_param: reheat_cache             # the param to pass to reheat the cache manually
      postpone: false                        # when encountering an expired page, defer the expiration for other users
      ignore_params: false                   # serve cached content to requests with query strings
      ignore_headers: [Set-Cookie, Other]    # headers to strip during storage, by default [Set-Cookie]
      serve_expired_content_to: Bot          # the user agent matcher for serving expired content
      panic_path: 'public/panic.txt'         # the relative path (from project root) for a panic file


### namespace

Storehouse provides a utility to prefix all keys entering your backend with a value provided by the config. This is especially useful when dealing with multiple environments, multiple apps sharing the same backend resource, etc. Provide a string via the `namespace` configuration and you're good to go.

### reheat_param

It's often nice to see a cached page get rewritten on-demand. For this reason Storehouse allows a `reheat_param` to be configured. If this value is set and a request is received with **only** the reheat_param, the cache will be ignored and potentially rewritten. Storehouse strips off the rewrite param before passing control to the app so make sure your reheat param is very unique.

### postpone

Postponing is a technique Storehouse uses to keep your app from undergoing an avalanche of requests for the same expired resource. If postponing is set to true and an expired resource is found, Storehouse will push back the resources expiration but allow the current request to continue through to the app server. In this case, any other request asking for the same resource will be given back the expired content rather than attempting to rewrite the cache. Before enabling this feature think about the use cases in your app. Are you ok with users seeing expired content while another request is handled?

### ignore_params

If this is set to `true`, Storehouse will serve cached content even if params are passed. This is especially useful for utm-like params or params which are handled in a previous middleware and essentially ignored in your app.

### ignore_headers

When storehouse stores a request it includes the headers. Some headers like 'Set-Cookie' should not be stored. If you have a custom header that is relevant to the current session but no other, add it to this list.

### serve_expired_content_to

Many times you're ok serving expired content to certain user agents. Bot's are a perfect example of this. You put a lot of effort into building a cache and just because it's expired doesn't mean it's not valuable to Bot's. The value of this setting is evaluated as a regular expression and compared to the User-Agent header on the request. Use with caution.

### panic_path

Storehouse provides an especially useful tool which allows you to switch your site into a "panic" mode. Panic mode is for when you're experiencing massive load due to a traffic spike. Serving files from disk is always going to be more efficient so Storehouse will attempt to make use of that. This **is** a destructive operation in that any content coming from your backend or from your app with the `X-Storehouse` header will be written to disk. It will also render expired content read from the cache instead of passing control to your app. [More production implementation details coming soon]

### subdomains / subdomain

If you need to restrict caching to certain subdomains, provide them in the configuration. All other subdomains will be ignored.

## Further Reading

Check out [our blog post about the relase of Storehouse](http://tech.taskrabbit.com/blog/2013/01/04/storehouse/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
