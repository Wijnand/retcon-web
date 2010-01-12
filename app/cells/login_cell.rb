class LoginCell < Cell::Base
  def login
    @user_session = UserSession.new
    render
  end
end
