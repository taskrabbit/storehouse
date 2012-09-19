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
      Delorean.time_travel_to Time.at(Time.now.to_i + key.split('::').last.to_i)
    end

  end

  let(:store){ TimeoutAdapter.new(:timeout => {:read => 2, :write => 4, :delete => 1}) }

  it 'should timeout for long running requests' do

    Storehouse.configure do |c|
      c.error_receiver lambda{|e| raise e }
    end

    lambda{ store._read('1') }.should_not raise_error
    lambda{ store._read('3') }.should raise_error(Timeout::Error)
    lambda{ store._write('3', 'val') }.should_not raise_error
    lambda{ store._write('5', 'val') }.should raise_error(Timeout::Error)

  end

  it 'should report errors to the error receiver' do
    @error_provided = nil
    handler = lambda{|e| @error_provided = e}

    Storehouse.configure do
      error_receiver handler
    end

    Storehouse.stub(:data_store).and_return(store)

    Storehouse.read('3')

    @error_provided.should be_a(Timeout::Error)
    
  end

end