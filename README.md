# **Triple-Stack**

### How to build this application from scratch:

Install rails: [RailsInstaller]

Build a rails app: `rails new triple-stack`

If you receive the following error: `Gem::RemoteFetcher::FetchError: SSL_connect`, you will have to temporarily edit your Gemfile source to http instead of https, `cd` into `triple-stack`, and run `bundle install`.

To run your new application, run `rails server` and navigate to http://localhost:3000/.
You will see the error " **Could not load 'active_record/connection_adapters/sqlite3_adapter'** ".

`Ctrl-C` to shutdown server.

Open your Gemfile and remove `gem 'sqlite3'` and add the following gems:
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
***
### For LDAP authentication:
- Run `rails g controller Welcome index`
- Set `root` in ***config/routes.rb*** to `'welcome#index'`
- Run `rails g controller Users`
- Run `rails g model User`
- Run `rails generate devise:install`
- Add the following between `<body></body>` tags in ***app/views/layouts/application.html.erb***:
    - `<p class="notice"><%= notice %></p>`
    - `<p class="alert"><%= alert %></p>`
- Run `rails generate devise User`
- Run `rails generate devise_ldap_authenticatable:install`
- Run `rails g devise:views`
- Run `bin/rake db:migrate` to update the database
- Run `rails server` and navigate to http://localhost:3000/users/sign_in to view the sign in page.
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
***
### To modify LDAP authentication to accept username:
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
- Open ***config/initializers/devise.rb***
    - Change `config.authentication_keys` to equal `[ :username ]`
    - Change `config.ldap_create_user` to equal `true` so all valid LDAP users will be allowed to login and an appropriate user record will be created.
    - Change `config.ldap_use_admin_to_bind` to equal `true` so the admin user will be used to bind to the LDAP server during authentication.
- Run `rails generate migration add_username_to_users username:string:uniq` to create a migration to add a username column to the users table.
- Run `rake db:migrate` to update the database with the migration.
***
### Create Sign In/Out links:
- Create partial `_login_items.html.erb` in directory ***app/views/devise/shared/*** with the following:
```r
<% if user_signed_in? %>
  <li>
  <%= link_to('Sign Out', destroy_user_session_path, :method => :delete) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Sign In', new_user_session_path)  %>  
  </li>
<% end %>
```
- In ***app/views/layouts/application.html.erb***, add `<%= render 'devise/shared/login_items' %>` above `<%= yield %>` to display the sign in/out links.
***
### Add Bootstrap styling & Font Awesome icons:
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
		<% if user_signed_in? %>
		  <li>
		  <%= link_to('Sign Out', destroy_user_session_path, :method => :delete) %>        
		  </li>
		<% else %>
		  <li>
		  <%= link_to('Sign In', new_user_session_path)  %>  
		  </li>
		<% end %>
  	</ul>
</nav>
```
- Place your brand image under ***app/assets/images/***.
***

[RailsInstaller]:http://railsinstaller.org/en
[ODBC Driver]:http://www.microsoft.com/en-us/download/details.aspx?id=36434
