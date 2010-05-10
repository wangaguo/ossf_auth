class CreateUrls < ActiveRecord::Migration
  def self.up
    create_table :urls do |t|
      t.integer :site_id
      t.string :action
      t.text :content

      t.timestamps
    end

    wsw = Site.find_by_name 'wsw'
    of =  Site.find_by_name 'of'
    #create sync urls
    wsw.urls.create!( :action => 'sync', 
      :content => '/index.php?option=com_ofsso&controller=sso&task=syncusers' )
    of.urls.create!( :action => 'sync', 
      :content => '/of/sync_data')
    #create logout urls
    wsw.urls.create!( :action => 'logout', 
      :content => '/index.php?option=com_ofsso&controller=sso&task=logout&username=')
  end

  def self.down
    drop_table :urls
  end
end
