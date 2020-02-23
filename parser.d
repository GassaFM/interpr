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

	string [] tokenize (string input)
	{
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
	check (!tokens.empty && tokens.front == toSkip, line,
	    "expected: " ~ toSkip ~ ", found: " ~ tokens.front);
	auto res = tokens.front;
	tokens.popFront ();
	return res;
}

FunctionBlock parse (T) (T t0)
{
	auto t = t0.enumerate (1)
	    .filter !(line => !line[1].strip.empty)
	    .map !(line => Line (line));

	FunctionBlock parseFunctionBlock (string prevIndent)
	{
		auto line = t.front;
		check (line.indent == prevIndent, line,
		    "indent does not match");
		t.popFront ();

		auto res = new FunctionBlock ();
		line.tokens.consume ("function", line);
		res.name = line.tokens.consume !(isIdent)
		    (line, "bad name: " ~ line.tokens.front);
		line.tokens.consume ("(", line);
		if (line.tokens.front != ")")
		{
			while (true)
			{
				res.parameterList ~=
				    line.tokens.consume !(isIdent)
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
		return res;
	}

	auto res = parseFunctionBlock ("");
	return res;
}

void check (bool cond, const ref Line line, lazy string comment)
{
	if (!cond)
	{
		enforce (cond, format ("line %s: %s\n%s",
		    line.lineId, comment, line.raw));
	}
}
