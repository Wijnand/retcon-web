class AddFinishedToBackupJob < ActiveRecord::Migration
  def self.up
    add_column :backup_jobs, :finished, :boolean
  end

  def self.down
    remove_column :backup_jobs, :finished
  end
end
