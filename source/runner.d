// Author: Ivan Kazmenko (gassa@mail.ru)
module runner;
import std.algorithm;
import std.conv;
import std.exception;
import std.range;
import std.stdio;
import std.string;
import language;
import parser;

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
	}

	RunnerControl control;
	int id;

	Context [] state;
	int delay;

	this (Args...) (RunnerControl control_, int id_,
	    FunctionBlock p, Args args)
	{
		control = control_;
		id = id_;

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
				if (cur.vars[name].isConst)
				{
					throw new Exception ("array " ~ name ~
					    " is constant");
				}
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
			if (name in cur.arrays)
			{
				if (cur.arrays[name].isConst)
				{
					throw new Exception ("array " ~ name ~
					    " is constant");
				}
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

	long varValue (string name)
	{
		foreach_reverse (ref cur; state)
		{
			if (name in cur.vars)
			{
				return cur.vars[name].value;
			}
		}
		throw new Exception ("no such variable: " ~ name);
	}

	long arrayValue (string name, long index)
	{
		foreach_reverse (ref cur; state)
		{
			if (name in cur.arrays)
			{
				if (index < 0 ||
				    cur.arrays[name].contents.length <= index)
				{
					throw new Exception ("array " ~ name ~
					    ": no index " ~ index.text);
				}
				return cur.arrays[name]
				    .contents[index.to !(size_t)];
			}
		}
		throw new Exception ("no such array: " ~ name);
	}

	long evalCall (CallExpression call)
	{
		auto values = call.argumentList
		    .map !(e => evalExpression (e)).array;

		if (call.name == "send")
		{
			if (values.length < 1)
			{
				throw new Exception
				    ("send: no first argument");
			}
			if (values[0] < 0 || control.num <= values[0])
			{
				throw new Exception ("send: first argument " ~
				    values[0].text ~ " not in [0.." ~
				    control.num.text ~ ")");
			}
			control.queues[id][values[0].to !(size_t)] ~=
			    values[1..$];
			return 0;
		}

		if (call.name == "receive")
		{
			throw new Exception ("can only assign with receive");
		}

		if (call.name == "array")
		{
			throw new Exception ("can only assign with array");
		}

		if (call.name == "print")
		{
			writefln ("%(%s %)", values);
			return 0;
		}

		throw new Exception ("call of non-existing function: " ~
		    call.name);
	}

	long evalExpression (Expression e)
	{
		auto cur0 = cast (BinaryOpExpression) (e);
		if (cur0 !is null) with (cur0)
		{
			auto leftValue = evalExpression (left);
			auto rightValue = evalExpression (right);
			final switch (type)
			{
			case Type.add:          return leftValue + rightValue;
			case Type.subtract:     return leftValue - rightValue;
			case Type.multiply:     return leftValue * rightValue;
			case Type.divide:       return leftValue / rightValue;
			case Type.modulo:       return leftValue % rightValue;
			case Type.xor:          return leftValue ^ rightValue;
			case Type.and:          return leftValue & rightValue;
			case Type.or:           return leftValue | rightValue;
			case Type.greater:      return leftValue > rightValue;
			case Type.greaterEqual: return leftValue >= rightValue;
			case Type.less:         return leftValue < rightValue;
			case Type.lessEqual:    return leftValue <= rightValue;
			case Type.equal:        return leftValue == rightValue;
			case Type.notEqual:     return leftValue != rightValue;
			case Type.sar:          return leftValue >> rightValue;
			case Type.shr:          return (cast (ulong)
			    (leftValue)) >> rightValue;
			case Type.shl:          return leftValue << rightValue;
			}
		}

		auto cur1 = cast (UnaryOpExpression) (e);
		if (cur1 !is null) with (cur1)
		{
			auto value = evalExpression (expr);
			final switch (type)
			{
			case Type.plus:       return +value;
			case Type.minus:      return -value;
			case Type.not:        return !value;
			case Type.complement: return ~value;
			}
		}

		auto cur2 = cast (VarExpression) (e);
		if (cur2 !is null) with (cur2)
		{
			if (index is null)
			{
				return varValue (name);
			}
			else
			{
				auto indexValue = evalExpression (index);
				return arrayValue (name, indexValue);
			}
		}

		auto cur3 = cast (ConstExpression) (e);
		if (cur3 !is null) with (cur3)
		{
			return value;
		}

		auto cur4 = cast (CallExpression) (e);
		if (cur4 !is null) with (cur4)
		{
			return evalCall (cur4);
		}

		assert (false);
	}

	long * getAddr (VarExpression dest, bool canCreate)
	{
		long * res;
		if (dest.index is null)
		{
			res = varAddress (dest.name, canCreate);
		}
		else
		{
			auto indexValue = evalExpression (dest.index);
			res = arrayAddress (dest.name, indexValue);
		}
		return res;
	}

	void doAssign (AssignStatement cur, long * addr, long value)
	{
		with (cur) final switch (type)
		{
		case Type.assign:         *(addr) = value; break;
		case Type.assignAdd:      *(addr) += value; break;
		case Type.assignSubtract: *(addr) -= value; break;
		case Type.assignMultiply: *(addr) *= value; break;
		case Type.assignDivide:   *(addr) /= value; break;
		case Type.assignModulo:   *(addr) %= value; break;
		case Type.assignXor:      *(addr) ^= value; break;
		case Type.assignAnd:      *(addr) &= value; break;
		case Type.assignOr:       *(addr) |= value; break;
		case Type.assignSar:      *(addr) >>= value; break;
		case Type.assignShr:      *(cast (ulong *) (addr)) >>= value;
		    break;
		case Type.assignShl:      *(addr) <<= value; break;
		}
	}

	void runStatementReceive (AssignStatement cur, CallExpression call)
	{
		auto values = call.argumentList
		    .map !(e => evalExpression (e)).array;

		if (values.length < 1)
		{
			throw new Exception
			    ("receive: no first argument");
		}
		if (values[0] < 0 || control.num <= values[0])
		{
			throw new Exception ("receive: " ~
			    "first argument " ~
			    values[0].text ~ " not in [0.." ~
			    control.num.text ~ ")");
		}
		if (values.length > 1)
		{
			throw new Exception
			    ("receive: more than one argument");
		}

		auto otherId = values[0].to !(size_t);
		if (control.queues[otherId][id].empty)
		{
			state.back.pos -= 1;
			delay = 1;
			return;
		}

		auto addr = getAddr (cur.dest, true);
		doAssign (cur, addr, control.queues[otherId][id].front);
		control.queues[otherId][id].popFront ();
		control.queues[otherId][id].assumeSafeAppend ();
	}

	void runStatementArray (AssignStatement cur, CallExpression call)
	{
		auto values = call.argumentList
		    .map !(e => evalExpression (e)).array;

		if (values.length < 1)
		{
			throw new Exception
			    ("array: no first argument");
		}
		if (values[0] < 0)
		{
			throw new Exception ("array: " ~
			    "first argument is " ~ values[0].text);
		}
		if (values.length > 1)
		{
			throw new Exception
			    ("array: more than one argument");
		}

		if (cur.dest.index !is null)
		{
			throw new Exception
			    ("array: destination can not have index");
		}

		foreach_reverse (ref curState; state)
		{
			if (cur.dest.name in curState.arrays)
			{
				curState.arrays[cur.dest.name] =
				    Array (new long [values[0].to !(size_t)]);
				return;
			}
		}
		state.back.arrays[cur.dest.name] =
		    Array (new long [values[0].to !(size_t)]);
	}

	void runStatementImpl (Statement s)
	{
		auto cur0 = cast (AssignStatement) (s);
		if (cur0 !is null) with (cur0)
		{
			// special syntax for receive and array
			auto expr0 = cast (CallExpression) (expr);
			if (expr0 !is null && expr0.name == "receive")
			{
				runStatementReceive (cur0, expr0);
				return;
			}

			if (type == Type.assign &&
			    expr0 !is null && expr0.name == "array")
			{
				runStatementArray (cur0, expr0);
				return;
			}

			auto value = evalExpression (expr);
			auto addr = getAddr (dest, type == Type.assign);
			doAssign (cur0, addr, value);
			delay = complexity;
			return;
		}

		auto cur1 = cast (CallStatement) (s);
		if (cur1 !is null) with (cur1)
		{
			evalCall (call);
			delay = complexity;
			return;
		}

		state ~= Context (s, -1);
	}

	void runStatement (Statement s)
	{
		try
		{
			runStatementImpl (s);
		}
		catch (Exception e)
		{
			throw new Exception (format
			    ("line %s: %s", s.lineId, e.msg));
		}
	}

	bool step ()
	{
		if (delay > 0)
		{
			delay -= 1;
			return true;
		}

		if (state.empty)
		{
			return false;
		}

		with (state.back)
		{
			auto cur0 = cast (FunctionBlock) (parent);
			if (cur0 !is null) with (cur0)
			{
				if (pos < 0)
				{
					pos += 1;
					block = statementList;
					delay = complexity;
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
			if (cur1 !is null) with (cur1)
			{
				if (pos < 0)
				{
					auto value = evalExpression (cond);
					block = value ?
					    statementListTrue :
					    statementListFalse;
					pos += 1;
					delay = complexity;
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

			auto cur2 = cast (WhileBlock) (parent);
			if (cur2 !is null) with (cur2)
			{
				if (pos >= block.length)
				{
					pos = -1;
				}
				if (pos < 0)
				{
					auto value = evalExpression (cond);
					delay = complexity;
					if (value)
					{
						block = statementList;
						pos += 1;
					}
					else
					{
						state.popBack ();
					}
				}
				else
				{
					pos += 1;
					runStatement (block[pos - 1]);
				}
				return true;
			}

			auto cur3 = cast (ForBlock) (parent);
			if (cur3 !is null) with (cur3)
			{
				if (pos < 0)
				{
					block = statementList;
					auto startValue =
					    evalExpression (start);
					auto finishValue =
					    evalExpression (finish);
					vars[name] = Var (startValue);
					delay = complexity;
					delay += 3;
					bool hasNext;
					final switch(style) {
						case ForStyle.until:
							hasNext = vars[name].value < finishValue;
							break;
						case ForStyle.rangeto:
							hasNext = vars[name].value <= finishValue;
							break;
						case ForStyle.downto:
							hasNext = vars[name].value >= finishValue;
							break;
					}
					if (hasNext)
					{
						pos += 1;
					}
					else
					{
						state.popBack ();
					}
				}
				else if (pos >= block.length)
				{
					auto finishValue =
					    evalExpression (finish);
					final switch(style) {
						case ForStyle.rangeto:
						case ForStyle.until:
							vars[name].value += 1;
							break;
						case ForStyle.downto:
							vars[name].value -= 1;
							break;
					}
					delay += 7;
					bool hasNext;
					final switch(style) {
						case ForStyle.until:
							hasNext = vars[name].value < finishValue;
							break;
						case ForStyle.rangeto:
							hasNext = vars[name].value <= finishValue;
							break;
						case ForStyle.downto:
							hasNext = vars[name].value >= finishValue;
							break;
					}
					if (hasNext)
					{
						pos = 0;
					}
					else
					{
						state.popBack ();
					}
				}
				else
				{
					pos += 1;
					runStatement (block[pos - 1]);
				}
				return true;
			}

			assert (false);
		}
	}
}

class RunnerControl
{
	Runner [] runners;
	long [] [] [] queues;

	@property int num () const
	{
		return runners.length.to !(int);
	}

	this (Args...) (int num_, FunctionBlock p, Args args)
	{
		runners = new Runner [num_];
		foreach (i, ref r; runners)
		{
			r = new Runner (this, i.to !(int), p,
			    i.to !(int), num_, args);
		}
		queues = new long [] [] [] (num_, num_);
	}

	bool step ()
	{
		bool isRunning = false;
		foreach (ref r; runners)
		{
			try
			{
				isRunning |= r.step ();
			}
			catch (Exception e)
			{
				throw new Exception (format
				    ("id %s, %s", r.id, e.msg));
			}
		}
		return isRunning;
	}
}
