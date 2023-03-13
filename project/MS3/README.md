README: COMP 436 Course Project MS3

This milestone contains the code necessary for the implementation of Access Control
Lists and Rate Limits. 

Files contained in the folder:
   Makefile: makefile for building MS3
   ms2-0.p4: Load balancer switch implementation
   ms2-1.p4: Switch 1 implementation
   ms2-2.p4: Switch 2 implementation
   ms2-3.p4: Backup switch implementation
   sendA.py: python script for sending queries for Alice
   sendB.py: python script for sending queries for Bob
   receive.py: python script for receiving packets
   topology.json: network topology
   MS3ReadWriteAccessTest: tests that Alice and Bob can only read and write to 
   their authorized areas.
   MS3RateLimitTest: tests that Alice and Bob's queries are rejected after reaching
   their rate limit.
   TestSuite.sh: script that runs all tests and verifies correctness
   TestUtil.py: python support for test-running script
   MS3ExpectedOutput.out: expected output (reference) for running all tests in the suite
   s0-runtime.json: runtime configuration for s0
   s1-runtime.json: runtime configuration for s1
   s2-runtime.json: runtime configuration for s2
   s3-runtime.json: runtime configuration for s3

The usage is almost the same as MS2, however, please note that ping/pong packets and 
switch information is suppressed from being printed in MS3. 

To test this milestone with your own queries, simply do the following:
   1. Run the 'make' command in this folder.
   2. Once in mininet, run 'xterm h1 h1' (single host implementation)
   3. In one of the terminals, run './receive.py'
   4. In the other terminal, invoke sendA.py (Alice) or sendB.py (Bob) with the following usage:
      PUT: ./sendA.py put <key> <value>
      GET: ./sendA.py get <key>
      RANGE: ./sendA.py range <lower index> <upper index> 
      SELECT: ./sendA.py select <qualifier> <k>
         Valid qualifiers for select include:
            <: 'l'
            <=: 'leq'
            ==: 'eq'
            >=: 'geq'
            >: 'g'
      
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