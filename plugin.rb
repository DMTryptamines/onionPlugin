# frozen_string_literal: true

# name: discourse-plugin-name
# about: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

::BLOG_HOST = "onion.tryp.digital"
::BLOG_DISCOURSE = "tryp226d7fpfih3tx6i2gfawp4fedzwipunedekpgigpcfiy3pav6wyd.onion" 

enabled_site_setting :plugin_name_enabled

module ::MyPluginModule
  PLUGIN_NAME = "dimitris-plugin"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  # Code which should run after Rails has finished booting
    # got to patch this class to allow more hostnames
  class ::Middleware::EnforceHostname
    def call(env)
      hostname = env[Rack::Request::HTTP_X_FORWARDED_HOST].presence || env[Rack::HTTP_HOST]

      env[Rack::Request::HTTP_X_FORWARDED_HOST] = nil

      if hostname == ::BLOG_HOST
        env[Rack::HTTP_HOST] = ::BLOG_HOST
      else
        env[Rack::HTTP_HOST] = ::BLOG_DISCOURSE
      end

      @app.call(env)
    end
  end

end
