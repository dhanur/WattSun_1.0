# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Wattsun::Application.initialize!
 ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
  :authentication => 'plain',
  :address => "smtp.sendgrid.net",
  :port => 587,
  :domain => "prospectzen.com",
  :user_name => "dhanur",
  :password => "G0$olar!",
  :enable_starttls_auto => true
}
