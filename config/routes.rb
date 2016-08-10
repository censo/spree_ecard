Spree::Core::Engine.routes.append do
  # Add your extension routes here
  namespace :gateway do
    get '/ecard/:gateway_id/:order_id' => 'ecard#show'
    get '/ecard/comeback/:gateway_id/:order_id' => 'ecard#comeback', as: :ecard_comeback
    get '/ecard/error/:gateway_id/:order_id' => 'ecard#error', as: :ecard_error
  end
end
