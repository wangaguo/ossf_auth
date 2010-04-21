class User < ActiveRecord::Base
  #####################
  # associations 
  #####################
  has_many :sessions
  has_many :messages
  has_many :events

  # for private params, implements as a hash, serialized in string field(yml) 
  serialize :params

  #####################
  # mixins
  #####################
  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }

  #####################
  # named scopes 
  #####################
  #   normal => verified, can login
  named_scope :normal, :conditions => {:status => 1} 
  named_scope :verified, :conditions => {:status => 2} 

  #####################
  # for change password, new password 
  #####################
  attr_accessor :password, :old_password, :password_confirmation, :change_password
  def crypt_password
    write_attribute(:shadow_password, User.encrypt(password) )
  end
  def should_crypt_password
    (password and not password.empty?) and ( new_record? or change_password )
  end
  private :crypt_password, :should_crypt_password
  before_save :crypt_password, :if => :should_crypt_password
  #####################
  # for change email 
  #####################
  attr_accessor :email_confirmation, :new_email
 
  #####################
  # validators 
  #####################
  validates_presence_of :name, :first_name, :last_name, :email
  validates_presence_of :password, :if => :change_password
  # make sure :password == :password_confirmation
  validates_confirmation_of :password, :if => :should_crypt_password

  def validate
    if (not self.params[:forgot_password]) and (not new_record?) and change_password
      #verify old password
      if User.encrypt(old_password) != shadow_password 
        errors.add :old_password, ' mismatch'
      end  
    end
  end

  # overload attribute params, by default is empty hash
  def params
    read_attribute(:params) || begin 
      write_attribute(:params, {} )
      read_attribute(:params)
    end
  end

  # generate random security token 
  def generate_token
    User.encrypt "#{name}kkk#{shadow_password}ttt#{Time.now.to_i}"
  end
  
  #####################
  # class methods 
  #####################
  class << self 
    #authn an user by token
    def authenticate_by_token(t)
      e = Event.find_by_token t
    end
    #authn an user
    def authenticate(name, password = '')
      u = User.normal.find_by_name(name) 
      if u and password.crypt(u.shadow_password) == u.shadow_password
        return u
      end
      return nil
    end
    
    #what column is editable?
    def editable_columns
      a = [:first_name, :last_name, :autobiography]
      self.content_columns.select{|col|a.member? col.name.to_sym}
    end
  
    def columns_for_signup
      [ :name, :first_name, :last_name, 
        :password, :password_confirmation, 
        :email, :email_confirmation ]
    end
    
    #for shadow password
    def encrypt(str)
      return str.crypt('$1$ossqooxd')
    end
    
    #for add user from CLI
    def add_user(atts)
      u = User.new(atts)
      #u.change_password
      u.status = 1
      u.save!
    end
  end
end
