# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :yield_or_default
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :current_user
  helper_method :current_ability
    
  private  
  def permission_denied
    flash[:error] = "Sorry, you are not allowed to access that page."
    redirect_to root_url
  end
  
  def current_user_session  
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end  

  def current_user  
    @current_user = current_user_session && current_user_session.record
  end
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  # Yield the content for a given block. If the block yiels nothing, the optionally specified default text is shown.
  #
  #   yield_or_default(:user_status)
  #
  #   yield_or_default(:sidebar, "Sorry, no sidebar")
  #
  # +target+ specifies the object to yield.
  # +default_message+ specifies the message to show when nothing is yielded. (Default: "")
  def yield_or_default(message, default_message = "")
    message.nil? ? default_message : message
  end
  
end
