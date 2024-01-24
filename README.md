# Pattern Matching for Stata

This package introduces the `match` command which is similar to a switch statement in terms of syntax, but with further guaranties on patterns usefulness and exhaustiveness. It is inspired by the [Rust](https://www.rust-lang.org/) Programming Language [pattern syntax](https://doc.rust-lang.org/book/ch18-03-pattern-syntax.html) and [algorithm](https://doc.rust-lang.org/book/ch18-03-pattern-syntax.html).

The purposes of the `match` command are:

- To provide a familiar syntax for those coming from other programming languages
- Check if all the possible cases are covered when creating a new variable $x$ based on another variable $y$
- Check that all the cases are useful and not overlapping

*WARNING*: This project is still under development, the core of the algorithm is implemented but the syntax and features are still evolving.

# How to install

Copy and paste the code if you really want, but for now this project is absolutely not stable.

# Pattern Syntax

Before presenting the magic of usefulness and exhaustiveness, I need to introduce the pattern syntax.

## Constant pattern

A simple case where the `match` command could be used is when creating a variable from another one with the constant pattern (also called literal).

```Stata
    sysuse auto, clear

* Usual way with 'replace newvar = value if condition'

    gen var_1 = ""
    replace var_1 = "very low"      if rep78 == 1
    replace var_1 = "low"           if rep78 == 2
    replace var_1 = "mid"           if rep78 == 3
    replace var_1 = "high"          if rep78 == 4
    replace var_1 = "very high"     if rep78 == 5
    replace var_1 = "missing"       if rep78 == .

* With the match command: match var, variables(newvar) body(condition => value)

    gen var_2 = ""
    match var_2, variables(rep78) body( ///
        1 => "very low",                ///
        2 => "low",                     ///
        3 => "mid",                     ///
        4 => "high",                    ///
        5 => "very high",               ///
        . => "missing",                 ///
    )

    assert var_1 == var_2

    drop var_1 var_2
```

In this example we match the simplest pattern: the constant. It can be a number, a string or a missing value. No other types are supported for now. The values in the pattern constant must have the same type as the variable.

## Wildcard pattern

To define a default value, the wildcard pattern `_` can be used. It covers all the values not called in the previous arms. This means that any arm included after a wildcard are ignored.

```Stata
    sysuse auto, clear

    gen var_1 = ""
    replace var_1 = "very low"      if rep78 == 1
    replace var_1 = "low"           if rep78 == 2
    replace var_1 = "other"         if var_1 == ""

    gen var_2 = ""
    match var_2, variables(rep78) body( ///
        1 => "very low",                ///
        2 => "low",                     ///
        _ => "other",                   ///
    )

    assert var_1 == var_2

    drop var_1 var_2
```

## Range pattern

The constant pattern is simple but not practical once we have many values or decimals. In such cases we can us the range pattern.

```Stata
    sysuse auto, clear

    gen var_1 = ""
    replace var_1 = "cheap"         if price >= 0    & price < 6000
    replace var_1 = "normal"        if price >= 6000 & price < 9000
    replace var_1 = "expensive"     if price >= 9000 & price <= 16000
    replace var_1 = "missing"       if price == .

    gen var_2 = ""
    match var_2, variables(price) body( ///
        0~!6000     => "cheap",         ///
        6000~!9000  => "normal",        ///
        9000~16000  => "expensive",     ///
        .           => "missing",       ///
    )

    assert var_1 == var_2

    drop var_1 var_2
```

A range pattern is composed of three parts. A minimum value on the left hand side, a symbol in the middle and a maximum value on the right hand side. The symbol can be:

- `~`: corresponding to `>= & <=`
- `~!`: corresponding to `>= & <`
- `!~`: corresponding to `> & <=`
- `!!`: corresponding to `> & <`

*Note*: If the minimum (or the maximum) value is missing, it is replaced by the actual minimum (or maximum) value.

*Bonus*: The previous note implies that an open range will not include the missing value, while `replace y = 1 if x > 10` means that `y == 1 if x == .`

## Or pattern

The or pattern is used to combine multiple patterns with the `|` syntax.

```Stata
    sysuse auto, clear

    gen var_1 = ""
    replace var_1 = "low"           if rep78 == 1 | rep78 == 2
    replace var_1 = "mid"           if rep78 == 3
    replace var_1 = "high"          if rep78 == 4 | rep78 == 5
    replace var_1 = "missing"       if rep78 == .

    gen var_2 = ""
    match var_2, variables(rep78) body( ///
        1 | 2   => "low",               ///
        3       => "mid",               ///
        4 | 5   => "high",              ///
        .       => "missing",           ///
    )

    assert var_1 == var_2

    drop var_1 var_2
```

## Tuple

Replacing a variable depending on another is useful but sometimes a variable depends on two other variable. In this case you can use a tuple pattern with the syntax `(y1, y2, ...)` to match multiple variables.

```Stata
    sysuse auto, clear

    gen var_1 = ""
    replace var_1 = "case 1"        if rep78 < 3 & price < 10000
    replace var_1 = "case 2"        if rep78 < 3 & price >= 10000
    replace var_1 = "case 3"        if rep78 >= 3
    replace var_1 = "missing"       if rep78 == . | price == .

    gen var_2 = ""
    match var_2, variables(rep78, price) body(  ///
        (~!3, ~!10000)      => "case 1",        ///
        (~!3, 10000~)       => "case 2",        ///
        (3~, _)             => "case 3",        ///
        (., _) | (_, .)     => "missing",       ///
    )

    assert var_1 == var_2

    drop var_1 var_2
```

# Exhaustiveness and usefulness

Even if the previous examples are simple, we can see that it's easy to mess up some cases, especially forgetting the missing value or overlapping ranges. The most important value added of the `match` command is it's capacity to check that none of the cases are overlapping and that all of them are covered.

To come back to the first example, if we forget to cover the missing value:

```Stata
    sysuse auto, clear

    gen var_1 = ""
    replace var_1 = "very low"      if rep78 == 1
    replace var_1 = "low"           if rep78 == 2
    replace var_1 = "mid"           if rep78 == 3
    replace var_1 = "high"          if rep78 == 4
    replace var_1 = "very high"     if rep78 == 5

    gen var_2 = ""
    match var_2, variables(rep78) body( ///
        1 => "very low",                ///
        2 => "low",                     ///
        3 => "mid",                     ///
        4 => "high",                    ///
        5 => "very high",               ///
    )
```

Here, we will receive a warning:

```
    Warning : Missing values
        .
```

Including a wildcard pattern or a tuple of wildcard patterns covers all the cases by default.

Looking at the range example, we can also mess up the ranges and cover some cases multiple times.

```Stata
    sysuse auto, clear

    gen var_1 = ""
    replace var_1 = "cheap"         if price >= 0    & price <= 6000
    replace var_1 = "normal"        if price >= 6000 & price <= 9000
    replace var_1 = "expensive"     if price >= 9000 & price <= 15000
    replace var_1 = "missing"       if price == .

    gen var_2 = ""
    match var_2, variables(rep78) body( ///
        0~6000      => "cheap",         ///
        6000~9000   => "normal",        ///
        9000~15000  => "expensive",     ///
        .           => "missing",       ///
    )
```

In this case we will receive another warning:

```
    Warning : Arm 2 has overlaps
        Arm 1: 6000
    Warning : Arm 3 has overlaps
        Arm 2: 9000
```

## Limitations

False warnings

- The wildcard pattern gives overlap warnings while it's his purpose, I need to fix it

Missing types

- I haven't checked any type apart from numerics and strings.
- Dates would be interesting especially with the range, but for now they are not covered.
- Encoded values will be added but it requires to define a proper syntax depending if we want to match on the values or the labels.
- Comparing two variables would be useful but it would require to define new patterns and greatly modify the algorithm I think.

Performance

- Because Stata is a dynamically typed language, the levels of the variables are checked at runtime
- The exhaustiveness and usefulness are also checked at run time.
- While it does not have a large impact on small databases, checking the levels is costly in large databases.
- According to a quick profiling, the checks are less important compared to getting the levels.
- Getting the levels from encoded values should decrease the performance cost.
- I need to implement a proper profiling suite.

Test

- I have some tests but a proper test suite would be better.
