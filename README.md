Simple function call generator with time measurment.


Usage:

Call 100x

   timer:sleep(3).

1> fcg:run(timer,sleep,[3], 100). 
calls: 100, tot:400214 uSec, call: 4002.14 uSec


Call the same, but in 5 threads (processes)


2> fcg:prun(timer,sleep,[3], 100, 5). 
calls: 100, tot:396813 uSec, call: 3968.13 uSec
run tinme: 79396

Reported times are in microseconds.
