class Profile < ActiveRecord::Base
  validates_presence_of :name
  validate :only_one_server_for_exclusives

  has_many :excludes, :dependent => :destroy
  has_many :includes, :dependent => :destroy
  has_many :splits, :dependent => :destroy
  has_many :profilizations, :dependent => :destroy
  has_many :servers, :through => :profilizations

  named_scope :public, :conditions => { :exclusive => false }

  def only_one_server_for_exclusives
    errors.add_to_base("can only have one server") if exclusive && servers.length > 1
  end
end
