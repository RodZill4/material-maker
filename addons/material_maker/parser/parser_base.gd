extends RefCounted

# Lexer
var lexer_regexs : Array = []

# Parser
var rules : Array
var actions : Array
var gotos : Array

class Token:
	var type : String
	var value
	var pos_begin : int
	var pos_end : int
	
	func _init(t, v, b, e):
		type = t
		value = v
		pos_begin = b
		pos_end = e
	
	func _to_string():
		return "token(%s, %s, %d, %d)" % [ type, str(value), pos_begin, pos_end ]

class StackElement:
	var state : int
	var token : Token
	
	func _init(s, t):
		state = s
		token = t
	
	func _to_string():
		return "( "+str(state)+", "+str(token)+" )"

func init_lexer(regexs : Array):
	for r in regexs:
		var regex = RegEx.new()
		regex.compile(r.regex)
		lexer_regexs.push_back({ type=r.type, regex=regex })

func create_token(type : String, value, pos_begin : int, pos_end : int) -> Token:
	return Token.new(type, value, pos_begin, pos_end)

func lex(s : String) -> Array:
	var position : int = 0
	var tokens : Array = []
	while s.length() > 0:
		var found : bool = false
		for r in lexer_regexs:
			var regex_match : RegExMatch = r.regex.search(s)
			if regex_match != null:
				var pos_begin = position
				var length : int = regex_match.strings[0].length()
				position += length
				if r.type != "ignore":
					tokens.push_back(create_token(r.type, s.left(length), pos_begin, position-1))
				s = s.right(-length)
				found = true
				break
		if !found:
			print("Token not found "+s.right(-position))
			break
	tokens.push_back(Token.new("$end", null, position, position))
	return tokens

func parse(s : String):
	var stack : Array = []
	var tokens : Array = lex(s)
	var state = 0
	var next_token = tokens.pop_front()
	var last_nt : String
	var penultimate_nt : String
	while true:
		if ! actions[state].has(next_token.type):
			return { status="ERROR", state=state, msg="near '%s' (expected '%s')" % [ next_token.value, "', '".join(PackedStringArray(actions[state].keys())) ], pos=next_token.pos_begin }
		var action = actions[state][next_token.type]
		match action[0]:
			"s":
				stack.push_back(StackElement.new(state, next_token))
				state = action.right(-1).to_int()
				if tokens.is_empty():
					return { status="ERROR", msg="Reached end of file", pos=next_token.pos_end+1 }
				next_token = tokens.pop_front()
			"r":
				var rule : Dictionary = rules[action.right(-1).to_int()]
				var reduce_tokens = []
				for i in rule.rule.size():
					var stack_element : StackElement = stack.pop_back()
					state = stack_element.state
					reduce_tokens.push_front(stack_element.token)
				var pos_begin = -1
				var pos_end = -1
				if ! reduce_tokens.is_empty():
					pos_begin = reduce_tokens[0].pos_begin
					pos_end = reduce_tokens[reduce_tokens.size()-1].pos_end
				var new_token : Token
				if has_method(rule.function):
					var value = callv(rule.function, reduce_tokens)
					if value == null:
						return { status="ERROR", msg="Error while building token", pos=next_token.pos_end+1 }
					new_token = Token.new(rule.nonterm, value, pos_begin, pos_end)
				elif reduce_tokens.size() == 1:
					new_token = reduce_tokens[0]
				else:
					new_token = Token.new(rule.nonterm, reduce_tokens, pos_begin, pos_end)
				stack.push_back(StackElement.new(state, new_token))
				state = gotos[state][rule.nonterm]
				penultimate_nt = last_nt
				last_nt = rule.nonterm
			_:
				return { status="OK", value=stack[0].token, non_terminal=penultimate_nt }
