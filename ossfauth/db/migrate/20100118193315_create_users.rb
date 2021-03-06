class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.integer :status
      t.string :name
      t.string :first_name
      t.string :last_name
      t.string :autobiography
      t.string :shadow_password
      t.string :email
      t.string :params
      t.string :timezone
      t.string :language

      t.timestamps
    end
    %W{tim kaworu river hyder aguo}.each{|n|
      User.add_user(:name => n, :first_name => n, :last_name => 'ossf\'s', 
        :password => n, :email => "hyderx@gmail.com")
    }
  end

  def self.down
    drop_table :users
  end
end
