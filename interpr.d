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
	// set default parameters
	bool compileOnly = false;
	int num = 100;
	int steps = 1_000_000;
	string fileName = "";

	// read custom parameters from arguments
	int pos = 1;
	while (pos < args.length)
	{
		if (args[pos] == "-c")
		{
			compileOnly = true;
		}
		else if (args[pos] == "-n")
		{
			pos += 1;
			num = args[pos].to !(int);
		}
		else if (args[pos] == "-s")
		{
			pos += 1;
			steps = args[pos].to !(int);
		}
		else
		{
			fileName = args[pos];
		}
		pos += 1;
	}

	// compile program
	auto f = File (fileName, "rt");
	auto s = new StatementParser ();
	auto p = s.parse (f.byLineCopy.array);
	if (compileOnly)
	{
		return;
	}

	// read input
	auto n = readln.strip.to !(long);
	auto a = readln.splitter.map !(to !(long)).array;

	// execute program
	auto rc = new RunnerControl (num, p, n, a);
	int step;
	bool working = true;
	for (step = 0; step < steps && working; step++)
	{
		working &= rc.step ();
	}
	stderr.writeln ("steps: ", step);

	// simulate time limit exceeded
	if (working)
	{
		for (ulong i = 0; ; i++)
		{
		}
	}
}
