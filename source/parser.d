// Author: Ivan Kazmenko (gassa@mail.ru)
module parser;
import std.algorithm;
import std.ascii;
import std.conv;
import std.exception;
import std.format;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import language;

immutable int NA = -1;

struct Line
{
	int lineId;
	string raw;
	string indent;
	string [] tokens;

	this (T) (T t)
	{
		lineId = t[0].to !(int);
		raw = t[1];
		indent = raw[0..raw.countUntil !(c => !isWhite (c))];
		tokens = tokenize (raw);
	}

	this (this)
	{
		tokens = tokens.dup;
	}

	string [] tokenize (string input)
	{
		string [] res;
		foreach (t; input.split)
		{
			while (!t.empty)
			{
				string temp;
				if (t.front.isDigit)
				{
					do
					{
						temp ~= t.front;
						t.popFront ();
					}
					while (!t.empty && t.front.isDigit);
				}
				else if (t.front.isIdent)
				{
					do
					{
						temp ~= t.front;
						t.popFront ();
					}
					while (!t.empty && t.front.isIdent);
				}
				else if (":+-*/%&|^><!".canFind (t.front))
				{
					int pos = 1;
					if (t.startsWith (">>>"))
					{
						pos += 2;
					}
					else if (t.startsWith (">>"))
					{
						pos += 1;
					}
					else if (t.startsWith ("<<"))
					{
						pos += 1;
					}
					if (t.length > pos && t[pos] == '=')
					{
						pos += 1;
					}
					temp = t[0..pos];
					t = t[pos..$];
				}
				else if (t.startsWith ("=="))
				{
					temp = t[0..2];
					t = t[2..$];
				}
				else if ("(,)[]~".canFind (t.front))
				{
					temp = t[0..1];
					t = t[1..$];
				}
				else
				{
					check (false, this, format
					    ("token not recognized: %s",
					    t.front));
				}
				res ~= temp;
			}
		}
		return res;
	}
}

bool isIdent (C) (C c)
    if (isSomeChar !(C))
{
	return c.isAlpha || c.isDigit || c == '_';
}

bool isIdentStart (C) (C c)
    if (isSomeChar !(C))
{
	return c.isAlpha || c == '_';
}

bool isIdent (string s)
{
	return !s.empty && s.front.isIdentStart && s.all !(isIdent);
}

string consume (alias pred) (ref string [] tokens,
    const ref Line line, lazy string comment)
{
	check (!tokens.empty && pred (tokens.front), line, comment);
	auto res = tokens.front;
	tokens.popFront ();
	return res;
}

string consume (ref string [] tokens, string toSkip,
    const ref Line line)
{
	if (tokens.empty)
	{
		check (!tokens.empty && tokens.front == toSkip, line,
		    "expected: " ~ toSkip ~ ", found end of line");
	}
	else
	{
		check (!tokens.empty && tokens.front == toSkip, line,
		    "expected: " ~ toSkip ~ ", found: " ~ tokens.front);
	}
	auto res = tokens.front;
	tokens.popFront ();
	return res;
}

