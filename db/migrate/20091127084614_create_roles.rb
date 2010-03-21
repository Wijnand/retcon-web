class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name

      t.timestamps
    end
    Role.create(:name => 'admin')
    Role.create(:name => 'user')
    Role.create(:name => 'agent')
  end

  def self.down
    drop_table :roles
  end
end
