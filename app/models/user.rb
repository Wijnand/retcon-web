class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.allow_http_basic_auth = true
  end
  
  attr_accessible :username, :password, :password_confirmation, :email
  has_many :roles, :through => :roles_users
  has_many :roles_users
  
  def role_symbols
    roles.map {|r| r.name.to_sym}
  end
  
end
