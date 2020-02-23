// Author: Ivan Kazmenko (gassa@mail.ru)
module test;
import std.algorithm;
import std.stdio;
import language;
import parser;

void main (string [] args)
{
	auto f = File (args[1], "rt");
	auto p = parse (f.byLineCopy);
}
