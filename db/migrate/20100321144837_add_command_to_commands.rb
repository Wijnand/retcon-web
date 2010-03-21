class AddCommandToCommands < ActiveRecord::Migration
  def self.up
    add_column :commands, :command, :string
  end

  def self.down
    remove_column :commands, :command
  end
end
