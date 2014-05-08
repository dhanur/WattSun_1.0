class HomesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  require 'digest/md5'
  require 'stripe'
  require "rexml/document"
  require 'rest_client'
  require 'time_diff'
  require 'local_time'
  require 'csv'

  def index

  end

  def adminlogin
        
    if session[:admin_user_id]      
          redirect_to :action => "adminuserstatus"
    elsif session[:super_admin_user_id]
          redirect_to :action => "superadmin"
    end

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
      @transctions=UserPurchase.select("address,transaction_id,purchase_date,user_zone").where("user_id = ? and status = 1",session[:admin_user_transaction_view_id])

    else
      redirect_to :action => "adminlogin"
    end

  end

  def userpurchasecsv
   
   if session[:current_user_id]
     
      @userpurchasestranc=User.joins(:user_purchases).select("users.id, users.first_name, users.last_name, users.company_name,users.company_email_id, users.credits, users.monthly_charge, user_purchases.*").where("users.id = ? and user_purchases.status = 1",session[:current_user_id])

      @userpurchasestranc_csv = CSV.generate do |csv|
               csv << ["Transaction Id", "Street", "City", "State", "Zip", "Name", "Company Name", "IPQ Checks", "Date", "Time", "IPQ Valid", "IPQ Active Price", "Active Monthly Access Fee", "Owner Name", "Mailing Address", "Owner occupied",
                        "Owned For", "Last Sale Price", "Land Use Code", "Zoning", "No. Of Residential/common units", "Gross Area", "No. of bedrooms", "No. of bathrooms",
                        "Age Of Home","Has Pool?", "Heat type", "Heat fuel", "Roof type", "Roof Shape", "Roof material","Roof frame", "No. of Stories", "Estimated Credit Score", "Segmentation",
                        "How Green?","Estimated Household Income", "Estimated Debt to Income", "Premoves","Approximate Head of Household Age", "Approximate no. of people living here", "% homes owned (vs. rented)",
                        "Estimated Home Equity", "Utility Provider", "Solar Homes for ZIP", "3rd Party for ZIP", "Avg. System for ZIP", "Installer1 for ZIP","Installer2 for ZIP","Installer3 for ZIP",
                        "Installer4 for ZIP","Installer5 for ZIP", "Panel Brand1 for ZIP", "Panel Brand2 for ZIP", "Panel Brand3 for ZIP","Inverter Brand1 for ZIP", "Inverter Brand2 for ZIP", "Inverter Brand3 for ZIP",
                        "Solar Homes for CITY", "3rd Party for CITY", "Avg. System for CITY", "Installer1 for CITY","Installer2 for CITY","Installer3 for CITY", "Installer4 for CITY","Installer5 for CITY", "Panel Brand1 for CITY",
                        "Panel Brand2 for CITY", "Panel Brand3 for CITY","Inverter Brand1 for CITY", "Inverter Brand2 for CITY", "Inverter Brand3 for CITY"]

                        
               @userpurchasestranc.each do |tranc|
                        user_zone_date=tranc.purchase_date
                        if (tranc.user_zone)[0]=='+'

                          user_zone_date=user_zone_date+(tranc.user_zone)[1,3].to_i.hours
                          user_zone_date=user_zone_date+(tranc.user_zone)[4,6].to_i.minutes

                        elsif  (tranc.user_zone)[0]=='-'

                          user_zone_date=user_zone_date-(tranc.user_zone)[1,3].to_i.hours
                          user_zone_date=user_zone_date-(tranc.user_zone)[4,6].to_i.minutes

                        end
                       
                        arr= tranc.company_email_id.split('@')
                       
                        if arr[1]=='prospectzen.com' 
                           prev_chk=tranc.prev_check                        
                        else                          
                           prev_chk=tranc.prev_check-1
                        end
                        
                        
                        if tranc.status=='1'
                          ipq_valid="Yes"
                        else
                          ipq_valid="No"
                        end
                        
                        if tranc.owner_occupied_indicator=='1'
                          ocp="Yes"
                        elsif tranc.owner_occupied_indicator=='0'
                          ocp="No"
                        else
                          ocp=""
                        end
                        
                        if tranc.pool=='1'
                          pool="Yes"
                        elsif tranc.pool=='0'
                          pool="No"
                        else
                          pool=""
                        end
                        
                        if tranc.credits=='0'
                           ipq_active_price=1
                        else
                           ipq_active_price=0
                        end
                        
                                   
                        if !(tranc.IncomeIQ_Dol.nil? || tranc.IncomeIQ_Dol.blank?)
                           eestimated_income='$'+((tranc.IncomeIQ_Dol).to_i * 1000).to_s
                        else
                           eestimated_income=''
                        end
              
                        if !(tranc.last_sale_date.nil? || tranc.last_sale_date.blank?)
                           owned=Time.diff(Time.now, Time.parse(tranc.last_sale_date),'%y, %M')[:diff]
                        else
                           owned=''
                        end
                        
                        if !(tranc.monthly_charge.nil? || tranc.monthly_charge.blank?)
                           mothly_access_fee='$'+(tranc.monthly_charge).to_s
                        else
                           mothly_access_fee=''
                        end
                       
                        if !(tranc.last_sale_price.nil? || tranc.last_sale_price.blank?)
                           last_sale_price='$'+(tranc.last_sale_price).to_s
                        else
                           last_sale_price=''
                        end
                       
                        if !(tranc.gross_area.nil? || tranc.gross_area.blank?)
                           gross_area=(tranc.gross_area).to_s+' sqft'
                        else
                           gross_area=''
                        end
  
                        if tranc.year_built.nil? || tranc.year_built.blank?
                          age =''
                        else
                          age =(Time.now.year - tranc.year_built).to_s + ' years'
                        end

                    
                        if !(tranc.riskiq3.nil? || tranc.riskiq3.blank?)
                     
                           if (tranc.riskiq3<= '36')                            
                              est_credit_score='<650';
                   
                           elsif(tranc.riskiq3<= '50')                   
                             est_credit_score='650-700';
                 
                           elsif(tranc.riskiq3<= '82')                    
                             est_credit_score='700-750';
                                     
                           else                      
                               est_credit_score='800+';                   
                  
                           end
                        else
                           est_credit_score='';
                        end
                       
                                           
                        if !(tranc.delineate.nil? || tranc.delineate.blank?)
                     
                           if (tranc.delineate >= '101' && tranc.delineate <= '105')                            
                              segmentation='Assimilating New Americans';
                   
                           elsif (tranc.delineate >= '201' && tranc.delineate <= '207')                            
                              segmentation='Mid-Market America';
 
                           elsif (tranc.delineate >= '301' && tranc.delineate <= '307')                            
                              segmentation='High Society';
                   
                           elsif (tranc.delineate >= '401' && tranc.delineate <= '406')                            
                              segmentation='Blue Collar America';
 
                           elsif (tranc.delineate >= '501' && tranc.delineate <= '506')                            
                              segmentation='The High and Mighty';

                           elsif (tranc.delineate >= '601' && tranc.delineate <= '604')                            
                              segmentation='In Town Homeowners';
                   
                           elsif (tranc.delineate >= '701' && tranc.delineate <= '704')                            
                              segmentation='Struggling to Get Ahead';
 
                           elsif (tranc.delineate >= '801' && tranc.delineate <= '803')                            
                              segmentation='New Americans';
                                     
                           elsif (tranc.delineate >= '901' && tranc.delineate <= '904')                     
                               segmentation='Economic Casualties';                   
                  
                           elsif (tranc.delineate >= '1001' && tranc.delineate <= '1006')                     
                               segmentation="The 'Burbs";                   
                  
                           else
                               segmentation=tranc.delineate;
                           end
                        else
                           segmentation='';
                        end
                     
                                           
                        if !(tranc.AIQ_Green.nil? || tranc.AIQ_Green.blank?)
                     
                           if (tranc.AIQ_Green<= '25')                            
                              aiq_green='Hardly';
                   
                           elsif(tranc.AIQ_Green<= '50')                   
                             aiq_green='Not very';
                 
                           elsif(tranc.AIQ_Green<= '75')                    
                             aiq_green='Somewhat';
                                     
                           else                      
                               aiq_green='Very';                   
                  
                           end
                        else
                           aiq_green='';
                        end
                       
                       
                        if !(tranc.DebtRatio.nil? || tranc.DebtRatio.blank?)
                           debt_ratio=(tranc.DebtRatio).to_s+'%'
                        else
                           debt_ratio=''
                        end
              
              
                                                               
                        if !(tranc.Premoves.nil? || tranc.Premoves.blank?)
                     
                           if (tranc.Premoves<= '25')                            
                              premoves='Very Unlikely';
                   
                           elsif(tranc.Premoves<= '50')                   
                              premoves='Unlikely';
                 
                           elsif(tranc.Premoves<= '75')                    
                              premoves='Somewhat';
                                     
                           else                      
                              premoves='Very';                   
                  
                           end
                        else
                           premoves='';
                        end
                       
                        if tranc.Age_z4.nil? || tranc.Age_z4.blank?
                          householdage =''
                        else
                          householdage =(tranc.Age_z4).to_s + ' years'
                        end                       

                        if !(tranc.HomeOwner_pct_z4.nil? || tranc.HomeOwner_pct_z4.blank?)
                           owner_rented=(tranc.HomeOwner_pct_z4).to_s+'%'
                        else
                           owner_rented=''
                        end

                        if !(tranc.Homeequity_pc_z4.nil? || tranc.Homeequity_pc_z4.blank?)
                           home_equity=(tranc.Homeequity_pc_z4).to_s+'%'
                        else
                           home_equity=''
                        end
          
          
                        splited_address=(tranc.address).split(",")
                        state=(splited_address[2]).split(" ")


                  
                        utl= Utilitytable.select("utility").where("zip = ?",tranc.zip)
                        
                        if !(utl.nil? || utl.blank?)
                        utlstr=''
                        utl.each do |u|       
                             utlstr=utlstr+u.utility+', '
                        end                           
                             utlstr=utlstr[0..(utlstr.length-3)] 
                        else
                             utlstr=''
                        end
                                                                                                     
                        zee=ZipEverythingElse.select("*").where("zip = ?",tranc.zip).limit(1)
                        
                        if !(zee.nil? || zee.blank?)
                          solar_homes=zee.first['no_of_solar_homes']
                          owned_system=zee.first['3rd_party_owned_system'].to_s+'%'
                          avg_sys_size=zee.first['average_system_size'].to_s+'kW'
                        else
                          solar_homes=''
                          owned_system=''
                          avg_sys_size=''
                        end
                        
                    
                        ztp=ZipTopInstaller.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(5)
                        
                        if !(ztp.nil? || ztp.blank?)
                          installer=''
                          ztp.each do |zp|       
                            installer=installer+zp.installers+','
                          end                           
                            installer=installer[0..(installer.length-2)].split(',')
                             
                            installer1=installer[0]
                            installer2=installer[1]
                            installer3=installer[2]
                            installer4=installer[3]
                            installer5=installer[4]
                        else
                            installer1=''  
                            installer2=''
                            installer3=''
                            installer4=''
                            installer5=''
                        end
                 
                        
                        zpb=ZipPanelBrand.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(3)
                        
                        if !(zpb.nil? || zpb.blank?)
                          panel=''
                            zpb.each do |zb|       
                              panel=panel+zb.panel_brands+','
                            end                           
                            panel=panel[0..(panel.length-2)].split(',')
                             
                            panel1=panel[0]
                            panel2=panel[1]
                            panel3=panel[2]
                        else
                            panel1=''  
                            panel2=''
                            panel3=''                           
                        end
                 
                        zib=ZipInverterBrand.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(3)
        
                        if !(zib.nil? || zib.blank?)
                          inverter=''
                            zib.each do |ib|       
                              inverter=inverter+ib.inverter_brands+','
                            end                           
                            inverter=inverter[0..(inverter.length-2)].split(',')
                             
                            inverter1=inverter[0]
                            inverter2=inverter[1]
                            inverter3=inverter[2]
                        else
                            inverter1=''  
                            inverter2=''
                            inverter3=''                           
                        end
                 
     
                        cee=CityEverythingElse.select("*").where("city = ?",tranc.city).limit(1)  
                                                 
                        if !(cee.nil? || cee.blank?)
                          city_solar_homes=cee.first['no_of_solar_homes']
                          city_owned_system=cee.first['3rd_party_owned_system'].to_s+'%'
                          city_avg_sys_size=cee.first['average_system_size'].to_s+'kW'
                        else
                          city_solar_homes=''
                          city_owned_system=''
                          city_avg_sys_size=''
                        end
                                            
          
                        ctp=CityTopInstaller.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(5) 
                        
                        if !(ctp.nil? || ctp.blank?)
                          city_installer=''
                          ctp.each do |cp|       
                            city_installer=city_installer+cp.installers+','
                          end                           
                            city_installer=city_installer[0..(city_installer.length-2)].split(',')
                             
                            city_installer1=city_installer[0]
                            city_installer2=city_installer[1]
                            city_installer3=city_installer[2]
                            city_installer4=city_installer[3]
                            city_installer5=city_installer[4]
                        else
                            city_installer1=''  
                            city_installer2=''
                            city_installer3=''
                            city_installer4=''
                            city_installer5=''
                        end
                               
                  
                        cpb=CityPanelBrand.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(3) 
                        
                        if !(cpb.nil? || cpb.blank?)
                            city_panel=''
                            cpb.each do |cb|       
                              city_panel=city_panel+cb.panel_brands+','
                            end                           
                            city_panel=city_panel[0..(city_panel.length-2)].split(',')
                             
                            city_panel1=city_panel[0]
                            city_panel2=city_panel[1]
                            city_panel3=city_panel[2]
                        else
                            city_panel1=''  
                            city_panel2=''
                            city_panel3=''                           
                        end
                                                        
                  
                        cib=CityInverterBrand.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(3)
 
                        if !(cib.nil? || cib.blank?)
                            city_inverter=''
                            cib.each do |ib|       
                              city_inverter=city_inverter+ib.inverter_brands+','
                            end                           
                            city_inverter=city_inverter[0..(city_inverter.length-2)].split(',')
                             
                            city_inverter1=city_inverter[0]
                            city_inverter2=city_inverter[1]
                            city_inverter3=city_inverter[2]
                        else
                            city_inverter1=''  
                            city_inverter2=''
                            city_inverter3=''                           
                        end                         

                                                            
                        csv << [tranc.transaction_id, splited_address[0], tranc.city, state[0], tranc.zip, tranc.first_name+' '+tranc.last_name, tranc.company_name, prev_chk, (user_zone_date).strftime('%d %b, %y'), (user_zone_date).strftime('%H:%M'),
                               ipq_valid, ipq_active_price, mothly_access_fee,tranc.owner_name, tranc.mailing_address,ocp,owned, last_sale_price, tranc.land_use_code, tranc.zoning, tranc.no_of_residential_per_common_units, gross_area,
                               tranc.no_of_bedrooms, tranc.no_of_bathrooms, age, pool, tranc.heat_type, tranc.heat_fuel, tranc.roof_type, tranc.roof_shape, tranc.roof_material, tranc.roof_frame, tranc.no_of_stories, est_credit_score, segmentation,
                               aiq_green, eestimated_income, debt_ratio, premoves, householdage, tranc.PersonsatResidence_z4, owner_rented, home_equity, utlstr, solar_homes,owned_system, avg_sys_size, installer1, installer2, installer3, installer4, installer5,
                               panel1, panel2, panel3, inverter1, inverter2, inverter3, city_solar_homes, city_owned_system, city_avg_sys_size, city_installer1, city_installer2, city_installer3, city_installer4, city_installer5,
                               city_panel1, city_panel2, city_panel3, city_inverter1, city_inverter2, city_inverter3]
                              end
           end

      send_data(@userpurchasestranc_csv, :type => 'text/csv', :filename => 'user_purchasestranc.csv')

    else
      redirect_to :action => "userlogin"
    end
 
    
  end

  def usersalescsv

    if ((session[:admin_user_id] || session[:super_admin_user_id]) && session[:admin_user_transaction_view_id])

      @usersalestranc=User.joins(:user_purchases).select("users.id, users.first_name, users.last_name, users.company_name,users.company_email_id, users.credits, users.monthly_charge, user_purchases.*").where("users.id = ? and user_purchases.status = 1",session[:admin_user_transaction_view_id])
                       
      @usersalestranc_csv = CSV.generate do |csv|
               csv << ["Transaction Id", "Street", "City", "State", "Zip", "Name", "Company Name", "IPQ Checks", "Date", "Time", "IPQ Valid", "IPQ Active Price", "Active Monthly Access Fee", "Owner Name", "Mailing Address", "Owner occupied",
                        "Owned For", "Last Sale Price", "Land Use Code", "Zoning", "No. Of Residential/common units", "Gross Area", "No. of bedrooms", "No. of bathrooms",
                        "Age Of Home","Has Pool?", "Heat type", "Heat fuel", "Roof type", "Roof Shape", "Roof material","Roof frame", "No. of Stories", "Estimated Credit Score", "Segmentation",
                        "How Green?","Estimated Household Income", "Estimated Debt to Income", "Premoves","Approximate Head of Household Age", "Approximate no. of people living here", "% homes owned (vs. rented)",
                        "Estimated Home Equity", "Utility Provider", "Solar Homes for ZIP", "3rd Party for ZIP", "Avg. System for ZIP", "Installer1 for ZIP","Installer2 for ZIP","Installer3 for ZIP",
                        "Installer4 for ZIP","Installer5 for ZIP", "Panel Brand1 for ZIP", "Panel Brand2 for ZIP", "Panel Brand3 for ZIP","Inverter Brand1 for ZIP", "Inverter Brand2 for ZIP", "Inverter Brand3 for ZIP",
                        "Solar Homes for CITY", "3rd Party for CITY", "Avg. System for CITY", "Installer1 for CITY","Installer2 for CITY","Installer3 for CITY", "Installer4 for CITY","Installer5 for CITY", "Panel Brand1 for CITY",
                        "Panel Brand2 for CITY", "Panel Brand3 for CITY","Inverter Brand1 for CITY", "Inverter Brand2 for CITY", "Inverter Brand3 for CITY"]

                        
               @usersalestranc.each do |tranc|
                        user_zone_date=tranc.purchase_date
                        if (tranc.user_zone)[0]=='+'

                          user_zone_date=user_zone_date+(tranc.user_zone)[1,3].to_i.hours
                          user_zone_date=user_zone_date+(tranc.user_zone)[4,6].to_i.minutes

                        elsif  (tranc.user_zone)[0]=='-'

                          user_zone_date=user_zone_date-(tranc.user_zone)[1,3].to_i.hours
                          user_zone_date=user_zone_date-(tranc.user_zone)[4,6].to_i.minutes

                        end

                       arr= tranc.company_email_id.split('@')
                       
                        if arr[1]=='prospectzen.com' 
                           prev_chk=tranc.prev_check                        
                        else                          
                           prev_chk=tranc.prev_check-1
                        end
                        
                        
                        if tranc.status=='1'
                          ipq_valid="Yes"
                        else
                          ipq_valid="No"
                        end
                        
                        if tranc.owner_occupied_indicator=='1'
                          ocp="Yes"
                        elsif tranc.owner_occupied_indicator=='0'
                          ocp="No"
                        else
                          ocp=""
                        end
                        
                        if tranc.pool=='1'
                          pool="Yes"
                        elsif tranc.pool=='0'
                          pool="No"
                        else
                          pool=""
                        end
                        
                        if tranc.credits=='0'
                           ipq_active_price=1
                        else
                           ipq_active_price=0
                        end
                        
                                   
                        if !(tranc.IncomeIQ_Dol.nil? || tranc.IncomeIQ_Dol.blank?)
                           eestimated_income='$'+((tranc.IncomeIQ_Dol).to_i * 1000).to_s
                        else
                           eestimated_income=''
                        end
              
                        if !(tranc.last_sale_date.nil? || tranc.last_sale_date.blank?)
                           owned=Time.diff(Time.now, Time.parse(tranc.last_sale_date),'%y, %M')[:diff]
                        else
                           owned=''
                        end
                        
                        if !(tranc.monthly_charge.nil? || tranc.monthly_charge.blank?)
                           mothly_access_fee='$'+(tranc.monthly_charge).to_s
                        else
                           mothly_access_fee=''
                        end
                       
                        if !(tranc.last_sale_price.nil? || tranc.last_sale_price.blank?)
                           last_sale_price='$'+(tranc.last_sale_price).to_s
                        else
                           last_sale_price=''
                        end
                       
                        if !(tranc.gross_area.nil? || tranc.gross_area.blank?)
                           gross_area=(tranc.gross_area).to_s+' sqft'
                        else
                           gross_area=''
                        end
  
                        if tranc.year_built.nil? || tranc.year_built.blank?
                          age =''
                        else
                          age =(Time.now.year - tranc.year_built).to_s + ' years'
                        end

                    
                        if !(tranc.riskiq3.nil? || tranc.riskiq3.blank?)
                     
                           if (tranc.riskiq3<= '36')                            
                              est_credit_score='<650';
                   
                           elsif(tranc.riskiq3<= '50')                   
                             est_credit_score='650-700';
                 
                           elsif(tranc.riskiq3<= '82')                    
                             est_credit_score='700-750';
                                     
                           else                      
                               est_credit_score='800+';                   
                  
                           end
                        else
                           est_credit_score='';
                        end
                       
                                           
                        if !(tranc.delineate.nil? || tranc.delineate.blank?)
                     
                           if (tranc.delineate >= '101' && tranc.delineate <= '105')                            
                              segmentation='Assimilating New Americans';
                   
                           elsif (tranc.delineate >= '201' && tranc.delineate <= '207')                            
                              segmentation='Mid-Market America';
 
                           elsif (tranc.delineate >= '301' && tranc.delineate <= '307')                            
                              segmentation='High Society';
                   
                           elsif (tranc.delineate >= '401' && tranc.delineate <= '406')                            
                              segmentation='Blue Collar America';
 
                           elsif (tranc.delineate >= '501' && tranc.delineate <= '506')                            
                              segmentation='The High and Mighty';

                           elsif (tranc.delineate >= '601' && tranc.delineate <= '604')                            
                              segmentation='In Town Homeowners';
                   
                           elsif (tranc.delineate >= '701' && tranc.delineate <= '704')                            
                              segmentation='Struggling to Get Ahead';
 
                           elsif (tranc.delineate >= '801' && tranc.delineate <= '803')                            
                              segmentation='New Americans';
                                     
                           elsif (tranc.delineate >= '901' && tranc.delineate <= '904')                     
                               segmentation='Economic Casualties';                   
                  
                           elsif (tranc.delineate >= '1001' && tranc.delineate <= '1006')                     
                               segmentation="The 'Burbs";                   
                  
                           else
                               segmentation=tranc.delineate;
                           end
                        else
                           segmentation='';
                        end
                     
                                           
                        if !(tranc.AIQ_Green.nil? || tranc.AIQ_Green.blank?)
                     
                           if (tranc.AIQ_Green<= '25')                            
                              aiq_green='Hardly';
                   
                           elsif(tranc.AIQ_Green<= '50')                   
                             aiq_green='Not very';
                 
                           elsif(tranc.AIQ_Green<= '75')                    
                             aiq_green='Somewhat';
                                     
                           else                      
                               aiq_green='Very';                   
                  
                           end
                        else
                           aiq_green='';
                        end
                       
                       
                        if !(tranc.DebtRatio.nil? || tranc.DebtRatio.blank?)
                           debt_ratio=(tranc.DebtRatio).to_s+'%'
                        else
                           debt_ratio=''
                        end
              
              
                                                               
                        if !(tranc.Premoves.nil? || tranc.Premoves.blank?)
                     
                           if (tranc.Premoves<= '25')                            
                              premoves='Very Unlikely';
                   
                           elsif(tranc.Premoves<= '50')                   
                              premoves='Unlikely';
                 
                           elsif(tranc.Premoves<= '75')                    
                              premoves='Somewhat';
                                     
                           else                      
                              premoves='Very';                   
                  
                           end
                        else
                           premoves='';
                        end
                       
                        if tranc.Age_z4.nil? || tranc.Age_z4.blank?
                          householdage =''
                        else
                          householdage =(tranc.Age_z4).to_s + ' years'
                        end                       

                        if !(tranc.HomeOwner_pct_z4.nil? || tranc.HomeOwner_pct_z4.blank?)
                           owner_rented=(tranc.HomeOwner_pct_z4).to_s+'%'
                        else
                           owner_rented=''
                        end

                        if !(tranc.Homeequity_pc_z4.nil? || tranc.Homeequity_pc_z4.blank?)
                           home_equity=(tranc.Homeequity_pc_z4).to_s+'%'
                        else
                           home_equity=''
                        end
          
          
                        splited_address=(tranc.address).split(",")
                        state=(splited_address[2]).split(" ")
                     
                        
                  
                        utl= Utilitytable.select("utility").where("zip = ?",tranc.zip)
                        
                        if !(utl.nil? || utl.blank?)
                        utlstr=''
                        utl.each do |u|       
                             utlstr=utlstr+u.utility+', '
                        end                           
                             utlstr=utlstr[0..(utlstr.length-3)] 
                        else
                             utlstr=''
                        end
                                                                                                     
                        zee=ZipEverythingElse.select("*").where("zip = ?",tranc.zip).limit(1)
                        
                        if !(zee.nil? || zee.blank?)
                          solar_homes=zee.first['no_of_solar_homes']
                          owned_system=zee.first['3rd_party_owned_system'].to_s+'%'
                          avg_sys_size=zee.first['average_system_size'].to_s+'kW'
                        else
                          solar_homes=''
                          owned_system=''
                          avg_sys_size=''
                        end
                        
                    
                        ztp=ZipTopInstaller.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(5)
                        
                        if !(ztp.nil? || ztp.blank?)
                          installer=''
                          ztp.each do |zp|       
                            installer=installer+zp.installers+','
                          end                           
                            installer=installer[0..(installer.length-2)].split(',')
                             
                            installer1=installer[0]
                            installer2=installer[1]
                            installer3=installer[2]
                            installer4=installer[3]
                            installer5=installer[4]
                        else
                            installer1=''  
                            installer2=''
                            installer3=''
                            installer4=''
                            installer5=''
                        end
                 
                        
                        zpb=ZipPanelBrand.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(3)
                        
                        if !(zpb.nil? || zpb.blank?)
                          panel=''
                            zpb.each do |zb|       
                              panel=panel+zb.panel_brands+','
                            end                           
                            panel=panel[0..(panel.length-2)].split(',')
                             
                            panel1=panel[0]
                            panel2=panel[1]
                            panel3=panel[2]
                        else
                            panel1=''  
                            panel2=''
                            panel3=''                           
                        end
                 
                        zib=ZipInverterBrand.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(3)
        
                        if !(zib.nil? || zib.blank?)
                          inverter=''
                            zib.each do |ib|       
                              inverter=inverter+ib.inverter_brands+','
                            end                           
                            inverter=inverter[0..(inverter.length-2)].split(',')
                             
                            inverter1=inverter[0]
                            inverter2=inverter[1]
                            inverter3=inverter[2]
                        else
                            inverter1=''  
                            inverter2=''
                            inverter3=''                           
                        end
                 
     
                        cee=CityEverythingElse.select("*").where("city = ?",tranc.city).limit(1)  
                                                 
                        if !(cee.nil? || cee.blank?)
                          city_solar_homes=cee.first['no_of_solar_homes']
                          city_owned_system=cee.first['3rd_party_owned_system'].to_s+'%'
                          city_avg_sys_size=cee.first['average_system_size'].to_s+'kW'
                        else
                          city_solar_homes=''
                          city_owned_system=''
                          city_avg_sys_size=''
                        end
                                            
          
                        ctp=CityTopInstaller.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(5) 
                        
                        if !(ctp.nil? || ctp.blank?)
                          city_installer=''
                          ctp.each do |cp|       
                            city_installer=city_installer+cp.installers+','
                          end                           
                            city_installer=city_installer[0..(city_installer.length-2)].split(',')
                             
                            city_installer1=city_installer[0]
                            city_installer2=city_installer[1]
                            city_installer3=city_installer[2]
                            city_installer4=city_installer[3]
                            city_installer5=city_installer[4]
                        else
                            city_installer1=''  
                            city_installer2=''
                            city_installer3=''
                            city_installer4=''
                            city_installer5=''
                        end
                               
                  
                        cpb=CityPanelBrand.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(3) 
                        
                        if !(cpb.nil? || cpb.blank?)
                            city_panel=''
                            cpb.each do |cb|       
                              city_panel=city_panel+cb.panel_brands+','
                            end                           
                            city_panel=city_panel[0..(city_panel.length-2)].split(',')
                             
                            city_panel1=city_panel[0]
                            city_panel2=city_panel[1]
                            city_panel3=city_panel[2]
                        else
                            city_panel1=''  
                            city_panel2=''
                            city_panel3=''                           
                        end
                                                        
                  
                        cib=CityInverterBrand.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(3)
 
                        if !(cib.nil? || cib.blank?)
                            city_inverter=''
                            cib.each do |ib|       
                              city_inverter=city_inverter+ib.inverter_brands+','
                            end                           
                            city_inverter=city_inverter[0..(city_inverter.length-2)].split(',')
                             
                            city_inverter1=city_inverter[0]
                            city_inverter2=city_inverter[1]
                            city_inverter3=city_inverter[2]
                        else
                            city_inverter1=''  
                            city_inverter2=''
                            city_inverter3=''                           
                        end                         

                                                            
                        csv << [tranc.transaction_id, splited_address[0], tranc.city, state[0], tranc.zip, tranc.first_name+' '+tranc.last_name, tranc.company_name, prev_chk, (user_zone_date).strftime('%d %b, %y'), (user_zone_date).strftime('%H:%M'),
                               ipq_valid, ipq_active_price, mothly_access_fee,tranc.owner_name, tranc.mailing_address,ocp,owned, last_sale_price, tranc.land_use_code, tranc.zoning, tranc.no_of_residential_per_common_units, gross_area,
                               tranc.no_of_bedrooms, tranc.no_of_bathrooms, age, pool, tranc.heat_type, tranc.heat_fuel, tranc.roof_type, tranc.roof_shape, tranc.roof_material, tranc.roof_frame, tranc.no_of_stories, est_credit_score, segmentation,
                               aiq_green, eestimated_income, debt_ratio, premoves, householdage, tranc.PersonsatResidence_z4, owner_rented, home_equity, utlstr, solar_homes,owned_system, avg_sys_size, installer1, installer2, installer3, installer4, installer5,
                               panel1, panel2, panel3, inverter1, inverter2, inverter3, city_solar_homes, city_owned_system, city_avg_sys_size, city_installer1, city_installer2, city_installer3, city_installer4, city_installer5,
                               city_panel1, city_panel2, city_panel3, city_inverter1, city_inverter2, city_inverter3]
                              end
           end

      send_data(@usersalestranc_csv, :type => 'text/csv', :filename => 'user_salestranc.csv')

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

      @alltransactions=User.joins(:user_purchases).select("users.id, users.first_name, users.last_name, users.company_name, user_purchases.transaction_id, user_purchases.address, user_purchases.purchase_date, user_purchases.user_zone")
    else
      redirect_to :action => "adminlogin"
    end

  end

  def allsalescsv

    if ((session[:admin_user_id] || session[:super_admin_user_id]))

       @allsalestranc=User.joins(:user_purchases).select("users.id, users.first_name, users.last_name, users.company_name, users.company_email_id, users.credits, users.monthly_charge, user_purchases.*")
       @allsalestranc_csv = CSV.generate do |csv|

               csv << ["Transaction Id", "Street", "City", "State", "Zip", "Name", "Company Name", "IPQ Checks", "Date", "Time", "IPQ Valid", "IPQ Active Price", "Active Monthly Access Fee", "Owner Name", "Mailing Address", "Owner occupied",
                        "Owned For", "Last Sale Price", "Land Use Code", "Zoning", "No. Of Residential/common units", "Gross Area", "No. of bedrooms", "No. of bathrooms",
                        "Age Of Home","Has Pool?", "Heat type", "Heat fuel", "Roof type", "Roof Shape", "Roof material","Roof frame", "No. of Stories", "Estimated Credit Score", "Segmentation",
                        "How Green?","Estimated Household Income", "Estimated Debt to Income", "Premoves","Approximate Head of Household Age", "Approximate no. of people living here", "% homes owned (vs. rented)",
                        "Estimated Home Equity", "Utility Provider", "Solar Homes for ZIP", "3rd Party for ZIP", "Avg. System for ZIP", "Installer1 for ZIP","Installer2 for ZIP","Installer3 for ZIP",
                        "Installer4 for ZIP","Installer5 for ZIP", "Panel Brand1 for ZIP", "Panel Brand2 for ZIP", "Panel Brand3 for ZIP","Inverter Brand1 for ZIP", "Inverter Brand2 for ZIP", "Inverter Brand3 for ZIP",
                        "Solar Homes for CITY", "3rd Party for CITY", "Avg. System for CITY", "Installer1 for CITY","Installer2 for CITY","Installer3 for CITY", "Installer4 for CITY","Installer5 for CITY", "Panel Brand1 for CITY",
                        "Panel Brand2 for CITY", "Panel Brand3 for CITY","Inverter Brand1 for CITY", "Inverter Brand2 for CITY", "Inverter Brand3 for CITY"]


               @allsalestranc.each do |tranc|

                        user_zone_date=tranc.purchase_date
                        if (tranc.user_zone)[0]=='+'

                          user_zone_date=user_zone_date+(tranc.user_zone)[1,3].to_i.hours
                          user_zone_date=user_zone_date+(tranc.user_zone)[4,6].to_i.minutes

                        elsif  (tranc.user_zone)[0]=='-'

                          user_zone_date=user_zone_date-(tranc.user_zone)[1,3].to_i.hours
                          user_zone_date=user_zone_date-(tranc.user_zone)[4,6].to_i.minutes

                        end
                        
 
                        arr= tranc.company_email_id.split('@')
                       
                        if arr[1]=='prospectzen.com' 
                           prev_chk=tranc.prev_check                        
                        else                          
                           prev_chk=tranc.prev_check-1
                        end


                        if tranc.status=='1'
                          ipq_valid="Yes"
                        else
                          ipq_valid="No"
                        end
                        
                        if tranc.owner_occupied_indicator=='1'
                          ocp="Yes"
                        elsif tranc.owner_occupied_indicator=='0'
                          ocp="No"
                        else
                          ocp=""
                        end
                        
                        if tranc.pool=='1'
                          pool="Yes"
                        elsif tranc.pool=='0'
                          pool="No"
                        else
                          pool=""
                        end

                        if tranc.credits=='0'
                           ipq_active_price=1
                        else
                           ipq_active_price=0
                        end
                                              
                        if !(tranc.IncomeIQ_Dol.nil? || tranc.IncomeIQ_Dol.blank?)
                           eestimated_income='$'+((tranc.IncomeIQ_Dol).to_i * 1000).to_s
                        else
                           eestimated_income=''
                        end
              
                        if !(tranc.last_sale_date.nil? || tranc.last_sale_date.blank?)
                           owned=Time.diff(Time.now, Time.parse(tranc.last_sale_date),'%y, %M')[:diff]
                        else
                           owned=''
                        end
                        
                        if !(tranc.monthly_charge.nil? || tranc.monthly_charge.blank?)
                           mothly_access_fee='$'+(tranc.monthly_charge).to_s
                        else
                           mothly_access_fee=''
                        end
                       
                        if !(tranc.last_sale_price.nil? || tranc.last_sale_price.blank?)
                           last_sale_price='$'+(tranc.last_sale_price).to_s
                        else
                           last_sale_price=''
                        end
                       
                        if !(tranc.gross_area.nil? || tranc.gross_area.blank?)
                           gross_area=(tranc.gross_area).to_s+' sqft'
                        else
                           gross_area=''
                        end
  
                        if tranc.year_built.nil? || tranc.year_built.blank?
                          age =''
                        else
                          age =(Time.now.year - tranc.year_built).to_s + ' years'
                        end

                    
                        if !(tranc.riskiq3.nil? || tranc.riskiq3.blank?)
                     
                           if (tranc.riskiq3<= '36')                            
                              est_credit_score='<650';
                   
                           elsif(tranc.riskiq3<= '50')                   
                             est_credit_score='650-700';
                 
                           elsif(tranc.riskiq3<= '82')                    
                             est_credit_score='700-750';
                                     
                           else                      
                               est_credit_score='800+';                   
                  
                           end
                        else
                           est_credit_score='';
                        end
                       
                                           
                        if !(tranc.delineate.nil? || tranc.delineate.blank?)
                     
                           if (tranc.delineate >= '101' && tranc.delineate <= '105')                            
                              segmentation='Assimilating New Americans';
                   
                           elsif (tranc.delineate >= '201' && tranc.delineate <= '207')                            
                              segmentation='Mid-Market America';
 
                           elsif (tranc.delineate >= '301' && tranc.delineate <= '307')                            
                              segmentation='High Society';
                   
                           elsif (tranc.delineate >= '401' && tranc.delineate <= '406')                            
                              segmentation='Blue Collar America';
 
                           elsif (tranc.delineate >= '501' && tranc.delineate <= '506')                            
                              segmentation='The High and Mighty';

                           elsif (tranc.delineate >= '601' && tranc.delineate <= '604')                            
                              segmentation='In Town Homeowners';
                   
                           elsif (tranc.delineate >= '701' && tranc.delineate <= '704')                            
                              segmentation='Struggling to Get Ahead';
 
                           elsif (tranc.delineate >= '801' && tranc.delineate <= '803')                            
                              segmentation='New Americans';
                                     
                           elsif (tranc.delineate >= '901' && tranc.delineate <= '904')                     
                               segmentation='Economic Casualties';                   
                  
                           elsif (tranc.delineate >= '1001' && tranc.delineate <= '1006')                     
                               segmentation="The 'Burbs";                   
                  
                           else
                               segmentation=tranc.delineate;
                           end
                        else
                           segmentation='';
                        end
                     
                                           
                        if !(tranc.AIQ_Green.nil? || tranc.AIQ_Green.blank?)
                     
                           if (tranc.AIQ_Green<= '25')                            
                              aiq_green='Hardly';
                   
                           elsif(tranc.AIQ_Green<= '50')                   
                             aiq_green='Not very';
                 
                           elsif(tranc.AIQ_Green<= '75')                    
                             aiq_green='Somewhat';
                                     
                           else                      
                               aiq_green='Very';                   
                  
                           end
                        else
                           aiq_green='';
                        end
                       
                       
                        if !(tranc.DebtRatio.nil? || tranc.DebtRatio.blank?)
                           debt_ratio=(tranc.DebtRatio).to_s+'%'
                        else
                           debt_ratio=''
                        end
              
              
                                                               
                        if !(tranc.Premoves.nil? || tranc.Premoves.blank?)
                     
                           if (tranc.Premoves<= '25')                            
                              premoves='Very Unlikely';
                   
                           elsif(tranc.Premoves<= '50')                   
                              premoves='Unlikely';
                 
                           elsif(tranc.Premoves<= '75')                    
                              premoves='Somewhat';
                                     
                           else                      
                              premoves='Very';                   
                  
                           end
                        else
                           premoves='';
                        end
                       
                        if tranc.Age_z4.nil? || tranc.Age_z4.blank?
                          householdage =''
                        else
                          householdage =(tranc.Age_z4).to_s + ' years'
                        end                       

                        if !(tranc.HomeOwner_pct_z4.nil? || tranc.HomeOwner_pct_z4.blank?)
                           owner_rented=(tranc.HomeOwner_pct_z4).to_s+'%'
                        else
                           owner_rented=''
                        end

                        if !(tranc.Homeequity_pc_z4.nil? || tranc.Homeequity_pc_z4.blank?)
                           home_equity=(tranc.Homeequity_pc_z4).to_s+'%'
                        else
                           home_equity=''
                        end
          
          
                        splited_address=(tranc.address).split(",")
                        state=(splited_address[2]).split(" ")

                  
                        utl= Utilitytable.select("utility").where("zip = ?",tranc.zip)
                        
                        if !(utl.nil? || utl.blank?)
                        utlstr=''
                        utl.each do |u|       
                             utlstr=utlstr+u.utility+', '
                        end                           
                             utlstr=utlstr[0..(utlstr.length-3)] 
                        else
                             utlstr=''
                        end
                                                                                                     
                        zee=ZipEverythingElse.select("*").where("zip = ?",tranc.zip).limit(1)
                        
                        if !(zee.nil? || zee.blank?)
                          solar_homes=zee.first['no_of_solar_homes']
                          owned_system=zee.first['3rd_party_owned_system'].to_s+'%'
                          avg_sys_size=zee.first['average_system_size'].to_s+'kW'
                        else
                          solar_homes=''
                          owned_system=''
                          avg_sys_size=''
                        end
                        
                    
                        ztp=ZipTopInstaller.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(5)
                        
                        if !(ztp.nil? || ztp.blank?)
                          installer=''
                          ztp.each do |zp|       
                            installer=installer+zp.installers+','
                          end                           
                            installer=installer[0..(installer.length-2)].split(',')
                             
                            installer1=installer[0]
                            installer2=installer[1]
                            installer3=installer[2]
                            installer4=installer[3]
                            installer5=installer[4]
                        else
                            installer1=''  
                            installer2=''
                            installer3=''
                            installer4=''
                            installer5=''
                        end
                 
                        
                        zpb=ZipPanelBrand.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(3)
                        
                        if !(zpb.nil? || zpb.blank?)
                          panel=''
                            zpb.each do |zb|       
                              panel=panel+zb.panel_brands+','
                            end                           
                            panel=panel[0..(panel.length-2)].split(',')
                             
                            panel1=panel[0]
                            panel2=panel[1]
                            panel3=panel[2]
                        else
                            panel1=''  
                            panel2=''
                            panel3=''                           
                        end
                 
                        zib=ZipInverterBrand.select("*").where("zip = ?",tranc.zip).order('no_of_solar_homes desc').limit(3)
        
                        if !(zib.nil? || zib.blank?)
                          inverter=''
                            zib.each do |ib|       
                              inverter=inverter+ib.inverter_brands+','
                            end                           
                            inverter=inverter[0..(inverter.length-2)].split(',')
                             
                            inverter1=inverter[0]
                            inverter2=inverter[1]
                            inverter3=inverter[2]
                        else
                            inverter1=''  
                            inverter2=''
                            inverter3=''                           
                        end
                 
     
                        cee=CityEverythingElse.select("*").where("city = ?",tranc.city).limit(1)  
                                                 
                        if !(cee.nil? || cee.blank?)
                          city_solar_homes=cee.first['no_of_solar_homes']
                          city_owned_system=cee.first['3rd_party_owned_system'].to_s+'%'
                          city_avg_sys_size=cee.first['average_system_size'].to_s+'kW'
                        else
                          city_solar_homes=''
                          city_owned_system=''
                          city_avg_sys_size=''
                        end
                                            
          
                        ctp=CityTopInstaller.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(5) 
                        
                        if !(ctp.nil? || ctp.blank?)
                          city_installer=''
                          ctp.each do |cp|       
                            city_installer=city_installer+cp.installers+','
                          end                           
                            city_installer=city_installer[0..(city_installer.length-2)].split(',')
                             
                            city_installer1=city_installer[0]
                            city_installer2=city_installer[1]
                            city_installer3=city_installer[2]
                            city_installer4=city_installer[3]
                            city_installer5=city_installer[4]
                        else
                            city_installer1=''  
                            city_installer2=''
                            city_installer3=''
                            city_installer4=''
                            city_installer5=''
                        end
                               
                  
                        cpb=CityPanelBrand.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(3) 
                        
                        if !(cpb.nil? || cpb.blank?)
                            city_panel=''
                            cpb.each do |cb|       
                              city_panel=city_panel+cb.panel_brands+','
                            end                           
                            city_panel=city_panel[0..(city_panel.length-2)].split(',')
                             
                            city_panel1=city_panel[0]
                            city_panel2=city_panel[1]
                            city_panel3=city_panel[2]
                        else
                            city_panel1=''  
                            city_panel2=''
                            city_panel3=''                           
                        end
                                                        
                  
                        cib=CityInverterBrand.select("*").where("city = ?",tranc.city).order('no_of_solar_homes desc').limit(3)
 
                        if !(cib.nil? || cib.blank?)
                            city_inverter=''
                            cib.each do |ib|       
                              city_inverter=city_inverter+ib.inverter_brands+','
                            end                           
                            city_inverter=city_inverter[0..(city_inverter.length-2)].split(',')
                             
                            city_inverter1=city_inverter[0]
                            city_inverter2=city_inverter[1]
                            city_inverter3=city_inverter[2]
                        else
                            city_inverter1=''  
                            city_inverter2=''
                            city_inverter3=''                           
                        end                         


                        csv << [tranc.transaction_id, splited_address[0], tranc.city, state[0], tranc.zip, tranc.first_name+' '+tranc.last_name, tranc.company_name, prev_chk, (user_zone_date).strftime('%d %b, %y'), (user_zone_date).strftime('%H:%M'),
                               ipq_valid, ipq_active_price, mothly_access_fee,tranc.owner_name, tranc.mailing_address,ocp,owned, last_sale_price, tranc.land_use_code, tranc.zoning, tranc.no_of_residential_per_common_units, gross_area,
                               tranc.no_of_bedrooms, tranc.no_of_bathrooms, age, pool, tranc.heat_type, tranc.heat_fuel, tranc.roof_type, tranc.roof_shape, tranc.roof_material, tranc.roof_frame, tranc.no_of_stories, est_credit_score, segmentation,
                               aiq_green, eestimated_income, debt_ratio, premoves, householdage, tranc.PersonsatResidence_z4, owner_rented, home_equity, utlstr, solar_homes,owned_system, avg_sys_size, installer1, installer2, installer3, installer4, installer5,
                               panel1, panel2, panel3, inverter1, inverter2, inverter3, city_solar_homes, city_owned_system, city_avg_sys_size, city_installer1, city_installer2, city_installer3, city_installer4, city_installer5,
                               city_panel1, city_panel2, city_panel3, city_inverter1, city_inverter2, city_inverter3]
                              end
           end

      send_data(@allsalestranc_csv, :type => 'text/csv', :filename => 'all_salestranc.csv')

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

  #  @contact = Contact.new(contact_params)

    if params[:mobile_phone]
       contact_no= params[:mobile_phone]
    else
       contact_no=""
    end

    Kernel.system 'curl https://prospectzen.zendesk.com/api/v2/tickets.json -d \'{"ticket":{"requester":{"name":"'+params[:full_name]+'", "email":"'+params[:email]+'"}, "subject": "'+params[:about]+'", "comment": { "body": "'+params[:message]+'" }}}\' -H "Content-Type: application/json" -v -u dhanur@prospectzen.com:prospectzen -X POST' 


  end

  def userlogin
    
    if session[:current_user_id]
       redirect_to :action => "viewmap"
    end

  end

  def forgotpassword

  end

  def resetpassword

    @user=User.select("id,company_email_id,verification_token").where("company_email_id=? and verification_token = ?",params[:emailid],params[:vt]).limit(1)
    if @user.blank?
      render :json =>{:error =>params[:emailid]}
    else
      md_pass=Digest::MD5.hexdigest(params[:password])
      User.where(:id=>@user.first['id']).limit(1).update_all(:last_activity => Time.now,:password=>md_pass)
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

      @user=User.select("first_name,last_name,company_email_id").where("id = ?",session[:current_user_id]).limit(1)
      @transctions=UserPurchase.select("address,transaction_id,purchase_date,user_zone").where("user_id = ? and status = 1",session[:current_user_id])

    else
      redirect_to :action => "userlogin"
    end

  end

  def particularaddressview

    if session[:current_user_id]
      session[:last_viewed_address]=params[:address]
      @latlng = UserPurchase.select("lat,lng").where("user_id = ? and address = ?",session[:current_user_id],params[:address])
      session[:lat]=@latlng.first['lat']
      session[:lng]=@latlng.first['lng']
      render :json => {:status =>"done" }

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

      elsif (@user.first['password']==(Digest::MD5.hexdigest(params[:cur_psd])))        
        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :password =>(Digest::MD5.hexdigest(params[:new_psd])))
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

      elsif (@user.first['password']==(Digest::MD5.hexdigest(params[:cur_psd])))

        User.where(:id=>@user.first['id']).update_all(:last_activity => Time.now, :password =>(Digest::MD5.hexdigest(params[:cur_psd])))
        render :json => {:status =>"done" }
      else
        render :json => {:status =>"not" }
      end

    end

  end

  def problemcreceipt

    if session[:current_user_id]
      @user=User.select("*").where("id = ?",session[:current_user_id]).limit(1)
      
      @user_name=@user.first["first_name"]+ "" + @user.first["last_name"]
      @email_id=@user.first["company_email_id"]
      Kernel.system 'curl https://prospectzen.zendesk.com/api/v2/tickets.json -d \'{"ticket":{"requester":{"name":"'+@user_name+'", "email":"'+@email_id+'"}, "subject": "'+params[:what_about]+'", "comment": { "body": "'+params[:message]+'" }}}\' -H "Content-Type: application/json" -v -u dhanur@prospectzen.com:prospectzen -X POST' 
   
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
    md_pass=Digest::MD5.hexdigest(params[:password])
    @admin=Admin.select("*").where("admin_email_id = ? and admin_password = ?",params[:emailid],md_pass).limit(1)

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
      @adminuser.admin_password=Digest::MD5.hexdigest(params[:admin_password])
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
      
      arr = params[:company_email_id].split("@")
    
      user_is_in_same_company=User.select("company_id").where("company_email_id like?","%#{arr[1]}").limit(1) 
      
      if user_is_in_same_company.blank?
                   new_company=User.select("company_id").order('company_id desc').limit(1) 
                  
                   if new_company.blank?
                      company_count=1
                   else
                      company_count=new_company.first['company_id']+1
                   end
      else
                   company_count=user_is_in_same_company.first['company_id']   
      end
     

      @user = User.new(user_params)
      @user.registration_date = Time.now
      @user.last_activity = Time.now
      @user.company_id= company_count
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
    session[:lat]=@transaction.first['lat']
    session[:lng]=@transaction.first['lng']
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
    
    @zip = @transaction.first['zip']

    @zee=ZipEverythingElse.select("*").where("zip = ?",@zip).limit(1)
    @zee = @zee.to_a.map(&:serializable_hash)

    @ztp=ZipTopInstaller.select("*").where("zip = ?",@zip).order('no_of_solar_homes desc').limit(5)
    @ztp = @ztp.to_a.map(&:serializable_hash)

    @zpb=ZipPanelBrand.select("*").where("zip = ?",@zip).order('no_of_solar_homes desc').limit(3)
    @zpb = @zpb.to_a.map(&:serializable_hash)

    @zib=ZipInverterBrand.select("*").where("zip = ?",@zip).order('no_of_solar_homes desc').limit(3)
    @zib = @zib.to_a.map(&:serializable_hash)

    @utility= Utilitytable.select("utility").where("zip = ?",@zip)
    @utility = @utility.to_a.map(&:serializable_hash)

    render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility,:transaction =>@transaction, :age=> age, :owned=> owned}

  end

  def alldatafetchonmarkernewtrans

    @transaction= UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)
    @transaction = @transaction.to_a.map(&:serializable_hash)

    session[:last_viewed_address]=@transaction.first['address']
    session[:lat]=@transaction.first['lat']
    session[:lng]=@transaction.first['lng']

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
    
    @zip = @transaction.first['zip']

    @zee=ZipEverythingElse.select("*").where("zip = ?",@zip).limit(1)
    @zee = @zee.to_a.map(&:serializable_hash)

    @ztp=ZipTopInstaller.select("*").where("zip = ?",@zip).order('no_of_solar_homes desc').limit(5)
    @ztp = @ztp.to_a.map(&:serializable_hash)

    @zpb=ZipPanelBrand.select("*").where("zip = ?",@zip).order('no_of_solar_homes desc').limit(3)
    @zpb = @zpb.to_a.map(&:serializable_hash)

    @zib=ZipInverterBrand.select("*").where("zip = ?",@zip).order('no_of_solar_homes desc').limit(3)
    @zib = @zib.to_a.map(&:serializable_hash)

    @utility= Utilitytable.select("utility").where("zip = ?",@zip)
    @utility = @utility.to_a.map(&:serializable_hash)

    render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility,:transaction =>@transaction, :age => age, :owned=> owned}

  end

  def login
    
    md_pass=Digest::MD5.hexdigest(params[:password])
    @user=User.select('id,payment_status,company_email_id').where("company_email_id = ? and password = ? and active_status=1",params[:emailid],md_pass).limit(1)
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
        session[:company_email]=@user.first['company_email_id'] # used for previous checks
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
    session[:company_email]=nil
    session[:last_viewed_address]=nil
    session[:lat]=nil
    session[:lng]=nil
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
      md_pass=Digest::MD5.hexdigest(params[:password])
      User.where(:id=>@user.first['id']).limit(1).update_all(:last_activity => Time.now, :password=>md_pass)
      session[:cust_user_id]=@user.first['id'];

      render :json =>{:results => "done" }
    end
  end

  def stripe

  end

  def entercreditinfo
    begin

      token = params[:stripeToken]
      @user=User.select("company_email_id,first_name").where("id=?",session[:cust_user_id]).limit(1)

      customer = Stripe::Customer.create(

      :email => @user.first['company_email_id'],

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
      subscription = customer.subscriptions.create(:plan => plan)

     User.where(:id=>session[:cust_user_id]).limit(1).update_all(:last_activity => Time.now, :cust_id=>customer_id,:payment_status=>1,:house_charge=>3,:subscription_id=>subscription.id,:credits=>0,:card_exp_year=> customer.cards.data[0]['exp_year'],:card_exp_month=>customer.cards.data[0]['exp_month'],:current_period_end=>subscription.current_period_end,:card_no=>customer.cards.data[0]['last4'])
    #
    redirect_to :action => "userlogin"
    
    rescue Stripe::CardError => e
       # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
    
      puts "Status is: #{e.http_status}"
      puts "Type is: #{err[:type]}"
      puts "Code is: #{err[:code]}"
      # param is '' in this case
      puts "Param is: #{err[:param]}"
      puts "Message is: #{err[:message]}"
     
      Emailer.new_record_notification(@user.first['company_email_id']).deliver
      render :template => "homes/carddeclinemsg", :locals => {:body => body, :err => err, :status => e.http_status} and return
      # render :json => {"error" => "something went wrong"} and return

    end

    

  end

  def checkpurchase

    session[:last_viewed_address]=params[:address]
    
    if !params[:lat].nil?
         session[:lat]=params[:lat]
         session[:lng]=params[:lng]
         lat = params[:lat]
         lng = params[:lng]
     else  
         lat = '0'
         lng = '0'
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

    customer = User.select('company_id,company_email_id,credits,cust_id,house_charge').where("id=?", session[:current_user_id])

    addressexist= UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)

    @prev_check_address=UserPurchase.select("*").where("address ='"+params[:address]+"'").limit(1)

    arr = customer.first['company_email_id'].split("@")
    if @prev_check_address.blank?
        if arr[1]=='prospectzen.com'
          @prev_chks=0
        else
          @prev_chks=1
        end
    else     
        if arr[1]=='prospectzen.com'
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

      purchasedate =  addressexist.first['purchase_date']

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

          if !root.elements["//_GENERAL_DESCRIPTION"].attributes["_EffectiveYearBuiltDateIdentifier"].blank?

            _YearBuiltDateIdentifier = root.elements["//_GENERAL_DESCRIPTION"].attributes["_EffectiveYearBuiltDateIdentifier"]

          else

            if  !root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"].nil?

              _YearBuiltDateIdentifier = root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"]

            else

              _YearBuiltDateIdentifier = ''

            end

          end
        else

          if  !root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"].nil?

            _YearBuiltDateIdentifier = root.elements["//_GENERAL_DESCRIPTION"].attributes["_YearBuiltDateIdentifier"]

          else

            _YearBuiltDateIdentifier = ''

          end

        end
      else

        _YearBuiltDateIdentifier = ''

      end

      #   render :json => {"tf"=>!root.elements["//_GENERAL_DESCRIPTION"].attributes["_EffectiveYearBuiltDateIdentifier"].blank?, "efd"=>_YearBuiltDateIdentifier} and return

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
      
        begin
          
        charge= Stripe::Charge.create(
        :customer => customer.first['cust_id'],
        :amount => ((customer.first['house_charge'].to_f * 100).to_i),
        :currency => "usd",
        :description => "Charge for IPQ" 
        )
        
      rescue Stripe::CardError => e
       # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
    
      puts "Status is: #{e.http_status}"
      puts "Type is: #{err[:type]}"
      puts "Code is: #{err[:code]}"
      # param is '' in this case
      puts "Param is: #{err[:param]}"
      puts "Message is: #{err[:message]}"
     
      Emailer.new_record_notification(@user.first['company_email_id']).deliver
      render :template => "homes/carddeclinemsg", :locals => {:body => body, :err => err, :status => e.http_status} and return
      # render :json => {"error" => "something went wrong"} and return

    end


        if(charge.failure_code=='1')
          
          render :json => JSON.pretty_generate('data' =>charge.failure_message) and return

        end

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


      user_zone_date=Time.now
      
      if (params[:usertimezone])[0]=='+'

            user_zone_date=user_zone_date+(params[:usertimezone])[1,3].to_i.hours
            user_zone_date=user_zone_date+(params[:usertimezone])[4,6].to_i.minutes

      elsif  (params[:usertimezone])[0]=='-'

            user_zone_date=user_zone_date-(params[:usertimezone])[1,3].to_i.hours
            user_zone_date=user_zone_date-(params[:usertimezone])[4,6].to_i.minutes

      end
                        

      transaction_id='IPQ-'+ user_zone_date.strftime("%d%m%y").to_s+'-'+customer.first['company_id'].to_s+'-'+session[:current_user_id].to_s+'-'+purchasecount

      if !(zip=='' || zip4=='' || zip.nil?)
        @speedon = SpeedOnData.select("*").where("ZIP5 = ? and ZIP4 = ?",zip,zip4).limit(1)

        if  @speedon.nil? || @speedon.blank?

          @userpurchase=UserPurchase.new(:transaction_id=>transaction_id, :user_id =>session[:current_user_id],:address=> params[:address],:lat =>lat,:lng =>lng,:prev_check =>@prev_chks, :zip =>zip,:city =>city, :zip4 =>zip4, :owner_name =>_OwnerName.titleize, :mailing_address =>mailing_address.titleize,
                      :owner_occupied_indicator=>_OwnerOccupiedIndicator,:last_sale_date=>_LastSalesDate , :last_sale_price =>_LastSalesPriceAmount,:last_sale_price_per_sqr_ft =>_PricePerSquareFootAmount,
                      :land_use_code=>_LandUseDescription.titleize, :zoning=>_ClassificationIdentifier, :no_of_residential_per_common_units=> _TotalUnitNumber,:gross_area=>_GrossLivingAreaSquareFeetNumber,:living_area=>_TotalLivingAreaSquareFeetNumber,
                      :no_of_bedrooms=>_TotalBedroomsCount,:no_of_bathrooms=>_TotalBathsCount, :year_built=>_YearBuiltDateIdentifier,:pool=>_HasFeatureIndicator,
                      :heat_type=>_HeatingTypeDescription.titleize, :heat_fuel=>_HeatFuel.titleize,:roof_type=>_RoofTypeDescription.titleize,:roof_shape=>_RoofShape.titleize,:roof_material=>_RoofSurfaceDescription.titleize,:roof_frame=>_RoofFrame.titleize,
                      :condition=> _ConditionsDescription.titleize,:no_of_stories=>_TotalStoriesNumber,:purchase_date=>Time.now.localtime,:user_zone=>params[:usertimezone],:status=>1);

        else

          @userpurchase=UserPurchase.new(:transaction_id=>transaction_id, :user_id =>session[:current_user_id],:address=> params[:address],:lat =>lat,:lng =>lng,:prev_check =>@prev_chks, :zip =>zip,:city =>city, :zip4 =>zip4, :owner_name =>_OwnerName.titleize, :mailing_address =>mailing_address.titleize,
                      :owner_occupied_indicator=>_OwnerOccupiedIndicator,:last_sale_date=>_LastSalesDate , :last_sale_price =>_LastSalesPriceAmount,:last_sale_price_per_sqr_ft =>_PricePerSquareFootAmount,
                      :land_use_code=>_LandUseDescription.titleize, :zoning=>_ClassificationIdentifier, :no_of_residential_per_common_units=> _TotalUnitNumber,:gross_area=>_GrossLivingAreaSquareFeetNumber,:living_area=>_TotalLivingAreaSquareFeetNumber,
                      :no_of_bedrooms=>_TotalBedroomsCount,:no_of_bathrooms=>_TotalBathsCount, :year_built=>_YearBuiltDateIdentifier,:pool=>_HasFeatureIndicator,
                      :heat_type=>_HeatingTypeDescription.titleize, :heat_fuel=>_HeatFuel.titleize,:roof_type=>_RoofTypeDescription.titleize,:roof_shape=>_RoofShape.titleize,:roof_material=>_RoofSurfaceDescription.titleize,:roof_frame=>_RoofFrame.titleize,
                      :condition=> _ConditionsDescription.titleize,:no_of_stories=>_TotalStoriesNumber,:purchase_date=>Time.now.localtime,:user_zone=>params[:usertimezone],:status=>1, :riskiq3 => @speedon.first['riskiq3'], :delineate =>@speedon.first['delineate'],
                      :AIQ_Green => @speedon.first['AIQ_Green'], :IncomeIQ_Dol =>@speedon.first['IncomeIQ_Dol'], :DebtRatio =>@speedon.first['DebtRatio'], :Premoves =>@speedon.first['Premoves'], :Age_z4 =>@speedon.first['Age_z4'],
                      :ResidenceTime_z4=>@speedon.first['ResidenceTime_z4'], :MortgageAmount_z4 =>@speedon.first['MortgageAmount_z4'], :PersonsatResidence_z4 =>@speedon.first['PersonsatResidence_z4'],
                      :HomeOwner_pct_z4 =>@speedon.first['HomeOwner_pct_z4'], :LoantoValue_z4=>@speedon.first['LoantoValue_z4'],:IncomeIQ_plus_z4=>@speedon.first['IncomeIQ_plus_z4'], :AIQ_Green_plus_z4=>@speedon.first['AIQ_Green_plus_z4'],
                      :Homeequity_pc_z4 =>@speedon.first['Homeequity_pc_z4'], :NumberofadultsinZip4 => @speedon.first['NumberofadultsinZip4'],:State2 =>@speedon.first['State2']);

        end

      else

          @userpurchase=UserPurchase.new(:transaction_id=>transaction_id, :user_id =>session[:current_user_id],:address=> params[:address],:lat =>lat,:lng =>lng,:prev_check =>@prev_chks, :zip =>zip,:city =>city, :zip4 =>zip4, :owner_name =>_OwnerName.titleize, :mailing_address =>mailing_address.titleize,
                      :owner_occupied_indicator=>_OwnerOccupiedIndicator,:last_sale_date=>_LastSalesDate , :last_sale_price =>_LastSalesPriceAmount,:last_sale_price_per_sqr_ft =>_PricePerSquareFootAmount,
                      :land_use_code=>_LandUseDescription.titleize, :zoning=>_ClassificationIdentifier, :no_of_residential_per_common_units=> _TotalUnitNumber,:gross_area=>_GrossLivingAreaSquareFeetNumber,:living_area=>_TotalLivingAreaSquareFeetNumber,
                      :no_of_bedrooms=>_TotalBedroomsCount,:no_of_bathrooms=>_TotalBathsCount, :year_built=>_YearBuiltDateIdentifier,:pool=>_HasFeatureIndicator,
                      :heat_type=>_HeatingTypeDescription.titleize, :heat_fuel=>_HeatFuel.titleize,:roof_type=>_RoofTypeDescription.titleize,:roof_shape=>_RoofShape.titleize,:roof_material=>_RoofSurfaceDescription.titleize,:roof_frame=>_RoofFrame.titleize,
                      :condition=> _ConditionsDescription.titleize,:no_of_stories=>_TotalStoriesNumber,:purchase_date=>Time.now.localtime,:user_zone=>params[:usertimezone],:status=>1);

      end

      if @userpurchase.save
        UserPurchase.where("address ='"+params[:address]+"'").update_all(:prev_check=>@prev_chks)
        @userpurchase = UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)
        @userpurchase = @userpurchase.to_a.map(&:serializable_hash)

        if @userpurchase.first['last_sale_date'].blank?
          owned =''
        else
          owned=Time.diff(Time.now, Time.parse(@userpurchase.first['last_sale_date']),'%y, %M')[:diff]
        end

        if @userpurchase.first['year_built'].blank?
          render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility, :results => @userpurchase, :age =>'', :owned=> owned}

        else
          render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility, :results => @userpurchase, :age=> (Time.now.year - @userpurchase.first['year_built']),:owned=> owned}
        end

      else
        render :json=> {:results => 'not datasaved'}

      end

    else

      addressexist = UserPurchase.select("*").where("user_id = ? and status = 1 and address='"+params[:address]+"'",session[:current_user_id]).limit(1)
      addressexist = addressexist.to_a.map(&:serializable_hash)

      if addressexist.first['last_sale_date'].blank?
        owned =''
      else
        owned=Time.diff(Time.now, Time.parse(addressexist.first['last_sale_date']),'%y, %M')[:diff]
      end

      if addressexist.first['year_built'].blank?
        render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility, :results => addressexist, :age =>'',:owned=> owned}
      else
        render :json=>{:zipeverythingelse=>@zee,:topinstaller=>@ztp,:toppanelbrands=>@zpb,:topinverterbrands=>@zib,:radiotype=>params[:radio],:utility=>@utility,:results => addressexist, :age=> (Time.now.year - addressexist.first['year_built']),:owned=> owned}
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
    
    if !session[:current_user_id]
      redirect_to :action => "index"
    else
      @address= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
      @address = @address.to_a.map(&:address)
      
      @lat= UserPurchase.select("lat").where("user_id = ? and status = 1",session[:current_user_id])
      @lat = @lat.to_a.map(&:lat)
      
      @long= UserPurchase.select("lng").where("user_id = ? and status = 1",session[:current_user_id])
      @long = @long.to_a.map(&:lng)

      @alltransaction= UserPurchase.select("transaction_id").where("user_id = ? and status = 1",session[:current_user_id])
      @transaction = @alltransaction.to_a.map(&:transaction_id)
    end

  end

  def viewmap_copy

    if !session[:current_user_id]
      redirect_to :action => "index"
    else
      @address= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
      @address = @address.to_a.map(&:address)

      @lat= UserPurchase.select("lat").where("user_id = ? and status = 1",session[:current_user_id])
      @lat = @lat.to_a.map(&:lat)

      @long= UserPurchase.select("lng").where("user_id = ? and status = 1",session[:current_user_id])
      @long = @long.to_a.map(&:lng)

      @alltransaction= UserPurchase.select("transaction_id").where("user_id = ? and status = 1",session[:current_user_id])
      @transaction = @alltransaction.to_a.map(&:transaction_id)
    end

  end

def viewmap_test
    
    if !session[:current_user_id]
      redirect_to :action => "index"
    else
      @address= UserPurchase.select("address").where("user_id = ? and status = 1",session[:current_user_id])
      @address = @address.to_a.map(&:address)
      
      @lat= UserPurchase.select("lat").where("user_id = ? and status = 1",session[:current_user_id])
      @lat = @lat.to_a.map(&:lat)
      
      @long= UserPurchase.select("lng").where("user_id = ? and status = 1",session[:current_user_id])
      @long = @long.to_a.map(&:lng)

      @alltransaction= UserPurchase.select("transaction_id").where("user_id = ? and status = 1",session[:current_user_id])
      @transaction = @alltransaction.to_a.map(&:transaction_id)
    end

  end


  private

  def admin_params
    params.permit(:admin_name, :admin_email_id, :admin_password, :admin_token);
  end

  def user_params
    params.permit(:first_name, :last_name, :title, :company_name, :company_address, :zip, :city, :state, :mobile_phone,:office_phone, :company_email_id,  :verification_token, :last_activity, :registration_date);
  end

  # def contact_params
    # params.permit(:full_name, :email, :mobile_phone, :about, :message);
  # end
end
