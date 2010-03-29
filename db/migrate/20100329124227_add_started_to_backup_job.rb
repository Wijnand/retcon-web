class AddStartedToBackupJob < ActiveRecord::Migration
  def self.up
    add_column :backup_jobs, :started, :datetime
  end

  def self.down
    remove_column :backup_jobs, :started
  end
end
