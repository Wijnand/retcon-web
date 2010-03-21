class RemoveCommandFromCommand < ActiveRecord::Migration
  def self.up
    remove_column :commands, :command
  end

  def self.down
    add_column :commands, :command, :string
  end
end
