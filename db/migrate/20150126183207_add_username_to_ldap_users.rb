class AddUsernameToLdapUsers < ActiveRecord::Migration
  def change
    add_column :ldap_users, :username, :string
    add_index :ldap_users, :username, unique: true
  end
end
