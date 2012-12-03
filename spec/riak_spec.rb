require 'spec_helper'

describe Storehouse::Connections::Riak do

  let(:store){ Storehouse.send(:store) }
  let(:riak){ store.send(:connection_for).instance_variable_get('@bucket') }

  before do 
    gem_config(:simple, :namespace, :type => :riak)
    pending unless riak_available?
  end

  it 'should connect to riak' do
    store.send(:connection_for).should be_a(::Storehouse::Connections::Riak)
    lambda{
      riak.get('anything')
    }.should raise_error(/404/)
  end

  it 'should write an object to riak and return it back' do
    objecta = store.write('/some/path', 200, {'My Header' => 'Value'}, 'The actual content', Time.now.to_i + 10)
    objectb = store.read(objecta.path)

    objecta.to_h.should eql(objectb.to_h)
  end

  it 'should expire the object, not the riak value' do
    objecta = store.write('/some/path', 200, {'My Header' => 'Value'}, 'The actual content', Time.now.to_i + 10)
    store.expire('/some/path')
    objectb = store.read('/some/path')

    objecta.to_h.except('expires_at').should eql(objectb.to_h.except('expires_at'))
    objecta.expires_at.to_i.should_not eql(objectb.expires_at.to_i)
  end

  it 'should delete an object out of redis' do
    objecta = store.write('/some/path', 200, {'My Header' => 'Value'}, 'The actual content', Time.now.to_i + 10)
    objectb = store.read('/some/path')
    objectb.should_not be_blank
    store.delete('/some/path')
    objectc = store.read('/some/path')
    objectc.should be_blank
  end

  it 'should clear all objects' do

    pending if ENV['TRAVIS']

    Riak.disable_list_keys_warnings = true

    store.clear!

    sleep 3 # gotta let riak catch up

    original_length = riak.keys.length

    [200, 201].each do |status|
      store.write("/b/some/path/#{status}", 200, {'My Header' => 'Value'}, 'The actual content')
    end
    
    riak.keys.length.should eql(original_length + 2)
    store.clear!

    sleep 3

    riak.keys.length.should eql(original_length)
  end

  def riak_available?
    begin
      Storehouse.store.send(:connection_for).read('anything')
      true
    rescue
      false
    end
  end

end