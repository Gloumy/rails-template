# Initial commit
puts "--- GIT ---"
git :init
git :add => '-A'
git :commit => '-qm "initial commit"'
puts "--- /GIT ---"

# HAML
puts "--- HAML ---"
gem 'haml-rails'
gem 'html2haml', :group => :development
require 'html2haml'
puts "convert layout to HAML"
rails_command "generate haml:application_layout convert"
puts "remove old ERB layout"
run "rm -rf app/views/layouts/application.html.erb"
git :add => '-A'
git :commit => '-qm "add HAML support"'
puts "--- /HAML ---"

