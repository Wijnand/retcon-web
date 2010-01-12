class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|  
      t.string :username  
      t.string :email  
      t.string :crypted_password  
      t.string :password_salt  
      t.string :persistence_token  
      t.timestamps  
    end
    u = User.new(:username => 'admin', :password => 'admin', :password_confirmation => 'admin', :email => 'root@example.org')
    u.save
  end

  def self.down
    drop_table :users
  end
end
