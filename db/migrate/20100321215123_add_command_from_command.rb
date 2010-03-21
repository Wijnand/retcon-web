class AddCommandFromCommand < ActiveRecord::Migration
  def self.up
    add_column :commands, :command, :text
  end

  def self.down
    remove_column :commands, :command
  end
end
