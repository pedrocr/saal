def SAAL::do_http_get(host, port, path, user, pass, timeout)
  begin
    http = Net::HTTP.new(host,port)
    # Timeout faster when the other side doesn't respond
    http.open_timeout = timeout
    http.read_timeout = timeout
    req = Net::HTTP::Get.new(path)
    req.basic_auth user, pass if user && path
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
