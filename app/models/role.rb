class Role < ActiveRecord::Base
  has_many :users, :through => :roles_users
  has_many :roles_users
end
