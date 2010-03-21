class Command < ActiveRecord::Base
  belongs_to :backup_job
  belongs_to :user
end
