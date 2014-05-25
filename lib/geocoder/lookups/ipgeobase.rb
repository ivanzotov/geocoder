require 'rexml/document'

require 'geocoder/lookups/base'
require 'geocoder/results/ipgeobase'

module Geocoder::Lookup
  class Ipgeobase < Base

    def name
      "IpGeoBase"
    end

    def query_url(query)
      "http://ipgeobase.ru:7020/geo?#{url_query_string(query)}"
    end

    private # ---------------------------------------------------------------

    def parse_raw_data(raw_data)
      encoded_data = raw_data

      if encoded_data.match(/Incorrect request|Not found/)
        return nil
      else        
        ip = REXML::Document.new(encoded_data).elements['ip-answer/ip']
              
        result = ip.elements.reduce({}){ |h, el| h[el.name] = el.text; h }
        result['ip'] = ip.attributes['value']

        result
      end
    end

    def results(query)      
      return [reserved_result(query.text)] if query.loopback_ip_address?

      begin
        return (doc = fetch_data(query)) ? [doc] : []
      rescue StandardError => err                
        raise_error(err)
        return []
      end
    end

    def reserved_result(ip)
      {
        'inetnum'     => "#{ip} - #{ip}",
        'ip'          => ip,
        'country'     => 'RU',
        'city'        => '',
        'district'    => '',       
        "lat"         => '0',
        "lng"         => '0'
      }
    end

    def query_url_params(query)
      {
        :ip => query.sanitized_text        
      }.merge(super)
    end
  end
end