function scp-transmission --wraps=scp --description 'alias for coping files to odroid transimmios watch folder.  Also removes the torrent file'
  scp $argv odroid:/srv/transmission/watch/;
  rm $argv;
end
