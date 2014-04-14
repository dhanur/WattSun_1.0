class HomesController < ApplicationController
skip_before_filter :verify_authenticity_token  
  def index
 
  end
  
  def create
   @user = User.new(user_params)
        @user.registration_date = Time.now
          
      if @user.save
          Emailer.new_record_notification(params[:work_email]).deliver
          redirect_to :action => "index"
      else
       render :json =>"something wrong"       
      end   
  
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

 
  def login
    
    @user=User.where(username: params[:username]).take
    if(@user && @user.password==params[:password])
        session[:current_user_id] =@user.id
           
            render :json =>session[:current_user_id]
         
    else
            render :json =>"something wrong"
    end
  end

  def logout
     session[:current_user_id] = nil   
     render :json => { :message => "You are logout"}
  end      
          
  end
  end
  
  
  def viewmap
       @streetaddress=params[:address];
  end
  
   private
    def user_params
       params.permit(:first_name, :last_name, :company_name,:title, :work_email,:mobile, :registration_date);
    end
end
