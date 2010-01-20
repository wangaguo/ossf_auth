class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.string :ip
      t.string :session_key
      t.datetime :login_time
      t.timestamps
    end
    add_column 'sessions', 'user_id', :integer
  end

  def self.down
    drop_table :sessions
  end
end
