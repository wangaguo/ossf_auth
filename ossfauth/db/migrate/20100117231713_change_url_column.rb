class ChangeUrlColumn < ActiveRecord::Migration
  def self.up
    rename_column 'urls', 'type', 'action'
  end

  def self.down
    rename_column 'urls', 'action', 'type'
  end
end
