require 'uri'
require 'net/http'
require 'net/http/digest_auth'

def SAAL::do_http_get(host, port, path, user, pass, timeout)
  begin
    http = Net::HTTP.new(host,port)
    # Timeout faster when the other side doesn't respond
    http.open_timeout = timeout
    http.read_timeout = timeout
    req = Net::HTTP::Get.new(path)
    req.basic_auth(user, pass) if user && pass
    response = http.request(req)
    if response.code != "200"
      #$stderr.puts "ERROR: Code #{response.code}"
      #$stderr.puts response.body
      return nil
    end
    return response
  rescue Exception
    return nil
  end
end

def SAAL::do_http_get_digest(host, port, path, user, pass, timeout)
  begin
    uri = URI.parse "http://#{host}:#{port}/#{path}"
    digest_auth = Net::HTTP::DigestAuth.new
    uri.user = user
    uri.password = pass
    http = Net::HTTP.new(host,port)
    # Timeout faster when the other side doesn't respond
    http.open_timeout = timeout
    http.read_timeout = timeout
    req = Net::HTTP::Get.new(path)
    response = http.request(req)
    if response.code == "401" && user && pass
      auth = digest_auth.auth_header uri, response['www-authenticate'], 'GET'
      req.add_field 'Authorization', auth
      response = http.request(req)
    end
    if response.code != "200"
      #$stderr.puts "ERROR: Code #{response.code}"
      #$stderr.puts response.body
      return nil
    end
    return response
  rescue Exception
    return nil
  end
end
