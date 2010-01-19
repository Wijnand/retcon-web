class Problem < ActiveRecord::Base
  belongs_to :server
  belongs_to :backup_server
end
