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
      sleep key.split('::').last.to_i # switch to delorean (no internet at the moment)
    end

  end

  let(:store){ TimeoutAdapter.new(:timeout => {:read => 2, :write => 4, :delete => 1}) }

  it 'should timeout for long running requests' do

    lambda{ store._read('1') }.should_not raise_error
    lambda{ store._read('3') }.should raise_error(Timeout::Error)
    lambda{ store._write('3', 'val') }.should_not raise_error
    lambda{ store._write('5', 'val') }.should raise_error(Timeout::Error)

  end

end