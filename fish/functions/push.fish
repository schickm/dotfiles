# Send notification via Pushover
function push -a message
    if ! set -q PUSHOVER_APP_TOKEN
        echo "Missing \$PUSHOVER_APP_TOKEN variable.  Please first defined with set -U ..."
        return 1
    end

    if ! set -q PUSHOVER_USER_KEY
        echo "Missing \$PUSHOVER_USER_KEY variable.  Please first defined with set -U ..."
        return 1
    end

    curl -s \
    --form-string "token=$PUSHOVER_APP_TOKEN" \
    --form-string "user=$PUSHOVER_USER_KEY" \
    --form-string "message=$message" \
    https://api.pushover.net/1/messages.json
end
