class CreateCommands < ActiveRecord::Migration
  def self.up
    create_table :commands do |t|
      t.integer :backup_job_id
      t.sting :command
      t.integer :exitstatus
      t.text :output

      t.timestamps
    end
  end

  def self.down
    drop_table :commands
  end
end
