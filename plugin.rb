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

  load File.expand_path("../app/jobs/blog_update_twitter.rb", __FILE__)

  require_dependency "plugin/filter"

  Plugin::Filter.register(:after_post_cook) do |post, cooked|
    if post.post_number == 1 && post.topic && post.topic.archetype == "regular"
      split = cooked.split(/<hr\/?>/)

      if split.length > 1
        post.topic.custom_fields["summary"] = split[0]
        post.topic.save unless post.topic.new_record?
        cooked = split[1..-1].join("<hr>")
      end
    end
    cooked
  end

  class BlogConstraint
    def matches?(request)
      request.host == BLOG_HOST
    end
  end

  class ::Topic
    before_save :blog_bake_summary
    before_save :ensure_permalink

    def ensure_permalink
      unless custom_fields["permalink"]
        custom_fields["permalink"] =  (Time.now.strftime "/archive/%Y/%m/%d/") + self.slug
      end
    end

    def blog_bake_summary
      if summary = custom_fields["summary"]
        custom_fields["cooked_summary"] = PrettyText.cook(summary)
      end
    end
  end

  Discourse::Application.routes.prepend do
    mount ::Blog::Engine, at: "/", constraints: BlogConstraint.new
  end
end
