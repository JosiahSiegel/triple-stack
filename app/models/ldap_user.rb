class LdapUser < ActiveRecord::Base
  before_validation:get_ldap_email
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def get_ldap_email
    array =  Devise::LDAP::Adapter.get_ldap_param(self.username, 'mail')
    self.email = array.first
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end
end
