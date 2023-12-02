require 'stripe'
require 'sinatra'
require 'dotenv'
require 'pry-byebug'
require './config_helper.rb'

# Copy the .env.example in the root into a .env file in this folder
Dotenv.load
ConfigHelper.check_env!

# For sample support and debugging, not required for production:
Stripe.set_app_info(
  'stripe-samples/accept-a-payment/payment-element',
  version: '0.0.2',
  url: 'https://github.com/stripe-samples'
)
Stripe.api_version = '2020-08-27'
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

set :static, true
set :public_folder, File.join(File.dirname(__FILE__), ENV['STATIC_DIR'])
set :port, 4242
set :bind, '0.0.0.0'

set :views, settings.public_folder

get '/' do
  binding.pry
  @uid = params['uid']
  content_type 'text/html'
  #send_file File.join(settings.public_folder, 'index.html')

  
  erb :index
end

get '/config' do
  content_type 'application/json'

  { publishableKey: ENV['STRIPE_PUBLISHABLE_KEY'] }.to_json
end

get '/create-payment-intent' do
  binding.pry
  # Create a PaymentIntent with the amount, currency, and a payment method type.
  #
  # See the documentation [0] for the full list of supported parameters.
  #
  # [0] https://stripe.com/docs/api/payment_intents/create
  begin
    payment_intent = Stripe::PaymentIntent.create({
      amount: 5999, # Charge the customer 59.99 EUR
      automatic_payment_methods: { enabled: true, allow_redirects: 'never' }, # Configure payment methods in the dashboard.
      currency: 'twd',
      metadata: {
        "uid": "6735"
      }
    })
  rescue Stripe::StripeError => e
    halt 400,
      { 'Content-Type' => 'application/json' },
      { error: { message: e.error.message }}.to_json
  rescue => e
    halt 500,
      { 'Content-Type' => 'application/json' },
      { error: { message: e.error.message }}.to_json
  end

  # This API endpoint renders back JSON with the client_secret for the payment
  # intent so that the payment can be confirmed on the front end. Once payment
  # is successful, fulfillment is done in the /webhook handler below.
  {
    clientSecret: payment_intent.client_secret,
  }.to_json
end

