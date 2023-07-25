#!/usr/bin/env fish .

set ALERTER_TITLE 'Gitlab Pipeline'

function __send_alert -a message subtitle
    push "$ALERTER_TITLE - $subtitle: $message"
    alerter -message "$message" -title $ALERTER_TITLE -subtitle $subtitle -actions 'Open Pipeline'
end

function poll_pipeline -a optionalBranch
    set BRANCH $(git rev-parse --abbrev-ref HEAD)
    if test $optionalBranch
        set BRANCH $optionalBranch
    end

    while true
        set GLAB_STATUS (glab ci status --branch=$BRANCH)
        set PIPELINE_URL (string match -r '^http.*' $GLAB_STATUS)
        set PIPELINE_STATUS (string match -r 'Pipeline State: (\w+)' $GLAB_STATUS | tail -n 1)
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
