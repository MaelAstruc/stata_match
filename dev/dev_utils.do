/*
Util functions when developing
*/

// Replace all the tabs in the code by 4 spaces

mata
    // Copy each line of file to tempfile without tabs and replace the original
    void function rm_tabs_file(file) {
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
        string scalar current_dir, file
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

// Translate the help files in docs to pdf

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


