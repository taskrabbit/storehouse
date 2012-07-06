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
      Storehouse.configure do |c|
        raise c.class.name
      end
    }.should raise_error('Storehouse::Config')
  end

  it 'should allow the adapter to be chosen and configured' do
    Storehouse.configure do |c|
      c.adapter = 'FakeAdapter'
      c.adapter_options = {:key => 'value'}
    end

    Storehouse::Adapter::FakeAdapter.should_receive(:new).with({:key => 'value'})
    Storehouse.data_store
  end

  it 'should allow path restrictions to be configured via "only"' do
    Storehouse.configure do |c|
      c.only = ['/path', /^\/pattern/]
    end

    conf.consider_caching?('/path').should be_true
    conf.consider_caching?('/other').should be_false
    conf.consider_caching?('/pattern').should be_true
    conf.consider_caching?('/pattern/subdir').should be_true
    conf.consider_caching?('/other/pattern').should be_false

    Storehouse.configure do |c|
      c.only = ['/new_path']
    end

    conf.consider_caching?('/new_path').should be_true
    conf.consider_caching?('/path').should be_false
  
    conf.reset!

    Storehouse.configure do |c|
      c.only! '/dog', '/cat', /^\/rat/
    end

    conf.consider_caching?('/dog').should be_true
    conf.consider_caching?('/cat').should be_true
    conf.consider_caching?('/rat').should be_true
    conf.consider_caching?('/fox').should be_false

    Storehouse.configure do |c|
      c.only! '/fox'
    end

    conf.consider_caching?('/dog').should be_true
    conf.consider_caching?('/cat').should be_true
    conf.consider_caching?('/rat').should be_true
    conf.consider_caching?('/fox').should be_true
  end

  it 'should allow path restrictions to be configured via "except"' do

    Storehouse.configure do |c|
      c.except = ['/tos', /^\/pages\//]
    end

    conf.consider_caching?('/tos').should be_false
    conf.consider_caching?('/about').should be_true
    conf.consider_caching?('/pages/about').should be_false

    conf.reset!

    Storehouse.configure do |c|
      c.except! '/terms', /no_cache/
    end 

    conf.consider_caching?('/terms').should be_false
    conf.consider_caching?('/other').should be_true

    Storehouse.configure do |c|
      c.except! '/other'
    end

    conf.consider_caching?('/terms').should be_false
    conf.consider_caching?('/other').should be_false   

  end

  it 'should allow distribution across multiple servers' do
    Storehouse.configure do |c|
      c.distribute! '/tos'
    end

    conf.distribute?('/tos').should be_true
    conf.distribute?('/page').should be_false

  end



end