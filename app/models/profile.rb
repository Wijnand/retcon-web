class Profile < ActiveRecord::Base
  validates_presence_of :name
  
  has_many :excludes, :dependent => :destroy
  has_many :includes, :dependent => :destroy
  has_many :profilizations, :dependent => :destroy
  has_many :servers, :through => :profilizations
end
