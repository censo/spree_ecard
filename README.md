# SpreeEcard

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spree_ecard', github: 'censo/spree_ecard'
```

Then execute:

    $ bundle

Or install it yourself as:

    $ gem install spree_ecard

Finally 

    $ rails generate spree_ecard:install

## Usage

Remember to set your eCard credentials:

 - MerchantId
 - Password

Also in Spree Admin you need to add new payment method:
`Spree::PaymentMethod::Ecard`

## Inspiration

My work is patterned on:
https://github.com/matfiz/spree_przelewy24
and
https://github.com/espresse/spree_dotpay_pl_payment

## TODO

Write tests

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/censo/spree_ecard. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).