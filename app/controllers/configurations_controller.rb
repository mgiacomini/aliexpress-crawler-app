class ConfigurationsController < ApplicationController
  def index
    @wordpresses = Wordpress.all
  end
end
