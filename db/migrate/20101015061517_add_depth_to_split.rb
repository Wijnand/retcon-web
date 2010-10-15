class AddDepthToSplit < ActiveRecord::Migration
  def self.up
    add_column :splits, :depth, :integer, :default => 1
  end

  def self.down
    remove_column :splits, :depth
  end
end
