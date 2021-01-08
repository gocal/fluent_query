import 'package:meta/meta.dart';

import '../utils/hash.dart';

part 'algebra.dart';
part 'bools.dart';
part 'comparable.dart';
part 'variables.dart';

/// Any sql expression that evaluates to some generic value. This does not
/// include queries (which might evaluate to multiple values) but individual
/// columns, functions and operators.
///
/// It's important that all subclasses properly implement [hashCode] and
/// [==].
abstract class Expression<D> {
  /// Constant constructor so that subclasses can be constant.
  const Expression();

  /// The precedence of this expression. This can be used to automatically put
  /// parentheses around expressions as needed.
  Precedence get precedence => Precedence.unknown;

  /// Whether this expression is equal to the given expression.
  Expression<bool> equalsExp(Expression<D> compare) =>
      _Comparison.equal(this, compare);

  /// Whether this column is equal to the given value, which must have a fitting
  /// type. The [compare] value will be written
  /// as a variable using prepared statements, so there is no risk of
  /// an SQL-injection.
  Expression<bool> equals(D compare) =>
      _Comparison.equal(this, Variable<D>(compare));
}

/// An expression that looks like "$a operator $b", where $a and $b itself
/// are expressions and the operator is any string.
abstract class _InfixOperator<D> extends Expression<D> {
  /// The left-hand side of this expression
  Expression get left;

  /// The right-hand side of this expresion
  Expression get right;

  /// The sql operator to write
  String get operator;

  @override
  int get hashCode =>
      $mrjf($mrjc(left.hashCode, $mrjc(right.hashCode, operator.hashCode)));

  @override
  bool operator ==(dynamic other) {
    return other is _InfixOperator &&
        other.left == left &&
        other.right == right &&
        other.operator == operator;
  }
}

class _BaseInfixOperator<D> extends _InfixOperator<D> {
  @override
  final Expression left;

  @override
  final String operator;

  @override
  final Expression right;

  @override
  final Precedence precedence;

  _BaseInfixOperator(this.left, this.operator, this.right,
      {this.precedence = Precedence.unknown});
}

enum _ComparisonOperator {
  /// '<' in sql
  less,

  /// '<=' in sql
  lessOrEqual,

  /// '=' in sql
  equal,

  /// '>=' in sql
  moreOrEqual,

  /// '>' in sql
  more
}

class _Comparison extends _InfixOperator<bool> {
  static const Map<_ComparisonOperator, String> _operatorNames = {
    _ComparisonOperator.less: '<',
    _ComparisonOperator.lessOrEqual: '<=',
    _ComparisonOperator.equal: '=',
    _ComparisonOperator.moreOrEqual: '>=',
    _ComparisonOperator.more: '>'
  };

  @override
  final Expression left;
  @override
  final Expression right;

  /// The operator to use for this comparison
  final _ComparisonOperator op;

  @override
  String get operator => _operatorNames[op];

  @override
  Precedence get precedence {
    if (op == _ComparisonOperator.equal) {
      return Precedence.comparisonEq;
    } else {
      return Precedence.comparison;
    }
  }

  /// Constructs a comparison from the [left] and [right] expressions to compare
  /// and the [ComparisonOperator] [op].
  _Comparison(this.left, this.op, this.right);

  /// Like [Comparison(left, op, right)], but uses [_ComparisonOperator.equal].
  _Comparison.equal(this.left, this.right) : op = _ComparisonOperator.equal;
}

class _UnaryMinus<DT> extends Expression<DT> {
  final Expression<DT> inner;

  _UnaryMinus(this.inner);

  @override
  Precedence get precedence => Precedence.unary;

  @override
  int get hashCode => inner.hashCode * 5;

  @override
  bool operator ==(dynamic other) {
    return other is _UnaryMinus && other.inner == inner;
  }
}

///
///
class Precedence implements Comparable<Precedence> {
  /// Higher means higher precedence.
  final int _value;

  const Precedence._(this._value);

  @override
  int compareTo(Precedence other) {
    return _value.compareTo(other._value);
  }

  @override
  int get hashCode => _value;

  @override
  bool operator ==(dynamic other) {
    // runtimeType comparison isn't necessary, the private constructor prevents
    // subclasses
    return other is Precedence && other._value == _value;
  }

  /// Returns true if this [Precedence] is lower than [other].
  bool operator <(Precedence other) => compareTo(other) < 0;

  /// Returns true if this [Precedence] is lower or equal to [other].
  bool operator <=(Precedence other) => compareTo(other) <= 0;

  /// Returns true if this [Precedence] is higher than [other].
  bool operator >(Precedence other) => compareTo(other) > 0;

  /// Returns true if this [Precedence] is higher or equal to [other].
  bool operator >=(Precedence other) => compareTo(other) >= 0;

  /// Precedence is unknown, assume lowest. This can be used for a
  /// [CustomExpression] to always put parens around it.
  static const Precedence unknown = Precedence._(-1);

  /// Precedence for the `OR` operator in sql
  static const Precedence or = Precedence._(10);

  /// Precedence for the `AND` operator in sql
  static const Precedence and = Precedence._(11);

  /// Precedence for most of the comparisons operators in sql, including
  /// equality, is (not) checks, in, like, glob, match, regexp.
  static const Precedence comparisonEq = Precedence._(12);

  /// Precedence for the <, <=, >, >= operators in sql
  static const Precedence comparison = Precedence._(13);

  /// Precedence for bitwise operators in sql
  static const Precedence bitwise = Precedence._(14);

  /// Precedence for the (binary) plus and minus operators in sql
  static const Precedence plusMinus = Precedence._(15);

  /// Precedence for the *, / and % operators in sql
  static const Precedence mulDivide = Precedence._(16);

  /// Precedence for the || operator in sql
  static const Precedence stringConcatenation = Precedence._(17);

  /// Precedence for unary operators in sql
  static const Precedence unary = Precedence._(20);

  /// Precedence for postfix operators (like collate) in sql
  static const Precedence postfix = Precedence._(21);

  /// Highest precedence in sql, used for variables and literals.
  static const Precedence primary = Precedence._(100);
}
