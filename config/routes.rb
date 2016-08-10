Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :gateway do
    post '/ecard/process_payment' => 'ecard#process_payment', as: :ecard_process_payment
    get '/ecard/:gateway_id/:order_id' => 'ecard#show', as: :ecard
    get '/ecard/comeback/:gateway_id/:order_id' => 'ecard#comeback', as: :ecard_comeback
    get '/ecard/error/:gateway_id/:order_id' => 'ecard#error', as: :ecard_error
  end
end
