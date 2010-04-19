class AddLastRsyncToBackupJob < ActiveRecord::Migration
  def self.up
    add_column :backup_jobs, :last_rsync, :boolean
  end

  def self.down
    remove_column :backup_jobs, :last_rsync
  end
end
