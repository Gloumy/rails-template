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

# Database setup
say "--- Database setup ---"
gsub_file "config/database.yml", /password:$/, "password: root"
rails_command "db:create"
rails_command "db:migrate"
git :add => '-A'
git :commit => '-qm "DB setup"'
say "--- /Database setup ---"

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