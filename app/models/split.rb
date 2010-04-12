class Split < ActiveRecord::Base
  belongs_to :profile
  validates_presence_of :path
end