Expression parseExpression (ref Line line)
{
	Expression parseCallExpression () ()
	{
		auto name = line.tokens.consume !(isIdent)
		    (line, "bad name: " ~ line.tokens.front);
		line.tokens.consume ("(", line);

		Expression [] params;
		if (line.tokens.front != ")")
		{
			while (true)
			{
				params ~= parse0 ();
				check (!line.tokens.empty, line,
				    "expected , or ), found end of line");
				if (line.tokens.front == ")")
				{
					break;
				}
				line.tokens.consume (",", line);
			}
		}
		line.tokens.consume (")", line);

		return new CallExpression (name, params);
	}

	Expression parseVarExpression () ()
	{
		auto name = line.tokens.consume !(isIdent)
		    (line, "bad name: " ~ line.tokens.front);
		Expression index = null;
		if (!line.tokens.empty && line.tokens.front == "[")
		{
			line.tokens.consume ("[", line);
			index = parse0 ();
			line.tokens.consume ("]", line);
		}
		return new VarExpression (name, index);
	}

	Expression parse9 () ()
	{
		check (!line.tokens.empty, line, "end of line in expression");
		if (line.tokens.front == "(")
		{
			line.tokens.popFront ();
			auto res = parse0 ();
			line.tokens.consume (")", line);
			return res;
		}
		if (line.tokens.front.front.isDigit)
		{
			auto res = new ConstExpression
			    (line.tokens.front.to !(long));
			line.tokens.popFront ();
			return res;
		}
		if (line.tokens.front.isIdent)
		{
			if (line.tokens.length > 1 && line.tokens[1] == "(")
			{
				return parseCallExpression ();
			}
			else
			{
				return parseVarExpression ();
			}
		}
		check (false, line,
		    "can not parse token: " ~ line.tokens.front);
		assert (false);
	}

	Expression parse8 () ()
	{
		if (!line.tokens.empty &&
		    (line.tokens.front == "+" || line.tokens.front == "-" ||
		    line.tokens.front == "!" || line.tokens.front == "~"))
		{
			auto type = (line.tokens.front == "+") ?
			    UnaryOpExpression.Type.plus :
			    (line.tokens.front == "-") ?
			    UnaryOpExpression.Type.minus :
			    (line.tokens.front == "!") ?
			    UnaryOpExpression.Type.not :
			    UnaryOpExpression.Type.complement;
			line.tokens.popFront ();
			auto next = parse7 ();
			return new UnaryOpExpression (type, next);
		}
		else
		{
			return parse9 ();
		}
	}

	Expression parse7 () ()
	{
		auto res = parse8 ();
		while (!line.tokens.empty && (line.tokens.front == "*" ||
		    line.tokens.front == "/" || line.tokens.front == "%"))
		{
			auto type = (line.tokens.front == "*") ?
			    BinaryOpExpression.Type.multiply :
			    (line.tokens.front == "/") ?
			    BinaryOpExpression.Type.divide :
			    BinaryOpExpression.Type.modulo;
			line.tokens.popFront ();
			auto next = parse8 ();
			res = new BinaryOpExpression (type, res, next);
		}
		return res;
	}

	Expression parse6 () ()
	{
		auto res = parse7 ();
		while (!line.tokens.empty &&
		    (line.tokens.front == "+" || line.tokens.front == "-"))
		{
			auto type = (line.tokens.front == "+") ?
			    BinaryOpExpression.Type.add :
			    BinaryOpExpression.Type.subtract;
			line.tokens.popFront ();
			auto next = parse7 ();
			res = new BinaryOpExpression (type, res, next);
		}
		return res;
	}

	Expression parse5 () ()
	{
		auto res = parse6 ();
		while (!line.tokens.empty && (line.tokens.front == ">>" ||
		    line.tokens.front == ">>>" || line.tokens.front == "<<"))
		{
			auto type = (line.tokens.front == ">>") ?
			    BinaryOpExpression.Type.sar :
			    (line.tokens.front == ">>>") ?
			    BinaryOpExpression.Type.shr :
			    BinaryOpExpression.Type.shl;
			line.tokens.popFront ();
			auto next = parse6 ();
			res = new BinaryOpExpression (type, res, next);
		}
		return res;
	}

	Expression parse4 () ()
	{
		auto res = parse5 ();
		while (!line.tokens.empty &&
		    (line.tokens.front == "<" || line.tokens.front == "<=" ||
		    line.tokens.front == ">" || line.tokens.front == ">="))
		{
			auto type = (line.tokens.front == "<") ?
			    BinaryOpExpression.Type.less :
			    (line.tokens.front == "<=") ?
			    BinaryOpExpression.Type.lessEqual :
			    (line.tokens.front == ">") ?
			    BinaryOpExpression.Type.greater :
			    BinaryOpExpression.Type.greaterEqual;
			line.tokens.popFront ();
			auto next = parse5 ();
			res = new BinaryOpExpression (type, res, next);
		}
		return res;
	}

	Expression parse3 () ()
	{
		auto res = parse4 ();
		while (!line.tokens.empty &&
		    (line.tokens.front == "==" || line.tokens.front == "!="))
		{
			auto type = (line.tokens.front == "==") ?
			    BinaryOpExpression.Type.equal :
			    BinaryOpExpression.Type.notEqual;
			line.tokens.popFront ();
			auto next = parse4 ();
			res = new BinaryOpExpression (type, res, next);
		}
		return res;
	}

	Expression parse2 () ()
	{
		auto res = parse3 ();
		while (!line.tokens.empty && line.tokens.front == "&")
		{
			line.tokens.popFront ();
			auto next = parse3 ();
			res = new BinaryOpExpression
			    (BinaryOpExpression.Type.and, res, next);
		}
		return res;
	}

	Expression parse1 () ()
	{
		auto res = parse2 ();
		while (!line.tokens.empty && line.tokens.front == "^")
		{
			line.tokens.popFront ();
			auto next = parse2 ();
			res = new BinaryOpExpression
			    (BinaryOpExpression.Type.xor, res, next);
		}
		return res;
	}

	Expression parse0 () ()
	{
		auto res = parse1 ();
		while (!line.tokens.empty && line.tokens.front == "|")
		{
			line.tokens.popFront ();
			auto next = parse1 ();
			res = new BinaryOpExpression
			    (BinaryOpExpression.Type.or, res, next);
		}
		return res;
	}

	return parse0 ();
}

