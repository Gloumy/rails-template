# Initial commit
say "--- GIT ---"
git :init
git :add => '-A'
git :commit => '-qm "initial commit"'
say "--- /GIT ---"

# HAML
say "--- HAML ---"
gem 'haml-rails'
gem 'html2haml', :group => :development
require 'html2haml'
say "convert layout to HAML"
rails_command "generate haml:application_layout convert"
say "remove old ERB layout"
run "rm -rf app/views/layouts/application.html.erb"
git :add => '-A'
git :commit => '-qm "add HAML support"'
say "--- /HAML ---"

# Foundation 6
after_bundle do
  say "--- Foundation 6 ---"
  run "yarn add jquery foundation-sites motion-ui"
  inject_into_file 'config/webpack/environment.js', "const webpack = require(\"webpack\")" ,after: "const vue = require('./loaders/vue')\n"
  inject_into_file 'config/webpack/environment.js', after: "environment.loaders.prepend('vue', vue)\n" do <<~EOF
    environment.plugins.append("Provide", new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery'
    }))

    EOF
  end
  run "mkdir app/javascript/src"
  run "touch app/javascript/src/application.scss"
  inject_into_file "app/javascript/src/application.scss" do <<~EOF
    @import '~foundation-sites/dist/css/foundation';
    @import '~motion-ui/motion-ui';

    EOF
  end

  inject_into_file "app/javascript/packs/application.js", after: "require(\"channels\")\n" do <<~EOF
    import "foundation-sites"
    require("src/application")

    $(document).on('turbolinks:load', function () {
      $(document).foundation()
    });

    EOF
  end
  gsub_file "app/views/layouts/application.html.haml", /stylesheet_link_tag/, 'stylesheet_pack_tag'
  git :add => '-A'
  git :commit => '-qm "add Foundation 6"'
  say "--- /Foundation 6 ---"
end

# Simple Form
say '--- Simple Form ---'
gem 'simple_form', '~> 5.0', '>= 5.0.2'
after_bundle do
  generate 'simple_form:install', '--foundation'
end
git :add => '-A'
git :commit => '-qm "add simple form"'
say '--- /Simple Form ---'

# active_storage
say 'Applying active_storage...'
after_bundle do
  rails_command 'active_storage:install'
end

# Browser Warrior
say "Applying browser_warrior..."
gem 'browser_warrior', '>= 0.11.0'
after_bundle do
  generate 'browser_warrior:install'
end

# Devise
say "Applying Devise ..."
gem 'devise', '~> 4.7', '>= 4.7.1'
after_bundle do 
  rails_command "generate devise:install"
  environment 'config.action_mailer.default_url_options = {host: "http://CHANGE.ME"}', env: 'production'
  environment 'config.action_mailer.default_url_options = {host: \'localhost\', port: 3000}', env: 'development'
  inject_into_file 'app/views/layouts/application.html.haml', after: "%body\n" do <<~EOF
    \t\t%p.notice= notice
    \t\t%p.alert= alert
    EOF
  end
  rails_command "generate devise User"
end

gem 'trestle'
gem 'trestle-auth'
after_bundle do
  rails_command "generate trestle:install"
  rails_command "generate trestle:auth:install Administrator"
  say "Don't forget to create an Administrator to access trestle !"
end

# Capistrano  + Unicorn
gem 'capistrano', '~> 3.1', group: :development
gem 'capistrano-rbenv', '~> 2.1', '>= 2.1.6', group: :development
gem 'capistrano-bundler', group: :development
gem 'capistrano-rails', '~> 1.1.0', group: :development
gem 'capistrano-rails-console', group: :development
gem 'unicorn'
# gem 'unicorn-rails' # might not be needed ?
gem 'capistrano3-unicorn', '~> 0.2.1', group: :development

after_bundle do
  run 'bundle exec cap install'
  # Uncomment requires
  ["rbenv", "bundler", "rails/assets", "rails/migrations"].each do |key|
    gsub_file "Capfile", "# require \"capistrano/#{key}\"", "require \"capistrano/#{key}\""
  end
  inject_into_file 'Capfile', "require 'capistrano3/unicorn'"
end

# Copy config folder
say "Copying config folder"
run "cp -fR ~/workspace/rails-template/files/config/* config"

# Database setup
say "--- Database setup ---"
gsub_file "config/database.yml", /password:$/, "password: root"
rails_command "db:create"
rails_command "db:migrate"
git :add => '-A'
git :commit => '-qm "DB setup"'
say "--- /Database setup ---"