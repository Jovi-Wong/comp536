errors = 0

with open('MS1TestOutput.out') as output, open('MS1ExpectedOutput.out') as expected:
    actual = filter(lambda x: not x.startswith("sniffing on h1") and not x.startswith("---"), output.readlines())
    ref = expected.readlines()

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