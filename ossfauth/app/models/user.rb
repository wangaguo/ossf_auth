class User < ActiveRecord::Base
  #associations
  has_many :sessions
  has_many :messages
  has_many :events

  #for private tags, implements as a hash, serialized in string field(yml) 
  serialize :tags

  #named scopes: normal => verified
  named_scope :normal, :conditions => {:status => 1} 

  #for change password
  attr_accessor :old_password, :password_confirmation
  #for change email
  attr_accessor :email_confirmation
 
  #validate :password == :password_confirmation
  validates_confirmation_of :password#, :if => Proc.new{ |u| u.new_record? or u.tags[:change_passwd] }

  #overload attribute tags, by default is empty hash
  def tags
    read_attribute(:tags) || {}
  end
  
  #authn an user
  def self.authenticate(name, password)
    find_by_name_and_password(name, password)
  end
  
  #what column is editable?
  def self.editable_columns
    a = [:first_name, :last_name, :autobiography]
    self.content_columns.select{|col|a.member? col.name.to_sym}
  end
  
  def self.encrypt(str)
    str.crypt('$1$ossqooxdd')
  end
end
