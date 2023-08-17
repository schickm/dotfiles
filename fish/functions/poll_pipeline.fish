#!/usr/bin/env fish .

set ALERTER_TITLE 'Gitlab Pipeline'

function __send_alert -a message subtitle
    push "$ALERTER_TITLE - $subtitle: $message" > /dev/null
    alerter -message "$message" -title $ALERTER_TITLE -subtitle $subtitle -actions 'Open Pipeline'
end

function __url_escape -a value
    string escape --style=url $value | sed -r 's|/|%2F|g'
end

function __gapi -a path
    set url "/projects/$GITLAB_PROJECT/$path"
    glab api $url
end

function poll_pipeline -a optionalBranch
    set -g GITLAB_PROJECT (__url_escape "jellyvision/code/tools/alex-builder")

    if test $optionalBranch
        set BRANCH $optionalBranch
    else
        set BRANCH (git rev-parse --abbrev-ref HEAD)
    end
    set BRANCH_URL_ENCODED (__url_escape $BRANCH)

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

    while true
        set PIPELINE_RESPONSE (__gapi "pipelines/$PIPELINE_ID")
        set PIPELINE_URL (echo $PIPELINE_RESPONSE | jq -r '.web_url')
        set PIPELINE_STATUS (echo $PIPELINE_RESPONSE | jq -r '.status')
        if test $PIPELINE_STATUS != 'running'
            set ALERTER_CLICK (__send_alert $PIPELINE_STATUS "$(basename $PWD) $BRANCH")
            if test $ALERTER_CLICK = 'Open Pipeline'
                open $PIPELINE_URL
            end
            break
        end
        sleep 1
    end
end
