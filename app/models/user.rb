class User < ActiveRecord::Base
  acts_as_authentic
 # attr_accessible :username, :password, :password_confirmation, :email, :roles
  has_many :roles, :through => :roles_users
  has_many :roles_users
  has_many :commands, :dependent => :destroy
  belongs_to :backup_server
  has_many :servers
  accepts_nested_attributes_for :servers

  def role_symbols
    roles.map {|r| r.name.to_sym}
  end
  
  def has_role?(role)
    role_symbols.include? role
  end
end

