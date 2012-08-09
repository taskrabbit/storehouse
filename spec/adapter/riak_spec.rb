require 'spec_helper'

describe Storehouse::Adapter::Riak do

  before do
    check_connectivity
    Storehouse.configure do |c|
      c.adapter = 'Riak'
    end
  end

  let(:store){ Storehouse.send(:data_store) }
  let(:bucket){ store.send(:bucket) }

  it 'should utilize the riak adapter' do
    store.should be_a(Storehouse::Adapter::Riak)
  end

  it 'should connect to Riak properly' do
    store.send(:bucket).should be_a(Riak::Bucket)
  end

  it 'should use the appropriate bucket name when it\'s provided' do
    Storehouse.configure do |c|
      c.adapter_options = {:bucket => 'my_custom_bucket_name'}
    end

    bucket.name.should eql('my_custom_bucket_name')
  end

  context 'scoped to storehouse integration tests' do

    before do
      Storehouse.configure do |c|
        c.scope = 'storehouse_tests'
        c.adapter_options = {:bucket => 'storehouse_integration_gem_tests'}
      end
    end

    # we'll be clearing keys in the tests - just make sure it's works
    it 'should clear the keys without an error' do
      store._write('test', 'value')
      bucket.keys.should_not be_empty
      store._clear!
      delay
      bucket.keys.should be_empty
    end

    context 'with all keys cleared' do

      before :all do
        store._clear!
        delay
      end

      it 'should write a key, scoped by the current scope' do
        store._write('scoped_key_test', 'value')
        bucket.keys.should include('storehouse_tests::scoped_key_test')
      end

      it 'should apply an created_at index to the object' do
        store._write('created_at_test', 'value')
        bucket.get('storehouse_tests::created_at_test').indexes['created_at_int'].should_not be_blank
      end

      it 'should apply an expired_at index if the write receives expiration info' do
        expires_at = Time.now.to_i + 10
        expires_in = 10

        store._write('expires_at_nil', 'value')
        bucket.get('storehouse_tests::expires_at_nil').indexes['expires_at_int'].should be_blank

        store._write('expires_at_test', 'value', :expires_at => expires_at)
        index = bucket.get('storehouse_tests::expires_at_test').indexes['expires_at_int'].first
        index.should eql(expires_at.to_i)

        expires_at = Time.now.to_i + 10
        store._write('expires_in_test', 'value', :expires_in => 10)
        index = bucket.get('storehouse_tests::expires_in_test').indexes['expires_at_int'].first
        index.should be_within(1).of(expires_at.to_i)
      end

      it 'should read a key properly' do
        store._write('reading_test', 'reading value')
        store._read('reading_test').should eql('reading value')
      end

      it 'should delete a key on read when it is expired' do
        expires_at = Time.now.to_i - 10
        store._write('reading_expired_test', 'reading expired value', :expires_at => expires_at)
        store._read('reading_expired_test').should be_nil
      end

    end

  end


  def check_connectivity
    pending unless defined?(Riak::Client)
    pending unless (Storehouse::Adapter::Riak.new.send(:bucket) rescue nil)
  end

  # let riak reflect the changes
  def delay
    sleep 3
  end

end