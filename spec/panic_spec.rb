require 'spec_helper'

describe 'Storehouse panic' do


  it 'should determine if it\'s in panic mode only when a path is provided in the spec' do
    gem_config
    File.should_receive(:file?).never
    Storehouse.panic?
  end

  it 'should determine if it\'s in panic mode when the path is provided' do
    config = gem_config(:panic)
    path = File.join(ROOT, config['panic_path'])
    File.should_receive(:file?).with(path).once.and_return(true)
    Storehouse.panic?.should be_true
  end

end