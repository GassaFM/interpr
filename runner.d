// Author: Ivan Kazmenko (gassa@mail.ru)
module display;
import std.algorithm;
import std.conv;
import std.exception;
import std.range;
import std.stdio;
import std.string;
import language;
import parser;

void display (Expression e)
{
	{
		auto cur = cast (CallExpression) (e);
		if (cur !is null)
		{
			write (cur.name, " (");
			foreach (i, r; cur.argumentList)
			{
				if (i > 0)
				{
					writef (", ");
				}
				display (r);
			}
			write (")");
		}
	}

	{
		auto cur = cast (BinaryOpExpression) (e);
		if (cur !is null)
		{
			write ("(");
			display (cur.left);
			writef (" %s ", ["+", "-", "*", "/", "%", "^", "&",
			    "|", ">", ">=", "<", "<=", "==", "!="][cur.type]);
			display (cur.right);
			write (")");
		}
	}

	{
		auto cur = cast (UnaryOpExpression) (e);
		if (cur !is null)
		{
			write ("+-!~"[cur.type]);
			display (cur.expr);
		}
	}

	{
		auto cur = cast (VarExpression) (e);
		if (cur !is null)
		{
			write (cur.name);
			if (cur.index !is null)
			{
				write ("[");
				display (cur.index);
				write ("]");
			}
		}
	}

	{
		auto cur = cast (ConstExpression) (e);
		if (cur !is null)
		{
			write (cur.value);
		}
	}
}

void display (Statement s, int indent)
{
	writef ("%4d:%-3d %-(%s%)", s.lineId, s.complexity,
	    "\t".repeat (indent));

	{
		auto cur = cast (AssignStatement) (s);
		if (cur !is null)
		{
			display (cur.dest);
			write (" ", ":+-*/%^&|"[cur.type], "=", " ");
			display (cur.expr);
			writeln;
		}
	}

	{
		auto cur = cast (CallStatement) (s);
		if (cur !is null)
		{
			display (cur.call);
			writeln;
		}
	}

	{
		auto cur = cast (WhileBlock) (s);
		if (cur !is null)
		{
			write ("while ");
			display (cur.cond);
			writeln (":");
			foreach (r; cur.statementList)
			{
				display (r, indent + 1);
			}
		}
	}

	{
		auto cur = cast (ForBlock) (s);
		if (cur !is null)
		{
			write ("for ", cur.name, " := ");
			display (cur.start);
			write (" until ");
			display (cur.finish);
			writeln (":");
			foreach (r; cur.statementList)
			{
				display (r, indent + 1);
			}
		}
	}

	{
		auto cur = cast (IfBlock) (s);
		if (cur !is null)
		{
			write ("if ");
			display (cur.cond);
			writeln (":");
			foreach (r; cur.statementListTrue)
			{
				display (r, indent + 1);
			}
			if (!cur.statementListFalse.empty)
			{
				writef ("    :   %-(%s%)",
				    "\t".repeat (indent));
				writeln ("else:");
				foreach (r; cur.statementListFalse)
				{
					display (r, indent + 1);
				}
			}
		}
	}
}

void display (FunctionBlock p)
{
	writefln ("%4d:    function %s (%-(%s, %)):",
	    p.lineId, p.name, p.parameterList);
	foreach (s; p.statementList)
	{
		display (s, 1);
	}
}

class Runner
{
	struct Var
	{
		long value;
		bool isConst;

		this (long value_, bool isConst_ = false)
		{
			value = value_;
			isConst = isConst_;
		}

		@disable this (this);
	}

	struct Array
	{
		long [] contents;
		bool isConst;

		this (long [] contents_, bool isConst_ = false)
		{
			contents = contents_;
			isConst = isConst_;
		}

		@disable this (this);
	}

	struct Context
	{
		Statement parent;
		int pos;
		Statement [] block;
		Var [string] vars;
		Array [string] arrays;

		@disable this (this);
	}

	Context [] state;
	int delay;

