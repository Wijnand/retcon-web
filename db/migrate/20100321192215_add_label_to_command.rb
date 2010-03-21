class AddLabelToCommand < ActiveRecord::Migration
  def self.up
    add_column :commands, :label, :string
  end

  def self.down
    remove_column :commands, :label
  end
end
