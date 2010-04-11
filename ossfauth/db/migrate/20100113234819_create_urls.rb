class CreateUrls < ActiveRecord::Migration
  def self.up
    create_table :urls do |t|
      t.integer :site_id
      t.string :action
      t.string :content

      t.timestamps
    end


    Url.create!(:site_id => 1, :action => 'sync', 
    :content => 'http://140.109.22.239/index.php?option=com_ofsso&controller=sso&task=syncusers' )
    Url.create!(:site_id => 2, :action => 'sync', 
    :content => 'http://140.109.22.15:3000/of/sync_data')
  end

  def self.down
    drop_table :urls
  end
end
