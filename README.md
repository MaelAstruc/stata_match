# Pattern Matching for Stata

This package introduces the `patmatch` command, which provides an alternative syntax to series of 'replace ... if ...' statements. It limits repetitions and might feel familiar for users coming from other programming languages with pattern matching.

Beyond the new syntax, the `patmatch` command provides run-time checks for the exhaustiveness and the usefulness of the conditions provided. The exhaustiveness check means that the command will tell you if some levels are not covered and which ones are missing. The usefulness check means that the command will tell you if the conditions you specified in each arm are useful, or if some of them overlap with previous ones.

The command is inspired by the [Rust](https://www.rust-lang.org/) Programming Language [pattern syntax](https://doc.rust-lang.org/book/ch18-03-pattern-syntax.html) and [algorithm](https://doi.org/10.1017/S0956796807006223).

For more information on the syntax and for examples, check the documentation [pdf](https://github.com/MaelAstruc/patmatch/blob/master/pkg/patmatch.pdf).

## Why patmatch?

- Safer alternative to long replace-if chains
- Exhaustiveness checking
- Overlap/usefulness diagnostics
- Tuple and range patterns
- Familiar syntax inspired by Rust

`patmatch` checks:
- missing cases (non exhaustive matches)
- unreachable arms
- overlapping patterns

## How to install

The code can be installed from this repository with:

```{Stata}
net install patmatch, replace from("https://raw.githubusercontent.com/MaelAstruc/patmatch/master/pkg")
```

## Examples

In this example, we use the values of the variable *rep78* to create a new variables using the normal way (*var_1*) and with the *patmatch* command (*var_2*), using Constant patterns with the '*x*' syntax.

```{Stata}
sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "very low"      if rep78 == 1
replace var_1 = "low"           if rep78 == 2
replace var_1 = "mid"           if rep78 == 3
replace var_1 = "high"          if rep78 == 4
replace var_1 = "very high"     if rep78 == 5
replace var_1 = "missing"       if rep78 == .

* With the patmatch command

patmatch var_2, variables(rep78) body( ///
    1 = "very low",                 ///
    2 = "low",                      ///
    3 = "mid",                      ///
    4 = "high",                     ///
    5 = "very high",                ///
    . = "missing",                  ///
)

assert var_1 == var_2
```

Other patterns let you cover all possible cases such as **Ranges**, **Or** and **Tuples**. However, the objective of the `patmatch` command is ***correctness***.

If we forgot to include the case where *rep_78* is missing, the command will print a warning.

```{Stata}
sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "very low"      if rep78 == 1
replace var_1 = "low"           if rep78 == 2
replace var_1 = "mid"           if rep78 == 3
replace var_1 = "high"          if rep78 == 4
replace var_1 = "very high"     if rep78 == 5

* With the patmatch command

patmatch var_2, variables(rep78) body( ///
    1 = "very low",                 ///
    2 = "low",                      ///
    3 = "mid",                      ///
    4 = "high",                     ///
    5 = "very high",                ///
)

// Warning : Missing cases
//     .

assert var_1 == var_2
```

We can also include conditions which are already checked by the previous arms.

```{Stata}
sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "cheap"        if price >= 0    & price <  6000
replace var_1 = "normal"       if price >= 6000 & price <  9000
replace var_1 = "expensive"    if price >= 9000 & price <= 16000
replace var_1 = "missing"      if price == .

* With the patmatch command

patmatch var_2, variables(price) body( ///
    min/!6000  = "cheap",           ///
    6000/!9000 = "normal",          ///
    9000/max   = "expensive",       ///
    min/max    = "oops",            ///
    .          = "missing",         ///
)

// Warning : Arm 4 is not useful
// Warning : Arm 4 has overlaps
//     Arm 1: 3291/5999
//     Arm 2: 6000/8999
//     Arm 3: 9000/15906


assert var_1 == var_2
```

## Limitations

Missing types

- Dates would be interesting especially with the range, but they are not covered for now.

## Performance

- Because Stata is a dynamically typed language, the levels of the variables are checked in the database similarly to `levelsof`.
- The exhaustiveness and usefulness are also checked at run time.
- With small databases (less than 1M observations), the performance cost is lower than 0.1s.
- With larger databases, getting the levels of the variables is costly, especially for string variables.
- You can check the latest end-to-end performance tests logs in [dev/logs](https://github.com/MaelAstruc/patmatch/tree/master/dev/logs).
    - The measures are in seconds.
	- The first line measures the time needed to run the equivalent `replace ... if ...` statements.
	- The last line measure the total time needed to run the `patmatch` command.
	- The last column gives the average difference in seconds.
	- The '%base' column compares the mean of each line to the average 'base' time.
