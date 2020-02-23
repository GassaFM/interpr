// Author: Ivan Kazmenko (gassa@mail.ru)
module parser;
import std.algorithm;
import std.ascii;
import std.conv;
import std.exception;
import std.range;
import std.stdio;
import std.string;
import language;

immutable int NA = -1;

struct Line
{
	int lineId;
	string indent;
	string [] tokens;
}

bool isIdent (C) (C c)
{
	return c.isAlpha || c.isDigit || c == '_';
}

string [] tokenize (string input)
{
	immutable string binaryOps = "+-*/%&|^";

	string [] res;
	foreach (t; input.split)
	{
		while (!t.empty)
		{
			string temp;
			if (t.front.isIdent)
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
				if (t.length > 1 && t[1] == '=')
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
			res ~= temp;
		}
	}
	return res;
}

FunctionBlock parse (T) (T t0)
{
	auto t = t0.enumerate (1)
	    .filter !(line => !line[1].strip.empty)
	    .map !(line => Line (line[0].to !(int),
	    line[1][0..line[1].countUntil !(c => !isWhite (c))],
	    line[1].tokenize));

	FunctionBlock parseFunctionBlock (string prevIndent)
	{
		foreach (line; t)
		{
			writefln ("%-(%s %)", line.tokens);
		}
/*
		auto line = t.front;
		enforce (line.indent == prevIndent, "indent does not match");
		t.popFront ();
*/
		auto res = new FunctionBlock ();
		return res;
	}

	auto res = parseFunctionBlock ("");
	return res;
}
