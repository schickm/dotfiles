#!/usr/bin/env fish .

set ALERTER_TITLE 'Gitlab Pipeline'

function __send_alert -a message subtitle
    push "$ALERTER_TITLE - $subtitle: $message" > /dev/null
    alerter -message "$message" -title $ALERTER_TITLE -subtitle $subtitle -actions 'Open Pipeline'
end

function poll_pipeline -a optionalBranch
    set BRANCH (git rev-parse --abbrev-ref HEAD)
    set PROJECT "jellyvision%2Fcode%2Ftools%2Falex-builder"
    if test $optionalBranch
        set BRANCH $optionalBranch
    end

    set BRANCH_IID (glab api "/projects/$PROJECT/merge_requests?source_branch=$BRANCH" | jq ".[0].iid")

    while true
        set GLAB_STATUS (glab api "/projects/$PROJECT/merge_requests/$BRANCH_IID")
        set PIPELINE_URL (echo $GLAB_STATUS | jq -r '.head_pipeline.web_url')
        set PIPELINE_STATUS (echo $GLAB_STATUS | jq -r '.head_pipeline.status')
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
