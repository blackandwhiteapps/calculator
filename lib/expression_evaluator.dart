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
      
      if (char == '(' || char == ')') {
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
    
    // Handle unary minus at the start
    if (tokens.length >= 2 && tokens[0] == '-') {
      tokens = ['-${tokens[1]}', ...tokens.sublist(2)];
    }
    
    // Process unary minus after operators
    for (int i = 1; i < tokens.length - 1; i++) {
      if (tokens[i] == '-' && 
          ['+', '-', '*', '/'].contains(tokens[i - 1])) {
        // Unary minus
        double value = -double.parse(tokens[i + 1]);
        tokens = [
          ...tokens.sublist(0, i),
          value.toString(),
          ...tokens.sublist(i + 2),
        ];
        i--;
      }
    }
    
    // Evaluate multiplication and division (left to right)
    int i = 1;
    while (i < tokens.length) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        double left = double.parse(tokens[i - 1]);
        double right = double.parse(tokens[i + 1]);
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
        double left = double.parse(tokens[i - 1]);
        double right = double.parse(tokens[i + 1]);
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
    
    return double.parse(tokens[0]);
  }
}
