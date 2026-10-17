import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/expression_evaluator.dart';

void main() {
  group('percent', () {
    test('converts a lone percentage to a fraction', () {
      expect(ExpressionEvaluator.evaluate('50%'), 0.5);
    });

    test('adds and subtracts a percentage of the left side', () {
      expect(ExpressionEvaluator.evaluate('200+10%'), closeTo(220, 1e-9));
      expect(ExpressionEvaluator.evaluate('200-25%'), closeTo(150, 1e-9));
    });

    test('multiplies and divides by the fraction', () {
      expect(ExpressionEvaluator.evaluate('80×25%'), closeTo(20, 1e-9));
      expect(ExpressionEvaluator.evaluate('10÷50%'), closeTo(20, 1e-9));
    });

    test('applies to groups and negatives', () {
      expect(ExpressionEvaluator.evaluate('(20+30)%'), closeTo(0.5, 1e-9));
      expect(ExpressionEvaluator.evaluate('-50%'), closeTo(-0.5, 1e-9));
      expect(ExpressionEvaluator.evaluate('2×-50%'), closeTo(-1, 1e-9));
    });

    test('rejects a percent with no operand', () {
      expect(ExpressionEvaluator.evaluate('%'), isNull);
      expect(ExpressionEvaluator.evaluate('5+%'), isNull);
    });
  });

  test('still evaluates plain expressions', () {
    expect(ExpressionEvaluator.evaluate('2+3×4'), 14);
    expect(ExpressionEvaluator.evaluate('(2+3)×4'), 20);
    expect(ExpressionEvaluator.evaluate('-3--2'), -1);
  });
}
