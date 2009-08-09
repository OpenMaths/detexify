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

set :user, 'kirel'

set :deploy_to, "/home/#{user}/www/#{application}"
 
default_run_options[:pty] = true
set :scm, :git
set :repository, "git@github.com:kirel/detexify.git"
set :branch, "deploy"
set :deploy_via, :remote_cache
 
set :ssh_options, { :forward_agent => true }
set :port, 7822
set :use_sudo, false

set :domain, "173.45.228.87"
role :app, domain
role :web, domain
role :db, domain, :primary => true

 
set :runner, user
set :admin_runner, user
 
namespace :deploy do
  task :start, :roles => [:web, :app] do
    run "cd #{deploy_to}/current && nohup thin -C config/thin.yml -R config.ru start"
  end
 
  task :stop, :roles => [:web, :app] do
    run "cd #{deploy_to}/current && nohup thin -C config/thin.yml -R config.ru stop"
  end
 
  task :restart, :roles => [:web, :app] do
    deploy.stop
    deploy.start
  end
 
  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
    deploy.start
  end
end
 
namespace :kirel do
  task :log do
    run "cat #{deploy_to}/current/log/thin.log"
  end
end