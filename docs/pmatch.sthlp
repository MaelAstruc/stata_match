{smcl}
{* *! version 0.0.0  15Aug2024}{...}
{marker syntax}{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{bf:pmatch} {hline 2}}Pattern matching{p_end}
{p2colreset}{...}

{marker syntax}{title:Syntax}

{p 4 8}
{cmd:pmatch} {varname}, {cmd:Variables}({varlist}) {cmd:Body(}{break}
{cmd:[}{help pmatch##pattern:{it:pattern}} => {help exp},{cmd:]}{break}
{cmd:[}{help pmatch##pattern:{it:pattern}} => {help exp},{cmd:]}{break}
...{p_end}
{p 4}{cmd:)}{p_end}
        
{pstd}
{varname} is the name of the variable (A) you would like to replace. 

{pstd}
{cmd:Variables}({varlist}) contains the list of variables (B) you want to match on.

{pstd}
{cmd:Body}(...) contains the list of replacements you would like to do. It's composed of multiple arms. Each arm includes a {help pmatch##pattern:{it:pattern}} on the left hand side indicating the conditions of the replacement based on the values of the variables (B). It also contains an {help expression} on the right hand side to replace the values of your variable (A). They are separated by an arrow {bf:=>}.

{marker description}{title:Description}

{pstd}
The {cmd:pmatch} command provides an alternative syntax to series of '{bind:{cmd:replace ... if ...}}' statements. It limits repetitions and might feel familiar for users coming from other programming languages with Pattern matching.

{pstd}
Beyond the new syntax, the {cmd:pmatch} command provides run-time checks for the exhaustiveness and the usefulness of the conditions provided. The exhaustiveness check means that the command will tell you if some levels are not covered and which one are missing. The usefulness check means that it will tell you if the conditions you specified in each arm are useful, or if one of them overlaps with a previous one.

{pstd}
The different {help pmatch##examples:examples} illustrate how to use the different patterns detailed in the next section and what kind of information the checks provide.

{marker syntax}{title:Patterns}

{synoptset 30}{...}
{synopthdr:Pattern}
{synoptline}
{synopt: {opt Constant: } {it:x}} A unique value, either a number or a string.{p_end}

{synopt: {opt Range: } {it:a}~{it:b}} A range from {it:a} to {it:b}, with {it:a} and {it:b} two numbers. The symbol {bf:~} indicates that both values are included. You can use {bf:!~} to exclude the min, {bf:~!} to exclude the max or {bf:!!} to exclude both. You use {it:min} and {it:max} to refer to the minimum and maximum values of your variable.{p_end}

{synopt: {opt Or: } {it:pattern} | {it:...} | {it:pattern}} A pattern to compose with multiple patterns for a variable.{p_end}

{synopt: {opt Wildcard: } _} A pattern to cover all the possibilities that are not covered by the previous arms.{p_end}

{synopt: {opt Tuple: } ({it:pattern}, {it:...}, {it:pattern})} A pattern ro use when multiple variables are provided for the matching. Each pattern matches with the corresponding variable.{p_end}
{synoptline}

{marker examples}{title:Examples}

{phang}{help pmatch##constant_example:Example 1: Constant patterns}{p_end}
{phang}{help pmatch##range_example:Example 2: Range patterns}{p_end}
{phang}{help pmatch##or_example:Example 3: Or patterns}{p_end}
{phang}{help pmatch##wildcard_example:Example 4: Wildcard patterns}{p_end}
{phang}{help pmatch##tuple_example:Example 5: Tuple patterns}{p_end}
{phang}{help pmatch##exhaustiveness_example:Example 6: Exhaustiveness}{p_end}
{phang}{help pmatch##usefulness_example:Example 7: Usefulness}{p_end}

{marker constant_example}{title:Example 1: Constant patterns}

{pstd}
In this example, we use the values of the variable {bf:rep78} to create a new variables using the normal way ({bf:var_1}) and with the {cmd:pmatch} command ({bf:var_2}), using Constant patterns with the '{hi:x}' syntax.

        {hline}
        {cmd:sysuse auto, clear}

        * Usual way

        {cmd:gen var_1 = ""}
        {cmd:replace var_1 = "very low"      if rep78 == 1}
        {cmd:replace var_1 = "low"           if rep78 == 2}
        {cmd:replace var_1 = "mid"           if rep78 == 3}
        {cmd:replace var_1 = "high"          if rep78 == 4}
        {cmd:replace var_1 = "very high"     if rep78 == 5}
        {cmd:replace var_1 = "missing"       if rep78 == .}
        
        * With the pmatch command
        
        {cmd:gen var_2 = ""}
        {cmd:pmatch var_2, variables(rep78) body( ///}
        {cmd:    1 => "very low",                ///}
        {cmd:    2 => "low",                     ///}
        {cmd:    3 => "mid",                     ///}
        {cmd:    4 => "high",                    ///}
        {cmd:    5 => "very high",               ///}
        {cmd:    . => "missing",                 ///}
        {cmd:)}

        {cmd:assert var_1 == var_2}

        {hline}

{marker range_example}{title:Example 2: Range patterns}

{pstd}
The Constant pattern is simple but not practical once we have many values or decimals. In such cases we can us the Range pattern with the '{hi:{it:a}~{it:b}}' syntax.

        {hline}
        {cmd:sysuse auto, clear}

        * Usual way
        
        {cmd:gen var_1 = ""}
        {cmd:replace var_1 = "cheap"        if price >= 0    & price < 6000}
        {cmd:replace var_1 = "normal"       if price >= 6000 & price < 9000}
        {cmd:replace var_1 = "expensive"    if price >= 9000 & price <= 16000}
        {cmd:replace var_1 = "missing"      if price == .}
        
        * With the pmatch command
        
        {cmd:gen var_2 = ""}
        {cmd:pmatch var_2, variables(price) body( ///}
        {cmd:    min~!6000   => "cheap",         ///}
        {cmd:    6000~!9000  => "normal",        ///}
        {cmd:    9000~max    => "expensive",     ///}
        {cmd:    .           => "missing",       ///}
        {cmd:)}

        {cmd:assert var_1 == var_2}

        {hline}

{marker or_example}{title:Example 3: Or patterns}

{pstd}
The Or pattern is used to combine multiple patterns with the '{hi:{help pmatch##pattern:{it:pattern}} | {it:...} | {help pmatch##pattern:{it:pattern}}}' syntax.{p_end}

        {hline}
        {cmd:sysuse auto, clear}

        * Usual way
        
        {cmd:gen var_1 = ""}
        {cmd:replace var_1 = "low"           if rep78 == 1 | rep78 == 2}
        {cmd:replace var_1 = "mid"           if rep78 == 3}
        {cmd:replace var_1 = "high"          if rep78 == 4 | rep78 == 5}
        {cmd:replace var_1 = "missing"       if rep78 == .}
        
        * With the pmatch command
        
        {cmd:gen var_2 = ""}
        {cmd:pmatch var_2, variables(rep78) body( ///}
        {cmd:    1 | 2   => "low",               ///}
        {cmd:    3       => "mid",               ///}
        {cmd:    4 | 5   => "high",              ///}
        {cmd:    .       => "missing",           ///}
        {cmd:)}

        {cmd:assert var_1 == var_2}

        {hline}

{marker wildcard_example}{title:Example 4: Wildcard patterns}

{pstd}
To define a default value, we can use the wildcard pattern '{hi:_}'. It covers all the values not included in the previous arms. This means that any value included after a wildcard is ignored.

        {hline}
        {cmd:sysuse auto, clear}

        * Usual way
        
        {cmd:gen var_1 = "other"}
        {cmd:replace var_1 = "very low"      if rep78 == 1}
        {cmd:replace var_1 = "low"           if rep78 == 2}
        
        * With the pmatch command
        
        {cmd:gen var_2 = ""}
        {cmd:pmatch var_2, variables(rep78) body( ///}
        {cmd:    1 => "very low",                ///}
        {cmd:    2 => "low",                     ///}
        {cmd:    _ => "other",                   ///}
        {cmd:)}

        {cmd:assert var_1 == var_2}

        {hline}

{marker tuple_example}{title:Example 5: Tuple patterns}

{pstd}
To pmatch on multiple variables at the same time, we can use the Tuple pattern with the '{hi:({help pmatch##pattern:{it:pattern}}, {it:...}, {help pmatch##pattern:{it:pattern}})}' syntax.

        {hline}
        {cmd:sysuse auto, clear}

        * Usual way
        
        {cmd:gen var_1 = ""}
        {cmd:replace var_1 = "case 1"        if rep78 < 3 & price < 10000}
        {cmd:replace var_1 = "case 2"        if rep78 < 3 & price >= 10000}
        {cmd:replace var_1 = "case 3"        if rep78 >= 3}
        {cmd:replace var_1 = "missing"       if rep78 == . | price == .}
        
        * With the pmatch command
        
        {cmd:gen var_2 = ""}
        {cmd:pmatch var_2, variables(rep78, price) body(  ///}
        {cmd:    (~!3, ~!10000)      => "case 1",        ///}
        {cmd:    (~!3, 10000~)       => "case 2",        ///}
        {cmd:    (3~, _)             => "case 3",        ///}
        {cmd:    (., _) | (_, .)     => "missing",       ///}
        {cmd:)}

        {cmd:assert var_1 == var_2}

        {hline}

{marker exhaustiveness_example}{title:Example 6: Exhaustiveness}

{pstd}
Coming back to {help pmatch##constant_example:Example 1}, if we forgot to include the case where {bf:rep_78} is missing, the command will print a warning.

        {hline}
        {cmd:sysuse auto, clear}

        * Usual way

        {cmd:gen var_1 = ""}
        {cmd:replace var_1 = "very low"      if rep78 == 1}
        {cmd:replace var_1 = "low"           if rep78 == 2}
        {cmd:replace var_1 = "mid"           if rep78 == 3}
        {cmd:replace var_1 = "high"          if rep78 == 4}
        {cmd:replace var_1 = "very high"     if rep78 == 5}
        
        * With the pmatch command
        
        {cmd:gen var_2 = ""}
        {cmd:pmatch var_2, variables(rep78) body( ///}
        {cmd:    1 => "very low",                ///}
        {cmd:    2 => "low",                     ///}
        {cmd:    3 => "mid",                     ///}
        {cmd:    4 => "high",                    ///}
        {cmd:    5 => "very high",               ///}
        {cmd:)}

        // Warning : Missing values
        //     .
        
        {cmd:assert var_1 == var_2}

        {hline}

{pstd}
Including a Wildcard pattern covers all the remaining cases by default. This should be used with caution, because you might cover some unexpected cases such as missing values.

{marker usefulness_example}{title:Example 7: Usefulness}

{pstd}
On the other hand, with {help pmatch##range_example:Example 2}, we can also do mistakes with the ranges and cover some cases multiple times.

        {hline}
        {cmd:sysuse auto, clear}

        * Usual way
        
        {cmd:gen var_1 = ""}
        {cmd:replace var_1 = "cheap"        if price >= 0    & price <= 6000}
        {cmd:replace var_1 = "normal"       if price >= 6000 & price <= 9000}
        {cmd:replace var_1 = "expensive"    if price >= 9000 & price <= 16000}
        {cmd:replace var_1 = "missing"      if price == .}
        
        * With the pmatch command
        
        {cmd:gen var_2 = ""}
        {cmd:pmatch var_2, variables(price) body( ///}
        {cmd:    min~6000   => "cheap",         ///}
        {cmd:    6000~9000  => "normal",        ///}
        {cmd:    9000~max    => "expensive",     ///}
        {cmd:    .           => "missing",       ///}
        {cmd:)}

        // Warning : Arm 2 has overlaps
        //     Arm 1: 6000
        // Warning : Arm 3 has overlaps
        //     Arm 2: 9000
        
        {cmd:assert var_1 == var_2}

        {hline}

{title:References}

{title:Package details}

Version      : {bf:pmatch} version 0.0.0
Source       : {browse "https://github.com/MaelAstruc/stata_match":GitHub}

Author       : {browse "https://github.com/MaelAstruc":Mael Astruc--Le Souder}
E-mail       : mael.astruc-le-souder@u-bordeaux.fr

{title:Feedback}

{p}Please submit bugs, errors, feature requests on {browse "https://github.com/MaelAstruc/stata_match/issues":GitHub} by opening a new issue, or by sending me an email.{p_end}

{title:Citation guidelines}

Suggested citation for this package:

{p}Astruc--Le Souder, M. (2024). Stata package "pmatch" version 0.0.0. https://github.com/MaelAstruc/stata_match.{p_end}

@software{pmatch,
   author = {Astruc--Le Souder Mael},
   title = {Stata package ``pmatch''},
   url = {https://github.com/MaelAstruc/stata_match},
   version = {0.0.0},
   date = {2024-08-15}
}
