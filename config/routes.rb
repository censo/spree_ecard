Spree::Core::Engine.routes.append do
  # Add your extension routes here
  namespace :gateway do
    get '/ecard/complete/:gateway_id/:order_id' => 'ecard#complete', :as => :ecard_complete
    get '/ecard/:gateway_id/:order_id' => 'ecard#show', :as => :ecard
    get '/ecard/error/:gateway_id/:order_id' => 'ecard#error', :as => :ecard_error
    get '/ecard/comeback/:gateway_id/:order_id' => 'ecard#comeback', :as => :ecard_comeback
  end
end
