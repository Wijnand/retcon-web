class AddRsyncsToBackupJob < ActiveRecord::Migration
  def self.up
    add_column :backup_jobs, :stored_rsyncs, :text
  end

  def self.down
    remove_column :backup_jobs, :stored_rsyncs
  end
end
