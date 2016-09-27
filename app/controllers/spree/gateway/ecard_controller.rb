require 'digest/md5'
module Spree
  class Gateway::EcardController < Spree::BaseController

    skip_before_filter :verify_authenticity_token, :only => [:comeback, :complete]

    # Show form ecard for pay
    def show
      @order = Order.find(params[:order_id])
      if params[:gateway_id]
        @gateway = @order.available_payment_methods.find { |x| x.id == params[:gateway_id].to_i }
        @order.payments.destroy_all
        @ecard_hash = generate_ecard_hash
        @link_ok = link_ok

        if payment_success(@gateway)
          @bill_address, @ship_address = @order.bill_address, (@order.ship_address || @order.bill_address)
        end
      end
    end

    def process_payment
      Rails.logger.info "[ECARD] payment service params:\n#{params.inspect}\n\n"

      order_id = params['ORDERNUMBER']
      order = Spree::Order.find_by(number: order_id)

      if order
        Rails.logger.info "[ECARD] Found order with number [#{order_id}]"
        if paid_status?(params)
          ecard_payment_success(order)
        end
      else
        Rails.logger.error "[ECARD] Cannot find order with number [#{order_id}]"
      end

      render nothing: true, status: :ok
    end

    # Result from ecard
    def comeback
      order = Spree::Order.find(params[:order_id])

      session[:order_id] = nil

      if order.state == "complete"
        redirect_to order_url(order), :notice => I18n.t("payment_success")
      else
        redirect_to order_url(order)
      end
    end

    private

    ## verifies if parameters values indicate valid payment for order
    def paid_status?(params)
      # Parameters: {"MERCHANTNUMBER"=>"10000002", "ORDERNUMBER"=>"26", "COMMTYPE"=>"ACCEPTPAYMENT", "PREVIOUSSTATE"=>"payment_pending", "CURRENTSTATE"=>"payment_deposited", "PAYMENTTYPE"=>"1", "EVENTTYPE"=>"1", "PAYMENTNUMBER"=>"1", "APPROVALCODE"=>"RMIDNK", "VALIDATIONCODE"=>"000", "BIN"=>"444444", "AUTHTIME"=>"2012-10-26 11:47:43.79", "TYPE"=>"22", "WITHCVC"=>"YES", "CURRENCY"=>"", "COUNTRY"=>"", "BRAND"=>"VISA"}
      %w{payment_deposited payment_closed transfer_closed}.include? params['CURRENTSTATE']
    end

    def generate_ecard_hash
      string_to = "#{@gateway.merchantid}#{@gateway.ecard_number(@order.number)}#{@gateway.ecard_amount(@order.total)}#{@gateway.currency}#{@gateway.ecard_desc(@order)}#{@gateway.first_name(@order)}#{@gateway.last_name(@order)}#{@gateway.autodeposit}#{@gateway.paymenttype}#{link_ok}#{SpreeEcard.configuration.password}"
      string_to_hash = string_to.encode("UTF-8")
      Digest::MD5.hexdigest(string_to_hash)
    end

    def link_ok
      gateway_ecard_comeback_url(:gateway_id => @gateway.id, :order_id => @order.id)
    end

    # Completed payment process
    def ecard_payment_success(order)
      gateway = Spree::PaymentMethod.find_by(type: "Spree::PaymentMethod::Ecard")
      payment = order.payments.where(payment_method_id: gateway.id).where(state: 'checkout').first
      payment.update_attribute(:amount, order.total)
      payment.started_processing
      payment.complete
      payment.order.finalize!
      payment.order.next!
    end

    def payment_success(payment_method)
      payment = @order.payments.build(
          payment_method_id: payment_method.id,
          amount: @order.total,
          state: 'checkout'
      )

      unless payment.save
        flash[:error] = payment.errors.full_messages.join("\n")
        redirect_to checkout_state_path(@order.state) and return
      end

      payment.pend!
    end

  end
end


