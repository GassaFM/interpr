// Author: Ivan Kazmenko (gassa@mail.ru)
module test;
import std.algorithm;
import std.range;
import std.stdio;
import language;
import parser;

void main (string [] args)
{
	auto f = File (args[1], "rt");
	auto r = new StatementParser ();
	auto p = r.parse (f.byLineCopy.array);
}
