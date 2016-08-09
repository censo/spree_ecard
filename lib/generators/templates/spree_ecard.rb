SpreeEcard.configure do |config|
  config.currency = '985' # PLN is a default one
  config.country = '616' # PL is a default country
  config.language = 'PL'
  config.charset = 'UTF-8'
  config.autodeposit = '1'
  config.hashalgorithm = 'MD5'
  config.transparentpages = '1'
  config.paymenttype = 'ALL'

  config.merchantid = 'ECARD_MERCHANT_ID'
  config.password = 'PASSWORD'
end