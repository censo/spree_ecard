require 'spree_core'
require 'spree_ecard/engine'
require "spree_ecard/version"

module SpreeEcard
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :currency, :country, :language, :charset, :autodeposit, :hashalgorithm, :transparentpages,
                  :merchantid, :password, :paymenttype

    def initialize
      @option = 'default_option'
    end
  end

end