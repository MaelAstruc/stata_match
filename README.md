# Pattern Matching for Stata

This package introduces the `pmatch` command, which provides an alternative syntax to series of 'replace ... if ...' statements. It limits repetitions and might feel familiar for users coming from other programming languages with pattern matching.

Beyond the new syntax, the `pmatch` command provides run-time checks for the exhaustiveness and the usefulness of the conditions provided. The exhaustiveness check means that the command will tell you if some levels are not covered and which ones are missing. The usefulness check means that the command will tell you if the conditions you specified in each arm are useful, or if some of them overlap with previous ones.

The command is inspired by the [Rust](https://www.rust-lang.org/) Programming Language [pattern syntax](https://doc.rust-lang.org/book/ch18-03-pattern-syntax.html) and [algorithm](https://doi.org/10.1017/S0956796807006223).

For more information on the syntax and for examples, check the documentation [pdf](https://github.com/MaelAstruc/stata_match/blob/master/docs/pmatch.pdf).

*WARNING*: This project is still under development, the core of the algorithm is implemented but the syntax and features are still evolving.

# How to install

The code can be installed from this repository with:

```
net install pmatch, from("https://raw.githubusercontent.com/MaelAstruc/stata_match/master/pkg")
```

## Limitations

Missing types

- I haven't checked any type apart from numerics and strings.
- Dates would be interesting especially with the range, but they are not covered for now.
- Comparing two variables would be useful, but it would require to define new patterns and greatly modify the algorithm I think.

## Performance

- Because Stata is a dynamically typed language, the levels of the variables are checked in the database similarly to `levelsof`.
- The exhaustiveness and usefulness are also checked at run time.
- With small databases (less than 1M observations), the performance cost is lower than 0.1s.
- With larger databases, getting the levels of the variables is costly, especially for string variables.
- You can check the latest end-to-end performance tests logs in [dev/logs](https://github.com/MaelAstruc/stata_match/tree/master/dev/logs).
    - The measures are in seconds.
	- The first line measures the time needed to run the equivalent `replace ... if ...` statements.
	- The last line measure the total time needed to run the `pmatch` command.
	- The last column gives the average difference in seconds.
	- The '%base' column compares the mean of each line to the average 'base' time.
