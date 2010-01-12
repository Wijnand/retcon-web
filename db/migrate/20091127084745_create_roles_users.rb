class CreateRolesUsers < ActiveRecord::Migration
  def self.up
    create_table :roles_users do |t|
      t.integer :user_id
      t.integer :role_id

      t.timestamps
    end
    admin = User.find :first
    admin.roles << Role.first(:conditions => {:name => 'admin'})
    admin.save
  end

  def self.down
    drop_table :roles_users
  end
end
