declare-option -docstring 'path to Skim.app displayline' \
    str skim_displayline '/Applications/Skim.app/Contents/SharedSupport/displayline'

declare-option -docstring 'temp directory containing output files from pdflatex' \
	str latex_tmp_dir


define-command latex-update-pdf-in-skim -override -docstring 'preview current latex file in skim' %{
	nop %sh{
        dir="$kak_opt_latex_tmp_dir"
        file=$(basename "$kak_buffile")
        pdffile="$dir/${file%.tex}.pdf"

        # run pdflatex and open or reload the pdf in Skim
        if pdflatex -synctex=1 -output-directory="$dir" "$kak_buffile"; then
	        /usr/bin/osascript <<-EOF
				set theFile to POSIX file "${pdffile}" as alias
				tell application "Skim"
				    set theDocs to get documents whose path is (get POSIX path of theFile)
				    if (count of theDocs) > 0 then revert theDocs
				    open theFile
				end tell
EOF
		else
			echo "echo 'pdflatex failed'" > "$kak_command_fifo"
		fi

    }
}

define-command latex-display-line -override %{
	nop %sh{
        dir="$kak_opt_latex_tmp_dir"
        file=$(basename "$kak_buffile")
        pdffile="$dir/${file%.tex}.pdf"

        $kak_opt_skim_displayline -background "$kak_cursor_line" \
        	"$pdffile" "${kak_buffile}"
    }
}

hook global WinSetOption filetype=latex %{
	map global file r ': latex-update-pdf-in-skim<ret>' -docstring 'preview pdf in Skim'
    map global file s \
    	': latex-display-line<ret>' \
    	-docstring 'search for line in output pdf'

    hook -group latex-hooks buffer BufWritePost .* latex-update-pdf-in-skim

	# Initialize the temp dir
    set-option buffer latex_tmp_dir %sh{ mktemp -d "${TMPDIR:-/tmp}"/kak-pdflatex.XXXXXXXX }

    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window latex-hooks
    }
}
