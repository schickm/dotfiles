const fetch = require('node-fetch');

module.exports = {
  shortenUrl: async url =>
    fetch('https://api-ssl.bitly.com/v4/shorten', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.BITLY_TOKEN}`,
      },
      body: JSON.stringify({
        group_guid: process.env.BITLY_GROUP_ID,
        long_url: url,
      }),
    })
      .then(res => res.json())
      .then(res => res.link),
};
