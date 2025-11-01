function upfind \
    --description "search upwards for a file, printing out the first match"

    set filename $argv[1]
    set current_dir (pwd)

    while true
        if test -f "$current_dir/$filename"
            realpath "$current_dir/$filename"
            return 0
        end

        # Move up one directory
        set parent_dir (dirname "$current_dir")

        # If we've reached the root directory and haven't found the file, exit
        if test "$parent_dir" = / -a "$current_dir" = /
            echo "File '$filename' not found in parent directories." >&2
            return 1
        end
        set current_dir "$parent_dir"
    end
end
