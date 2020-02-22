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

class AssignStatement : Statement
{
	enum Type : byte {assign, assignAdd, assignSubtract, assignMultiply,
	    assignDivide, assignModulo, assignXor, assignAnd, assignOr};
	Type type;
	VarExpression dest;
	Expression expr;
}

class CallStatement : Statement
{
	CallExpression call;
}

class WhileStatement : Statement
{
	Expression cond;
	Statement [] statementList;
}

class IfStatement : Statement
{
	Expression cond;
	Statement [] statementListTrue;
	Statement [] statementListFalse;
}

class Expression
{
}

class CallExpression : Expression
{
	string name;
	Expression [] argumentList;
}

class BinaryOpExpression : Expression
{
	enum Type : byte {add, subtract, multiply, divide, modulo,
	    xor, and, or, greater, greaterEqual, less, lessEqual,
	    equal, notEqual};
	Type type;
	Expression left;
	Expression right;
}

class UnaryOpExpression : Expression
{
	enum Type : byte {plus, minus, not, complement};
	Type type;
	Expression expr;
}

class VarExpression : Expression
{
	string name;
	Expression index;
}

class ConstExpression : Expression
{
	long value;
}
