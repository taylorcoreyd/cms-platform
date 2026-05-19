class HomeController < ApplicationController
  def index
    render plain: Current.tenant.name
  end
end
