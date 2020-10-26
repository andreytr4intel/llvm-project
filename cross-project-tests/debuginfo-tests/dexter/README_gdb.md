# DExTer (Debugging Experience Tester)

## Introduction

DExTer is a suite of tools used to evaluate the "User Debugging Experience". DExTer drives an external debugger, running on small test programs, and collects information on the behavior at each debugger step to provide quantitative values that indicate the quality of the debugging experience.

## Supported Debuggers

DExTer currently supports GDB debugger via [RPyC interface](https://pypi.org/project/rpyc/) (see [doc](https://rpyc.readthedocs.io/en/latest/)), LLDB via its [Python interface](https://lldb.llvm.org/python-reference.html) and the Visual Studio 2015 and Visual Studio 2017 debuggers via the [DTE interface](https://docs.microsoft.com/en-us/dotnet/api/envdte.dte).

The following command evaluates your environment, listing the available and compatible debuggers:

    python3 dexter.py list-debuggers

Should be line:

    gdb    [gdb]                YES (9.1)

with green "YES".

If you have "python" symlink to "python3", you can ommit latter, i.e.:

    dexter.py list-debuggers

And the same for all rest following dexter.py commands.

## Dependencies
[TODO] Add a requirements.txt or an install.py and document it here.

### Python 3.6

DExTer requires python version 3.6 or greater.

### rpyc python package

This is required to access the RPyC interface for the GDB debugger.

    <python-executable> -m pip install rpyc --user

### gcc

DExTer is currently compatible also with 'gcc' and 'g++' compiler drivers.  The compiler must be available for DExTer, for example the following command should successfully build a runnable executable.

     <compiler-executable> tests/nostdlib/fibonacci/test.cpp

## Running a test case

The following DExTer commands build the test.cpp from the tests/nostdlib/fibonacci directory and quietly runs it on the GDB debugger, reporting the debug experience heuristic.  The first command builds with no optimizations and scores 1.0000.  The second command builds with optimizations (-O2) and scores 0.2566 which suggests a worse debugging experience.

    python3 dexter.py test --builder clang --debugger gdb --cflags="-g" --ldflags="-g" -- tests/nostdlib/fibonacci
    fibonacci: (1.0000)

    python3 dexter.py test --builder clang --debugger gdb --cflags="-O2 -g" --ldflags="-g" -- tests/nostdlib/fibonacci
    fibonacci: (0.2566)

## An example test case

The sample test case (tests/nostdlib/fibonacci) looks like this:

    1.  #ifdef _MSC_VER
    2.  # define DEX_NOINLINE __declspec(noinline)
    3.  #else
    4.  # define DEX_NOINLINE __attribute__((__noinline__))
    5.  #endif
    6.
    7.  DEX_NOINLINE
    8.  void Fibonacci(int terms, int& total)
    9.  {
    10.     int first = 0;
    11.     int second = 1;
    12.     for (int i = 0; i < terms; ++i)
    13.     {
    14.         int next = first + second; // DexLabel('start')
    15.         total += first;
    16.         first = second;
    17.         second = next;             // DexLabel('end')
    18.     }
    19. }
    20.
    21. int main()
    22. {
    23.     int total = 0;
    24.     Fibonacci(5, total);
    25.     return total;
    26. }
    27.
    28. /*
    29. DexExpectWatchValue('i', '0', '1', '2', '3', '4',
    30.                     from_line=ref('start'), to_line=ref('end'))
    31. DexExpectWatchValue('first', '0', '1', '2', '3', '5',
    32.                     from_line=ref('start'), to_line=ref('end'))
    33. DexExpectWatchValue('second', '1', '2', '3', '5',
    34.                     from_line=ref('start'), to_line=ref('end'))
    35. DexExpectWatchValue('total', '0', '1', '2', '4', '7',
    36.                     from_line=ref('start'), to_line=ref('end'))
    37. DexExpectWatchValue('next', '1', '2', '3', '5', '8',
    38.                     from_line=ref('start'), to_line=ref('end'))
    39. DexExpectWatchValue('total', '7', on_line=25)
    40. DexExpectStepKind('FUNC_EXTERNAL', 0)
    41. */

[DexLabel][1] is used to give a name to a line number.

The [DexExpectWatchValue][2] command states that an expression, e.g. `i`, should
have particular values, `'0', '1', '2', '3','4'`, sequentially over the program
lifetime on particular lines. You can refer to a named line or simply the line
number (See line 39).

At the end of the test is the following line:

    DexExpectStepKind('FUNC_EXTERNAL', 0)

This [DexExpectStepKind][3] command indicates that we do not expect the debugger
to step into a file outside of the test directory.

[1]: Commands.md#DexLabel
[2]: Commands.md#DexExpectWatchValue
[3]: Commands.md#DexExpectStepKind

## Detailed DExTer reports

Running the command below launches the tests/nostdlib/fibonacci test case in DExTer, using clang as the compiler, GDB as the debugger, and producing a detailed report:

    python3 dexter.py test --builder clang --debugger gdb --cflags="-O2 -g" --ldflags="-g" -v -- tests/nostdlib/fibonacci

The detailed report is enabled by `-v` and shows a breakdown of the information from each debugger step. For example:

    fibonacci: (0.2566)

    ## BEGIN ##
    [1, "main()", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 23, 0, "StopReason.BREAKPOINT", "StepKind.FUNC", []]
    [2, "main()", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 24, 0, "StopReason.BREAKPOINT", "StepKind.VERTICAL_FORWARD", []]
    .   [3, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 12, 0, "StopReason.BREAKPOINT", "StepKind.FUNC", []]
    .   [4, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 15, 0, "StopReason.BREAKPOINT", "StepKind.VERTICAL_FORWARD", []]
    .   [5, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 12, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [6, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 15, 0, "StopReason.OTHER", "StepKind.VERTICAL_FORWARD", []]
    .   [7, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 14, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [8, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 12, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [9, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 15, 0, "StopReason.OTHER", "StepKind.VERTICAL_FORWARD", []]
    .   [10, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 14, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [11, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 12, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [12, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 15, 0, "StopReason.OTHER", "StepKind.VERTICAL_FORWARD", []]
    .   [13, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 14, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [14, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 12, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [15, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 15, 0, "StopReason.OTHER", "StepKind.VERTICAL_FORWARD", []]
    .   [16, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 14, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [17, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 12, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [18, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 15, 0, "StopReason.OTHER", "StepKind.VERTICAL_FORWARD", []]
    .   [19, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 14, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [20, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 12, 0, "StopReason.OTHER", "StepKind.VERTICAL_BACKWARD", []]
    .   [21, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 15, 0, "StopReason.OTHER", "StepKind.VERTICAL_FORWARD", []]
    .   [22, "Fibonacci(int, int&)", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 19, 0, "StopReason.BREAKPOINT", "StepKind.VERTICAL_FORWARD", []]
    [23, "main()", ".../dexter/tests/nostdlib/fibonacci/test.cpp", 25, 0, "StopReason.BREAKPOINT", "StepKind.VERTICAL_FORWARD", []]
    ## END (23 steps) ##


      step kind differences [0/1]
        StepKind.FUNC_EXTERNAL:
          0

      test.cpp:14-17 [first] ExpectValue [9/21]
        expected encountered watches:
          0
          1
          2
          3

        missing values:
          5 [-6]

        result optimized away:
          step 6 (0) [-3]
          step 9 (0)
          step 12 (0)
          step 15 (0)
          step 18 (0)
          step 21 (0)

      test.cpp:14-17 [i] ExpectValue [21/21]
        expected encountered watches:
          0

        missing values:
          1 [-6]
          2 [-6]
          3 [-6]
          4 [-3]

      test.cpp:14-17 [next] ExpectValue [16/21]
        expected encountered watches:
          1
          2
          3
          5

        missing values:
          8 [-6]

        result optimized away:
          step 4 (0) [-3]
          step 21 (0)

        unexpected result:
          step 6 (4) [-7]
          step 7 (4)

      test.cpp:14-17 [second] ExpectValue [17/21]
        expected encountered watches:
          1
          2
          3
          5

        result optimized away:
          step 21 (0) [-3]

        unexpected result:
          step 6 (4) [-7]
          step 7 (4) [-7]

      test.cpp:14-17 [total] ExpectValue [21/21]
        expected encountered watches:
          0

        missing values:
          1 [-6]
          2 [-6]
          4 [-6]
          7 [-3]

      test.cpp:25 [total] ExpectValue [0/7]
        expected encountered watches:
          7

The first line

    fibonacci: (0.2566)

shows a score of 0.2566 suggesting that unexpected behavior has been seen.  This score is on scale of 0.0000 to 1.0000, with 0.0000 being the worst score possible and 1.0000 being the best score possible.  The verbose output shows the reason for any scoring.  For example:

      test.cpp:14-17 [first] ExpectValue [9/21]
        expected encountered watches:
          0
          1
          2
          3

        missing values:
          5 [-6]

        result optimized away:
          step 6 (0) [-3]
          step 9 (0)
          step 12 (0)
          step 15 (0)
          step 18 (0)
          step 21 (0)

shows that for `first` the expected values 0, 1, 2 and 3 were seen, 5 was not.  On some steps the variable was reported as being optimized away.
