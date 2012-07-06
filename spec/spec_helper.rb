# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper.rb"` to ensure that it is only
# loaded once.
#

rails_version = ENV['RAILS_VERSION'] || '2'
ENV['RAILS_VERSION'] = rails_version.to_s

require "mockery#{rails_version}/config/environment.rb"


module GlobalMethods
  def get_storehouse_middleware
    Rails.configuration.middleware.select{|m| m.klass.name =~ /Storehouse/}.first
  end

  def use_middleware_adapter!(name, options = {})
    Storehouse.reset_data_store!
    Storehouse.configure do |c|
      c.adapter = name
      c.adapter_options = options
    end
    Storehouse.data_store
  end

  def reset
    Storehouse.config.try(:reset!)
    dir = Rails.root.join('public', 'cache')
    system("rm -r #{dir}") if File.exists?(dir)
  end

end


if rails_version == '2'
  require 'spec/rails'
  Spec::Runner.configure do |config|
    config.include GlobalMethods
    config.before do
      reset()
    end
  end
else 
  require 'rspec/rails'
  # See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.filter_run :focus
    config.include GlobalMethods
    config.before do
      reset()
    end

  end
end