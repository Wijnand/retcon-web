class Profile < ActiveRecord::Base
  validates_presence_of :path
  validates_presence_of :name
  
  has_many :excludes
  has_many :includes
  has_many :profilizations
  has_many :servers, :through => :profilizations
end
