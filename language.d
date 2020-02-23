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

	this (Type type_, VarExpression dest_, Expression expr_)
	{
		type = type_;
		dest = dest_;
		expr = expr_;
	}
}

final class CallStatement : Statement
{
	CallExpression call;

	this (CallExpression call_)
	{
		call = call_;
	}
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

	this (string name_, Expression [] argumentList_)
	{
		name = name_;
		argumentList = argumentList_.dup;
	}
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

	this (string name_, Expression index_)
	{
		name = name_;
		index = index_;
	}
}

final class ConstExpression : Expression
{
	long value;

	this (long value_)
	{
		value = value_;
	}
}
