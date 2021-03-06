class Include < ActiveRecord::Base
  belongs_to :profile
  
  validates_presence_of :path, :profile_id
  
  def to_s
    self.path
  end
end
