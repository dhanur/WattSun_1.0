class HomesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  require 'digest/md5'
  require 'stripe'
  require "rexml/document"
  require 'rest_client'
  require 'time_diff'
  
  def index
          
  end

  def adminlogin

  end

    
  def adminuserstatus
    
     if (session[:admin_user_id] || session[:super_admin_user_id])
                   @allusers=User.all
     else
         redirect_to :action => "adminlogin"
    end   
  
  end
  
   
  def adminuserprofile
    
     if (session[:admin_user_id] || session[:super_admin_user_id])
                    @allusers=User.all
     else
         redirect_to :action => "adminlogin"
     end   
    
  end
  
  
  def singleuserview
     
    if (session[:admin_user_id] || session[:super_admin_user_id])   
       session[:admin_userview_id]=params[:user_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
  
  end
  
  
  def adminprofileview
    if ((session[:admin_user_id] || session[:super_admin_user_id]) && session[:admin_userview_id])
      @user=User.select("*").where("id = ?",session[:admin_userview_id]).limit(1)
    else
      redirect_to :action => "adminlogin"
    end

  end
  
  
  
 def adminuserpayment
    
    
     if (session[:admin_user_id] || session[:super_admin_user_id])
                   @allusers=User.all
     else
         redirect_to :action => "adminlogin"
    end 
    
  end
  

  def updatecardnumber
    
    if session[:current_user_id]
       
        user=User.select("cust_id").where("id = ?",session[:current_user_id]).limit(1)
        token = params[:stripeToken]
        customer_id = user.first['cust_id']
        customer = Stripe::Customer.retrieve(customer_id)
       
        customer.description = "Customer for test@example.com"
        customer.card = token # obtained with Stripe.js
        customer.save  
        User.where(:id=>session[:current_user_id]).limit(1).update_all(:last_activity => Time.now, :cust_id=>customer_id,:payment_status=>1,:card_exp_year=> customer.cards.data[0]['exp_year'],:card_exp_month=>customer.cards.data[0]['exp_month'],
        :card_no=>customer.cards.data[0]['last4'])
        redirect_to :action => "userpayment"
    
    else
        redirect_to :action => "userlogin"
    end     
 
  end
  
  
   def singleusercredits
     
    if (session[:admin_user_id]  || session[:super_admin_user_id])  
       session[:admin_userpayment_id]=params[:user_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
  
  end
  
 
  def adminusernumber    
    
    if ((session[:admin_user_id] || session[:super_admin_user_id]) && session[:admin_userpayment_id])
      @user=User.select("*").where("id = ?",session[:admin_userpayment_id]).limit(1)
    else
      redirect_to :action => "adminlogin"
    end    
    
  end
  
  
  
  def updateplan
             
              customer = User.select('payment_status,subscription_id,cust_id').where("id=?", session[:admin_userpayment_id])
              
              if (customer.first['payment_status'] == 1)
          
              customer2= Stripe::Customer.retrieve(customer.first['cust_id'])
          
               amount = (params[:ma].to_f * 100).to_i     
              plan = Stripe::Plan.retrieve(customer.first['cust_id'])
          
              plan.delete
              
              Stripe::Plan.create(          
              :amount => amount,          
              :interval => 'month',          
              :name => 'monthly plan',          
              :currency => 'usd',          
              :id => customer.first['cust_id'],          
              )
          
              subscription = customer2.subscriptions.retrieve(customer.first['subscription_id'])         
              subscription.plan = customer.first['cust_id']          
              subscription.prorate = 'true'          
              subscription.save      
              
              else
                 
                 amount = (params[:ma].to_f * 100).to_i 
                 
              end
              
              User.where(:id=>session[:admin_userpayment_id]).limit(1).update_all(:last_activity => Time.now, :monthly_charge=>params[:ma])
              
              render :json => {:results =>"done"}
    
   end

  
  def updatechrg
        
      User.where(:id=>session[:admin_userpayment_id]).limit(1).update_all(:last_activity => Time.now, :house_charge=>(params[:hc].to_f))
      render :json => {:results =>"done"}
    
    
  end

   
  def updatecredits
      @oldcredits=User.select("credits").where(:id=>session[:admin_userpayment_id]).limit(1)             
      newcredits = params[:cur_credits].to_i + @oldcredits.first['credits']
      User.where(:id=>session[:admin_userpayment_id]).limit(1).update_all(:last_activity => Time.now, :credits=>newcredits)
      render :json => {:results =>newcredits}
  end
 
 
  def adminuserpurchase
    
     if (session[:admin_user_id] || session[:super_admin_user_id])
                   @allusers=User.select("*").all
                   
                   @paidcounter= Array.new
                   
                   @allusers.each do |u|
                     
                   @paidcounter << UserPurchase.where(:user_id => u.id).count
                     
                   end
                   
     else
         redirect_to :action => "adminlogin"
    end   
    
  end
  
  
  def singleuserviewbyadmin
     
    if (session[:admin_user_id] || session[:super_admin_user_id])    
       session[:admin_user_transaction_view_id]=params[:user_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
  
  end
  
  
  def adminuserpurchaselist   
    
    if ((session[:admin_user_id] || session[:super_admin_user_id]) && session[:admin_user_transaction_view_id])
      
      @userbyadmin=User.select("*").where("id = ?",session[:admin_user_transaction_view_id]).limit(1)
      @transctions=UserPurchase.select("address,transaction_id,last_purchase_date").where("user_id = ? and status = 1",session[:admin_user_transaction_view_id])
      
    else
      redirect_to :action => "adminlogin"
    end
    
    
  end
  
  
  def viewtransctionbyadmin
  
    if ((session[:admin_user_id] || session[:super_admin_user_id]) && session[:admin_user_transaction_view_id])   
       session[:current_transction_view_of_user_byadmin_id]=params[:tranc_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
    
  end
  
 
 def adminpurchaseview

    if session[:current_transction_view_of_user_byadmin_id] && (session[:admin_user_id] || session[:super_admin_user_id])     
      
        @transction=UserPurchase.select("*").where("transaction_id = ? and status = 1",session[:current_transction_view_of_user_byadmin_id])  
        @userbyadmin=User.select("*").where("id = ?",session[:admin_user_transaction_view_id]).limit(1)  
        
        if @transction.blank?  
              @zee=''
              @zti=''
              @zpb=''
              @zib=''
              @age =''
              @owned =''
        else     
          
              if @transction.first['year_built'].blank?
                  @age =''               
              else         
                  @age =(Time.now.year - @transction.first['year_built'])
              end          
          
              if @transction.first['last_sale_date'].blank?
                    @owned =''               
              else         
                    @owned=Time.diff(Time.now, Time.parse(@transction.first['last_sale_date']),'%y, %M')[:diff]
              end 
               
             
              @utility= Utilitytable.select("utility").where("zip = ?",@transction.first['zip'])
              @utility = @utility.to_a.map(&:utility)
            
              @zee=ZipEverythingElse.select("*").where("zip = ?",@transction.first['zip']).limit(1)
                     
              @zti=ZipTopInstaller.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(5)
                      
              @zpb=ZipPanelBrand.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(3)
                     
              @zib=ZipInverterBrand.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(3)
              
              
              @cee=CityEverythingElse.select("*").where("city = ?",@transction.first['city']).limit(1)
     
              @cti=CityTopInstaller.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(5)             
        
              @cpb=CityPanelBrand.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(3)           
        
              @cib=CityInverterBrand.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(3)
                      
        end        
        
     else 
        redirect_to :action => "adminlogin"
     end  
    

  end
 
 

 
 def sales 
    
    if ((session[:admin_user_id] || session[:super_admin_user_id]))
          
      @alltransactions=User.joins(:user_purchases).select("users.id, users.first_name, users.last_name, users.company_name, user_purchases.transaction_id, user_purchases.address, user_purchases.last_purchase_date")   
    else
      redirect_to :action => "adminlogin"
    end
    
    
  end


  def salesviewtransaction
  
    if ((session[:admin_user_id] || session[:super_admin_user_id]))   
       session[:sales_transaction_id]=params[:tranc_id]
        
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
    
  end
  



  def salesview

    if session[:sales_transaction_id] && (session[:admin_user_id] || session[:super_admin_user_id])     
      
        @transction=UserPurchase.select("*").where("transaction_id = ? and status = 1",session[:sales_transaction_id])  
        @userbyadmin=User.select("*").where("id = ?",@transction.first['user_id']).limit(1)  
        
        if @transction.blank?  
              @zee=''
              @zti=''
              @zpb=''
              @zib=''
              @age =''
              @owned =''  
        else     
          
              if @transction.first['year_built'].blank?
                  @age =''               
              else         
                  @age =(Time.now.year - @transction.first['year_built'])
              end  
             
              if @transction.first['last_sale_date'].blank?
                    @owned =''               
                else         
                    @owned=Time.diff(Time.now, Time.parse(@transction.first['last_sale_date']),'%y, %M')[:diff]
              end 
              
              @utility= Utilitytable.select("utility").where("zip = ?",@transction.first['zip'])
              @utility = @utility.to_a.map(&:utility)          
           
              @zee=ZipEverythingElse.select("*").where("zip = ?",@transction.first['zip']).limit(1)
                     
              @zti=ZipTopInstaller.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(5)
                      
              @zpb=ZipPanelBrand.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(3)
                     
              @zib=ZipInverterBrand.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(3)
              
            
              @cee=CityEverythingElse.select("*").where("city = ?",@transction.first['city']).limit(1)
     
              @cti=CityTopInstaller.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(5)             
        
              @cpb=CityPanelBrand.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(3)           
        
              @cib=CityInverterBrand.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(3)
                      
        end        
        
     else 
        redirect_to :action => "adminlogin"
     end  
    

  end
 
 
 
 
  def signup

  end

  def contact

  end

  def contactreceipt

    @contact = Contact.new(contact_params)

    if !@contact.save
      render :json =>"something wrong"
    end

  end

  def userlogin

  end

  def forgotpassword

  end
  
  
  def resetpassword

    @user=User.select("id,company_email_id,verification_token").where("company_email_id=? and verification_token = ?",params[:emailid],params[:vt]).limit(1)
    if @user.blank?
      render :json =>{:error =>params[:emailid]}
    else
      User.where(:id=>@user.first['id']).limit(1).update_all(:last_activity => Time.now,:password=>params[:password])
      session[:cust_user_id]=@user.first['id'];
      
       redirect_to :action => "userlogin"
    end

  end
  
  
  
  def checkuserexist

    @user=User.select("*").where("company_email_id = ? and mobile_phone = ?",params[:emailid],params[:mobilephone]).limit(1)
    if @user.blank?

      session[:errormessage]= params[:emailid]
      redirect_to :action => "forgotpassword"

    else
      session[:errormessage]=nil
      @user.update_all(:forgot_pass_date =>Date.today, :last_activity => Time.now)

      if @user
        Emailer.passwordchanged(@user).deliver
        redirect_to :action => "resetpasswordmessage"
      else
        render :json=>"Not updated login date"
      end

    end

  end
  
  
  def passwordreset
     
       @forgotuser = User.select("*").where("company_email_id=? and verification_token = ?",params[:id],params[:vt]).limit(1)
    
       if  @forgotuser.blank? || (@forgotuser.first['forgot_pass_date'] < Date.today - 30.days)
            redirect_to :action => "forgotpassword"
       end
        
   end
  
 
  def resetpasswordmessage
    
    
  end

  def userpayment

    if session[:current_user_id]
      @user=User.select("*").where("id = ?",session[:current_user_id]).limit(1)
    else
      redirect_to :action => "userlogin"
    end

  end
  
  
  def userproblem

    if !session[:current_user_id]
      redirect_to :action => "userlogin"
    end
  end

  def userprofile

    if session[:current_user_id]
      @user=User.select("*").where("id = ?",session[:current_user_id]).limit(1)
    else
      redirect_to :action => "userlogin"
    end
  end

  
  def purchaseitq
   
    if session[:current_user_id]
      
      @user=User.select("first_name,last_name").where("id = ?",session[:current_user_id]).limit(1)
      @transctions=UserPurchase.select("address,transaction_id,last_purchase_date").where("user_id = ? and status = 1",session[:current_user_id])
      
    else
      redirect_to :action => "userlogin"
    end
    
  end


  def viewtransction
  
    if session[:current_user_id]      
       session[:current_transction_id]=params[:tranc_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "userlogin"   
    end
    
  end
  
  
 
  def userpurchaseview
    
    if session[:current_transction_id] && session[:current_user_id]      
      
        @transction=UserPurchase.select("*").where("transaction_id = ? and status = 1",session[:current_transction_id])  
        @user=User.select("*").where("id = ?",session[:current_user_id]).limit(1)  
        
        
        if @transction.blank? 
              @zee=''
              @zti=''
              @zpb=''
              @zib=''
              @age=''
              @owned ='' 
        else   
            
             if @transction.first['year_built'].blank?
                @age =''               
             else         
                @age =(Time.now.year - @transction.first['year_built'])
             end     
            
             if @transction.first['last_sale_date'].blank?
                    @owned =''               
             else         
                    @owned=Time.diff(Time.now, Time.parse(@transction.first['last_sale_date']),'%y, %M')[:diff]
             end 
               
              @utility= Utilitytable.select("utility").where("zip = ?",@transction.first['zip'])
              @utility = @utility.to_a.map(&:utility)
             
              @zee=ZipEverythingElse.select("*").where("zip = ?",@transction.first['zip']).limit(1)
                     
              @zti=ZipTopInstaller.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(5)
                      
              @zpb=ZipPanelBrand.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(3)
                     
              @zib=ZipInverterBrand.select("*").where("zip = ?",@transction.first['zip']).order('no_of_solar_homes desc').limit(3)
              
       
              @cee=CityEverythingElse.select("*").where("city = ?",@transction.first['city']).limit(1)
     
              @cti=CityTopInstaller.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(5)             
        
              @cpb=CityPanelBrand.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(3)           
        
              @cib=CityInverterBrand.select("*").where("city = ?",@transction.first['city']).order('no_of_solar_homes desc').limit(3)
            
        end        
        
     else 
        redirect_to :action => "userlogin"
     end  
    
  end

 
 
  def profileupdate

    @user=User.select("*").where("id = ?",session[:current_user_id]).limit(1)

    if @user.blank?
      redirect_to :action => "userlogin"
    else
      
      if params[:ntitle]

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :title => params[:ntitle])
        render :json => {:status =>"done" }
  
      elsif params[:mphone]

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :mobile_phone => params[:mphone])
        render :json => {:status =>"done" }

      elsif params[:ophone]

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :office_phone => params[:ophone])
        render :json => {:status =>"done" }

      elsif (@user.first['password']==params[:cur_psd])

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :password => params[:new_psd])
        render :json => {:status =>"done" }
      else
        render :json => {:status =>"not" }
      end

    end

  end
  
  def profileupdatebyadmin
     
    @user=User.select("*").where("id = ?",session[:admin_userview_id]).limit(1)

    if @user.blank?
      redirect_to :action => "adminlogin"
    else
      
      if params[:ntitle]

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :title => params[:ntitle])
        render :json => {:status =>"done" }
  
      elsif params[:mphone]

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :mobile_phone => params[:mphone])
        render :json => {:status =>"done" }

      elsif params[:ophone]

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :office_phone => params[:ophone])
        render :json => {:status =>"done" }

      elsif (@user.first['password']==params[:cur_psd])

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :password => params[:new_psd])
        render :json => {:status =>"done" }
      else
        render :json => {:status =>"not" }
      end

    end
    
  end


  def problemcreceipt

    if session[:current_user_id]
      @user=User.select("*").where("id = ?",session[:current_user_id]).limit(1)
      @contact=Contact.new(:full_name=>@user.first['first_name']+@user.first['last_name'],:email=>@user.first['company_email_id'],:mobile_phone=>@user.first['mobile_phone'],:about=>params[:what_about],:message=>params[:message])

      if !@contact.save
        render :json=>"Not saved"
      end
    else
      redirect_to :action => "userlogin"

    end

  end

  def infofetch
   
    @info=User.select("*").where("id = ?",params[:user_id]).limit(1)
    @info = @info.to_a.map(&:serializable_hash)
    render :json=>{:info=>@info}
  end
  
  


  def adminsignin
  
     @admin=Admin.select("*").where("admin_email_id = ? and admin_password = ?",params[:emailid],params[:password]).limit(1)
   
    if @admin.blank?
      session[:admin_errormessage]= params[:emailid]
      redirect_to :action => "adminlogin"
    else
      
      if (@admin.first['admin_status']=='2')  
        
          session[:super_admin_user_id]=@admin.first['id'];      
          redirect_to :action => "superadmin"        
      
      elsif (@admin.first['admin_status']=='1')
        
           session[:admin_user_id]=@admin.first['id'];
           redirect_to :action => "adminuserstatus" 
      else 
           session[:admin_approval_error]= params[:emailid]
           redirect_to :action => "adminlogin"
      end
        
    end
  end
  
  
  
  def adminlogout     
       session[:sales_transaction_id]=nil
      session[:admin_errormessage]=nil
      session[:super_admin_user_id] = nil
      session[:admin_user_id] = nil
      session[:payment_flag]= nil
      redirect_to :action => "adminlogin"
   
  end
  
  def admincreate
    
    @adminuser=Admin.select("id").where("admin_email_id = ?",params[:admin_email_id]).limit(1)
    
    if @adminuser.blank?
        session[:admin_signup_errormessage]=nil     
        @adminuser = Admin.new(admin_params)
        @adminuser.admin_token=Digest::MD5.hexdigest(params[:admin_email_id])
        
        if @adminuser.save
           #Emailer.new_record_notification(params[:company_email_id]).deliver
           redirect_to :action => "adminlogin"
     
        end
     
    else
      session[:admin_signup_errormessage]=params[:admin_email_id]                        
      redirect_to :action => "adminsignup"     
    end  
    
  end

  
  
  def superadmin
    
     if session[:super_admin_user_id]    
          @alladmins=Admin.select("*").where("admin_status !=2 ")
     else
          redirect_to :action => "adminlogin"
     end 
    
  end
  
 
  def changeadminstatus    
    
    @admin=Admin.select("*").where("id=?",params[:admin_id]).limit(1)
   
    if @admin.blank?
      render :json =>{:error =>"Unchanged"}
    else
   
      if (params[:newstatus]=='Applied')
                                           Admin.where(:id=>@admin.first['id']).update_all("admin_status = '0'")
                                            redirect_to :json => "done"
      elsif (params[:newstatus]=='Approved')
                                           Admin.where(:id=>@admin.first['id']).update_all("admin_status = '1'")
                                            redirect_to :json => "done"
      end
      
     
    end
    
  end
  
   
   
  def create
    
    @user=User.select("id").where("company_email_id = ?",params[:company_email_id]).limit(1)
    
    if @user.blank?
  
      @user = User.new(user_params)
      @user.registration_date = Time.now
      @user.last_activity = Time.now
      @user.verification_token=Digest::MD5.hexdigest(params[:company_email_id])
    
        if @user.save
          Emailer.new_record_notification(params[:company_email_id]).deliver
         render :json =>{:results => 1 }
        end
     
    else
      
      render :json =>{:results => 2 }
      
    end  

  end


 def createmsg
   
 end

  def datafetch

    if params[:radio]=='zip'

      @zee=ZipEverythingElse.select("*").where("zip = ?",params[:zip]).limit(1)
      @zee = @zee.to_a.map(&:serializable_hash)

      @ztp=ZipTopInstaller.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(5)
      @ztp = @ztp.to_a.map(&:serializable_hash)

      @zpb=ZipPanelBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zpb = @zpb.to_a.map(&:serializable_hash)

      @zib=ZipInverterBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zib = @zib.to_a.map(&:serializable_hash)

      @utility= Utilitytable.select("utility").where("zip = ?",params[:zip])
      @utility = @utility.to_a.map(&:serializable_hash)

      render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility}

    elsif params[:radio]=='city'

      @zee=CityEverythingElse.select("*").where("city = ?",params[:citycode]).limit(1)
      @zee = @zee.to_a.map(&:serializable_hash)

      @ztp=CityTopInstaller.select("*").where("city = ?",params[:citycode]).order('no_of_solar_homes desc').limit(5)
      @ztp = @ztp.to_a.map(&:serializable_hash)

      @zpb=CityPanelBrand.select("*").where("city = ?",params[:citycode]).order('no_of_solar_homes desc').limit(3)
      @zpb = @zpb.to_a.map(&:serializable_hash)

      @zib=CityInverterBrand.select("*").where("city = ?",params[:citycode]).order('no_of_solar_homes desc').limit(3)
      @zib = @zib.to_a.map(&:serializable_hash)

      @utility= Utilitytable.select("utility").where("zip = ?",params[:zip])
      @utility = @utility.to_a.map(&:serializable_hash)

      render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility}

    end
  end



  def alldatafetchonmarkerclick    

      @transaction= UserPurchase.select("*").where("transaction_id = ?",params[:tranc]).limit(1) 
      @transaction = @transaction.to_a.map(&:serializable_hash)
      
      session[:last_viewed_address]=@transaction.first['address']
      
      if @transaction.first['year_built'].blank?
          age =''               
      else         
          age =(Time.now.year - @transaction.first['year_built'])
      end     
 
      if @transaction.first['last_sale_date'].blank?
          owned =''               
      else         
          owned=Time.diff(Time.now, Time.parse(@transaction.first['last_sale_date']),'%y, %M')[:diff]
      end     
      
      
      @zee=ZipEverythingElse.select("*").where("zip = ?",params[:zip]).limit(1)
      @zee = @zee.to_a.map(&:serializable_hash)

      @ztp=ZipTopInstaller.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(5)
      @ztp = @ztp.to_a.map(&:serializable_hash)

      @zpb=ZipPanelBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zpb = @zpb.to_a.map(&:serializable_hash)

      @zib=ZipInverterBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zib = @zib.to_a.map(&:serializable_hash)

      @utility= Utilitytable.select("utility").where("zip = ?",params[:zip])
      @utility = @utility.to_a.map(&:serializable_hash)

      render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility,:transaction =>@transaction, :age=> age, :owned=> owned}
    
    
    
  end


  def alldatafetchonmarkernewtrans

      @transaction= UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)
      @transaction = @transaction.to_a.map(&:serializable_hash)
    
      session[:last_viewed_address]=@transaction.first['address']  
      
      if @transaction.first['year_built'].blank?
          age =''               
      else         
          age =(Time.now.year - @transaction.first['year_built'])
      end  

      
      if @transaction.first['last_sale_date'].blank?
          owned =''               
      else      
         owned=Time.diff(Time.now, Time.parse(@transaction.first['last_sale_date']),'%y, %M')[:diff]
      end     
            
      @zee=ZipEverythingElse.select("*").where("zip = ?",params[:zip]).limit(1)
      @zee = @zee.to_a.map(&:serializable_hash)

      @ztp=ZipTopInstaller.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(5)
      @ztp = @ztp.to_a.map(&:serializable_hash)

      @zpb=ZipPanelBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zpb = @zpb.to_a.map(&:serializable_hash)

      @zib=ZipInverterBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zib = @zib.to_a.map(&:serializable_hash)

      @utility= Utilitytable.select("utility").where("zip = ?",params[:zip])
      @utility = @utility.to_a.map(&:serializable_hash)

      render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility,:transaction =>@transaction, :age => age, :owned=> owned}
    
    
    
  end


  def login

    @user=User.select('id,payment_status').where("company_email_id = ? and password = ? and active_status=1",params[:emailid],params[:password]).limit(1)
    if @user.blank?

      session[:errormessage]= params[:emailid]
      redirect_to :action => "userlogin"

    else
      session[:errormessage]=nil
      session[:cust_user_id]=@user.first['id']
      @user.update_all(:last_activity => Time.now)
      
      if @user.first['payment_status']=='0'  
              
        redirect_to :action => "register_cc"
     
      else
        session[:payment_flag]= nil
        session[:current_user_id] =@user.first['id']
        redirect_to :action => "viewmap"
     
      end
      
    end
  end
  
 
  def register_cc
    
    if session[:cust_user_id]  
        @user=User.select("id, company_email_id, monthly_charge, payment_status").where("id=?",session[:cust_user_id]).limit(1)
           
        if @user.first['payment_status']=='1'
           redirect_to :action => "userlogin"
        end
        
    else
       redirect_to :action => "index"
    end   
     
  end


  def logout
      session[:cust_user_id]=nil
      session[:last_viewed_address]=nil
      session[:errormessage]=nil
      session[:current_user_id] = nil
      session[:payment_flag]= nil
      redirect_to :action => "index"
  end

 
  def changestatus

    @user=User.select("*").where("id=?",params[:user_id]).limit(1)
    if @user.blank?
      render :json =>{:error =>"Unchanged"}
    else
      if (params[:newstatus]=='Approve')
        User.where(:id=>@user.first['id']).update_all("active_status = 1")
      elsif (params[:newstatus]=='Waitlist')
        User.where(:id=>@user.first['id']).update_all("active_status = 2")
      elsif (params[:newstatus]=='Deny')
        User.where(:id=>@user.first['id']).update_all("active_status = 3")
      elsif (params[:newstatus]=='Block')
        User.where(:id=>@user.first['id']).update_all("active_status = 4")
      elsif (params[:newstatus]=='Unblock')
        User.where(:id=>@user.first['id']).update_all("active_status = 1")
      end
      @user=User.select("*").where("id=?",params[:user_id]).limit(1)
      Emailer.statuschanged(@user).deliver
      redirect_to :json => "done"

    end
  end

 
  def activate
    
    @password = User.select("password,first_name,last_name").where("company_email_id=? and verification_token = ?",params[:id],params[:vt]).limit(1)
    
    if !@password.first['password'].blank?
       redirect_to :action => "userlogin"
    end
         
  end

 
  def activation
    @user=User.select("id,company_email_id,verification_token").where("company_email_id=? and verification_token = ?",params[:email],params[:vt]).limit(1)
    if @user.blank?
      render :json =>{:error =>"Not Exists"}
    else
      User.where(:id=>@user.first['id']).limit(1).update_all(:last_activity => Time.now, :password=>params[:password])
      session[:cust_user_id]=@user.first['id'];
      
      render :json =>{:results => "done" }
    end
  end

  def stripe

  end
  
  

  def entercreditinfo
   
        token = params[:stripeToken]
    
        customer = Stripe::Customer.create(
    
        :email => "neha@clicklabs.in",
    
        :card  => token,
    
        )
    
        @amount = User.select('monthly_charge').where("id=?", session[:cust_user_id])
    
        if ( !@amount.first['monthly_charge'].nil?)
          
          amount = (@amount.first['monthly_charge'].to_f * 100).to_i
          
        else
          
          amount = 9900  
          
          User.where(:id=>session[:cust_user_id]).limit(1).update_all(:monthly_charge=>99)
        
        end
        
        customer_id = customer.id
    
        plan=   Stripe::Plan.create(
    
        :amount => amount,
    
        :interval => 'month',
    
        :name => 'monthly plan',
    
        :currency => 'usd',
    
        :id => customer_id,
    
        )
    
        subscription= customer.subscriptions.create(:plan => plan)
    
        # render :json => {"data"=> amount}
    
         # Amount in cents
    
        User.where(:id=>session[:cust_user_id]).limit(1).update_all(:last_activity => Time.now, :cust_id=>customer_id,:payment_status=>1,:house_charge=>3,:subscription_id=>subscription.id,:credits=>0,:card_exp_year=> customer.cards.data[0]['exp_year'],:card_exp_month=>customer.cards.data[0]['exp_month'],:current_period_end=>subscription.current_period_end,:card_no=>customer.cards.data[0]['last4'])
    
        redirect_to :action => "userlogin"
    
    
    end
    
    


   def checkpurchase
    
      session[:last_viewed_address]=params[:address]  
     
      @zee=ZipEverythingElse.select("*").where("zip = ?",params[:zip]).limit(1)
      @zee = @zee.to_a.map(&:serializable_hash)

      @ztp=ZipTopInstaller.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(5)
      @ztp = @ztp.to_a.map(&:serializable_hash)

      @zpb=ZipPanelBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zpb = @zpb.to_a.map(&:serializable_hash)

      @zib=ZipInverterBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(3)
      @zib = @zib.to_a.map(&:serializable_hash)

      @utility= Utilitytable.select("utility").where("zip = ?",params[:zip])
      @utility = @utility.to_a.map(&:serializable_hash)

          
     customer = User.select('company_name,credits,cust_id,house_charge').where("id=?", session[:current_user_id])
     
     addressexist= UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1) 
     
        
     @prev_check_address=UserPurchase.select("*").where("address ='"+params[:address]+"'").limit(1) 
     
     if @prev_check_address.blank?
          @prev_chks=0
     else
          if customer.first['company_name']=='ProspectZen'
              @prev_chks=@prev_check_address.first['prev_check']
          else
              @prev_chks=@prev_check_address.first['prev_check']+1
          end
     end
     
  
     purchasedate=''
     
     flag=0
     
     
      if addressexist.blank?
            flag=1
      else  
                    
           purchasedate =  addressexist.first['last_purchase_date'] 
                   
           time_diff_components= Date.today - 90.days
            if  time_diff_components > purchasedate
             flag=1
             UserPurchase.where("user_id=? and status = 1 and address ='"+params[:address]+"'",session[:current_user_id]).limit(1).update_all(:status=>0)
            else 
             flag=0              
           end
       
      end     
      
                 
     if flag==1 
      
       
            zip = params[:zip]
      
            city = params[:city]
      
            street = params[:street]
      
            route = params[:route]
      
            country = params[:country]
      
             administrative_area_level_1 = params[:state]
            
              administrative_area_level_2 = params[:county]
    
            xml = '<?xml version = "1.0" encoding = "UTF-8"?>
      
      <!DOCTYPE REQUEST_GROUP SYSTEM "C2DRequestv2.0.dtd">
      
      <REQUEST_GROUP MISMOVersionID = "2.1">
      
      <REQUEST
      
          LoginAccountIdentifier = "SUNIBLEDEMO"
      
          LoginAccountPassword = "C2DTEST">
      
      <REQUESTDATA>
      
      <PROPERTY_INFORMATION_REQUEST>
      
      <_CONNECT2DATA_PRODUCT _DetailedSubjectReport = "Y"
      
                             _IncludePDFIndicator = "Y"
      
                             _IncludeSearchCriteriaIndicator = "Y"/>
      
      <_PROPERTY_CRITERIA _StreetAddress = "'+street+" "+route+'"
      
                          _StreetAddress2 = ""
      
                          _City = "'+city+'"
      
                          _State = "'+administrative_area_level_1+'"
      
                          _County = "'+administrative_area_level_1+'"
      
                          _PostalCode = "'+zip+'">
      
      <PARSED_STREET_ADDRESS _HouseNumber = ""
      
                             _DirectionPrefix = ""
      
                             _StreetName = ""
      
                             _StreetSuffix = ""
      
                             _ApartmentOrUnit = ""
      
                             _DirectionSuffix = "" />
      
      </_PROPERTY_CRITERIA>
      
      <_SEARCH_CRITERIA>
      
      <_SUBJECT_SEARCH _OwnerLastName = ""
      
                       _OwnerFirstName = ""
      
                       _AssessorsParcelIdentifier = ""
      
           _UnformattedParcelIdentifier = ""/>
      
      </_SEARCH_CRITERIA>
      
      </PROPERTY_INFORMATION_REQUEST>
      
      </REQUESTDATA>
      
      </REQUEST>
      
      </REQUEST_GROUP>'
      

      @user = RestClient.post 'https://staging.connect2data.com', xml , {:content_type => :xml}

      xml = @user.body

      doc = REXML::Document.new xml

      root = doc.root

     
     
     
           if  !root.elements["//PROPERTY_OWNER"].nil?
          
            if !root.elements["//PROPERTY_OWNER"].attributes["_OwnerName"].nil?
          
              _OwnerName = root.elements["//PROPERTY_OWNER"].attributes["_OwnerName"]
          
           
           else
          
              _OwnerName = ''
           end
          
             else
          
              _OwnerName = ''
          
          end
          
          mailing_address=''
          
          if  !root.elements["//PROPERTY_OWNER"].nil?
          
            if !root.elements["//PROPERTY_OWNER"].attributes["_MailingAddress"].nil?
          
              _MailingAddress = root.elements["//PROPERTY_OWNER"].attributes["_MailingAddress"]
              mailing_address=mailing_address+" "+_MailingAddress;
          
            else
          
              _MailingAddress = ''
          
            end
            
            if !root.elements["//PROPERTY_OWNER"].attributes["_MailingCityAndState"].nil?
          
              _MailingCityAndState = root.elements["//PROPERTY_OWNER"].attributes["_MailingCityAndState"]
              
                mailing_address=mailing_address+" "+_MailingCityAndState;
          
            else
          
              _MailingCityAndState = ''
          
            end
            
            if !root.elements["//PROPERTY_OWNER"].attributes["_MailingPostalCode"].nil?
          
              _MailingPostalCode = root.elements["//PROPERTY_OWNER"].attributes["_MailingPostalCode"]
              
              mailing_address=mailing_address+" "+_MailingPostalCode;
          
            else
          
              _MailingPostalCode = ''
          
            end
            
            if !root.elements["//PROPERTY_OWNER"].attributes["_MailingPostalCode4"].nil?
          
              _MailingPostalCode4 = root.elements["//PROPERTY_OWNER"].attributes["_MailingPostalCode4"]
              
              zip4 = _MailingPostalCode4;
              
               mailing_address=mailing_address+" "+_MailingPostalCode4;
          
            else
          
              _MailingPostalCode4 = ''
              
              zip4 = ''
          
            end
            
             else
          
             zip4 = ''
              
              mailing_address = ''
          end
          
              
          
          if  !root.elements["//PROPERTY_OWNER"].nil?

        if !root.elements["//PROPERTY_OWNER"].attributes["_OwnerOccupiedIndicator"].nil?

          if root.elements["//PROPERTY_OWNER"].attributes["_OwnerOccupiedIndicator"] == 'Y'

          _OwnerOccupiedIndicator = 1

          else

          _OwnerOccupiedIndicator = 0

          end

        else

          _OwnerOccupiedIndicator = ''

        end

      else

        _OwnerOccupiedIndicator = ''

      end

          if  !root.elements["//_ZONING"].nil?
          
            if !root.elements["//_ZONING"].attributes["_ClassificationIdentifier"].nil?
          
              _ClassificationIdentifier = root.elements["//_ZONING"].attributes["_ClassificationIdentifier"]
          
            else
          
              _ClassificationIdentifier = ''
          
            end
            
            else
          
              _ClassificationIdentifier = ''
          
          end
          
          if  !root.elements["//_CHARACTERISTICS"].nil?
          
            if !root.elements["//_CHARACTERISTICS"].attributes["_LandUseDescription"].nil?
          
              _LandUseDescription = root.elements["//_CHARACTERISTICS"].attributes["_LandUseDescription"]
          
            else
          
              _LandUseDescription = ''
          
            end
            
             else
          
              _LandUseDescription = ''
          
          
          end
          
     if  !root.elements["//_GENERAL_DESCRIPTION"].nil?

        if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_EffectiveYearBuiltDateIdentifier"].nil?

          _YearBuiltDateIdentifier = root.elements["//_GENERAL_DESCRIPTION"].attributes["_EffectiveYearBuiltDateIdentifier"]

        else

          if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"].nil?

            _YearBuiltDateIdentifier = root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"]

          else

            _YearBuiltDateIdentifier = ''

          end

        end

      else

        _YearBuiltDateIdentifier = ''

      end

           if  !root.elements["//_GENERAL_DESCRIPTION"].nil?
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_TotalUnitNumber"].nil?
          
              _TotalUnitNumber = root.elements["//_GENERAL_DESCRIPTION"].attributes["_TotalUnitNumber"]
          
            else
          
              _TotalUnitNumber = ''
          
            end
            
             else
          
              _TotalUnitNumber = ''
          
          end
          
          if  !root.elements["//_GENERAL_DESCRIPTION"].nil?
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatingTypeDescription"].nil?
          
              _HeatingTypeDescription = root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatingTypeDescription"]
          
            else
          
              _HeatingTypeDescription = ''
          
            end
            
            else
          
              _HeatingTypeDescription = ''
          
          
          end
          
          if  !root.elements["//_GENERAL_DESCRIPTION"].nil?
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatFuel"].nil?
          
              _HeatFuel = root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatFuel"]
          
            else
          
              _HeatFuel = ''
          
            end
            
             else
          
              _HeatFuel = ''
          
          end
          
          if  !root.elements["//_GENERAL_DESCRIPTION"].nil?
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_TotalStoriesNumber"].nil?
          
              _TotalStoriesNumber = root.elements["//_GENERAL_DESCRIPTION"].attributes["_TotalStoriesNumber"]
          
            else
          
              _TotalStoriesNumber = ''
          
            end
            
            else
          
              _TotalStoriesNumber = ''
          
          end
          
          if  !root.elements["//_EXTERIOR_DESCRIPTION"].nil?
          
            if !root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofSurfaceDescription"].nil?
          
              _RoofSurfaceDescription = root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofSurfaceDescription"]
          
            else
          
              _RoofSurfaceDescription = ''
          
            end
            
            else
          
              _RoofSurfaceDescription = ''
          
          end
          
          if  !root.elements["//_EXTERIOR_DESCRIPTION"].nil?
          
            if !root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofShape"].nil?
          
              _RoofShape = root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofShape"]
          
            else
          
              _RoofShape = ''
          
            end
            
            if !root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofFrame"].nil?
          
              _RoofFrame = root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofFrame"]
          
            else
          
              _RoofFrame = ''
          
            end
            
             else
          
              _RoofShape = ''
              
              _RoofFrame = ''
          
          end
          
          if  !root.elements["//_EXTERIOR_DESCRIPTION"].nil?
          
            if !root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofTypeDescription"].nil?
          
              _RoofTypeDescription = root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofTypeDescription"]
          
            else
          
              _RoofTypeDescription = ''
          
            end
            
            else
          
              _RoofTypeDescription = ''
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_TotalBedroomsCount"].nil?
          
              _TotalBedroomsCount = root.elements["//_ROOM_COUNT"].attributes["_TotalBedroomsCount"]
          
            else
          
              _TotalBedroomsCount = ''
          
            end
             
              else
          
              _TotalBedroomsCount = ''
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_TotalBathsCount"].nil?
          
              _TotalBathsCount = root.elements["//_ROOM_COUNT"].attributes["_TotalBathsCount"]
          
            else
          
              _TotalBathsCount = ''
          
            end
            
            else
          
              _TotalBathsCount = ''
          
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_TotalLivingAreaSquareFeetNumber"].nil?
          
              _TotalLivingAreaSquareFeetNumber = root.elements["//_ROOM_COUNT"].attributes["_TotalLivingAreaSquareFeetNumber"]
          
            else
          
              _TotalLivingAreaSquareFeetNumber = ''
          
            end
            
            
            else
          
              _TotalLivingAreaSquareFeetNumber = ''
          
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_GrossLivingAreaSquareFeetNumber"].nil?
          
              _GrossLivingAreaSquareFeetNumber = root.elements["//_ROOM_COUNT"].attributes["_GrossLivingAreaSquareFeetNumber"]
          
            else
          
              _GrossLivingAreaSquareFeetNumber = ''
          
            end
            
            else
          
              _GrossLivingAreaSquareFeetNumber = ''
          
          
          end
          
          if  !root.elements["//_POOL"].nil?
          
            if !root.elements["//_POOL"].attributes["_HasFeatureIndicator"].nil?
          
               if root.elements["//_POOL"].attributes["_HasFeatureIndicator"] == 'Y'

                _HasFeatureIndicator = 1
      
                else
      
                _HasFeatureIndicator = 0
      
                end
    
            else
          
              _HasFeatureIndicator = ''
          
            end
            
            else
          
              _HasFeatureIndicator = ''
          
          end
          
          if  !root.elements["//_SALES_HISTORY"].nil?
          
            if !root.elements["//_SALES_HISTORY"].attributes["_LastSalesPriceAmount"].nil?
          
              _LastSalesPriceAmount = root.elements["//_SALES_HISTORY"].attributes["_LastSalesPriceAmount"]
          
            else
          
              _LastSalesPriceAmount = ''
          
            end
            
            else
          
              _LastSalesPriceAmount = ''
          
          end
          
          if  !root.elements["//_SALES_HISTORY"].nil?
          
            if !root.elements["//_SALES_HISTORY"].attributes["_LastSalesDate"].nil?
          
              _LastSalesDate = root.elements["//_SALES_HISTORY"].attributes["_LastSalesDate"]
          
            else
          
              _LastSalesDate = ''
          
            end
            
            else
          
              _LastSalesDate = ''
          
          end
          
          if  !root.elements["//_SALES_HISTORY"].nil?
          
            if !root.elements["//_SALES_HISTORY"].attributes["_PricePerSquareFootAmount"].nil?
          
              _PricePerSquareFootAmount = root.elements["//_SALES_HISTORY"].attributes["_PricePerSquareFootAmount"]
          
            else
          
              _PricePerSquareFootAmount = ''
          
            end
            
             else
          
              _PricePerSquareFootAmount = ''
          
          end
          
          if  !root.elements["//_IMPROVEMENT_ANALYSIS"].nil?
          
            if !root.elements["//_IMPROVEMENT_ANALYSIS"].attributes["_ConditionsDescription"].nil?
          
              _ConditionsDescription = root.elements["//_IMPROVEMENT_ANALYSIS"].attributes["_ConditionsDescription"]
          
            else
          
              _ConditionsDescription = ''
          
            end
            
            else
          
              _ConditionsDescription = ''
          
          end
          

     
           if customer.first['credits']==0
         
              charge= Stripe::Charge.create(
              :customer => customer.first['cust_id'],
              :amount => ((customer.first['house_charge'].to_f * 100).to_i),
              :currency => "usd",
              :description => "Charge for test@example.com"
              )
                                
           else    
                  
              User.where(:id=>session[:current_user_id]).limit(1).update_all(:last_purchase_date => Time.now, :credits=>customer.first['credits']-1) 
                     
           end
           
              User.where(:id=>session[:current_user_id]).limit(1).update_all(:last_purchase_date => Time.now) 
           
              purchasecount=UserPurchase.where(:user_id => session[:current_user_id]).count
            
              if purchasecount.blank?
                 purchasecount='1'
              else
                 purchasecount=(purchasecount+1).to_s
              end
             
              transaction_id='IPQ-'+ Date.today.strftime("%d%m%y").to_s+'-'+session[:current_user_id].to_s+'-'+purchasecount
              
              if !(zip=='' || zip4=='' || zip.nil?)
                  @speedon = SpeedOnData.select("*").where("ZIP5 = ? and ZIP4 = ?",zip,zip4).limit(1)             
                         
                  if  @speedon.nil? || @speedon.blank?
                    
                      @userpurchase=UserPurchase.new(:transaction_id=>transaction_id, :user_id =>session[:current_user_id],:address=> params[:address],:prev_check =>@prev_chks, :zip =>zip,:city =>city, :zip4 =>zip4, :owner_name =>_OwnerName.titleize, :mailing_address =>mailing_address.titleize,
                      :owner_occupied_indicator=>_OwnerOccupiedIndicator,:last_sale_date=>_LastSalesDate , :last_sale_price =>_LastSalesPriceAmount,:last_sale_price_per_sqr_ft =>_PricePerSquareFootAmount,
                      :land_use_code=>_LandUseDescription.titleize, :zoning=>_ClassificationIdentifier, :no_of_residential_per_common_units=> _TotalUnitNumber,:gross_area=>_GrossLivingAreaSquareFeetNumber,:living_area=>_TotalLivingAreaSquareFeetNumber,
                      :no_of_bedrooms=>_TotalBedroomsCount,:no_of_bathrooms=>_TotalBathsCount, :year_built=>_YearBuiltDateIdentifier,:pool=>_HasFeatureIndicator,
                      :heat_type=>_HeatingTypeDescription.titleize, :heat_fuel=>_HeatFuel.titleize,:roof_type=>_RoofTypeDescription.titleize,:roof_shape=>_RoofShape.titleize,:roof_material=>_RoofSurfaceDescription.titleize,:roof_frame=>_RoofFrame.titleize,
                      :condition=> _ConditionsDescription.titleize,:no_of_stories=>_TotalStoriesNumber,:last_purchase_date=>Time.now,:status=>1);
                    
                  else              
                     
                      
                      @userpurchase=UserPurchase.new(:transaction_id=>transaction_id, :user_id =>session[:current_user_id],:address=> params[:address],:prev_check =>@prev_chks, :zip =>zip,:city =>city, :zip4 =>zip4, :owner_name =>_OwnerName.titleize, :mailing_address =>mailing_address.titleize,
                      :owner_occupied_indicator=>_OwnerOccupiedIndicator,:last_sale_date=>_LastSalesDate , :last_sale_price =>_LastSalesPriceAmount,:last_sale_price_per_sqr_ft =>_PricePerSquareFootAmount,
                      :land_use_code=>_LandUseDescription.titleize, :zoning=>_ClassificationIdentifier, :no_of_residential_per_common_units=> _TotalUnitNumber,:gross_area=>_GrossLivingAreaSquareFeetNumber,:living_area=>_TotalLivingAreaSquareFeetNumber,
                      :no_of_bedrooms=>_TotalBedroomsCount,:no_of_bathrooms=>_TotalBathsCount, :year_built=>_YearBuiltDateIdentifier,:pool=>_HasFeatureIndicator,
                      :heat_type=>_HeatingTypeDescription.titleize, :heat_fuel=>_HeatFuel.titleize,:roof_type=>_RoofTypeDescription.titleize,:roof_shape=>_RoofShape.titleize,:roof_material=>_RoofSurfaceDescription.titleize,:roof_frame=>_RoofFrame.titleize,
                      :condition=> _ConditionsDescription.titleize,:no_of_stories=>_TotalStoriesNumber,:last_purchase_date=>Time.now,:status=>1, :riskiq3 => @speedon.first['riskiq3'], :delineate =>@speedon.first['delineate'],
                      :AIQ_Green => @speedon.first['AIQ_Green'], :IncomeIQ_Dol =>@speedon.first['IncomeIQ_Dol'], :DebtRatio =>@speedon.first['DebtRatio'], :Premoves =>@speedon.first['Premoves'], :Age_z4 =>@speedon.first['Age_z4'], 
                      :ResidenceTime_z4=>@speedon.first['ResidenceTime_z4'], :MortgageAmount_z4 =>@speedon.first['MortgageAmount_z4'], :PersonsatResidence_z4 =>@speedon.first['PersonsatResidence_z4'],
                      :HomeOwner_pct_z4 =>@speedon.first['HomeOwner_pct_z4'], :LoantoValue_z4=>@speedon.first['LoantoValue_z4'],:IncomeIQ_plus_z4=>@speedon.first['IncomeIQ_plus_z4'], :AIQ_Green_plus_z4=>@speedon.first['AIQ_Green_plus_z4'],
                      :Homeequity_pc_z4 =>@speedon.first['Homeequity_pc_z4'], :NumberofadultsinZip4 => @speedon.first['NumberofadultsinZip4'],:State2 =>@speedon.first['State2']);
                 
                  end
             
               else
                   
                      @userpurchase=UserPurchase.new(:transaction_id=>transaction_id, :user_id =>session[:current_user_id],:address=> params[:address],:prev_check =>@prev_chks, :zip =>zip,:city =>city, :zip4 =>zip4, :owner_name =>_OwnerName.titleize, :mailing_address =>mailing_address.titleize,
                      :owner_occupied_indicator=>_OwnerOccupiedIndicator,:last_sale_date=>_LastSalesDate , :last_sale_price =>_LastSalesPriceAmount,:last_sale_price_per_sqr_ft =>_PricePerSquareFootAmount,
                      :land_use_code=>_LandUseDescription.titleize, :zoning=>_ClassificationIdentifier, :no_of_residential_per_common_units=> _TotalUnitNumber,:gross_area=>_GrossLivingAreaSquareFeetNumber,:living_area=>_TotalLivingAreaSquareFeetNumber,
                      :no_of_bedrooms=>_TotalBedroomsCount,:no_of_bathrooms=>_TotalBathsCount, :year_built=>_YearBuiltDateIdentifier,:pool=>_HasFeatureIndicator,
                      :heat_type=>_HeatingTypeDescription.titleize, :heat_fuel=>_HeatFuel.titleize,:roof_type=>_RoofTypeDescription.titleize,:roof_shape=>_RoofShape.titleize,:roof_material=>_RoofSurfaceDescription.titleize,:roof_frame=>_RoofFrame.titleize,
                      :condition=> _ConditionsDescription.titleize,:no_of_stories=>_TotalStoriesNumber,:last_purchase_date=>Time.now,:status=>1);
                    
               end 
         
            if @userpurchase.save
                      UserPurchase.where("address ='"+params[:address]+"'").update_all(:prev_check=>@prev_chks) 
                      session[:new_marker]=session[:current_user_id]
                      @userpurchase = UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)
                      @userpurchase = @userpurchase.to_a.map(&:serializable_hash)
                     
               
                                  
                if @userpurchase.first['last_sale_date'].blank?
                    owned =''               
                else         
                    owned=Time.diff(Time.now, Time.parse(@userpurchase.first['last_sale_date']),'%y, %M')[:diff]
                end     
                
                @alladdress= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
                @alladdress = @alladdress.to_a.map(&:address)
       
                @address1= UserPurchase.select("transaction_id").where("user_id = ? and status = 1",session[:current_user_id])
                @alltransaction = @address1.to_a.map(&:transaction_id)
               
               if @userpurchase.first['year_built'].blank?
                  render :json=>{:alladdress => @alladdress, :alltransaction =>@alltransaction, :zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility, :results => @userpurchase, :age =>'', :owned=> owned}
                    
               else
                  render :json=>{:alladdress => @alladdress, :alltransaction =>@alltransaction,:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility, :results => @userpurchase, :age=> (Time.now.year - @userpurchase.first['year_built']),:owned=> owned}
               end   
               
            else
               render :json=> {:results => 'not datasaved'}   
                
            end
            
       else
            
             
            addressexist = UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)
            addressexist = addressexist.to_a.map(&:serializable_hash)
            
            @alladdress= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
            @alladdress = @alladdress.to_a.map(&:address)
       
            @address1= UserPurchase.select("transaction_id").where("user_id = ? and status = 1",session[:current_user_id])
            @alltransaction = @address1.to_a.map(&:transaction_id)       
       
            if addressexist.first['last_sale_date'].blank?
                owned =''               
            else         
                owned=Time.diff(Time.now, Time.parse(addressexist.first['last_sale_date']),'%y, %M')[:diff]
            end     
            
                   
            if addressexist.first['year_built'].blank?
                   render :json=>{:alladdress => @alladdress, :alltransaction =>@alltransaction,:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility, :results => addressexist, :age =>'',:owned=> owned}
            else
                   render :json=>{:alladdress => @alladdress, :alltransaction =>@alltransaction,:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility,:results => addressexist, :age=> (Time.now.year - addressexist.first['year_built']),:owned=> owned}
            end
       end  
             
   end   
  
    
 
   def addresspresentcheck
    
    addressexist= UserPurchase.select("transaction_id").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1) 
     
    
      if addressexist.blank?
           render :json => {:data => 0 }
      else         
           render :json => {:data => 1 }
       
      end     
  end
  
  
  
  
  
  
  def viewmap
    
    session[:new_marker]=nil    
    if !session[:current_user_id]
       redirect_to :action => "index"
    else    
         @address= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
         @address = @address.to_a.map(&:address)
       
         @address1= UserPurchase.select("transaction_id").where("user_id = ? and status = 1",session[:current_user_id])
         @transaction = @address1.to_a.map(&:transaction_id)
    end
   
  end
  
    def viewmap_copy
    
    session[:new_marker]=nil    
    if !session[:current_user_id]
       redirect_to :action => "index"
    else    
         @address= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
         @address = @address.to_a.map(&:address)
       
         @address1= UserPurchase.select("transaction_id").where("user_id = ? and status = 1",session[:current_user_id])
         @transaction = @address1.to_a.map(&:transaction_id)
    end
   
  end
    



  private

  def admin_params
    params.permit(:admin_name, :admin_email_id, :admin_password, :admin_token);
  end
  
  def user_params
    params.permit(:first_name, :last_name, :title, :company_name, :company_address, :zip, :city, :state, :mobile_phone,:office_phone, :company_email_id,  :verification_token, :last_activity, :registration_date);
  end

  def contact_params
    params.permit(:full_name, :email, :mobile_phone, :about, :message);
  end
end
