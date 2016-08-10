require 'digest/md5'
module Spree
  class Gateway::EcardController < Spree::BaseController
    skip_before_filter :verify_authenticity_token, :only => [:comeback, :complete]
    
    # Show form ecard for pay
    def show
      binding.pry
      @order = Order.find(params[:order_id])
      if params[:gateway_id]
        @gateway = @order.available_payment_methods.find{|x| x.id == params[:gateway_id].to_i }
        @order.payments.destroy_all
        payment = @order.payments.create!(:amount => 0, :payment_method_id => @gateway.id)

        @ecard_hash = generate_ecard_hash
        @link_ok = link_ok
        @link_fail = link_fail
    
        if @order.blank? || @gateway.blank?
          flash[:error] = I18n.t("invalid_arguments")
          redirect_to :back
        else
          @bill_address, @ship_address = @order.bill_address, (@order.ship_address || @order.bill_address)
        end
      end
    end
  
    # Result from ecard
    def comeback
      order = Order.find(params[:order_id])
      gateway = Spree::PaymentMethod.find(params[:gateway_id])
      ecard_payment_success(order, gateway)
      
      session[:order_id] = nil
      if @order.state == "complete"
        redirect_to order_url(order), :notice => I18n.t("payment_success")
      else
        redirect_to order_url(order)
      end
    end

    def error
      @order = Order.find(params[:order_id])
    end
    
    private
  
      def generate_ecard_hash
        string_to = "#{@gateway.merchantid}#{@gateway.ecard_number(@order.number)}#{@gateway.ecard_amount(@order.total)}#{@gateway.currency}#{@order.line_items.map(&:name).join(', ')}#{@order.try(:bill_address).try(:firstname)}#{@order.try(:bill_address).try(:lastname)}#{@gateway.autodeposit}#{@gateway.paymenttype}#{link_fail}#{link_ok}#{SpreeEcard.configuration.password}"
        string_to_hash = string_to.encode("UTF-8")
        Digest::MD5.hexdigest(string_to_hash)
      end

      def link_ok
        gateway_ecard_comeback_url(:gateway_id => @gateway.id, :order_id => @order.id)
      end

      def link_fail
        gateway_ecard_error_url(:gateway_id => @gateway.id,:order_id => @order.id)
      end
    
      # Completed payment process
      def ecard_payment_success(order, gateway)
        payment = @order.payments.where(payment_method_id: @gateway.id).where(state: 'checkout').first
        payment.started_processing
        payment.complete
        @order.finalize!
        @order.next
        @order.next
        @order.save
        binding.pry
      end
    
  end
end


