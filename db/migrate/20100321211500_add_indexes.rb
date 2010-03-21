class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :backup_jobs, :status, :unique => false
  end

  def self.down
    remove_index :backup_jobs, :status
  end
end
