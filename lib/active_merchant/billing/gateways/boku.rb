module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BokuGateway < Gateway

      require "digest/md5"

      # endpoints
      BASE_URL = "https://api2.boku.com/billing/request"

      # real actions
      AUTHORIZE_ACTION = "prepare"
      VERIFY_ACTION = "verify-trx-id"

      def initialize(options = {})
        requires!(options, :merchant_id, :service_id, :api_key)
        @options = options
        super
      end

      def authorize(options = {})
        requires!(options, :mtid, :amount, :currency, :desc, :country)
        post = {}
        add_boilerplate_info(post)
        add_purchase_data(post, options)
        add_fwd_url(post, options)
        commit(AUTHORIZE_ACTION, post)
      end

      def verify(options = {})
        requires!(options, :trx_id)
        post = {}
        add_boilerplate_info(post)
        add_verify_data(post, options)
        commit(VERIFY_ACTION, post)
      end

      private

      def add_boilerplate_info(post)
        post[:'merchant-id'] = @options[:merchant_id]
        post[:'service-id'] = @options[:service_id]
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
        post[:fwdurl] = options[:fwdurl] if options[:fwdurl]
      end

      def commit(action, parameters)
        parameters.update(:action => action)
        xml = ssl_post(api_url, post_data(parameters) )
        response = parse(xml)

        Response.new(response['result-code'] == '0', response['result-msg'],  response,
          :authorization => response["trx-id"],
          :test => test?
        )
      end

      def post_data(paramaters = {})
        paramaters.update(:timestamp => Time.now.utc.to_i)
        params = paramaters.map {|key,value| "#{key}=#{CGI.escape(value.to_s)}"}.join("&")
        sig = Digest::MD5.hexdigest(paramaters.stringify_keys.sort.map {|key,value| "#{key}#{value}"}.join + @options[:api_key])
        params + "&sig=" + sig
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
