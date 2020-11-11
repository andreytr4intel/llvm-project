# Getting Started for DExTer (Debugging Experience Tester)

## Installing

Download DExTer (clone Git repository).

If you have exception about RPyC interface, you need to install rpyc module for the first time:

    python3 -m pip install rpyc --user

Check first that GDB debugger is available for DExTer:

    python3 dexter.py list-debuggers

Should be line:

    gdb    [gdb]                YES (9.1)

with green "YES".

## Running a test case

    cd path/to/dexter/

    python3 dexter.py test --binary tests/nostdlib/fibonacci/test --debugger gdb -v -- tests/nostdlib/fibonacci
