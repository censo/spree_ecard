module Spree
  CheckoutController.class_eval do

    before_filter :redirect_for_ecard, :only => :update

    private

    def redirect_for_ecard
      return unless params[:state] == "payment"
      return if params[:order].blank? || params[:order][:payments_attributes].blank?

      payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])

      if payment_method && payment_method.kind_of?(PaymentMethod::Ecard)
        redirect_to gateway_ecard_path(:gateway_id => payment_method.id, :order_id => @order.id)
      end
    end

  end
end