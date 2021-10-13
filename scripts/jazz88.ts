// running: deno run --allow-net --allow-run path/to/jazz88.ts

const METADATA_URL = 'http://www.jazz88.org/OnTheAir2/';
const STREAM_URL = 'http://ksds-ice.streamguys1.com/ksds.mp3';
const APP_ICON = 'https://www.jazz88.org/sysLibrary/Images/S/3FA23A57D4CC339CE62869.jpg';
const RETRY_MIN_TIME = 1000;
const RETRY_MAX_TIME = 60000;

const sleep = async (ms: number): Promise<void> => new Promise(resolve => setTimeout(resolve, ms));

const playStream = (): Deno.Process => {
	const process = Deno.run({
		cmd: [
			'mpg123',
			STREAM_URL,
		],
	});

	return process;
}

const sleepBackoff = (failCount: number): Promise<void> => {
    const sleepMS = Math.min(RETRY_MIN_TIME*(2^failCount), RETRY_MAX_TIME);
    console.log(`Sleeping for ${sleepMS}`);
    return sleep(sleepMS);
}

const handleNowPlayingFailure = async (failCount: number): Promise<string> => {
        console.log('Now Playing request failed');
	return sleepBackoff(failCount).then(() => fetchNowPlaying(failCount + 1));
}
const fetchNowPlaying = async (failCount = 0): Promise<string> =>
	fetch(METADATA_URL).then(response => {
        	if (response.status !== 200) {
        		return handleNowPlayingFailure(failCount + 1);
        	} else {
                	return response.text();
        	}
	}).catch(err => handleNowPlayingFailure(failCount + 1));




const showNotification = async (): Promise<void> => {
	const text = await fetchNowPlaying();

    	const [ _, __, artist, album, title, albumArtId, ___, ____, endTime ] = text.split("\n");
    	const contentImage = `https://www.jazz88.org/img/s/${albumArtId}.jpg`;
    	console.log(text);
    	console.log(contentImage);

    	if (artist || album || title) {
    		const process = Deno.run({
    			cmd: [
    				'terminal-notifier',
    				'-appIcon', APP_ICON,
    				'-contentImage', contentImage,
    				'-title', title,
    				'-subtitle', artist,
    				'-message', album,
    			],
    		});

    		await process.status();
    	}

    	await sleep(Number(endTime));

	return showNotification();
}

playStream();
showNotification();
