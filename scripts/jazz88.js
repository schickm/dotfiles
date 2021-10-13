// running: deno run --allow-net --allow-run path/to/jazz88.js

const METADATA_URL = 'http://www.jazz88.org/OnTheAir2/';
const STREAM_URL = 'http://ksds-ice.streamguys1.com/ksds.mp3';
const APP_ICON = 'https://www.jazz88.org/sysLibrary/Images/S/3FA23A57D4CC339CE62869.jpg';

const sleep = async ms => new Promise(resolve => setTimeout(resolve, ms));

const playStream = () => {
	const process = Deno.run({
		cmd: [
			'mpg123',
			STREAM_URL,
		],
	});

	return process;
}

const showNotification = async () => {
	const response = await fetch(METADATA_URL);
	const text = await response.text();

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

	await sleep(endTime);

	return showNotification();
}

playStream();
showNotification();
