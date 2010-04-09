class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.integer :istatus
      t.string :name
      t.string :first_name
      t.string :last_name
      t.string :autobiography
      t.string :password
      t.string :email
      t.string :timezone
      t.string :language

      t.timestamps
    end
    %W{tim kaworu river hyder aguo}.each{|n|
      User.create!(:name => n, :first_name => n, :last_name => 'ossf\'s', 
        :password => n, :email => "#{n}@ossf.org")
    }
  end

  def self.down
    drop_table :users
  end
end
