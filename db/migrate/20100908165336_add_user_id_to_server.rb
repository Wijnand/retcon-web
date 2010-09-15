class AddUserIdToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :user_id, :integer
  end

  def self.down
    remove_column :servers, :user_id
  end
end
