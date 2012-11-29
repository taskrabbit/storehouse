require 'spec_helper'

describe Storehouse::Connections::Redis do

  let(:store){ Storehouse.send(:store) }
  let(:redis){ store.send(:connection_for).instance_variable_get('@redis') }

  before do 
    gem_config(:simple, :namespace, :type => :redis)
    pending unless redis_available?
  end

  it 'should connect to redis' do
    store.send(:connection_for, nil).should be_a(::Storehouse::Connections::Redis)
    redis.get('anything').should be_nil
  end

  it 'should write an object to redis and return it back' do
    objecta = store.write('/some/path', 200, {'My Header' => 'Value'}, 'The actual content', Time.now.to_i + 10)
    objectb = store.read(objecta.path)

    objecta.to_h.should eql(objectb.to_h)
  end

  it 'should expire the object, not the redis value' do
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
    store.clear!

    [200, 201].each do |status|
      store.write("/b/some/path/#{status}", 200, {'My Header' => 'Value'}, 'The actual content')
    end
    redis.keys('test:*').length.should eql(2)
    store.clear!
    
    redis.keys('test:*').should be_empty
  end

  def redis_available?
    begin
      Storehouse.store.send(:connection_for).read('anything')
      true
    rescue
      false
    end
  end

end