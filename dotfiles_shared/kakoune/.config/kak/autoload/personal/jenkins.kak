#
# Jenkins specific integrations for kakoune
#
# Expects to be triggered in project dir specific .kakrc.local file like:
#
# bind-jenkins-build t 'open testcafe build for branch' umami,umami_testcafe_run branch '%sh{ git rev-parse --abbrev-ref HEAD }'
#


define-command bind-jenkins-build \
	-params 5 \
	-docstring 'bind-jenkins-build <key> <docstring> <jobName[,subJobName]> <paramName> <paramValue>' \
	-override %{

	map global local %arg{1} ": open-jenkins-build %arg{3} %arg{4} %arg{5}<ret>" -docstring %arg{2} 
}

define-command open-jenkins-build \
	-hidden \
	-params 3 \
	-docstring 'open-jenkins-build <jobName[,subJobName]> <paramName> <paramValue>' \
	-override %{

	nop %sh{
		build_url=$(jenkins-build-with-param.js --job "$1" --param "$2,$3")
		open "$build_url"
	}
}
