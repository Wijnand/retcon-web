class AddDefaultEnabledToServer < ActiveRecord::Migration
  def self.up
    change_column(:servers, :enabled, :boolean, :default => true)
  end

  def self.down
  end
end
