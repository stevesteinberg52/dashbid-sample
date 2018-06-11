class Api::ApiController < ActionController::Base
  def unmatched_route
    render json: "Not Found\n", status: :not_found
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, options|
      @user = Customer.where(authentication_token: token).first
    end
  end
end
