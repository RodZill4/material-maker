extends HTTPRequest


export var website_address : String = "http://localhost:3000"

var cookies : PoolStringArray = PoolStringArray()


signal return_request_result(data)


func _ready():
	pass # Replace with function body.

func request(path : String, custom_headers: PoolStringArray = PoolStringArray(), ssl_validate_domain: bool = true, method = 0, request_data_raw: String = "") -> int:
	var headers = PoolStringArray()
	headers.append_array(custom_headers)
	headers.append("Cookie: %s" % cookies.join("; "))
	return .request(website_address+path, headers, true, method, request_data_raw)

func do_request(path : String, custom_headers: PoolStringArray = PoolStringArray(), ssl_validate_domain: bool = true, method = 0, request_data_raw: String = "") -> Dictionary:
	var error = request(path, custom_headers, true, method, request_data_raw)
	if error != OK:
		return { error=error }
	var return_value = yield(self, "return_request_result")
	return return_value

func split_headers(headers : PoolStringArray) -> Dictionary:
	var rv : Dictionary = {}
	for h in headers:
		var s = h.split(":", true, 1)
		var n : String = s[0].to_lower()
		var v : String = s[1].strip_edges()
		if n == "set-cookie":
			for c in v.split("; "):
				var found : bool = false
				for i in range(cookies.size()):
					if c.split("=", true, 0)[0] == cookies[i].split("=", true, 0)[0]:
						cookies[i] = c
						found = true
						break
				if !found:
					cookies.append(c)
		else:
			rv[n] = v
	return rv

func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	match response_code:
		200:
			split_headers(headers)
			emit_signal("return_request_result", { result=result, response_code=response_code, headers=headers, body=body.get_string_from_ascii() })
		302:
			# Redirection
			var loc = ""
			var header_dict = split_headers(headers)
			if header_dict.has("location"):
				request(header_dict.location)
		_:
			emit_signal("return_request_result", { error=FAILED, response_code=response_code })
