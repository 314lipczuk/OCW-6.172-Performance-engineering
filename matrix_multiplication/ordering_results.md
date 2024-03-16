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






