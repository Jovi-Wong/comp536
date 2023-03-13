errors = 0

with open('MS2TestOutput.out') as output, open('MS2ExpectedOutput.out') as expected:
    actual = filter(lambda x: not x.startswith("sniffing on h1") and not x.startswith("---"), output.readlines())
    ref = expected.readlines()

    before = len(actual)
    actual = filter(lambda x: not x.startswith("Pong received by"), actual)
    after = len(actual)

    numPongs = before - after
    
    if numPongs != 4:
        print "Incorrect number of pongs."
        errors += 1

    if len(actual) != len(ref):
        print "Output mismatch"
        errors += 1
        
    else:
        for i in range(len(ref)):
            if ref[i] != actual[i]:
                errors += 1

if errors == 0:
    print "All tests passed."
else:
    print "Found at least " + str(errors) + " error in testing."