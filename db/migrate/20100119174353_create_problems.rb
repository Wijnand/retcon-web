class CreateProblems < ActiveRecord::Migration
  def self.up
    create_table :problems do |t|
      t.integer :server_id
      t.integer :backup_server_id
      t.text :message

      t.timestamps
    end
  end

  def self.down
    drop_table :problems
  end
end
