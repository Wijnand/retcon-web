class AddExclusiveToProfile < ActiveRecord::Migration
  def self.up
    add_column :profiles, :exclusive, :boolean, :default => false
  end

  def self.down
    remove_column :profiles, :exclusive
  end
end
