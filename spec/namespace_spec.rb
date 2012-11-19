require 'spec_helper'

describe 'Storehouse namespacing' do

  let(:connection){ Storehouse.store.send(:connection_for, 'test') }

  it 'should not namespace keys unless told to' do
    connection.should_receive(:read).with('test').once
    Storehouse.read('test')
  end

  it 'should namespace the keys when told to' do
    gem_config(:namespace)
    connection.should_receive(:read).with('test:test').once
    Storehouse.read('test')
  end

end