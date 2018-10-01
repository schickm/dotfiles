define-command ember-enable \
-override \
-docstring 'enable ember add-ins for kakoune' %{
    declare-user-mode ember
    map global ember <t> ':ember-toggle-template<ret>' -docstring 'toggle template'
    map global ember <c> ':ember-edit-component ' -docstring 'edit a component'
    map global ember <o> ':ember-edit-controller ' -docstring 'edit a controller'
    map global ember <r> ':ember-edit-route ' -docstring 'edit a route'
    map global ember <a> ':ember-edit-adapter ' -docstring 'edit an adapter'
    map global ember <s> ':ember-edit-serializer ' -docstring 'edit a serializer'
    map global ember <l> ':source ~/vc/dotfiles/kak/ember.kak<ret>'

    map global normal <space> ':enter-user-mode<space>ember<ret>'
}

evaluate-commands %sh{
    define_edit_command() {
        thing=$1
        file_ending=$2
        is_pod=$3

        if [ "$is_pod" ] ; then
            sed_args="-e '/app\/${thing}s\/[^\.]*\.${file_ending}/ !{/${thing}\.${file_ending}/ !b' -e '}; p'"
        else
            sed_args="'/app\/${thing}s\/[^\.]*\.${file_ending}/p'"
        fi

        printf "
            define-command ember-edit-$thing -override -params 1 \
            -shell-candidates %%{

                git ls-files | sed -n $sed_args
            } \
            %%{
                edit %%arg{1}
            }
        " $thing
    }

    define_edit_command "route" "[tj]s" "true"
    define_edit_command "controller" "[tj]s" "true"
    define_edit_command "component" "[tj]s" "true"
    define_edit_command "adapter" "[tj]s"
    define_edit_command "serializer" "[tj]s"
}

declare-option -hidden str-to-str-map ember_template_toggle_map

define-command ember-toggle-template \
-override \
-docstring 'toggle between template and associated component/route/controller' %{ evaluate-commands %sh{
    grep_bufname() {
        regex=$1
        echo "$kak_bufname" | grep "$@" >/dev/null
    }

    # javascript file in a pod
    if grep_bufname -e 'component\.[jt]s$' -e 'route\.[tj]s$' -e 'controller\.[tj]s$'; then
        template=$(printf "%s" "$kak_bufname" | sed 's/\/[^/]*\.[tj]s$/\/template.hbs/')
        printf "
            set-option -add global ember_template_toggle_map $template=$kak_bufname
            edit $template
        "

    # old style
    elif grep_bufname -e '^app/controllers/.*[^./]*\.[tj]s$' -e '^app/routes/.*[^./]*\.[tj]s$'; then
        printf "edit %s" $(printf "$kak_bufname" | sed 's/^app\/[a-z]*/app\/templates/ ; s/\.[jt]s$/.hbs/' )

    elif grep_bufname '^app/components/.*[^./]*\.[tj]s$'; then
        printf "edit %s" $(printf "$kak_bufname" | sed 's/^app/app\/templates/ ; s/\.[jt]s$/.hbs/' )

    elif grep_bufname '\.hbs$'; then
        test_var=$(printf "$kak_opt_ember_template_toggle_map" | sed "s|.*[[:space:]]\{0,1\}${kak_bufname}=\([^ ]*\).*|\1|")
        # this is weird, for somereason test_var ends with a single quote...don't know what's going on here
        # But I'm just stripping it off for now, will investigate later
        test_var=$(printf "$test_var" | sed "s/\(.*\)'/\1/")
        printf "edit $test_var\n"
    fi
} }