final class StatementParser
{
	Line [] t;

	Statement parseWhileBlock (string prevIndent)
	{
		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");
		t.popFront ();

		line.tokens.consume ("while", line);
		auto cond = parseExpression (line);
		line.tokens.consume (":", line);
		check (line.tokens.empty, line,
		    "extra token at end of line: " ~ line.tokens.front);

		WhileBlock res = new WhileBlock (line.lineId, cond);
		res.statementList = parseBlock (prevIndent);
		return res;
	}

	Statement parseForBlock (string prevIndent)
	{
		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");
		t.popFront ();

		line.tokens.consume ("for", line);
		auto name = line.tokens.consume !(isIdent)
		    (line, "bad name: " ~ line.tokens.front);
		line.tokens.consume (":=", line);
		auto start = parseExpression (line);
		line.tokens.consume ("until", line);
		auto finish = parseExpression (line);
		line.tokens.consume (":", line);
		check (line.tokens.empty, line,
		    "extra token at end of line: " ~ line.tokens.front);

		ForBlock res = new ForBlock (line.lineId, name, start, finish);
		res.statementList = parseBlock (prevIndent);
		return res;
	}

	Statement parseIfBlock (string prevIndent)
	{
		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");
		t.popFront ();

		line.tokens.consume ("if", line);
		auto cond = parseExpression (line);
		line.tokens.consume (":", line);
		check (line.tokens.empty, line,
		    "extra token at end of line: " ~ line.tokens.front);

		IfBlock res = new IfBlock (line.lineId, cond);
		res.statementListTrue = parseBlock (prevIndent);

		if (!t.empty)
		{
			line = t.front;
			if (line.indent == prevIndent &&
			    line.tokens.front == "else")
			{
				t.popFront ();
				line.tokens.consume ("else", line);
				line.tokens.consume (":", line);
				res.statementListFalse =
				    parseBlock (prevIndent);
			}
		}
		return res;
	}

	Statement parseCallStatement (string prevIndent)
	{
		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");
		t.popFront ();

		auto cur = cast (CallExpression) (parseExpression (line));
		check (cur !is null, line,
		    "call statement detected but not parsed");
		check (line.tokens.empty, line,
		    "extra token at end of line: " ~ line.tokens.front);

		return new CallStatement (line.lineId, cur);
	}

