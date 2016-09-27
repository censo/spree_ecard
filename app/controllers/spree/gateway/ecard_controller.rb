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

    # Result from ecard after payment
    def comeback
      order = Spree::Order.find(params[:order_id])

      unless order.next
        flash[:error] = order.errors.full_messages.join("\n")
      end

      redirect_to order_url(order)
    end

    # Ecard notification
    def process_payment
      Rails.logger.info "[ECARD] payment service params:\n#{params.inspect}\n\n"

      order_id = params['ORDERNUMBER']
      order = Spree::Order.find_by(number: order_id)

      if order
        Rails.logger.info "[ECARD] Found order with number [#{order_id}]"
        if success_status?(params)
          ecard_payment_success(order)
        elsif fail_status?(params)
          ecard_payment_fail(order)
        end
      else
        Rails.logger.error "[ECARD] Cannot find order with number [#{order_id}] for ecard params:\n#{params.inspect}\n\n"
      end

      render nothing: true, status: :ok
    end

    private

    ## verifies if parameters values indicate valid payment for order
    def success_status?(params)
      %w{payment_deposited payment_closed transfer_closed}.include? params['CURRENTSTATE']
    end

    def fail_status?(params)
      %w{payment_declined payment_canceled payment_void transfer_declined transfer_canceled}.include? params['CURRENTSTATE']
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
      payment = order.payments.last
      unless payment.completed? || payment.failed?
        payment.complete!
        order.finalize!
      end
    end

    def ecard_payment_fail(order)
      payment = order.payments.last
      unless payment.completed? || payment.failed?
        payment.failure!
      end
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

      payment.started_processing!
      payment.pend!
    end

  end
end


