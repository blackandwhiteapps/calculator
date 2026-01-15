import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/calculation_history.dart';
import 'expression_evaluator.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '';
  bool _hasError = false;

  final Box<CalculationHistory> _historyBox =
      Hive.box<CalculationHistory>('calculations');

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _clear();
      } else if (value == '⌫') {
        _backspace();
      } else if (value == '=') {
        _calculate();
      } else if (value == '(' || value == ')') {
        _handleParenthesis(value);
      } else if (['+', '-', '×', '÷'].contains(value)) {
        _handleOperation(value);
      } else if (value == '.') {
        _handleDecimal();
      } else {
        _handleNumber(value);
      }
    });
  }

  void _clear() {
    _expression = '';
    _result = '';
    _hasError = false;
  }

  void _backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _result = '';
      _hasError = false;
    }
  }

  void _handleNumber(String number) {
    if (_hasError || _result.isNotEmpty) {
      // Start new expression if there's an error or a result showing
      _expression = number;
      _hasError = false;
      _result = '';
    } else {
      _expression += number;
    }
  }

  void _handleDecimal() {
    if (_hasError || _result.isNotEmpty) {
      // Start new expression if there's an error or a result showing
      _expression = '0.';
      _hasError = false;
      _result = '';
    } else {
      // Check if current number already has a decimal
      String lastNumber = _getLastNumber();
      if (!lastNumber.contains('.')) {
        if (lastNumber.isEmpty || _expression.isEmpty || 
            ['+', '-', '×', '÷', '(', ')'].contains(_expression[_expression.length - 1])) {
          _expression += '0.';
        } else {
          _expression += '.';
        }
      }
    }
  }

  void _handleOperation(String op) {
    if (_hasError) {
      _expression = '';
      _hasError = false;
    }
    
    // If there's a result showing, start new expression with result
    if (_result.isNotEmpty) {
      _expression = _result;
      _result = '';
    }
    
    if (_expression.isEmpty) {
      if (op == '-') {
        _expression = '-';
      }
      return;
    }
    
    // Replace trailing operator
    String lastChar = _expression[_expression.length - 1];
    if (['+', '-', '×', '÷'].contains(lastChar)) {
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else {
      _expression += op;
    }
  }

  void _handleParenthesis(String paren) {
    if (_hasError) {
      _expression = '';
      _hasError = false;
    }
    
    // If there's a result showing, start new expression with result
    if (_result.isNotEmpty) {
      _expression = _result;
      _result = '';
    }
    
    if (paren == '(') {
      // Can add opening parenthesis
      if (_expression.isEmpty || ['+', '-', '×', '÷', '('].contains(
          _expression.isEmpty ? '' : _expression[_expression.length - 1])) {
        _expression += '(';
      } else {
        // Insert multiplication if needed: 2(3) -> 2×(3)
        _expression += '×(';
      }
    } else {
      // Closing parenthesis
      int openCount = _expression.split('(').length - 1;
      int closeCount = _expression.split(')').length - 1;
      
      if (openCount > closeCount) {
        String lastChar = _expression.isEmpty ? '' : _expression[_expression.length - 1];
        if (!['+', '-', '×', '÷', '('].contains(lastChar)) {
          _expression += ')';
        }
      }
    }
  }

  String _getLastNumber() {
    if (_expression.isEmpty) return '';
    
    int i = _expression.length - 1;
    while (i >= 0 && !['+', '-', '×', '÷', '(', ')'].contains(_expression[i])) {
      i--;
    }
    return _expression.substring(i + 1);
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    
    // Clean up trailing operators
    String cleanExpression = _expression;
    while (cleanExpression.isNotEmpty && 
           ['+', '-', '×', '÷'].contains(cleanExpression[cleanExpression.length - 1])) {
      cleanExpression = cleanExpression.substring(0, cleanExpression.length - 1);
    }
    
    if (cleanExpression.isEmpty) return;
    
    double? calculatedResult = ExpressionEvaluator.evaluate(cleanExpression);
    
    if (calculatedResult == null) {
      _result = 'Error';
      _hasError = true;
      return;
    }
    
    String resultStr = _formatNumber(calculatedResult);
    _result = resultStr;
    
    // Save to history (keep original expression, not the result)
    _historyBox.add(CalculationHistory(
      expression: cleanExpression,
      result: resultStr,
      timestamp: DateTime.now(),
    ));
    
    // Keep the expression for history, but display will show result
    _hasError = false;
  }

  String _formatNumber(double number) {
    if (number.isInfinite || number.isNaN) {
      return 'Error';
    }
    
    if (number % 1 == 0) {
      return number.toInt().toString();
    } else {
      String formatted = number.toStringAsFixed(10);
      // Remove trailing zeros
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
      return formatted;
    }
  }

  Widget _buildButton(String text, {bool isEquals = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isEquals ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onButtonPressed(text),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: isEquals ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Display and History Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: _buildDisplayView(),
              ),
            ),
            // Button Grid - positioned at bottom
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildButton('C'),
                      _buildButton('('),
                      _buildButton(')'),
                      _buildButton('÷'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('×'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('-'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('+'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('0'),
                      _buildButton('.'),
                      _buildButton('⌫'),
                      _buildButton('=', isEquals: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Scrollable history above current display
        Expanded(
          child: ValueListenableBuilder<Box<CalculationHistory>>(
            valueListenable: _historyBox.listenable(),
            builder: (context, box, child) {
              if (box.isEmpty) {
                return const SizedBox.shrink();
              }

              // Get all calculations and sort by timestamp (oldest first)
              final calculations = box.values.toList()
                ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

              return ListView.builder(
                itemCount: calculations.length,
                itemBuilder: (context, index) {
                  final calc = calculations[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _expression = calc.result;
                        _result = '';
                        _hasError = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            calc.expression,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            calc.result,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Unified display - shows result if available, otherwise expression
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Builder(
            builder: (context) {
              String displayText = _result.isNotEmpty 
                  ? _result 
                  : (_expression.isEmpty ? '0' : _expression);
              
              // Adjust font size based on length
              double fontSize = 64;
              if (displayText.length > 10) {
                fontSize = 48;
              }
              if (displayText.length > 15) {
                fontSize = 36;
              }
              if (displayText.length > 20) {
                fontSize = 28;
              }
              
              return Text(
                displayText,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w200,
                  color: _hasError ? Colors.red : Colors.white,
                ),
                textAlign: TextAlign.end,
              );
            },
          ),
        ),
      ],
    );
  }
}
