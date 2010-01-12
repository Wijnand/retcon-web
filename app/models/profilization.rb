class Profilization < ActiveRecord::Base
  belongs_to :server
  belongs_to :profile
end
