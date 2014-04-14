Rails.configuration.stripe = {
  :publishable_key => ENV['pk_live_frgzJTSq0tizdpyJCJli9bgN'],
  :secret_key      => ENV['sk_live_dhhfUUyfrAYAbxdBAZ10JrAD']
}

Stripe.api_key = "sk_live_dhhfUUyfrAYAbxdBAZ10JrAD"
Stripe.api_version = "2014-03-13"