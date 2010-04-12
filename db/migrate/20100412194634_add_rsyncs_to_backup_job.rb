class AddRsyncsToBackupJob < ActiveRecord::Migration
  def self.up
    add_column :backup_jobs, :rsyncs, :text
  end

  def self.down
    remove_column :backup_jobs, :rsyncs
  end
end
