# **Triple-Stack**

## Build from scratch:

Install rails: [RailsInstaller]

Verify your installation by running `rails --version`

If you see the error `cannot load such file -- c:/RailsInstaller/Ruby2.1.0/lib/ruby/gems/2.1.0/gems/rails-4.2.0/bin/rails (LoadError)` 
or similar, do the following:

- Navigate to the rails file and set the correct rails path:

>  `C:/Users/xmr/Desktop/railsinstaller-windows/stage/Ruby2.1.0/bin/rails`
    
>  to
    
>  `C:/RailsInstaller/Ruby2.1.0/bin/rails`
 
Build a rails app: `rails new triple-stack`

If you receive the following error: `Gem::RemoteFetcher::FetchError: SSL_connect`, you will have to temporarily edit your Gemfile source to http instead of https, `cd` into `triple-stack`, and run `bundle install`.

To run your new application, run `rails server` and navigate to http://localhost:3000/.
You will see the error " **Could not load 'active_record/connection_adapters/sqlite3_adapter'** ".

`Ctrl-C` to shutdown server.

Open your Gemfile, remove `gem 'sqlite3'`, and add the following gems:
```ruby
gem 'tiny_tds'
gem 'ruby-odbc'
gem 'activerecord-sqlserver-adapter'
gem 'devise'
gem 'devise_ldap_authenticatable'

gem 'bootstrap-sass', '~> 3.3.3'
gem 'font-awesome-rails'
```

and change the rails gem version to `'4.1.9'`. You will then need to run `bundle update`, comment out `config.active_record.raise_in_transactional_callbacks = true` in ***config/application.rb***, and replace the content in your ***app/config/database.yml*** file to the following:
```ruby
default: &default
  adapter: sqlserver
  dsn: local_sqlserver
  mode: odbc
  database: XXXX
  username: XXXX
  password: XXXX

development:
  adapter: sqlserver
  dsn: local_sqlserver
  mode: odbc
  database: XXXX
  username: XXXX
  password: XXXX

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: sqlserver
  dsn: local_sqlserver
  mode: odbc
  database: XXXX
  username: XXXX
  password: XXXX

production:
  adapter: sqlserver
  dsn: local_sqlserver
  mode: odbc
  database: XXXX
  username: XXXX
  password: XXXX
```

To create an odbc connection in Windows: 
- Open up the **Control Panel** 
- Click on **Administrative Tools** 
- Open **Data Sources (ODBC)**
- Select the tab **User DSN** 
- Click **Add**
- Select **ODBC Driver 11 for SQL Server**

If this driver is not available, you will have to download it here: [ODBC Driver].
Once your ODBC connection is configured and you are able to successfully test the connection, you will then be able to add the name of the connection to `dsn` in you ***config/database.yml*** file.

Run `rails server` and navigate to http://localhost:3000/. 

`Ctrl-C` to shutdown server.

## LDAP authentication:
- Run `rails g controller Welcome index`
- Set `root` in ***config/routes.rb*** to `'welcome#index'`
- Run `rails generate devise:install`
- Add the following between `<body></body>` tags in ***app/views/layouts/application.html.erb***:
    - `<p class="notice"><%= notice %></p>`
    - `<p class="alert"><%= alert %></p>`
- Declaring a devise model other than 'User' may be necessary if your db already contains a 'users' table.
  - Run `rails generate devise LdapUser`
  - Run `rails generate devise_ldap_authenticatable:install --user-model=ldap_user`
- Run `rails g devise:views`
- Run `bin/rake db:migrate` to update the database
- Run `rails server` and navigate to http://localhost:3000/ldap_users/sign_in to view the sign in page.
- `Ctrl-C` to shutdown server.
- Open ***config/ldap.yml*** and configure with appropriate credentials.
    - You may need to contact your IT department for this information.
    - Example:
```ruby
development:
  host: name.company.local
  port: 389
  attribute: sAMAccountName
  base: "DC=company,DC=local"
  admin_user: domain\user
  admin_password: XXXX
  ssl: false
  # <<: *AUTHORIZATIONS
```

### Modify LDAP authentication to accept username:
- Open ***app/views/devise/sessions/new.html.erb*** and change
```html
<%= f.label :email %><br />
<%= f.email_field :email, autofocus: true %>
```
to
```html
<%= f.label :username %><br />
<%= f.text_field :username, autofocus: true %>
```
- Note email_field became text_field to disable email authentication.
- Modify the ldap_user model to populate the user's email and to no longer require it for validation:

  ```ruby
  before_validation:get_ldap_email
  
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
  ```
- Open ***config/initializers/devise.rb***
    - Change `config.authentication_keys` to equal `[ :username ]`
    - Change `config.ldap_create_user` to equal `true` so all valid LDAP users will be allowed to login and an appropriate user record will be created.
    - Change `config.ldap_use_admin_to_bind` to equal `true` so the admin user will be used to bind to the LDAP server during authentication.
