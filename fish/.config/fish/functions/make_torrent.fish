function make_red_torrent --description "Makes a torrent using imdl and scps  <data path>"
    echo $argv
    set -l input $argv[1]
    set -l torrent_file "$input.torrent"

    echo $input

    imdl torrent create --private --source RED \
        --announce $REDACTED_ANNOUNCE_URL \
        --input $input \
        --output $torrent_file

    scp -r $input odroid:/srv/transmission/downloads/complete/

    read -P 'Press any key to upload torrent file...'

    scp $torrent_file odroid:/srv/transmission/watch/
end
