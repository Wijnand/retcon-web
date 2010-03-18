class RemoveUselessFromBackupJob < ActiveRecord::Migration
  def self.up
    remove_column :backup_jobs, :pid
    remove_column :backup_jobs, :result
    remove_column :backup_jobs, :log
  end

  def self.down
    add_column :backup_jobs, :log, :text
    add_column :backup_jobs, :result, :string
    add_column :backup_jobs, :pid, :integer
  end
end
