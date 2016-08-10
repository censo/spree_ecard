module Spree
  class PaymentMethod::Ecard < PaymentMethod
  
    PREFERENCES = [:currency, :language, :merchantid, :country, :charset, :autodeposit, :hashalgorithm, :transparentpages, :paymenttype]
    
    def ecard_amount(amount)
      (amount*100.00).to_i.to_s #total amount * 100
    end

    def ecard_number(order_number)
      order_number.gsub('R','')
    end

    PREFERENCES.each do |meth|
      define_method("#{meth.to_s}") { SpreeEcard.configuration.send(meth) }
    end
  
  end
end

