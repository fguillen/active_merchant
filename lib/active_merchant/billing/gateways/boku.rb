module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BokuGateway < Gateway

      # endpoints
      BASE_URL = "https://api2.boku.com/billing/request"

      # real actions
      AUTHORIZE_ACTION = "prepare"
      GET_PRICES_ACTION = "price"


      def initialize(options = {})
        requires!(options, :merchant_id, :service_id, :password)
        @options = options
        super
      end

      def authorize(options = {})
        requires!(options, :mtid, :amount, :currency, :fwdurl, :desc, :country)
        post = {}
        add_boilerplate_info(post)
        add_purchase_data(post, options)
        add_fwd_url(post, options)
        commit(AUTHORIZE_ACTION, post)
      end

      def get_prices(options = {})
        requires!(options, :country, :reference_currency)
        post = {}
        add_boilerplate_info(post)
        add_prices_info(post, options)
        commit(GET_PRICES_ACTION, post)
      end

      private

      def add_boilerplate_info(post)
        post[:'merchant-id'] = @options[:merchant_id]
        post[:'service-id'] = @options[:service_id]
        post[:'password'] = @options[:password]
      end

      def add_verify_data(post, options)
        post[:'trx-id'] = options[:trx_id]
      end

      def add_purchase_data(post, options)
        post[:currency] = options[:currency]
        post[:'price-inc-salestax'] = options[:amount]
        post[:country] = options[:country]
      end

      def add_prices_info(post, options)
        post[:'reference-currency'] = options[:reference_currency]
        post[:country] = options[:country]
      end

      def add_fwd_url(post, options)
        post[:fwdurl] = options[:fwdurl]
      end

      def commit(action, parameters)
        parameters.update(:action => action)
        xml = ssl_post(api_url, post_data(parameters) )
        response = parse(xml)

        Response.new(response['result-code'] == '0', response['result-msg'], {:hash => response, :xml => xml},
          :authorization => response["trx-id"],
          :test => test?
        )
      end

      def post_data(paramaters = {})
        paramaters.map {|key,value| "#{key}=#{CGI.escape(value.to_s)}"}.join("&")
      end

      def parse(xml)
        doc = REXML::Document.new(xml)
        hash = doc.root.elements.inject(nil, {}) do |a, node|
          a[node.name] = node.text
          a
        end
        hash
      end

      def api_url
        BASE_URL
      end
    end
  end
end
