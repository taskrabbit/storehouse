require 'fileutils'

namespace :storehouse do

  task :storehouse_env do
    raise "Please provide an :environment task which sets up the environment to run storehouse tasks" unless Rake::Task.task_defined?('environment')
    Rake::Task['environment'].invoke
  end

  task :clean => :storehouse_env do
    Storehouse.clean!
  end

  task :clear => :storehouse_env do
    Storehouse.clear!
  end


  namespace :panic do

    task :enable => :storehouse_env do
      File.open(Storehouse.panic_path, 'w') do |io|
        io.write('Panic Mode Enabled')
      end
    end

    task :on => :enable

    task :disable => :storehouse_env do
      return unless Storehouse.spec['panic_path']
      FileUtils.rm(Storehouse.panic_path)
    end

    task :off => :disable

    task :clear => :disable do
      FileUtils.rm_r(Storehouse.cache_path)
    end

  end

end