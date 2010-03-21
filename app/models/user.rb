class User < ActiveRecord::Base
  acts_as_authentic
 # attr_accessible :username, :password, :password_confirmation, :email, :roles
  has_many :roles, :through => :roles_users
  has_many :roles_users
  has_many :commands
  
  def role_symbols
    roles.map {|r| r.name.to_sym}
  end
  
end

