require "nokogiri"
require "curb"

query = {
  "K01"             => "WINQ000",
  "DFH_STATE_TOKEN" => "abvdwoan",
  "M00_DIN_FLD1I"   => "12",
  "M00_DIN_FLD2I"   => "A",
  "M00_DIN_FLD3I"   => "0001"
}

request = Curl::Easy.http_post("http://nysdoccslookup.doccs.ny.gov/GCA00P00/WIQ1/WINQ000",
                               query.map { |k, v| Curl::PostField.content(k, v) })

begin
  request.perform
rescue e => Curl::Err
  puts "There was an error with the HTTP request."
  puts e.inspect
else
  puts request.body_str
end

