class AddRegistKeyToSite < ActiveRecord::Migration
  def self.up
    add_column 'sites', 'regist_key', :text
  end

  def self.down
    remove_column 'sites', 'regist_key'
  end
end
