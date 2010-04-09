class AddRegistKeyToSite < ActiveRecord::Migration
  def self.up
    add_column 'sites', 'regist_key', :text
    Site.create!(:name => 'of', :ip => '140.109.22.15', 
        :regist_key => 'c1cac710-030f-012d-c173-0011254f08ff')
    Site.create!(:name => 'wsw', :ip => '140.109.22.239', 
        :regist_key => 'e3052d90-f7d1-012c-c171-0011254f08ff')
  end

  def self.down
    remove_column 'sites', 'regist_key'
  end
end
