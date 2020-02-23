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

final class WhileStatement : Statement
{
	Expression cond;
	Statement [] statementList;
}

final class IfStatement : Statement
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
}

final class UnaryOpExpression : Expression
{
	enum Type : byte {plus, minus, not, complement};
	Type type;
	Expression expr;
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
