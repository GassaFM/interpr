// Author: Ivan Kazmenko (gassa@mail.ru)
module interpr;
import std.algorithm;
import std.conv;
import std.exception;
import std.range;
import std.stdio;
import std.string;
import language;
import parser;
import runner;

void main (string [] args)
{
	auto f = File (args[1], "rt");
	auto s = new StatementParser ();
	auto p = s.parse (f.byLineCopy.array);
	auto n = readln.strip.to !(long);
	auto a = readln.splitter.map !(to !(long)).array;
	auto r = new RunnerControl (1, p, n, a);
	int step;
	for (step = 0; r.step (); step++)
	{
//		writeln (step);
	}
}
