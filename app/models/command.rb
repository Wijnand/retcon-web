class Command < ActiveRecord::Base
  belongs_to :backup_job
end
