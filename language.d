// Author: Ivan Kazmenko (gassa@mail.ru)
module language;

final class FunctionBlock
{
	string name;
	string [] parameterList;
	Statement [] statementList;
	int lineId;
}

class Statement
{
	int lineId;
}

final class AssignStatement : Statement
{
	enum Type : byte {assign, assignAdd, assignSubtract, assignMultiply,
	    assignDivide, assignModulo, assignXor, assignAnd, assignOr};
	Type type;
	VarExpression dest;
	Expression expr;
}

final class CallStatement : Statement
{
	CallExpression call;
}

final class WhileBlock : Statement
{
	Expression cond;
	Statement [] statementList;
}

final class ForBlock : Statement
{
	string name;
	Expression start;
	Expression finish;
	Statement [] statementList;
}

final class IfBlock : Statement
{
	Expression cond;
	Statement [] statementListTrue;
	Statement [] statementListFalse;
}

class Expression
{
}

final class CallExpression : Expression
{
	string name;
	Expression [] argumentList;
}

final class BinaryOpExpression : Expression
{
	enum Type : byte {add, subtract, multiply, divide, modulo,
	    xor, and, or, greater, greaterEqual, less, lessEqual,
	    equal, notEqual};
	Type type;
	Expression left;
	Expression right;

	this (Type type_, Expression left_, Expression right_)
	{
		type = type_;
		left = left_;
		right = right_;
	}
}

final class UnaryOpExpression : Expression
{
	enum Type : byte {plus, minus, not, complement};
	Type type;
	Expression expr;

	this (Type type_, Expression expr_)
	{
		type = type_;
		expr = expr_;
	}
}

final class VarExpression : Expression
{
	string name;
	Expression index;
}

final class ConstExpression : Expression
{
	long value;
}
