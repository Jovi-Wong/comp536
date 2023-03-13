README: COMP 436 Course Project MS1

This milestone contains the code necessary for handling GET, PUT, SELECT, and RANGE
queries. It also contains the implementation for versioning (extra credit).

Files contained in the folder:
   Makefile: makefile for building MS1
   ms1.p4: p4 implementation for the switch logic
   send.py: python script for sending queries
   receive.py: python script for receiving packets
   topology.json: network topology
   MS1GetAndPutTest: script for testing get and puts
   MS1RangeAndSelectTest: script for testing range and select
   MS1VersionTest: script for testing versioning
   MS1ErrorTest: script for testing edge and error cases
   TestSuite.sh: script that runs all tests and verifies correctness
   TestUtil.py: python support for test-running script
   MS1ExpectedOutput.out: expected output (reference) for running all tests in the suite
   s1-runtime.json: runtime configuration for s1

To test this milestone with your own queries, simply do the following:
   1. Run the 'make' command in this folder.
   2. Once in mininet, run 'xterm h1 h1' (single host implementation)
   3. In one of the terminals, run './receive.py'
   4. In the other terminal, invoke send.py with the following usage:
      PUT: ./send.py put <key> <value>
      GET: ./send.py get <key> <version>
      RANGE: ./send.py range <lower index> <upper index> <version>
      SELECT: ./send.py select <qualifier> <k> <version>
         Valid qualifiers for select include:
            <: 'l'
            <=: 'leq'
            ==: 'eq'
            >=: 'geq'
            >: 'g'
      
      So for example, if you want to perform SELECT(k >= 100) on version 3 in the database, the command would be:

         ./send.py select geq 100 3
      
   5. You should see the result of the query execution in the terminal running receive.py, or an error message if the query was rejected/illegal.

To run the test suite, follow steps 1 and 2 as described above. Then, do the following:
   1. In one of the terminals, run './TestSuite.sh'
   2. The script should automatically execute each of the tests. If the tests are successful, you should see it print "All tests passed." Otherwise, it will report
   that it has found an error.

If you want to make use of the individual test scripts, you will do the same thing 
as testing with your own queries, except, instead of running ./send.py with your own
command, you can invoke any of the shell testing scripts in the sender's window.

PLEASE NOTE: The database is persistent until mininet is closed. So, if you try to 
run the test suite multiple times, the behavior may not be what is expected. The 
safest way to handle this is just to exit and restart mininet before each execution
of the test scripts, so that previous operations do not affect future tests.