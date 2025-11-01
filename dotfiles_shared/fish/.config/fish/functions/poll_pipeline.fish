#!/usr/bin/env fish .

set __ALERTER_TITLE 'Gitlab Pipeline'
set __RUNNING_PIPELINE_STATUSES 'running' 'pending' 'null' 'created'


function __send_alert -a message subtitle
    push "$__ALERTER_TITLE - $subtitle: $message" > /dev/null
    alerter -message "$message" -title $__ALERTER_TITLE -subtitle $subtitle -actions 'Open Pipeline'
end

function __gapi -a path
    set url "/projects/$GITLAB_PROJECT/$path"
    glab api $url
end

function poll_pipeline -a optionalBranch
    set -g GITLAB_PROJECT (urlescape "jellyvision/code/tools/alex-builder")

    if test $optionalBranch
        set BRANCH $optionalBranch
    else
        set BRANCH (git rev-parse --abbrev-ref HEAD)
    end
    set BRANCH_URL_ENCODED (urlescape $BRANCH)

    set MERGE_REQUESTS (__gapi "merge_requests?source_branch=$BRANCH")
    # If there's a merged result pipeline
    if test "$MERGE_REQUESTS" != "[]"
        set BRANCH_IID (echo $MERGE_REQUESTS | jq ".[0].iid")
        set GLAB_STATUS (__gapi "merge_requests/$BRANCH_IID")
        set PIPELINE_ID (echo $GLAB_STATUS | jq -r '.head_pipeline.id')
    # else there's no merge request, so just pull the latest pipeline off the branch
    # (used for long running branch like 'main')
    else
	set PIPELINE_ID (__gapi "pipelines?ref=$BRANCH_URL_ENCODED&sort=desc" | jq '.[0].id')
    end

    set LAST_STATUS ''

    while true
        set PIPELINE_RESPONSE (__gapi "pipelines/$PIPELINE_ID")
        set PIPELINE_URL (echo $PIPELINE_RESPONSE | jq -r '.web_url')
        set PIPELINE_STATUS (echo $PIPELINE_RESPONSE | jq -r '.status')
        # make sure we have a status, and is not one of the running ones
        if test $PIPELINE_STATUS != "" && not contains $PIPELINE_STATUS $__RUNNING_PIPELINE_STATUSES
            echo "GOT PIPELINE_STATUS '$PIPELINE_STATUS'"
            set ALERTER_CLICK (__send_alert $PIPELINE_STATUS "$(basename $PWD) $BRANCH")
            if test $ALERTER_CLICK = 'Open Pipeline'
                open $PIPELINE_URL
            end
            break
        end

        # echo out the status if it's changed
        if test $PIPELINE_STATUS != $LAST_STATUS
            printf "Status: %s" $PIPELINE_STATUS
        end

        set LAST_STATUS $PIPELINE_STATUS

	# show a little activity
        printf '.'

        sleep 10

    end
end
