#!/usr/bin/env node

const wrap = require('word-wrap');

const screenCols = process.stdout.columns;

const {
  request: dbRequest,
  makePost,
  getPostsByPath,
  writePosts,
} = require('./db');

const { shortenUrl } = require('./urlShortener');

const { notify } = require('./notify');
const { searchForSale } = require('./mountainProject');

const query = process.argv[2];

const main = async () => {
  // make http MP requests
  const forSalePosts = await searchForSale(query);

  if (forSalePosts.length > 0) {
    const seenPaths = await getPostsByPath(forSalePosts.map(p => p.id));

    const newPosts = await Promise.all(
      forSalePosts
        .filter(post => !seenPaths.includes(post.id))
        .map(post =>
          shortenUrl(post.url).then(url => Object.assign({}, post, { url }))
        )
    );

    if (newPosts.length > 0) {
      await writePosts(newPosts.map(p => p.id));
      await Promise.all(newPosts.map(notify));
    }
  }
};

const printResult = ({ url, title, timestamp, match }) => {
  console.log(`${title + timestamp.padStart(screenCols - title.length)}
${wrap(match, { width: screenCols })}
${url}
`);
};

main()
  .then(() => process.exit())
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
