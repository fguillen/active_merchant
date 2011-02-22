module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaysafeGateway < Gateway

      OUTPUT_FORMAT = 'xml_v1'

      # endpoints
      BASE_URL = "https://shops.%s.at.paysafecard.com/pscmerchant/%s"
      CUSTOMER_BASE_URL = "https://customer.%s.at.paysafecard.com/psccustomer/GetCustomerPanelServlet"

      # test actions
      INITIALIZE_TEST_ACTION = 'InitializeMerchantTestDataServlet'

      # real actions
      AUTHORIZE_ACTION = "CreateDispositionServlet"
      CHECK_TRANSACTION_ACTION = "GetDispositionStateServlet"
      CAPTURE_ACTION = "DebitServlet"

      # disposition statuses
      DISPOSITION_CREATED = 'C'
      DISPOSITION_DISPOSED = 'D'
      DISPOSITION_EXPIRED = 'X'

      def initialize(options = {})
        requires!(options, :merchant_id, :business_type, :pem, :pem_password, :ca_file, :currency)
        @options = options
        super
      end

      def initialize_merchant_data
        raise StandardError, "Can only initialize merchant test data in test mode" unless test?
        post = {}
        add_boilerplate_info(post)
        commit(INITIALIZE_TEST_ACTION, post)
      end

      def authorize(options = {})
        requires!(options, :subid, :amount, :return_url, :cancel_return_url)
        post = {}
        add_boilerplate_info(post)
        add_transaction_data(post, options)
        add_purchase_data(post, options)
        add_ok_urls(post, options)

        commit(AUTHORIZE_ACTION, post)
      end

      def check_transaction_status(options)
        requires!(options, :subid)
        post = {}

        add_boilerplate_info(post)
        add_transaction_data(post, options)

        commit(CHECK_TRANSACTION_ACTION, post)
      end

      def capture(options = {})
        requires!(options, :subid, :amount)
        post = { :close => 1 }
        add_boilerplate_info(post)
        add_transaction_data(post, options)
        add_purchase_data(post, options)

        commit(CAPTURE_ACTION, post)
      end

      def redirect_url(options = {})
        requires!(options, :subid, :amount, :language)
        customer_url + "?currency=#{@options[:currency]}&mid=#{@options[:merchant_id]}&mtid=#{options[:subid]}&amount=#{ "%.2f" % options[:amount]}&language=#{options[:language]}"
      end

      private

      def add_boilerplate_info(post)
        post[:mid] = @options[:merchant_id]
        post[:outputFormat] = OUTPUT_FORMAT
      end

      def add_transaction_data(post, options)
        post[:mtid] = options[:subid]
      end

      def add_purchase_data(post, options)
        post[:currency] = @options[:currency]
        post[:amount] = '%.2f' % options[:amount]
        post[:businesstype] = @options[:business_type]
      end

      def add_ok_urls(post, options)
        post[:okurl] = options[:return_url]
        post[:nokurl] = options[:cancel_return_url]
      end

      def commit(action, parameters)
        response = parse( ssl_post( api_url(action), post_data(parameters) ) )

        Response.new(response['errCode'] == '0', response['errMessage'], response,
          :authorization => response["MTID"],
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

      def api_url(action)
        merchant_id = test? ? 'test' : options[:merchant_id]
        BASE_URL % [ merchant_id, action ]
      end

      def customer_url
        merchant_id = test? ? 'test' : options[:merchant_id]
        CUSTOMER_BASE_URL % merchant_id
      end
    end
  end
end
