Wattsun::Application.routes.draw do
  
  get '/contact'  => 'high_voltage/pages#show', id: 'contact'
  get '/faqs'    => 'high_voltage/pages#show', id: 'faqs'
  get '/privacy'    => 'high_voltage/pages#show', id: 'privacy'
  get '/terms'    => 'high_voltage/pages#show', id: 'terms'
 
  
  # root :to => 'high_voltage/pages#show', id: 'index'
  # resources :homes
   root :to => "homes#index"
   get '/homes/index' => 'homes#index'   
   get '/homes/stripe' => 'homes#stripe'    
   post '/homes/entercreditinfo' => 'homes#entercreditinfo'
   post '/homes/checkpurchase' => 'homes#checkpurchase' 
   
   get '/homes/resetpasswordmessage' => 'homes#resetpasswordmessage'
   
   get '/homes/ifr' => 'homes#ifr' 
   
   post '/homes/checkuserexist' => 'homes#checkuserexist' 
   get '/homes/register_cc' => 'homes#register_cc' 
   get '/homes/passwordreset' => 'homes#passwordreset' 
   post '/homes/updatecardnumber' => 'homes#updatecardnumber'  
   post '/homes/updateplan' => 'homes#updateplan' 
   post '/homes/updatechrg' => 'homes#updatechrg' 
   get '/homes/otheraddresses' => 'homes#otheraddresses' 
   get '/homes/signup' => 'homes#signup'
   get '/homes/contact' => 'homes#contact'
   post '/homes/create' => 'homes#create'
   get '/homes/createmsg' => 'homes#createmsg'
   post '/homes/viewmap' => 'homes#viewmap'
   get '/homes/viewmap' => 'homes#viewmap'
   post '/homes/datafetch' => 'homes#datafetch'
   post '/homes/infofetch' => 'homes#infofetch'
   get '/homes/userlogin' => 'homes#userlogin'
   post '/homes/login' => 'homes#login'
   post '/homes/logout' => 'homes#logout'   
   post '/homes/adminlogout' => 'homes#adminlogout'
   get '/homes/viewmap_copy' => 'homes#viewmap_copy'   
   get  '/homes/example' => 'homes#example'
   post '/homes/changestatus' => 'homes#changestatus'
  
   get '/homes/activate' => 'homes#activate'
   post '/homes/activation' => 'homes#activation'
   get '/homes/adminlogin' => 'homes#adminlogin'
   post '/homes/adminsignin' => 'homes#adminsignin'  
   
   get '/homes/superadmin' => 'homes#superadmin' 
   post '/homes/changeadminstatus' => 'homes#changeadminstatus' 
   
    
   
   get '/homes/adminsignup' => 'homes#adminsignup'
   post '/homes/admincreate' => 'homes#admincreate'
   
       
   get '/homes/adminuserstatus' => 'homes#adminuserstatus'
   
   get '/homes/forgotpassword' => 'homes#forgotpassword'
   post '/homes/resetpassword' => 'homes#resetpassword'
   post '/homes/contactreceipt' => 'homes#contactreceipt'
   
   get '/homes/userproblem' => 'homes#userproblem'
   post '/homes/problemcreceipt' => 'homes#problemcreceipt'
   
   get '/homes/userprofile' => 'homes#userprofile'
   post '/homes/profileupdate' => 'homes#profileupdate' 
  
   get '/homes/userpayment' => 'homes#userpayment' 
   get '/homes/faq' => 'homes#faq'    
   
   get '/homes/useradminpayment' => 'homes#useradminpayment'
   
   get '/homes/purchaseitq' => 'homes#purchaseitq'   
   get '/homes/userpurchaseview' => 'homes#userpurchaseview'
         
   get '/homes/adminprofileview' => 'homes#adminprofileview'   
   get '/homes/adminpurchaseview' => 'homes#adminpurchaseview'
   
   post '/homes/viewtransction' => 'homes#viewtransction'
   
   post '/homes/singleuserview' => 'homes#singleuserview'
   
   get '/homes/adminuserprofile' => 'homes#adminuserprofile'
   post '/homes/profileupdatebyadmin' => 'homes#profileupdatebyadmin' 
  
   get '/homes/adminuserpayment' => 'homes#adminuserpayment'  
   post '/homes/singleusercredits' => 'homes#singleusercredits'   
   get '/homes/adminusernumber' => 'homes#adminusernumber'
   
   post '/homes/updatecredits' => 'homes#updatecredits'
   
   
   get '/homes/adminuserpurchaselist' => 'homes#adminuserpurchaselist'   
   get '/homes/adminuserpurchase' => 'homes#adminuserpurchase'
   
   post '/homes/singleuserviewbyadmin' => 'homes#singleuserviewbyadmin'
   post '/homes/viewtransctionbyadmin' => 'homes#viewtransctionbyadmin'
   
   post '/homes/addresspresentcheck' => 'homes#addresspresentcheck'
   
   post '/homes/alldatafetchonmarkerclick' => 'homes#alldatafetchonmarkerclick'
   post '/homes/alldatafetchonmarkernewtrans' => 'homes#alldatafetchonmarkernewtrans'  
   
   get '/homes/viewmap_test' => 'homes#viewmap_test'
   
         
   get '/homes/sales' => 'homes#sales'   
   get '/homes/salesview' => 'homes#salesview'
   post '/homes/salesviewtransaction' => 'homes#salesviewtransaction'
   
   post '/homes/viewmap_copy' => 'homes#viewmap_copy'
   get '/homes/viewmap_copy' => 'homes#viewmap_copy'
   
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
