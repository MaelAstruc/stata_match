/*
Util functions when developing
*/

// Replace all the tabs in the code by 4 spaces

capture mata: mata drop rm_tabs_file() rm_tabs_dir()

mata
    // Copy each line of file to tempfile without tabs and replace the original
    void function rm_tabs_file(string scalar file) {
        real scalar fh, i
        string scalar line
        string vector lines
        
        lines = J(1, 0, "")
        
        fh = fopen(file, "r")
        while ((line = fget(fh)) != J(0, 0, "")) {
            lines = lines, ustrregexra(line, char(9), " " * 4)
        }
        fclose(fh)
        
        fh = fopen(file, "rw")
        for (i = 1; i <= length(lines); i++) {
            fput(fh, lines[i])
        }
        fclose(fh)
    }
    
    // Loop over all the files in a directory
    void function rm_tabs_dir(string scalar directory) {
        string scalar current_dir
        string vector files
        real scalar i
        
        current_dir = pwd()
        
        files =  dir(directory, "files", "*")
        chdir(directory)
        
        for (i = 1; i <= length(files); i++) {
            rm_tabs_file(files[i])
        }
        
        chdir(current_dir)
    }
    
end

**#************************************* Translate the help files in docs to pdf

capture program drop sthlp2pdf_file sthlp2pdf_dir

// Translates .sthlp to .ps and .ps to .pdf
program sthlp2pdf_file
    syntax anything
    
    local file = "`1'"
    
    translate "`file'.sthlp" "`file'.ps", translator(smcl2ps) replace header(off) logo(off) pagesize(A4)
    shell ps2pdf "`file'.ps"
    rm "`file'.ps"
end

// Loop over all the .sthlp files of a directory
program sthlp2pdf_dir
    syntax anything
    
    local directory = "`1'"
    
    local files: dir "`directory'" files "*.sthlp"
    local files = regexr(`"`files'"', "\.sthlp", "")
    
    foreach file of local files {
        sthlp2pdf_file "`directory'/`file'"
    }
end

**#*********************** Combine all files, add file name and remove bench_*()

capture mata: mata drop combine_files() rm_tabs_dir()

mata
function combine_files(
    string vector files,
    string scalar file_out,
    string scalar version_str,
    string scalar distrib_date,
    string scalar keep_function
) {
    real scalar fh_in, fh_out, i
    string scalar file_name, head_line, line
    
    unlink(file_out)
    fh_out = fopen(file_out, "w")
    fput(fh_out, "*! version " + version_str + "  " + distrib_date)
    
    for (i = 1; i <= length(files); i++) {
        file_name = files[i]
        fh_in = fopen(file_name, "r")
        
        head_line = "**#" + "*" * (76 - ustrlen(file_name)) + " " + file_name
        
        fput(fh_out, "")
        fput(fh_out, head_line)
        fput(fh_out, "")
        
        while ((line = fget(fh_in)) != J(0, 0, "")) {
            if (keep_function == "bench") {
                line = regexr(line, "// bench_", "bench_")
            }
            else if (keep_function == "profiler") {
                line = regexr(line, "// profiler_", "profiler_")
            }
            fput(fh_out, line)
        }
        
        fput(fh_out, "")
        
        fclose(fh_in)
    }
    
    fclose(fh_out)
}
end

**#************************************************************** Write pkg file

capture mata: mata drop write_pkg()

mata
function write_pkg(
    string scalar file_out,
    string scalar distrib_date
) {
    real   scalar date, fh_out
    string scalar date_fmt
    
    date     = date(distrib_date, "DMY")
    date_fmt = sprintf("%02.0f/%02.0f/%04.0f", day(date), month(date), year(date))
    
    unlink(file_out)
    fh_out = fopen(file_out, "w")
    
    fput(fh_out, "v 3")
    fput(fh_out, "")
    fput(fh_out, "d {bf:PMATCH}: Pattern matching in Stata.")
    fput(fh_out, "d")
    fput(fh_out, "d Distribution-Date: " + date_fmt)
    fput(fh_out, "")
    fput(fh_out, "f pmatch.ado")
    fput(fh_out, "f pmatch.sthlp")
    fput(fh_out, "f pmatch.pdf")
    
    fclose(fh_out)
}
end

**#********************************************* Write full sthlp file from body

