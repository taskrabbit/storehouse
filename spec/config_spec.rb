require 'spec_helper'

describe Storehouse::Config do

  module Storehouse
    module Adapter
      class FakeAdapter < ::Storehouse::Adapter::Base

      end
    end
  end

  let(:conf){ Storehouse.config }

  before do
    conf.reset!
  end

  after do
    conf.reset!
  end

  it 'should return the config object for manipulation' do
    conf.is_a?(Storehouse::Config).should be_true
    Storehouse.configure.is_a?(Storehouse::Config).should be_true
  end

  it 'should yield to the config if a block is present' do
    lambda{
      Storehouse.configure do
        raise self.class.name
      end
    }.should raise_error('Storehouse::Config')
  end

  it 'should allow the adapter to be chosen and configured' do
    Storehouse.configure do
      adapter 'FakeAdapter'
      adapter_options({:key => 'value'})
    end

    Storehouse::Adapter::FakeAdapter.should_receive(:new).with({:key => 'value'})
    Storehouse.send(:data_store)
  end

  it 'should allow path restrictions to be configured via "only"' do
    Storehouse.configure do
      only '/path', /^\/pattern/
    end

    conf.consider_caching?('/path').should be_true
    conf.consider_caching?('/other').should be_false
    conf.consider_caching?('/pattern').should be_true
    conf.consider_caching?('/pattern/subdir').should be_true
    conf.consider_caching?('/other/pattern').should be_false

    conf.reset!

    Storehouse.configure do
      only '/new_path'
    end

    conf.consider_caching?('/new_path').should be_true
    conf.consider_caching?('/path').should be_false
  
    conf.reset!

    Storehouse.configure do
      only '/dog', '/cat', /^\/rat/
    end

    conf.consider_caching?('/dog').should be_true
    conf.consider_caching?('/cat').should be_true
    conf.consider_caching?('/rat').should be_true
    conf.consider_caching?('/fox').should be_false

    Storehouse.configure do
      only '/fox'
    end

    conf.consider_caching?('/dog').should be_true
    conf.consider_caching?('/cat').should be_true
    conf.consider_caching?('/rat').should be_true
    conf.consider_caching?('/fox').should be_true
  end

  it 'should allow path restrictions to be configured via "except"' do

    Storehouse.configure do
      except '/tos', /^\/pages\//
    end

    conf.consider_caching?('/tos').should be_false
    conf.consider_caching?('/about').should be_true
    conf.consider_caching?('/pages/about').should be_false

    conf.reset!

    Storehouse.configure do
      except '/terms', /no_cache/
    end 

    conf.consider_caching?('/terms').should be_false
    conf.consider_caching?('/other').should be_true

    Storehouse.configure do
      except '/other'
    end

    conf.consider_caching?('/terms').should be_false
    conf.consider_caching?('/other').should be_false   

  end

  it 'should allow distribution across multiple servers' do
    Storehouse.configure do
      distribute '/tos'
    end

    conf.distribute?('/tos').should be_true
    conf.distribute?('/page').should be_false

  end

  it 'should allow different types of list elements' do

    Storehouse.configure do
      except '/tos', 
              /\/privacy/, 
              [/^\/users\//, lambda{|path| path == '/users/2' }],
              lambda{|path| path == '/something/dynamic' }
    end
    conf.consider_caching?('/page').should be_true
    conf.consider_caching?('/tos').should be_false
    conf.consider_caching?('/privacy_statement').should be_false
    conf.consider_caching?('/users/2').should be_false
    conf.consider_caching?('/users/1').should be_true
    conf.consider_caching?('/something/dynamic').should be_false

  end

  it 'should allow complete disabling' do

    Storehouse.configure do
      disable!
    end

    Storehouse.should_receive(:data_store).never

    Storehouse.read('test')
    Storehouse.write('test', 'value')
    Storehouse.config.consider_caching?('anything').should be_false
    Storehouse.delete('test')
    Storehouse.clear!

  end

end