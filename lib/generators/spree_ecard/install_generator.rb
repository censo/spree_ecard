module SpreeEcard
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
      desc "Creates SpreeEcard initializer for your application"

      def copy_initializer
        template "spree_ecard.rb", "config/initializers/spree_ecard.rb"
        puts "Install complete!"
      end
    end
  end
end