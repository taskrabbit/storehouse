require 'spec_helper'

describe 'Storehouse Store Interface' do

  before do
    gem_config(:simple)
  end 

  let(:store){ Storehouse.send(:store) }

  it 'should handle timeouts' do 

    store.read('/path').should_not be_nil

    store.send(:connection_for).stub(:read) do |path|
      sleep 1
    end

    store.read('/path').should be_nil
  end

  
end