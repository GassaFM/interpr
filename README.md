## Pr

(К [русской](README.ru.md#pr) версии)

This is an interpreter for Pr, a toy language to learn parallel computing.

This document starts with an [example](#example) showcasing the language and its usage.
Then follows a section on [syntax](#syntax) with formal definitions.
After that, it discusses command-line [invocation](#invocation) and options.

Grab a Windows executable, or the source code, in the [releases](https://github.com/GassaFM/interpr/releases) section.

## Example

### Example Problem

Given a sequence of integers, compute and print their sum.

### Example Solution: Naive

```
function sum (id, pr, n, a):
    if id == 0:
        s := 0
        for i := 0 until n:
            s += a[i]
        print (s)
```

Let us read it, line by line.

```1: function sum (id, pr, n, a):```

This starts a function definition.
The function is called `sum`, and its parameters are:

* `id`, the id of the process
* `pr`, the total number of processes
* `n`, the size of the given sequence of integers
* `a`, the sequence of integers

```2:     if id == 0:```

The following block will run only for the first process.

```3:         s := 0```

Create a variable named `s` and initialize it with constant `0`.

```4:         for i := 0 until n:```

The following block will be run for `i = 0`, `i = 1`, and so on, all the way to `i = n - 1`.
Note that the upper bound, `n`, is excluded: the loop runs `until` the condition is satisfied, but no more.

```5:             s += a[i]```

Add `a[i]` to the sum.

```6:         print (s)```

Print the sum, followed by end of line.
Note the indentation: it is outside the `for` block but inside the `if` block.

### Example Solution: Parallel

But what if we have 100 processes instead of just one?
Here is a solution that utilizes them for some speed gain.

```
function sum (id, pr, n, a):
    lo := id * n / pr
    hi := (id + 1) * n / pr

    s := 0
    for i := lo until hi:
        s += a[i]
    send (0, s)

    if id == 0:
        r := 0
        for k := 0 until pr:
            r += receive (k)
        print (r)
```

Here, each process has a range `[lo..hi)` to process.
It computes the sum for the range, and `send`s the result to process 0.
After that, process 0 `receive`s partial sums from all processes, including itself, sums them up, and prints the total.

Message passing works as follows.
There are `pr` * `pr` message queues, one for every ordered pair of processes.
For process `id`:

* Function `send (dest, ...)` pushes data to the message queue from `id` to `dest`.
* Function `receive (from)` returns the next data item from the message queue from `from` to `id`.
It blocks execution of `id` until the data is available.

Functions `send` can send one or more integer values, separated by commas.
Function `receive` retrieves one value from the queue.

### Example Solution: Alternative

Here is another take at parallelizing the computations.

```
function sum (id, pr, n, a):
    s := 0
    i := id
    while i < n:
        s += a[i]
        i += pr

    left := id * 2 + 1
    right := left + 1
    if left < pr:
        s += receive (left)
    if right < pr:
        s += receive (right)

    send ((id - 1) / 2, s)

    if id == 0:
        print (s)
```

There are two key differences.

* Process `id` sums up the values `a[id]`, `a[id + pr]`, `a[id + 2 * pr]`, and so on.

* The final collecting step is organized in a tree-like fashion:
process `id` sums up two values from processes `id * 2 + 1` and `id * 2 + 2`,
and sends the sum to process `(id - 1) / 2`.
So, for example, process `5` receives from processes `11` and `12`,
and sends the sum to process `2`.
At the root of the tree, process `0` is the one printing the total.

## Syntax

Here is a summary of language syntax.

### Variables

There are two data types in Pr: 64-bit signed integers and arrays of 64-bit signed integers.
An integer variable is addressed by its name, as `<name>`.
An array element is addressed by array name and element index, as `<name>[<expr>]`.
Each variable is visible in the block where it was declared, and all nested blocks.
A name can contain alphanumeric characters and underscores, and can not start with a digit.

### Functions

Each program is a single function declared as:
```
function <name> (<arg1>, <arg2>, ...):
    <statement1>
    <statement2>
    ...
```

The first two arguments are the id of the process the number of processes.
The rest are problem-specific data.
All function arguments are constants, they can not be changed.

Function header is followed by statements, one per line, all using the same indentation.

There are four special functions defined as well:

* `print (<expr1>, <expr2>, ...)` prints the values of the expressions separated by spaces,
followed by end of line.

* `<name> := array (<len>)` creates an array of length `<len>`, fills it with zeroes,
and assigns the name `<name>` to it.

* `send (<dest>, <expr1>, <expr2>, ...)` sends the values of the expressions to process `<dest>`.

* `<var> <assignOp> receive (<from>)` receives the next value from process `<from>`,
waiting for it if necessary, and uses assignment operator `<assignOp>`
to alter the value of variable `<var>`.

No other functions are allowed.

### Statements

A statement can have one of the following forms:

* `<var> <assignOp> <expr>` is an assignment statement.
It computes the value of `<expr>`, and uses assignment operator `<assignOp>`
to alter the value of variable `<var>`.
The assignment operator can be one of the following:
`:=`, `+=`, `-=`, `*=`, `/=`, `%=`, `^=`, `|=`, `&=`, `>>=`, `>>>=`, `<<=`.

* `<name> (<arg1>, <arg2>, ...)` is a call statement.
It calls the function `<name>` with respective arguments.

* `if <cond>:` is an if block.
It is followed by one or more statements using the same deeper indentation.
The statements are executed if the expression `<cond>` evaluates to non-zero.
They are then optionally followed by an `else:` line, indented the same as `if`,
and one or more statements using the same deeper indentation again.
This group of statements is executed if the expression `<cond>` evaluates to zero.

* `while <cond>:` is a while block.
It is followed by one or more statements using the same deeper indentation.
As long as the expression `<cond>` evaluates to non-zero,
the statements are executed from top to bottom, and `<cond>` is evaluated again.

* `for <name> := <start> until <finish>:` is a for block.
It is followed by one or more statements using the same deeper indentation.
It first assigns the value of expression `<start>` to variable `<name>`.
Then, as long as `<name>` is strictly less than the value of expression `<finish>`,
the statements are executed from top to bottom, the variable is increased by one,
and the condition is evaluated again.

### Expressions

An expression can have one of the following forms:

* `<left> <binaryOp> <right>` is a binary operator expression.
The possible binary operators are, grouped from lower to higher priority:
  - `|` (bitwise or)
  - `^` (bitwise xor)
  - `&` (bitwise and)
  - `==` (equal), `!=` (not equal)
  - `>` (greater), `>=` (greater or equal), `<` (less), `<=` (less or equal)
  - `>>` (arithmetic shift right), `>>>` (logical shift right), `<<` (shift left)
  - `+` (add), `-` (subtract),
  - `*` (multiply), `/` (divide), `%` (modulo)

Operators with the same priority are processed from left to right.
The priorities are the same as in C language.

* <unaryOp> <expr> is an unary operator expression.
The possible unary operators are `+` (unary plus), `-` (unary minus),
`!` (logical negation), and `~` (bitwise complement).
As unary operators are on the left side of their argument, they apply from right to left.

* `<name> (arg1, arg2, ...)` is a call expression.
It calls the function `<name>` with respective arguments.

* `(<expr>)` are parentheses, useful to prioritize some expression, or just for readability.

* Variables come as either `<name>` for 64-bit integers or `<name>[<expr>]` for array elements.

* Constants are numbers in decimal notation, composed entirely of decimal digits.

## Invocation

The interpreter can be invoked on the command line as follows:

```interpr [options] program.pr [< input.txt] [> output.txt]```

Here, `program.pr` is the program to run.

If you are new to command line, it is useful to know that you can
add `< input.txt` to read input from a file (instead of standard input),
and add `> output.txt` to write output to a file (instead of standard output).

The available options are:
* `-c` check syntax only, do not run
* `-d` display the program with line numbers and complexity (in steps) for each line
* `-n <pr>` set the number of processes (default: 100)
* `-s <steps>` set the maximum number of steps (default: 1000000)
