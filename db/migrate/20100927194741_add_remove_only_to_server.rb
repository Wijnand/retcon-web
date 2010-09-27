class AddRemoveOnlyToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :remove_only, :boolean
  end

  def self.down
    remove_column :servers, :remove_only
  end
end
