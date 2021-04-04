// Author: Ivan Kazmenko (gassa@mail.ru)
module display;
import std.algorithm;
import std.range;
import std.stdio;
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
			    "|", ">", ">=", "<", "<=", "==", "!=",
			    ">>", ">>>", "<<"][cur.type]);
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
	writef ("%4d:%-3d %-(%s%)", s.lineId, s.complexity+1,
	    "\t".repeat (indent));

	{
		auto cur = cast (AssignStatement) (s);
		if (cur !is null)
		{
			display (cur.dest);
			write (" ", [":", "+", "-", "*", "/", "%", "^", "&",
			    "|", ">>", ">>>", "<<"][cur.type], "=", " ");
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
				writef ("%4d:    %-(%s%)", cur.statementListFalse[0].lineId-1,
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

void displayFunction (FunctionBlock p)
{
	writefln ("%4d:%-3d function %s (%-(%s, %)):",
	    p.lineId, p.parameterList.length, p.name, p.parameterList);
	foreach (s; p.statementList)
	{
		display (s, 1);
	}
}
