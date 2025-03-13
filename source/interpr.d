// Author: Ivan Kazmenko (gassa@mail.ru)
module interpr;
import std.algorithm;
import std.conv;
import std.exception;
import std.range;
import std.stdio;
import std.string;
import display;
import language;
import parser;
import runner;

int main (string [] args)
{
	// set default parameters
	bool compileOnly = false;
	bool doDisplay = false;
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
		else if (args[pos] == "-d")
		{
			doDisplay = true;
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
		else if (args[pos] == "-i") 
		{	
			pos += 1;
			try 
			{
				auto input = File(args[pos], "r");
				stdin = input;
			}
			catch (Exception e)
			{
				stderr.writefln("Cannot find input file \"%s\", using stdin", args[pos]);
			}
			
		}
		else if (args[pos] == "-o") 
		{
			pos += 1;
			try 
			{
				auto output = File(args[pos], "w");
				stdout = output;
			}
			catch (Exception e)
			{
				stderr.writefln("Cannot find output file \"%s\", using stdout", args[pos]);
			}
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
	FunctionBlock p;
	try
	{
		p = s.parse (f.byLineCopy.array);
	}
	catch (Exception e)
	{
		stderr.writeln (e.msg);
		return 1;
	}
	if (doDisplay)
	{
		displayFunction (p);
	}
	if (compileOnly)
	{
		return 0;
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
		try
		{
			working &= rc.step ();
		}
		catch (Exception e)
		{
			stderr.writeln ("step ", step, ", ", e.msg);
			return 1;
		}
	}
	stderr.writeln ("steps: ", step);

	// simulate time limit exceeded
	if (working)
	{
		for (ulong i = 0; ; i++)
		{
		}
	}

	return 0;
}
