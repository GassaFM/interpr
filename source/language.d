// Author: Ivan Kazmenko (gassa@mail.ru)
module language;
import std.algorithm;

class Statement
{
	int lineId;
	int complexity;
}

final class FunctionBlock : Statement
{
	string name;
	string [] parameterList;
	Statement [] statementList;

	this (int lineId_, string name_, string [] parameterList_)
	{
		lineId = lineId_;
		name = name_;
		parameterList = parameterList_;
		complexity = 1;
	}
}

final class AssignStatement : Statement
{
	enum Type : byte {assign, assignAdd, assignSubtract, assignMultiply,
	    assignDivide, assignModulo, assignXor, assignAnd, assignOr,
	    assignSar, assignShr, assignShl};
	Type type;
	VarExpression dest;
	Expression expr;

	this (int lineId_, Type type_, VarExpression dest_, Expression expr_)
	{
		lineId = lineId_;
		type = type_;
		dest = dest_;
		expr = expr_;
		complexity = 1 + dest.complexity + expr.complexity;
	}
}

final class CallStatement : Statement
{
	CallExpression call;

	this (int lineId_, CallExpression call_)
	{
		lineId = lineId_;
		call = call_;
		complexity = call.complexity;
	}
}

final class WhileBlock : Statement
{
	Expression cond;
	Statement [] statementList;

	this (int lineId_, Expression cond_)
	{
		lineId = lineId_;
		cond = cond_;
		complexity = cond.complexity;
	}
}

final class ForBlock : Statement
{
	string name;
	bool isUntil;
	Expression start;
	Expression finish;
	Statement [] statementList;

	this (int lineId_, string name_, bool isUntil_, Expression start_, Expression finish_)
	{
		lineId = lineId_;
		isUntil = isUntil_;
		name = name_;
		start = start_;
		finish = finish_;
		complexity = 1 + 1 + start.complexity + finish.complexity;
	}
}

final class IfBlock : Statement
{
	Expression cond;
	Statement [] statementListTrue;
	Statement [] statementListFalse;
	bool isElif;

	this (int lineId_, Expression cond_)
	{
		lineId = lineId_;
		cond = cond_;
		complexity = cond.complexity;
		isElif = false;
	}
}

class Expression
{
	int complexity;
}

final class CallExpression : Expression
{
	string name;
	Expression [] argumentList;

	this (string name_, Expression [] argumentList_)
	{
		name = name_;
		argumentList = argumentList_.dup;
		complexity = 1 + argumentList.map !(e => e.complexity).sum;
	}
}

final class BinaryOpExpression : Expression
{
	enum Type : byte {add, subtract, multiply, divide, modulo,
	    xor, and, or, greater, greaterEqual, less, lessEqual,
	    equal, notEqual, sar, shr, shl};
	Type type;
	Expression left;
	Expression right;

	this (Type type_, Expression left_, Expression right_)
	{
		type = type_;
		left = left_;
		right = right_;
		complexity = 1 + left.complexity + right.complexity;
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
		complexity = 1 + expr.complexity;
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
		complexity = 1;
		if (index !is null)
		{
			complexity += index.complexity;
		}
	}
}

final class ConstExpression : Expression
{
	long value;

	this (long value_)
	{
		value = value_;
		complexity = 1;
	}
}