- Run `rails generate migration add_username_to_ldap_users username:string:uniq` to create a migration to add a username column to the ldap_users table.
- Run `rake db:migrate` to update the database with the migration.

## Sign In/Out links:
- Create partial `_login_items.html.erb` in directory ***app/views/devise/shared/*** with the following:
```r
<% if ldap_user_signed_in? %>
  <li>
  <%= link_to('Sign Out', destroy_ldap_user_session_path, :method => :delete) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Sign In', new_ldap_user_session_path)  %>  
  </li>
<% end %>
```
- In ***app/views/layouts/application.html.erb***, add `<%= render 'devise/shared/login_items' %>` above `<%= yield %>` to display the sign in/out links.

## Bootstrap styling & Font Awesome icons:
- In directory ***app/assets/stylesheets/***, rename file ***application.css*** to ***application.css.scss***.
- Add the following to ***application.css.scss***:
```css
@import 'bootstrap';
@import 'font-awesome';
```
- In file ***app/assets/javascripts/application.js***, add `//= require bootstrap`
- Add the following to ***config/initializers/assets.rb***:
```ruby
Rails.application.config.assets.precompile += %w( fontawesome-webfont.eot )
Rails.application.config.assets.precompile += %w( fontawesome-webfont.woff )
Rails.application.config.assets.precompile += %w( fontawesome-webfont.ttf )
Rails.application.config.assets.precompile += %w( fontawesome-webfont.svg )
```
- Modify `_login_items.html.erb` in ***app/views/devise/shared/*** to:
```r
<nav class="navbar navbar-default" role="navigation">
  <%= link_to image_tag('stacker.png', size: '25x20'), '#', class: 'navbar-brand' %>
    <%= link_to 'Triple Stack', root_path, class: 'navbar-brand' %>
  <ul class="nav navbar-nav pull-right">
    <% if ldap_user_signed_in? %>
      <li>
      <%= link_to('Sign Out', destroy_ldap_user_session_path, :method => :delete) %>        
      </li>
    <% else %>
      <li>
      <%= link_to('Sign In', new_ldap_user_session_path)  %>  
      </li>
    <% end %>
    </ul>
</nav>
```
- Place your brand image under ***app/assets/images/***.

## Build on a preexisting database:
- Open your Gemfile and add `gem 'schema_to_scaffold'`
- Run `bundle install`
- Run `scaffold`
- When prompted, enter the path of your schema that was populated after running `rake db:migrate`:
  - `app/db/schema.rb`
- When prompted, designate the tables that you want scaffolding generated for.
- Scripts will be generated that you can copy and run to build the necessary scaffolding.

## SQL 2014 support:
- Modify the activerecord-sqlserver-adapter gem in the Gemfile to the following:
   ```
    gem 'activerecord-sqlserver-adapter', :git => "git://github.com/rails-sqlserver/activerecord-sqlserver-adapter.git", :branch => "4-1-stable"
    ```
    
## Secrets:
The .gitignore file should contain `config/secrets.yml`, to prevent sensitive information from being stored in the repository.

Example `secrets.yml`:
```yml
development:
  secret_key_base: XXXXX
  LDAP_SECRET: XXX
  LDAP_USER: "CN=Test User,OU=City,OU=XXXX Users,DC=xxxx,DC=local"
  LDAP_HOST: XXXX.xxxx.local
  LDAP_BASE: "DC=xxxx,DC=local"
  DOMAIN_USER: XXXX\user

test:
  secret_key_base: XXXXX
  LDAP_SECRET: XXX
  LDAP_USER: "CN=Test User,OU=City,OU=XXXX Users,DC=xxxx,DC=local"
  LDAP_HOST: XXXX.xxxx.local
  LDAP_BASE: "DC=xxxx,DC=local"
  DOMAIN_USER: XXXX\user

# Do not keep production secrets in the repository,
# instead read values from the environment.
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
  LDAP_SECRET: <%= ENV["LDAP_SECRET"] %>
  LDAP_USER: "CN=Test User,OU=City,OU=XXXX Users,DC=xxxx,DC=local"
  LDAP_HOST: XXXX.xxxx.local
  LDAP_BASE: "DC=xxxx,DC=local"
  DOMAIN_USER: XXXX\user
```

To reference a value, use `<%= Rails.application.secrets.DOMAIN_USER %>` in a view or .yml file, or 
`Rails.application.secrets.DOMAIN_USER` in an .rb file.


[RailsInstaller]:http://railsinstaller.org/en
[ODBC Driver]:http://www.microsoft.com/en-us/download/details.aspx?id=36434