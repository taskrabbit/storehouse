require 'spec_helper'

describe Storehouse::Object do

  it 'should apply attributes properly' do
    object = Storehouse::Object.new(:status => 201, :expires_at => 2904)
    object.status.should eql(201)
    object.expires_at.should eql(2904)
  end

  it 'should produce a hash with string values' do
    h = {'Some-Header' => 'Value'}
    object = Storehouse::Object.new(:status => 201, :expires_at => 291343, :headers => h)
    expected_response = {
      'status' => '201',
      'expires_at' => '291343',
      'headers' => h.to_json
    }

    object.to_h.slice('status', 'expires_at', 'headers').should eql(expected_response)
  end

  it 'should generate the correct rack response' do
    status = 201
    headers = {'Some-Header' => 'Value'}.to_json
    content = 'body content'
    object = Storehouse::Object.new(:status => status, :headers => headers, :content => content)

    object.rack_response.should eql([
      201,
      {'Some-Header' => 'Value'},
      ['body content']
    ])
  end

end