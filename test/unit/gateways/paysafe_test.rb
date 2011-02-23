#from: https://github.com/stopdropandrew/active_merchant
require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class PaysafeTest < Test::Unit::TestCase
  def setup
    @gateway = PaysafeGateway.new(fixtures(:paysafe))

    @options = { 
      :currency => 'EUR',
      :transaction_id => 'cool-trans',
      :amount => 20,
      :return_url => 'http://www.kongregate.com/paysafe?ok=true',
      :cancel_return_url => 'http://www.kongregate.com/paysafe?ok=false',
      :subid => "test-mtid"
      #TODO: return_url -> ok_url, subid => mtid
    }
  end
  
  def test_successful_authorize
    @gateway.expects(:ssl_post).returns(successful_authorize_response)
    
    assert response = @gateway.authorize(@options)
    assert_instance_of Response, response
    assert_success response
  end
  
  def test_authorizing_duplicate_transaction_id_fails
    @gateway.expects(:ssl_post).returns(failed_authorize_response)
    
    assert response = @gateway.authorize(@options)
    assert_instance_of Response, response
    assert_failure response
    assert_equal '2001', response.params['errCode']
    assert_equal 'The Transaction <testid, cool-trans> already exists.', response.message
  end
  
  def test_get_transaction_state
    @gateway.expects(:ssl_post).returns(successful_get_transaction_state_response)
    
    assert response = @gateway.authorize(@options)
    assert_instance_of Response, response
    assert_success response
    
    assert_equal PaysafeGateway::DISPOSITION_CREATED, response.params['TransactionState']
  end
  
  def test_successful_capture
    @gateway.expects(:ssl_post).returns(successful_capture_response)
    
    assert response = @gateway.authorize(@options)
    assert_instance_of Response, response
    assert_success response
  end
  
  def test_successful_capture
    @gateway.expects(:ssl_post).returns(already_captured_capture_response)
    
    assert response = @gateway.authorize(@options)
    assert_instance_of Response, response
    assert_failure response
  end
  
  private

  def successful_authorize_response
    <<-RESPONSE
    <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
    <paysafecard:PaysafecardTransaction xmlns:paysafecard="http://www.paysafecard.com/MerchantApi" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.paysafecard.com/MerchantApi MerchantApi_v1.xsd">
      <actionKey>com.psc.pay.CreateDispositionAction_1272988103184_24.22.29.22</actionKey>
      <txCode>0</txCode>
      <txMessage></txMessage>
      <MID>testid</MID>
      <MTID>cool-trans</MTID>
      <errCode>0</errCode>
      <errMessage></errMessage>
    </paysafecard:PaysafecardTransaction>
    RESPONSE
  end
  
  def failed_authorize_response
    <<-RESPONSE
    <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
    <paysafecard:PaysafecardTransaction xmlns:paysafecard="http://www.paysafecard.com/MerchantApi" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.paysafecard.com/MerchantApi MerchantApi_v1.xsd">
      <actionKey>com.psc.pay.CreateDispositionAction_1272991664088_24.22.29.22</actionKey>
      <txCode>1</txCode>
      <txMessage>The Transaction &lt;testid, cool-trans&gt; already exists.</txMessage>
      <MID>testid</MID>
      <MTID>cool-trans</MTID>
      <errCode>2001</errCode>
      <errMessage>The Transaction &lt;testid, cool-trans&gt; already exists.</errMessage>
    </paysafecard:PaysafecardTransaction>
    RESPONSE
  end
  
  def successful_get_transaction_state_response
    <<-RESPONSE
    <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
    <paysafecard:PaysafecardTransaction xmlns:paysafecard="http://www.paysafecard.com/MerchantApi" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.paysafecard.com/MerchantApi MerchantApi_v1.xsd">
      <actionKey>com.psc.pay.GetDispositionStateAction_1272996216356_24.22.29.22</actionKey>
      <txCode>0</txCode>
      <txMessage></txMessage>
      <MID>testid</MID>
      <MTID>cool-trans</MTID>
      <Amount>10.00</Amount>
      <Currency>ARS</Currency>
      <TransactionState>C</TransactionState>
      <errCode>0</errCode>
      <errMessage></errMessage>
    </paysafecard:PaysafecardTransaction>
    RESPONSE
  end

  def successful_capture_response
    <<-RESPONSE
    <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
    <paysafecard:PaysafecardTransaction xmlns:paysafecard="http://www.paysafecard.com/MerchantApi" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.paysafecard.com/MerchantApi MerchantApi_v1.xsd">
      <actionKey>com.psc.pay.DebitAction_1272997321935_24.22.29.22</actionKey>
      <txCode>0</txCode>
      <txMessage></txMessage>
      <MID>testid</MID>
      <MTID>cool-trans</MTID>
      <errCode>0</errCode>
      <errMessage></errMessage>
    </paysafecard:PaysafecardTransaction>
    RESPONSE
  end
  
  def already_captured_capture_response
    <<-RESPONSE
    <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
    <paysafecard:PaysafecardTransaction xmlns:paysafecard="http://www.paysafecard.com/MerchantApi" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.paysafecard.com/MerchantApi MerchantApi_v1.xsd">
      <actionKey>com.psc.pay.DebitAction_1272997548988_24.22.29.22</actionKey>
      <txCode>1</txCode>
      <txMessage>Transaction (testid/cool-trans) is in invalid state null, expected is null or null.</txMessage>
      <MID>testid</MID>
      <MTID>cool-trans</MTID>
      <errCode>2017</errCode>
      <errMessage>Transaction (testid/cool-trans) is in invalid state null, expected is null or null.</errMessage>
    </paysafecard:PaysafecardTransaction>
    RESPONSE
  end
end
