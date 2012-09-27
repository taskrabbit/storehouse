require 'spec_helper'

describe Storehouse::Adapter::Base do

  class TimeoutAdapter < Storehouse::Adapter::Base

    protected

    def read(key)
      sleep_for(key)
    end

    def write(key, val, options = {})
      sleep_for(key)
    end

    def delete(key)
      sleep_for(key)
    end

    def sleep_for(key)
      sleep key.split('::').last.to_i
    end

  end

  let(:store){ TimeoutAdapter.new(:timeout => {:read => 1, :write => 1, :delete => 1}) }

  it 'should timeout for long running requests' do

    Storehouse.configure do |c|
      c.error_receiver lambda{|e| raise e }
    end

    lambda{ store._read('0') }.should_not raise_error
    lambda{ store._read('2') }.should raise_error(Timeout::Error)
    lambda{ store._write('0', 'val') }.should_not raise_error
    lambda{ store._write('2', 'val') }.should raise_error(Timeout::Error)

  end

  it 'should report errors to the error receiver' do
    @error_provided = nil
    handler = lambda{|e| @error_provided = e}

    Storehouse.configure do
      error_receiver handler
    end

    Storehouse.stub(:data_store).and_return(store)

    Storehouse.read('2')

    @error_provided.should be_a(Timeout::Error)
    
  end

end