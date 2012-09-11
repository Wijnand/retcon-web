class AddIndexesToBackupJobs < ActiveRecord::Migration
  def self.up
    add_index :backup_jobs, :finished
    add_index :backup_jobs, :server_id
  end

  def self.down
    remove_index :backup_jobs, :finished
    remove_index :backup_jobs, :server_id
  end
end
