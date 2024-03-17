# Evaluated for multiplying random matrix by diagonal matrix of 2.
Results from mac m2.
### Ordering 0:
89697.4ms
89.7s
### Ordering 1:
47489.6ms
47.5s
### Ordering 2:
92339.5ms
92.3s
### Ordering 3:
120790.7ms
120.8s
### Ordering 4:
47466.5ms
47.5s
### Ordering 5:
122780.0ms
122.8s

## Results
So, by that i can tell that ACB and CAB are the ones that work.

```txt
            column
              |
              |
              v
      |     | a b c |    <------ 
  i   |     | d e f |           |
      v     | g h i |           |
----->                          |
                                |
| a b c |                       row
| d e f |                       |
| g h i |    <------------------


and the working ones are:

CAB (4):
for (0..N) |i| {            // C
    for (0..N) |c_row| {    // A
        for (0..N) |c_col| {// B
            result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
        }
    }
}

ACB (1):
for (0..N) |c_row| {        // A
    for (0..N) |i| {        // C
        for (0..N) |c_col| {// B
            result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
        }
    }
}

```

Why is this faster?
What's the access pattern?

cache lines
TODO: explain it 

# Cachegrind

Results from running (on different, x86 machine)

### Fast ordering:

```txt
==3301== Cachegrind, a cache and branch-prediction profiler
==3301== Copyright (C) 2002-2017, and GNU GPL'd, by Nicholas Nethercote et al.
==3301== Using Valgrind-3.18.1 and LibVEX; rerun with -h for copyright info
==3301== Command: ./main
==3301==
--3301-- warning: L3 cache found, using its data for the LL simulation.
Timing for a 1024x1024 matrix multiply:
926024.0ms
926.0s
Total operations: 1.07374182e+09
therefore FLOPS:1.15951837e+06
==3301==
==3301== I   refs:      103,897,262,395
==3301== I1  misses:                954
==3301== LLi misses:                918
==3301== I1  miss rate:            0.00%
==3301== LLi miss rate:            0.00%
==3301==
==3301== D   refs:       60,601,974,024  (39,957,061,890 rd   + 20,644,912,134 wr)
==3301== D1  misses:         68,814,179  (    68,223,100 rd   +        591,079 wr)
==3301== LLd misses:         68,814,178  (    68,223,099 rd   +        591,079 wr)
==3301== D1  miss rate:             0.1% (           0.2%     +            0.0%  )
==3301== LLd miss rate:             0.1% (           0.2%     +            0.0%  )
==3301==
==3301== LL refs:            68,815,133  (    68,224,054 rd   +        591,079 wr)
==3301== LL misses:          68,815,096  (    68,224,017 rd   +        591,079 wr)
==3301== LL miss rate:              0.0% (           0.0%     +            0.0%  )
```


### Slow ordering:

```txt

==3384== Cachegrind, a cache and branch-prediction profiler
==3384== Copyright (C) 2002-2017, and GNU GPL'd, by Nicholas Nethercote et al.
==3384== Using Valgrind-3.18.1 and LibVEX; rerun with -h for copyright info
==3384== Command: ./main
==3384==
--3384-- warning: L3 cache found, using its data for the LL simulation.
Timing for a 1024x1024 matrix multiply:
933923.9ms
933.9s
Total operations: 1.07374182e+09
therefore FLOPS:1.14971025e+06
==3384==
==3384== I   refs:      103,897,262,753
==3384== I1  misses:                940
==3384== LLi misses:                907
==3384== I1  miss rate:            0.00%
==3384== LLi miss rate:            0.00%
==3384==
==3384== D   refs:       60,601,974,196  (39,957,062,002 rd   + 20,644,912,194 wr)
==3384== D1  misses:      1,075,577,186  ( 1,074,985,084 rd   +        592,102 wr)
==3384== LLd misses:      1,075,488,357  ( 1,074,896,255 rd   +        592,102 wr)
==3384== D1  miss rate:             1.8% (           2.7%     +            0.0%  )
==3384== LLd miss rate:             1.8% (           2.7%     +            0.0%  )
==3384==
==3384== LL refs:         1,075,578,126  ( 1,074,986,024 rd   +        592,102 wr)
==3384== LL misses:       1,075,489,264  ( 1,074,897,162 rd   +        592,102 wr)
==3384== LL miss rate:              0.7% (           0.7%     +            0.0%  )
```

## Cachegrind - Conclusion

Slow ordering did in fact affect cache miss rate, and therefore performance. This example is somewhat small, and therefore i'm not sure if it's sufficient to demonstrate it.

One thing that actually is interesting though, is how current 'fast' ordering would fare against 
an even more expanded version, that partitions the matrix further to fit within the cache line size restriction. Actually, before trying anything i should probably look at current compiled assembly.



