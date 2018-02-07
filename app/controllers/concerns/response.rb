# app/controllers/concerns/response.rb
module Response
  def rot13(s)
    s.tr('A-Za-z', 'N-ZA-Mn-za-m').tr('1-9', '4-91-3')
  end
  
  def json_response(object, status = :ok)
    render json: object, status: status
  end

  def rot13_json_response_safe_encode(object, status = :ok)
    render json: rot13(object.to_json.gsub!(/\\u([0-9a-z]{4})/) {|s| [$1.to_i(16)].pack("U")}), status: status
  end

  def rot13_json_response(object, status = :ok)
    render json: rot13(object.to_json), status: status
  end
end
