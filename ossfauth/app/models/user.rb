class User < ActiveRecord::Base
  has_many :sessions
  has_many :messages
  ISTATUS = { :NO => 0, :READY => 1 }.freeze
  def self.authenticate(name, password)
    find_by_name_and_password(name, password)
  end
  
  def self.editable_columns
    a = [:first_name, :last_name, :autobiography]
    self.content_columns.select{|col|a.member? col.name.to_sym}
  end
end
