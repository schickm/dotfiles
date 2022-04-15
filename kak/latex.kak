declare-option -docstring 'path to Skim.app displayline' \
    str skim_displayline '/Applications/Skim.app/Contents/SharedSupport/displayline'

define-command latex-update-pdf-in-skim -override -docstring 'preview current latex file in skim' \
	%{ echo -debug %sh{

        # the first argument should be the tex file, either with or without extension
        file="$kak_buffile"
        [ "${file:0:1}" == "/" ] || file="${PWD}/${file}"
        pdffile="${file%.tex}.pdf"

        # run pdflatex and open or reload the pdf in Skim
        pdflatex -synctex=1 "${file}"  
        /usr/bin/osascript << EOF
            set theFile to POSIX file "${pdffile}" as alias
            tell application "Skim"
                set theDocs to get documents whose path is (get POSIX path of theFile)
                if (count of theDocs) > 0 then revert theDocs
                open theFile
            end tell
        EOF
    }
}

hook global WinSetOption filetype=latex %{
    map global file r ': latex-update-pdf-in-skim<ret>' -docstring 'preview pdf in Skim'
    map global file s \
    	': nop %sh{ $kak_opt_skim_displayline -background $kak_cursor_line "${kak_buffile%.tex}.pdf" "${kak_buffile}" }<ret>' \
    	-docstring 'search for line in output pdf'

}

hook global BufWritePost .*\.tex latex-update-pdf-in-skim



