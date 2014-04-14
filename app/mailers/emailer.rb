class Emailer < ActionMailer::Base
 default from: "dhanur@prospectzen.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.model_mailer.new_record_notification.subject
  #
   def new_record_notification(email)
    mail to: email, subject: "Success! You did it."
    render :json => "mailingdone" and return
   end
  
   def statuschanged(user)
     @user = user
     mail(to: @user.first['company_email_id'], subject: 'Welcome to WattSun')
   end
     
   def passwordchanged(user)
     @user = user
     mail(to: @user.first['company_email_id'], subject: 'Welcome to WattSun')
   end
     
end
