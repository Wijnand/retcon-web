class AddIndexesToCommands < ActiveRecord::Migration
  def self.up
    add_index :commands, :exitstatus
    add_index :commands, :backup_job_id
  end

  def self.down
    remove_index :commands, :exitstatus
    remove_index :commands, :backup_job_id
  end
end