	Statement parseAssignStatement (string prevIndent)
	{
		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");
		t.popFront ();

		auto var = cast (VarExpression) (parseExpression (line));
		check (var !is null, line,
		    "assign statement detected but left side not parsed");

		check (!line.tokens.empty, line,
		    "expected assignment operator, found end of line");
		auto op = line.tokens.consume !(op => (op.length == 2 &&
		    ":+-*/%|^&".canFind (op[0]) && op[1] == '=') ||
		    (op == ">>=") || (op == ">>>=") || (op == "<<="))
		    (line, "expected assignment operator, found " ~
		    line.tokens.front);
		auto type =
		    (op == "+=") ? AssignStatement.Type.assignAdd :
		    (op == "-=") ? AssignStatement.Type.assignSubtract :
		    (op == "*=") ? AssignStatement.Type.assignMultiply :
		    (op == "/=") ? AssignStatement.Type.assignDivide :
		    (op == "%=") ? AssignStatement.Type.assignModulo :
		    (op == "|=") ? AssignStatement.Type.assignOr :
		    (op == "^=") ? AssignStatement.Type.assignXor :
		    (op == "&=") ? AssignStatement.Type.assignAnd :
		    (op == ">>=") ? AssignStatement.Type.assignSar :
		    (op == ">>>=") ? AssignStatement.Type.assignShr :
		    (op == "<<=") ? AssignStatement.Type.assignShl :
		    AssignStatement.Type.assign;

		auto cur = parseExpression (line);
		check (line.tokens.empty, line,
		    "extra token at end of line: " ~ line.tokens.front);

		return new AssignStatement (line.lineId, type, var, cur);
	}

	Statement parseStatement (string prevIndent)
	{
		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");

		auto start = line.tokens.front;
		if (start == "for")
		{
			return parseForBlock (prevIndent);
		}
		else if (start == "if")
		{
			return parseIfBlock (prevIndent);
		}
		else if (start == "while")
		{
			return parseWhileBlock (prevIndent);
		}
		else if (line.tokens.length > 1 && line.tokens[1] == "(")
		{
			return parseCallStatement (prevIndent);
		}
		else
		{
			return parseAssignStatement (prevIndent);
		}
	}

	Statement [] parseBlock (string prevIndent)
	{
		auto nextLine = t.front;
		auto newIndent = nextLine.indent;
		check (newIndent.startsWith (prevIndent), t.front,
		    "next indent does not start with previous");
		check (newIndent != prevIndent, t.front,
		    "no added indent for a block");

		Statement [] res;
		while (!t.empty && t.front.indent == newIndent)
		{
			res ~= parseStatement (newIndent);
		}
		return res;
	}

	FunctionBlock parseFunctionBlock (string prevIndent)
	{
		if (t.empty)
		{
			enforce (!t.empty, "program is empty");
		}

		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");
		t.popFront ();

		line.tokens.consume ("function", line);
		auto name = line.tokens.consume !(isIdent)
		    (line, "bad name: " ~ line.tokens.front);
		string [] params;
		line.tokens.consume ("(", line);
		if (line.tokens.front != ")")
		{
			while (true)
			{
				params ~= line.tokens.consume !(isIdent)
				    (line, "bad name: " ~ line.tokens.front);
				if (line.tokens.front == ")")
				{
					break;
				}
				line.tokens.consume (",", line);
			}
		}
		line.tokens.consume (")", line);
		line.tokens.consume (":", line);
		check (line.tokens.empty, line,
		    "extra token at end of line: " ~ line.tokens.front);
		auto res = new FunctionBlock (line.lineId, name, params);

		res.statementList = parseBlock (prevIndent);

		if (!t.empty)
		{
			enforce (t.empty, format ("line %s: %s\n%s",
			    t.front.lineId, "stray indent", t.front.raw));
		}

		return res;
	}

	FunctionBlock parse (string [] t0)
	{
		t = t0.map !(line => line.findSplitBefore("#")[0])
		    .enumerate (1)
		    .filter !(line => !line[1].strip.empty)
		    .map !(line => Line (line))
		    .array;
		auto res = parseFunctionBlock ("");
		return res;
	}
}

void check (bool cond, const ref Line line, lazy string comment)
{
	if (!cond)
	{
		enforce (cond, format ("line %s: %s\n%s",
		    line.lineId, comment, line.raw));
	}
}
