require 'digest/md5'
module Spree
  class Gateway::EcardController < Spree::BaseController
    skip_before_filter :verify_authenticity_token, :only => [:comeback, :complete]
    
    # Show form ecard for pay
    def show
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
    
    def error
      @order = Order.find(params[:order_id])
    end
    
  
    # Result from ecard
    def comeback
      # @order = Order.find(params[:order_id])
      # @gateway = @order && @order.payments.first.payment_method
      # @response = ecard_verify(@gateway,@order,params)
      # @amount = 100.0
      # @amount = params[:p24_kwota].to_f/100
      # result = @response.split("\r\n")

      # if result[1] == "TRUE"
      #   ecard_payment_success(@amount)
      #   redirect_to gateway_ecard_complete_path(:order_id => @order.id, :gateway_id => @gateway.id)
      # else
      #   redirect_to gateway_ecard_error_path(:gateway_id => @gateway.id, :order_id => @order.id, :error_code => result[2], :error_descr => result[3])
      # end
    end
    
    # complete the order
    def complete    
      @order = Order.find(params[:order_id])
      
      session[:order_id]=nil
      if @order.state == "complete"
        redirect_to order_url(@order, {:checkout_complete => true, :order_token => @order.token}), :notice => I18n.t("payment_success")
      else
        redirect_to order_url(@order)
      end
    end
    
    private
  
      def generate_ecard_hash
        string_to = "#{@gateway.merchantid}#{@order.number}
                     #{@gateway.ecard_amount(@order.total)}#{@gateway.currency}#{@order.line_items.map(&:name).join(', ')}
                     #{@order.try(:bill_address).try(:firstname)}#{@order.try(:bill_address).try(:lastname)}#{@gateway.autodeposit}
                     #{@gateway.paymenttype}#{@link_fail}
                     #{@link_ok}
                     #{SpreeEcard.configuration.password}"
        string_to_hash = string_to.encode("UTF-8")
        Digest::MD5.hexdigest(string_to_hash)
      end

      def link_ok
        gateway_ecard_comeback_url(:gateway_id => @gateway.id, :order_id => @order.id)
        'www.ruch.pl'
      end

      def link_fail
        gateway_ecard_error_url(:gateway_id => @gateway.id,:order_id => @order.id)
        'www.ruch.pl'
      end
    
      # Completed payment process
      def ecard_payment_success(amount)
        @order.payment.started_processing
        if @order.total.to_f == amount.to_f      
          @order.payment.complete     
        end    
        
        @order.finalize!
        
        @order.next
        @order.next
        @order.save
      end
    
  end
end


