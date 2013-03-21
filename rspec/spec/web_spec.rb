require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "init" do
  it "should run a test" do
    1.should == 1
  end
end

describe "get_authorization" do
  it "should produce the hash" do
    message = "asdf123"
    publicKey = "xyz"
    privateKey = "0000"
    
    get_authorization(message, publicKey, privateKey).should == "xyz:+09f9yylLmUq7LiIB3DE6Q=="
  end
end

describe "get_response" do
  it "should return a json object" do
    result = get_json_response("/rest/json/Projects/?wfspstart=0&wfsplimit=1")
    result["Projects"]["Message"].should == "Success"
  end
end