	this (Args...) (FunctionBlock p, Args args)
	{
		state = [Context (p, -1)];
		delay = 0;
		int argNum = 0;
		static foreach (cur; args)
		{
			if (argNum >= p.parameterList.length)
			{
				throw new Exception ("not enough parameters");
			}
			static if (is (typeof (cur) : long))
			{
				state.back.vars[p.parameterList[argNum]] =
				    Var (cur, true);
			}
			else static if (is (typeof (cur) : long []))
			{
				state.back.arrays[p.parameterList[argNum]] =
				    Array (cur, true);
			}
			else
			{
				static assert (false);
			}
			argNum += 1;
		}
	}

	long * varAddress (string name, bool canCreate = false)
	{
		foreach_reverse (ref cur; state)
		{
			if (name in cur.vars)
			{
				return &(cur.vars[name].value);
			}
		}
		if (!canCreate)
		{
			throw new Exception ("no such variable: " ~ name);
		}
		state.back.vars[name] = Var (0);
		return &(state.back.vars[name].value);
	}

	long * arrayAddress (string name, long index)
	{
		foreach_reverse (ref cur; state)
		{
			if (name in cur.vars)
			{
				if (index < 0 ||
				    cur.arrays[name].contents.length <= index)
				{
					throw new Exception ("array " ~ name ~
					    ": no index " ~ index.text);
				}
				return &(cur.arrays[name]
				    .contents[index.to !(size_t)]);
			}
		}
		throw new Exception ("no such array: " ~ name);
	}

	long evalExpression (Expression e)
	{
		long res = 0;
		return res;
	}

	void runStatement (Statement s)
	{
		auto cur0 = cast (AssignStatement) (s);
		if (cur0 !is null) with (cur0)
		{
			// special syntax for creating arrays
			if (type == Type.assign)
			{
				auto expr0 = cast (CallStatement) (expr);
				if (expr0 !is null &&
				    expr0.call.name == "array")
				{
					// goes here
					return;
				}
			}
			auto value = evalExpression (expr);
			long * addr;
			if (dest.index is null)
			{
				addr = varAddress (dest.name,
				    type == Type.assign);
			}
			else
			{
				auto indexValue = evalExpression (dest.index);
				addr = arrayAddress (dest.name, indexValue);
			}
			*(addr) = value;
			return;
		}

		assert (false);
	}

	bool step ()
	{
		if (state.empty)
		{
			return false;
		}

		if (delay > 0)
		{
			delay -= 1;
			return true;
		}

		with (state.back)
		{
			writeln (delay, " ", state.back.vars, state.back.pos);
			auto cur0 = cast (FunctionBlock) (parent);
			if (cur0 !is null)
			{
				if (pos < 0)
				{
					pos += 1;
					block = cur0.statementList;
					delay = cur0.complexity;
				}
				else if (pos >= block.length)
				{
					state.popBack ();
				}
				else
				{
					pos += 1;
					runStatement (block[pos - 1]);
				}
				return true;
			}

			auto cur1 = cast (IfBlock) (parent);
			if (cur1 !is null)
			{
				if (pos < 0)
				{
					auto value = evalExpression
					    (cur1.cond);
					block = value ?
					    cur1.statementListTrue :
					    cur1.statementListFalse;
					pos += 1;
					delay = cur1.complexity;
				}
				else if (pos >= block.length)
				{
					state.popBack ();
				}
				else
				{
					pos += 1;
					runStatement (block[pos - 1]);
					delay = block[pos - 1].complexity;
				}
				return true;
			}

			assert (false);
		}
	}
}

void main (string [] args)
{
	auto f = File (args[1], "rt");
	auto s = new StatementParser ();
	auto p = s.parse (f.byLineCopy.array);
	auto n = readln.strip.to !(long);
	auto a = readln.splitter.map !(to !(long)).array;
	auto r = new Runner (p, 0, 1, n, a);
	int step;
	for (step = 0; r.step (); step++)
	{
		writeln (step);
	}
//	display (p);
}
