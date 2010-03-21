class AddBackupServerToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :backup_server_id, :integer
  end

  def self.down
    remove_column :users, :backup_server_id
  end
end
