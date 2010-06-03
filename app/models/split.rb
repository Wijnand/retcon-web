class Split < ActiveRecord::Base
  belongs_to :profile, :counter_cache => true
  validates_presence_of :path
  
  def to_s
    path
  end
end
