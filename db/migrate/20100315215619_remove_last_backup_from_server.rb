class RemoveLastBackupFromServer < ActiveRecord::Migration
  def self.up
    remove_column :servers, :last_backup
  end

  def self.down
    add_column :servers, :last_backup, :datetime
  end
end
