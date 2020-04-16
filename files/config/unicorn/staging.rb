app_name    = "CHANGE-ME"
environment = 'staging'
app_path    = "/home/deploy/#{app_name}/#{environment}/htdocs/current"
pid         = "#{app_path}/tmp/pids/unicorn.pid"

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{app_path}/Gemfile"
end

working_directory "#{app_path}"
pid               "#{pid}"
stderr_path       "#{app_path}/log/unicorn.log"
stdout_path       "#{app_path}/log/unicorn.log"

listen "/tmp/unicorn_#{app_name}_#{environment}.sock"
worker_processes 1
timeout 180 # Increased timeout for imports TODO : might be better to delegate to a job

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection

  old_pid_file = "#{pid}.oldbin"
  if File.exists?(old_pid_file) && server.pid != old_pid_file
    begin
      old_pid = File.read(old_pid_file).to_i
      server.logger.info("sending QUIT to #{old_pid}")
      Process.kill("QUIT", old_pid)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
