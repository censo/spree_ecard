require 'digest/md5'
module Spree
  class Gateway::EcardController < Spree::BaseController

    skip_before_filter :verify_authenticity_token, :only => [:comeback, :process_payment]

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

      if order.state != "complete"
        order.next
      end

      payment = order.payments.last
      payment.started_processing!
      payment.pend!

      redirect_to order_url(order, {:checkout_complete => true})
    end

    # Ecard notification
    def process_payment
      Rails.logger.info "[ECARD] payment service params:\n#{params.inspect}\n\n"

      order_id = "R#{params['ORDERNUMBER']}"
      order = Spree::Order.find_by(number: order_id)

      begin
        if order
          Rails.logger.info "[ECARD] Found order with number [#{order_id}]"
          if success_status?(params['CURRENTSTATE'])
            ecard_payment_success(order)
          elsif fail_status?(params['CURRENTSTATE'])
            ecard_payment_fail(order)
          end
        else
          raise "[ECARD] Cannot find order with number [#{order_id}] for ecard params:\n#{params.inspect}\n\n"
        end
      rescue => e
        msg = "Unable to process incoming payment for order #{order_id}."
        Rollbar.error(e, msg)
        Rails.logger.error "#{msg} Problem is\n#{e}"
      end

      render :inline => 'OK'
    end

    private

    ## verifies if parameters values indicate valid payment for order
    def success_status?(state)
      Rails.logger.debug "[ECARD] check if success status for state #{state}"
      %w{payment_deposited payment_closed transfer_closed}.include? state
    end

    def fail_status?(state)
      Rails.logger.debug "[ECARD] check if fail status #{state}"
      %w{payment_declined payment_canceled payment_void transfer_declined transfer_canceled}.include? state
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
      Rails.logger.debug "[ECARD] going to finalize order #{order.number} with payment [#{payment.number}/#{payment.state}]"
      unless payment.completed? || payment.failed?
        payment.complete
      end
      order.next unless order.state == "complete"
    end

    def ecard_payment_fail(order)
      payment = order.payments.last
      Rails.logger.debug "[ECARD] going to fail order #{order.number} with payment [#{payment.number}/#{payment.state}]"
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

      unless @order.next
        flash[:error] = order.errors.full_messages.join("\n")
        redirect_to checkout_state_path(@order.state) and return
      end

    end

  end
end


