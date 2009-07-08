set :application, "detexify"

# If you have previously been relying upon the code to start, stop 
# and restart your mongrel application, or if you rely on the database
# migration code, please uncomment the lines you require below

# If you are deploying a rails app you probably need these:

# load 'ext/rails-database-migrations.rb'
# load 'ext/rails-shared-directories.rb'

# There are also new utility libaries shipped with the core these 
# include the following, please see individual files for more
# documentation, or run `cap -vT` with the following lines commented
# out to see what they make available.

# load 'ext/spinner.rb'              # Designed for use with script/spin
# load 'ext/passenger-mod-rails.rb'  # Restart task for use with mod_rails
# load 'ext/web-disable-enable.rb'   # Gives you web:disable and web:enable

set :deploy_to, "/home/kirel/#{application}"
 
default_run_options[:pty] = true
set :scm, :git
set :repository,  "git@github.com:kirel/detexify.git"
set :branch, "master"
set :deploy_via, :remote_cache
 
set :user, 'kirel'
set :ssh_options, { :forward_agent => true }
set :port, 7822
set :use_sudo, false

set :domain, "kirelabs.org"
role :app, domain
role :web, domain
 
namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
  
  task :cold do
     deploy.update
     deploy.start
  end
end