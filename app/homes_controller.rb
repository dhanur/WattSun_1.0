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
    
     if session[:admin_user_id]
                   @allusers=User.all
     else
         redirect_to :action => "adminlogin"
    end   
  
  end
  
   
  def adminuserprofile
    
     if session[:admin_user_id]
                   @allusers=User.all
     else
         redirect_to :action => "adminlogin"
    end   
    
  end
  
  
  def singleuserview
     
    if session[:admin_user_id]    
       session[:admin_userview_id]=params[:user_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
  
  end
  
  
  def adminprofileview
    if session[:admin_user_id] && session[:admin_userview_id]
      @user=User.select("*").where("id = ?",session[:admin_userview_id]).limit(1)
    else
      redirect_to :action => "adminlogin"
    end

  end
  
  
  
 def adminuserpayment
    
    
     if session[:admin_user_id]
                   @allusers=User.all
     else
         redirect_to :action => "adminlogin"
    end 
    
  end
  
  
   def singleusercredits
     
    if session[:admin_user_id]    
       session[:admin_userpayment_id]=params[:user_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
  
  end
  
 
  def adminusernumber    
    
    if session[:admin_user_id] && session[:admin_userpayment_id]
      @user=User.select("*").where("id = ?",session[:admin_userpayment_id]).limit(1)
    else
      redirect_to :action => "adminlogin"
    end    
    
  end
  
 
  def updateplan
    
              customer = User.select('subscription_id,cust_id').where("id=?", session[:admin_userpayment_id])
          
              customer2= Stripe::Customer.retrieve(customer.first['cust_id'])
          
                     
              plan = Stripe::Plan.retrieve(customer.first['cust_id'])
          
              plan.delete
          
              Stripe::Plan.create(          
              :amount => params[:ma],          
              :interval => 'month',          
              :name => 'monthly plan',          
              :currency => 'usd',          
              :id => customer.first['cust_id'],          
              )
          
              subscription = customer2.subscriptions.retrieve(customer.first['subscription_id'])         
              subscription.plan = customer.first['cust_id']          
              subscription.prorate = 'true'          
              subscription.save       
              
              User.where(:id=>session[:admin_userpayment_id]).limit(1).update_all(:monthly_charge=>params[:ma])
              
              render :json => {:results =>"done"}
    
   end

  
  def updatechrg
        
      User.where(:id=>session[:admin_userpayment_id]).limit(1).update_all(:house_charge=>params[:hc])
      render :json => {:results =>"done"}
    
    
  end

   
  def updatecredits
      User.where(:id=>session[:admin_userpayment_id]).limit(1).update_all(:credits=>params[:cur_credits])
      render :json => {:results =>"done"}
  end
 
 
  def adminuserpurchase
    
     if session[:admin_user_id]
                   @allusers=User.all
     else
         redirect_to :action => "adminlogin"
    end   
    
  end
  
  
  def singleuserviewbyadmin
     
    if session[:admin_user_id]    
       session[:admin_user_transaction_view_id]=params[:user_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
  
  end
  
  
  def adminuserpurchaselist   
    
    if session[:admin_user_transaction_view_id]
      
      @userbyadmin=User.select("*").where("id = ?",session[:admin_user_transaction_view_id]).limit(1)
      @transctions=UserPurchase.select("address,transaction_id,last_purchase_date").where("user_id = ? and status = 1",session[:admin_user_transaction_view_id])
      
    else
      redirect_to :action => "adminlogin"
    end
    
    
  end
  
  
  def viewtransctionbyadmin
  
    if session[:admin_user_id] && session[:admin_user_transaction_view_id]    
       session[:current_transction_view_of_user_byadmin_id]=params[:tranc_id]
       render :json => {:status =>"done" }
    else
       redirect_to :action => "adminlogin"   
    end
    
  end
  
 
 def adminpurchaseview

    if session[:current_transction_view_of_user_byadmin_id] && session[:admin_user_id]      
      
        @transction=UserPurchase.select("*").where("transaction_id = ? and status = 1",session[:current_transction_view_of_user_byadmin_id])  
        @userbyadmin=User.select("*").where("id = ?",session[:admin_user_transaction_view_id]).limit(1)  
        
        if @userbyadmin.blank?  
              @zee=''
              @ztp=''
              @zpb=''
              @zib=''
        else            
              @zee=ZipEverythingElse.select("*").where("zip = ?",@userbyadmin.zip).limit(1)
                     
              @ztp=ZipTopInstaller.select("*").where("zip = ?",@userbyadmin.zip).order('no_of_solar_homes desc').limit(5)
                      
              @zpb=ZipPanelBrand.select("*").where("zip = ?",@userbyadmin.zip).order('no_of_solar_homes desc').limit(5)
                     
              @zib=ZipInverterBrand.select("*").where("zip = ?",@userbyadmin.zip).order('no_of_solar_homes desc').limit(5)
                      
        end        
        
     else 
        redirect_to :action => "adminlogin"
     end  
    

  end
 
 
  # def adminmain
     # @allusers=User.all
  # end


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
  
  def checkpassword
    @password = User.select("password").where("company_email_id=? and verification_token = ?",params[:id],params[:vt]).limit(1)
    
    if @password.blank?
      render :json => {:results =>0}
    else
      render :json => {:results =>1}
    end
    
  end
  
  

  def resetpassword

    @user=User.select("id,company_email_id,verification_token").where("company_email_id=? and verification_token = ?",params[:emailid],params[:vt]).limit(1)
    if @user.blank?
      render :json =>{:error =>params[:emailid]}
    else
      User.where(:id=>@user.first['id']).limit(1).update_all(:password=>params[:password])
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
      @user.update_all(:last_activity => Time.now)

      if @user
        Emailer.passwordchanged(@user).deliver
        redirect_to :action => "resetpasswordmessage"
      else
        render :json=>"Not updated login date"
      end

    end

  end
  
  
   def passwordreset
    
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
  
  
#   
   # def useradminpayment
# 
    # if session[:admin_user_id]
      # @user=User.select("*").where("id = ?",session[:current_user_id]).limit(1)
    # else
      # redirect_to :action => "adminlogin"
    # end
# 
  # end
  

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
        
        if @user.blank?  
              @zee=''
              @ztp=''
              @zpb=''
              @zib=''
        else            
              @zee=ZipEverythingElse.select("*").where("zip = ?",@user.zip).limit(1)
                     
              @ztp=ZipTopInstaller.select("*").where("zip = ?",@user.zip).order('no_of_solar_homes desc').limit(5)
                      
              @zpb=ZipPanelBrand.select("*").where("zip = ?",@user.zip).order('no_of_solar_homes desc').limit(5)
                     
              @zib=ZipInverterBrand.select("*").where("zip = ?",@user.zip).order('no_of_solar_homes desc').limit(5)
                      
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
      if params[:mphone]

        User.where(:id=>@user.first['id']).update_all(:mobile_phone => params[:mphone])
        render :json => {:status =>"done" }

      elsif params[:ophone]

        User.where(:id=>@user.first['id']).update_all(:office_phone => params[:ophone])
        render :json => {:status =>"done" }

      elsif (@user.first['password']==params[:cur_psd])

        User.where(:id=>@user.first['id']).update_all(:password => params[:new_psd])
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
    @user=User.select("id").where("company_email_id = ? and password = ?",params[:emailid],params[:password]).limit(1)
    if @user.blank?
      session[:admin_errormessage]= params[:emailid]
      redirect_to :action => "adminlogin"
    else
      session[:admin_user_id]=@user.first['id'];
      redirect_to :action => "adminuserstatus"
    end
  end

  
  def create
    
    @user=User.select("id").where("company_email_id = ?",params[:company_email_id]).limit(1)
    
    if @user.blank?

    session[:errormessagesignup]=nil     
    @user = User.new(user_params)
    @user.registration_date = Time.now
    @user.verification_token=Digest::MD5.hexdigest(params[:company_email_id])
    
        if @user.save
          Emailer.new_record_notification(params[:company_email_id]).deliver
    
        else
          render :json =>"something wrong"
        end
     
    else
      session[:errormessagesignup]=params[:company_email_id]                        
      redirect_to :action => "signup"
     
     
      
    end  

  end

  
  def admin
    @users=User.all
  end

  def datafetch

    if params[:radio]=='zip'

      @zee=ZipEverythingElse.select("*").where("zip = ?",params[:zip]).limit(1)
      @zee = @zee.to_a.map(&:serializable_hash)

      @ztp=ZipTopInstaller.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(5)
      @ztp = @ztp.to_a.map(&:serializable_hash)

      @zpb=ZipPanelBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(5)
      @zpb = @zpb.to_a.map(&:serializable_hash)

      @zib=ZipInverterBrand.select("*").where("zip = ?",params[:zip]).order('no_of_solar_homes desc').limit(5)
      @zib = @zib.to_a.map(&:serializable_hash)

      @utility= Utilitytable.select("utility").where("zip = ?",params[:zip])
      @utility = @utility.to_a.map(&:serializable_hash)

      render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility}

    elsif params[:radio]=='city'

      @zee=CityEverythingElse.select("*").where("city = ?",params[:citycode]).limit(1)
      @zee = @zee.to_a.map(&:serializable_hash)

      @ztp=CityTopInstaller.select("*").where("city = ?",params[:citycode]).order('no_of_solar_homes desc').limit(5)
      @ztp = @ztp.to_a.map(&:serializable_hash)

      @zpb=CityPanelBrand.select("*").where("city = ?",params[:citycode]).order('no_of_solar_homes desc').limit(5)
      @zpb = @zpb.to_a.map(&:serializable_hash)

      @zib=CityInverterBrand.select("*").where("city = ?",params[:citycode]).order('no_of_solar_homes desc').limit(5)
      @zib = @zib.to_a.map(&:serializable_hash)

      @utility= Utilitytable.select("utility").where("zip = ?",params[:zip])
      @utility = @utility.to_a.map(&:serializable_hash)

      render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility}

    end
  end

  def login

    @user=User.select('id,payment_status').where("company_email_id = ? and password = ?",params[:emailid],params[:password]).limit(1)
    if @user.blank?

      session[:errormessage]= params[:emailid]
      redirect_to :action => "userlogin"

    else
      session[:errormessage]=nil
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

  def logout
      session[:errormessage]=nil
      session[:admin_errormessage]=nil
      session[:current_user_id] = nil
      session[:admin_user_id] = nil
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

  end

  def activation
    @user=User.select("id,company_email_id,verification_token").where("company_email_id=? and verification_token = ?",params[:email],params[:vt]).limit(1)
    if @user.blank?
      render :json =>{:error =>"Not Exists"}
    else
      User.where(:id=>@user.first['id']).limit(1).update_all(:password=>params[:password])
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
    
        customer_id = customer.id
    
        plan=   Stripe::Plan.create(
    
        :amount => "9900",
    
        :interval => 'month',
    
        :name => 'monthly plan',
    
        :currency => 'usd',
    
        :id => customer_id,
    
        )
    
        subscription= customer.subscriptions.create(:plan => plan)
    
        # render :json => {"data"=> amount}
    
        #  # Amount in cents
    
        User.where(:id=>session[:cust_user_id]).limit(1).update_all(:cust_id=>customer_id,:payment_status=>1, :monthly_charge=>99,:house_charge=>3,:subscription_id=>subscription.id,:credits=>0,:card_exp_year=> customer.cards.data[0]['exp_year'],:card_exp_month=>customer.cards.data[0]['exp_month'],:current_period_end=>subscription.current_period_end,:card_no=>customer.cards.data[0]['last4'])
    
        redirect_to :action => "userlogin"
    
    
    end
    
    


   def checkpurchase
    
     customer = User.select('credits,cust_id,house_charge').where("id=?", session[:current_user_id])
     
     addressexist= UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1) 
     
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
      
      <_PROPERTY_CRITERIA _StreetAddress = "'+street+route+'"
      
                          _StreetAddress2 = ""
      
                          _City = "'+city+'"
      
                          _State = ""
      
                          _County = "'+country+'"
      
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
          
          if  !root.elements["//PROPERTY_OWNER"].nil?
          
            if !root.elements["//PROPERTY_OWNER"].attributes["_MailingAddress"].nil?
          
              _MailingAddress = root.elements["//PROPERTY_OWNER"].attributes["_MailingAddress"]
          
            else
          
              _MailingAddress = ''
          
            end
            
             else
          
              _MailingAddress = ''
          
          end
          
          if  !root.elements["//PROPERTY_OWNER"].nil?
          
            if !root.elements["//PROPERTY_OWNER"].attributes["_OwnerOccupiedIndicator"].nil?
          
              _OwnerOccupiedIndicator = root.elements["//PROPERTY_OWNER"].attributes["_OwnerOccupiedIndicator"]
          
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
          
              _ClassificationIdentifier = ' '
          
            end
            
            else
          
              _ClassificationIdentifier = ' '
          
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
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"].nil?
          
              _YearBuiltDateIdentifier = root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"]
          
            else
          
              _YearBuiltDateIdentifier = ' '
          
            end
            
             else
          
              _YearBuiltDateIdentifier = ' '
          
          end
          
          if  !root.elements["//_GENERAL_DESCRIPTION"].nil?
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatingTypeDescription"].nil?
          
              _HeatingTypeDescription = root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatingTypeDescription"]
          
            else
          
              _HeatingTypeDescription = ' '
          
            end
            
            else
          
              _HeatingTypeDescription = ' '
          
          
          end
          
          if  !root.elements["//_GENERAL_DESCRIPTION"].nil?
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatFuel"].nil?
          
              _HeatFuel = root.elements["//_GENERAL_DESCRIPTION"].attributes["_HeatFuel"]
          
            else
          
              _HeatFuel = ' '
          
            end
            
             else
          
              _HeatFuel = ' '
          
          end
          
          if  !root.elements["//_GENERAL_DESCRIPTION"].nil?
          
            if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_TotalStoriesNumber"].nil?
          
              _TotalStoriesNumber = root.elements["//_GENERAL_DESCRIPTION"].attributes["_TotalStoriesNumber"]
          
            else
          
              _TotalStoriesNumber = ' '
          
            end
            
            else
          
              _TotalStoriesNumber = ' '
          
          end
          
          if  !root.elements["//_EXTERIOR_DESCRIPTION"].nil?
          
            if !root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofSurfaceDescription"].nil?
          
              _RoofSurfaceDescription = root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofSurfaceDescription"]
          
            else
          
              _RoofSurfaceDescription = ' '
          
            end
            
            else
          
              _RoofSurfaceDescription = ' '
          
          end
          
          if  !root.elements["//_EXTERIOR_DESCRIPTION"].nil?
          
            if !root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofShape"].nil?
          
              _RoofShape = root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofShape"]
          
            else
          
              _RoofShape = ' '
          
            end
            
             else
          
              _RoofShape = ' '
          
          end
          
          if  !root.elements["//_EXTERIOR_DESCRIPTION"].nil?
          
            if !root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofTypeDescription"].nil?
          
              _RoofTypeDescription = root.elements["//_EXTERIOR_DESCRIPTION"].attributes["_RoofTypeDescription"]
          
            else
          
              _RoofTypeDescription = ' '
          
            end
            
            else
          
              _RoofTypeDescription = ' '
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_TotalBedroomsCount"].nil?
          
              _TotalBedroomsCount = root.elements["//_ROOM_COUNT"].attributes["_TotalBedroomsCount"]
          
            else
          
              _TotalBedroomsCount = ' '
          
            end
             
              else
          
              _TotalBedroomsCount = ' '
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_TotalFullBathsCount"].nil?
          
              _TotalFullBathsCount = root.elements["//_ROOM_COUNT"].attributes["_TotalFullBathsCount"]
          
            else
          
              _TotalFullBathsCount = ' '
          
            end
            
            else
          
              _TotalFullBathsCount = ' '
          
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_TotalLivingAreaSquareFeetNumber"].nil?
          
              _TotalLivingAreaSquareFeetNumber = root.elements["//_ROOM_COUNT"].attributes["_TotalLivingAreaSquareFeetNumber"]
          
            else
          
              _TotalLivingAreaSquareFeetNumber = ' '
          
            end
            
            
            else
          
              _TotalLivingAreaSquareFeetNumber = ' '
          
          end
          
          if  !root.elements["//_ROOM_COUNT"].nil?
          
            if !root.elements["//_ROOM_COUNT"].attributes["_GrossLivingAreaSquareFeetNumber"].nil?
          
              _GrossLivingAreaSquareFeetNumber = root.elements["//_ROOM_COUNT"].attributes["_GrossLivingAreaSquareFeetNumber"]
          
            else
          
              _GrossLivingAreaSquareFeetNumber = ' '
          
            end
            
            else
          
              _GrossLivingAreaSquareFeetNumber = ' '
          
          
          end
          
          if  !root.elements["//_POOL"].nil?
          
            if !root.elements["//_POOL"].attributes["_HasFeatureIndicator"].nil?
          
              _HasFeatureIndicator = root.elements["//_POOL"].attributes["_HasFeatureIndicator"]
          
            else
          
              _HasFeatureIndicator = ' '
          
            end
            
            else
          
              _HasFeatureIndicator = ' '
          
          end
          
          if  !root.elements["//_SALES_HISTORY"].nil?
          
            if !root.elements["//_SALES_HISTORY"].attributes["_PriorSalePriceAmount"].nil?
          
              _PriorSalePriceAmount = root.elements["//_SALES_HISTORY"].attributes["_PriorSalePriceAmount"]
          
            else
          
              _PriorSalePriceAmount = ' '
          
            end
            
            else
          
              _PriorSalePriceAmount = ' '
          
          end
          
          if  !root.elements["//_SALES_HISTORY"].nil?
          
            if !root.elements["//_SALES_HISTORY"].attributes["_PriorSaleDate"].nil?
          
              _PriorSaleDate = root.elements["//_SALES_HISTORY"].attributes["_PriorSaleDate"]
          
            else
          
              _PriorSaleDate = ' '
          
            end
            
            else
          
              _PriorSaleDate = ' '
          
          end
          
          if  !root.elements["//_SALES_HISTORY"].nil?
          
            if !root.elements["//_SALES_HISTORY"].attributes["_PricePerSquareFootAmount"].nil?
          
              _PricePerSquareFootAmount = root.elements["//_SALES_HISTORY"].attributes["_PricePerSquareFootAmount"]
          
            else
          
              _PricePerSquareFootAmount = ' '
          
            end
            
             else
          
              _PricePerSquareFootAmount = ' '
          
          end
          
          if  !root.elements["//_IMPROVEMENT_ANALYSIS"].nil?
          
            if !root.elements["//_IMPROVEMENT_ANALYSIS"].attributes["_ConditionsDescription"].nil?
          
              _ConditionsDescription = root.elements["//_IMPROVEMENT_ANALYSIS"].attributes["_ConditionsDescription"]
          
            else
          
              _ConditionsDescription = ' '
          
            end
            
            else
          
              _ConditionsDescription = ' '
          
          end
          

     
           if customer.first['credits']==0
         
              charge= Stripe::Charge.create(
              :customer => customer.first['cust_id'],
              :amount => (customer.first['house_charge'].to_i)*100,
              :currency => "usd",
              :description => "Charge for test@example.com"
              )
                                
           else    
                  
             User.where(:id=>session[:current_user_id]).limit(1).update_all(:credits=>customer.first['credits']-1) 
                     
           end
           
             @userpurchase=UserPurchase.new(:user_id =>session[:current_user_id],:address=> params[:address],:owner_name =>_OwnerName, :mailing_address =>_MailingAddress,
              :owner_occupied_indicator=>_OwnerOccupiedIndicator,:last_sale_date=>_PriorSaleDate , :last_sale_price =>_PriorSalePriceAmount,:last_sale_price_per_sqr_ft =>_PricePerSquareFootAmount,
              :land_use_code=>_LandUseDescription, :zoning=>_ClassificationIdentifier, :no_of_residential_per_common_units=> '0',:gross_area=>_GrossLivingAreaSquareFeetNumber,:living_area=>_TotalLivingAreaSquareFeetNumber,
              :no_of_bedrooms=>_TotalBedroomsCount,:no_of_bathrooms=>_TotalFullBathsCount, :year_built=>_YearBuiltDateIdentifier,:pool=>_HasFeatureIndicator,
              :heat_type=>_HeatingTypeDescription, :heat_fuel=>_HeatFuel,:roof_type=>_RoofTypeDescription,:roof_shape=>_RoofShape,:roof_material=>_RoofSurfaceDescription,
              :condition=> _ConditionsDescription,:no_of_stories=>_TotalStoriesNumber,:last_purchase_date=>Date.today,:status=>1);
             
            if @userpurchase.save
               
                session[:new_marker]=session[:current_user_id]
                @userpurchase = UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)
                @userpurchase = @userpurchase.to_a.map(&:serializable_hash)
               
               if @userpurchase.first['year_built'].blank?
                  render :json => {:results => @userpurchase, :age =>'' }
               else
                  render :json => {:results => @userpurchase, :age =>(Time.now.year - @userpurchase.first['year_built']) }
               end   
               
            else
               render :json=> {:results => 'not datasaved'}   
                
            end
            
       else
            addressexist = addressexist.to_a.map(&:serializable_hash)
          
            if addressexist.first['year_built'].blank?
                  render :json => {:results => addressexist, :age =>'' }
            else
                  render :json =>{:results => addressexist,:age =>(Time.now.year - addressexist.first['year_built'])}
            end
       end  
       
        @address= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
       @address = @address.to_a.map(&:address)
             
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
       redirect_to :action => "userlogin"
    else    
       @address= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
       @address = @address.to_a.map(&:address)
    end
   
  end
  
  


  private

  def user_params
    params.permit(:first_name, :last_name, :title, :company_name, :company_address, :zip, :city, :state, :mobile_phone,:office_phone, :company_email_id,  :verification_token, :last_activity, :registration_date);
  end

  def contact_params
    params.permit(:full_name, :email, :mobile_phone, :about, :message);
  end
end