capture mata: mata drop write_sthlp_file() write_sthlp_dir() sthlp_header() ///
    copy_file() write_pkg_details() write_feedback() write_citation()

mata
// Rewrite sthlp file from body and other informations
function write_sthlp_file(
    string scalar file_in,
    string scalar file_out,
    string scalar pkg_version,
    string scalar distrib_date
) {
    real scalar fh_out
    
    unlink(file_out)
    fh_out = fopen(file_out, "w")
    
    sthlp_header(fh_out, pkg_version, distrib_date)
    copy_file(file_in, fh_out)
    write_pkg_details(fh_out, pkg_version)
    write_feedback(fh_out)
    write_citation(fh_out, pkg_version, distrib_date)
    
    fclose(fh_out)
}

function write_sthlp_dir(
    string scalar dir_in,
    string scalar dir_out,
    string scalar pkg_version,
    string scalar distrib_date
) {
    string vector files
    string scalar file_in, file_out
    real scalar i
    
    files = dir(dir_in, "files", "*.sthlp")
    
    for (i = 1; i <= length(files); i++) {
        file_in  = dir_in  + "/" + files[i]
        file_out = dir_out + "/" + files[i]
        write_sthlp_file(file_in, file_out, pkg_version, distrib_date)
    }
}

// Add header to sthlp file
function sthlp_header(
    real scalar fh_out,
    string scalar pkg_version,
    string scalar distrib_date
) {
    real   scalar date
    string scalar date_fmt
    
    date     = date(distrib_date, "DMY")
    date_fmt = sprintf("%02.0f/%02.0f/%04.0f", day(date), month(date), year(date))
    
    fput(fh_out, "{smcl}")
    fput(fh_out, "{* *! version " + pkg_version + " " + date_fmt + "}{...}")
}

// Copy main file from file name to file handle
function copy_file(string scalar file_in, real scalar fh_out) {
    real   scalar fh_in
    string scalar line
    
    fh_in = fopen(file_in, "r")
    while ((line = fget(fh_in)) != J(0, 0, "")) {
        fput(fh_out, line)
    }
    fclose(fh_in)
}

// Write package details
function write_pkg_details(real scalar fh, string scalar pkg_version) {
    fput(fh, `""')
    fput(fh, `"{title:Package details}"')
    fput(fh, `""')
    fput(fh, `"Version      : {bf:pmatch} version "' + pkg_version)
    fput(fh, `"Source       : {browse "https://github.com/MaelAstruc/stata_match":GitHub}"')
    fput(fh, `""')
    fput(fh, `"Author       : {browse "https://github.com/MaelAstruc":Mael Astruc--Le Souder}"')
    fput(fh, `"E-mail       : mael.astruc-le-souder@u-bordeaux.fr"')
}

// Write feedback
function write_feedback(real scalar fh) {
    fput(fh, `""')
    fput(fh, `"{title:Feedback}"')
    fput(fh, `""')
    fput(fh, `"{p}Please submit bugs, errors, feature requests on {browse "https://github.com/MaelAstruc/stata_match/issues":GitHub} by opening a new issue, or by sending me an email.{p_end}"')
}

// Write citation
function write_citation(
    real scalar fh,
    string scalar pkg_version,
    string scalar distrib_date
) {
    real   scalar date
    string scalar date_fmt
    
    date  = date(distrib_date, "DMY")
    date_fmt = sprintf("%04.0f-%02.0f-%02.0f", year(date), month(date), day(date))
    
    fput(fh, `""')
    fput(fh, "{title:Citation guidelines}")
    fput(fh, "")
    fput(fh, "Suggested citation for this package:")
    fput(fh, "")
    fput(fh, "{p}Astruc--Le Souder, M. (" + strofreal(year(date), "%04.0f") + "). Stata package 'pmatch' version " + pkg_version + " https://github.com/MaelAstruc/stata_match.{p_end}")
    fput(fh, "")
    fput(fh, "@software{pmatch,")
    fput(fh, "   author = {Astruc--Le Souder Mael},")
    fput(fh, "   title = {Stata package ``pmatch''},")
    fput(fh, "   url = {https://github.com/MaelAstruc/stata_match},")
    fput(fh, "   version = {" + pkg_version + "},")
    fput(fh, "   date = {" + date_fmt + "}")
    fput(fh, "}")
}
end
