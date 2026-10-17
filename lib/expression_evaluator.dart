class ExpressionEvaluator {
  static double? evaluate(String expression) {
    try {
      // Remove all spaces
      expression = expression.replaceAll(' ', '');
      
      // Replace display symbols with standard operators
      expression = expression.replaceAll('×', '*');
      expression = expression.replaceAll('÷', '/');
      
      // Validate parentheses
      if (!_validateParentheses(expression)) {
        return null;
      }
      
      // Convert to tokens
      List<String> tokens = _tokenize(expression);
      
      // Evaluate tokens
      return _evaluateTokens(tokens);
    } catch (e) {
      return null;
    }
  }
  
  static bool _validateParentheses(String expression) {
    int count = 0;
    for (var char in expression.split('')) {
      if (char == '(') count++;
      if (char == ')') count--;
      if (count < 0) return false;
    }
    return count == 0;
  }
  
  static List<String> _tokenize(String expr) {
    List<String> tokens = [];
    String current = '';
    
    for (int i = 0; i < expr.length; i++) {
      String char = expr[i];
      
      if (char == '(' || char == ')' || char == '%') {
        if (current.isNotEmpty) {
          tokens.add(current);
          current = '';
        }
        tokens.add(char);
      } else if (['+', '-', '*', '/'].contains(char)) {
        if (current.isNotEmpty) {
          tokens.add(current);
          current = '';
        }
        tokens.add(char);
      } else {
        current += char;
      }
    }
    
    if (current.isNotEmpty) {
      tokens.add(current);
    }
    
    return tokens;
  }
  
  static double _evaluateTokens(List<String> tokens) {
    if (tokens.isEmpty) {
      throw Exception('Empty expression');
    }
    
    // Handle parentheses recursively
    while (tokens.contains('(')) {
      int openIndex = tokens.lastIndexOf('(');
      int closeIndex = -1;
      int depth = 1;
      
      for (int i = openIndex + 1; i < tokens.length; i++) {
        if (tokens[i] == '(') depth++;
        if (tokens[i] == ')') {
          depth--;
          if (depth == 0) {
            closeIndex = i;
            break;
          }
        }
      }
      
      if (closeIndex == -1) {
        throw Exception('Mismatched parentheses');
      }
      
      List<String> subExpr = tokens.sublist(openIndex + 1, closeIndex);
      double subResult = _evaluateTokens(subExpr);
      
      tokens = [
        ...tokens.sublist(0, openIndex),
        subResult.toString(),
        ...tokens.sublist(closeIndex + 1),
      ];
    }
    
    // Attach postfix percent signs to their operand: ['50', '%'] -> ['50%']
    List<String> merged = [];
    for (var token in tokens) {
      if (token == '%') {
        if (merged.isEmpty || _isOperator(merged.last)) {
          throw Exception('Percent without operand');
        }
        merged[merged.length - 1] += '%';
      } else {
        merged.add(token);
      }
    }
    tokens = merged;
    
    // Handle unary minus at the start
    if (tokens.length >= 2 && tokens[0] == '-') {
      tokens = [_negate(tokens[1]), ...tokens.sublist(2)];
    }
    
    // Process unary minus after operators
    for (int i = 1; i < tokens.length - 1; i++) {
      if (tokens[i] == '-' && 
          ['+', '-', '*', '/'].contains(tokens[i - 1])) {
        // Unary minus
        tokens = [
          ...tokens.sublist(0, i),
          _negate(tokens[i + 1]),
          ...tokens.sublist(i + 2),
        ];
        i--;
      }
    }
    
    // Evaluate multiplication and division (left to right)
    int i = 1;
    while (i < tokens.length) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        double left = _parseOperand(tokens[i - 1]);
        double right = _parseOperand(tokens[i + 1]);
        double result;
        
        if (tokens[i] == '*') {
          result = left * right;
        } else {
          if (right == 0) throw Exception('Division by zero');
          result = left / right;
        }
        
        tokens = [
          ...tokens.sublist(0, i - 1),
          result.toString(),
          ...tokens.sublist(i + 2),
        ];
        i = 0; // Reset to check from beginning
      } else {
        i += 2;
      }
    }
    
    // Evaluate addition and subtraction (left to right)
    i = 1;
    while (i < tokens.length) {
      if (tokens[i] == '+' || tokens[i] == '-') {
        double left = _parseOperand(tokens[i - 1]);
        double right = _parseOperand(tokens[i + 1]);
        // A percentage added or subtracted is taken of the left side:
        // 200+10% -> 200+20
        if (tokens[i + 1].endsWith('%')) {
          right = left * right;
        }
        double result = tokens[i] == '+' ? left + right : left - right;
        
        tokens = [
          ...tokens.sublist(0, i - 1),
          result.toString(),
          ...tokens.sublist(i + 2),
        ];
        i = 0; // Reset to check from beginning
      } else {
        i += 2;
      }
    }
    
    if (tokens.isEmpty) {
      throw Exception('Empty expression after evaluation');
    }
    
    if (tokens.length != 1) {
      throw Exception('Malformed expression');
    }
    
    return _parseOperand(tokens[0]);
  }
  
  static bool _isOperator(String token) {
    return ['+', '-', '*', '/'].contains(token);
  }
  
  static String _negate(String token) {
    return token.startsWith('-') ? token.substring(1) : '-$token';
  }
  
  // Parses a number, dividing by 100 for each trailing percent sign
  static double _parseOperand(String token) {
    double value = double.parse(token.replaceAll('%', ''));
    for (int i = token.length - 1; i >= 0 && token[i] == '%'; i--) {
      value /= 100;
    }
    return value;
  }
}
