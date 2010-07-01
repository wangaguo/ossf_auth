class User < ActiveRecord::Base
  #####################
  # associations 
  #####################
  has_many :sessions, :dependent => :destroy
  has_many :messages, :dependent => :destroy
  has_many :events, :dependent => :destroy

  # for private params, implements as a hash, serialized in string field(yml) 
  serialize :params

  #####################
  # mixins
  #####################
  has_attached_file :avatar, :styles => 
    { :medium => "60x60>", :thumb => "16x16>" }

  #####################
  # named scopes 
  #####################
  #   unverified => email not reply(just signup), can't login
  #   normal => email verified, can login
  named_scope :unverified, :conditions => {:status => 0} 
  named_scope :normal, :conditions => {:status => 1} 
  #named_scope :verified, :conditions => {:status => 2} 

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
    if new_record? and %w{admin administrator superuser root openfoundry}.member? name
      errors.add :name, 'preserved'
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
    UUID.new.generate :compact
  end
  
  #####################
  # class methods 
  #####################
  class << self 
    #authn an user by token
    def authenticate_by_token(t)
      e = Event.find_by_token t
      return nil unless e
      u = e.user
      if u.status == 0 and User.normal.find_by_email(u.email)
        flash[:error] = 'Email already used'
        return nil
      end
      e
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
      a = [:first_name, :last_name]
      self.content_columns.select{|col|a.member? col.name.to_sym}
    end

    def columns_for_edit
      [:first_name, :last_name]
    end
  
    def columns_for_signup
      [ :name, :first_name, :last_name, 
        :password, :password_confirmation, 
        :email, :email_confirmation ]
    end

    def columns_for_change_email
      [ :new_email, :email_confirmation]
    end

    def columns_for_change_password
      [ :password, :password_confirmation, :old_password ]
    end
    
    #for shadow password
    def encrypt(str)
      return str.crypt('$1$ossqooxd')
    end
    
    #for add user from CLI
    def add_user(atts)
      u = User.new(atts)
      #u.change_password
      # WARNNING: 'add_user' produces status => "normal" user
      u.status = 1
      u.save!
    end
  end
end
