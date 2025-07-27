class TestController < ApplicationController
  def api
    render json: { min_subscribers: 5_000 }
  end
end
