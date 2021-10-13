const fetch = require('node-fetch');
const cheerio = require('cheerio');

const forumForSaleURL =
  'https://www.mountainproject.com/forum/103989416/for-sale-for-free-want-to-buy';

const extractPath = $result =>
  $result('a')
    .attr('href')
    .split('?')[0];

const makeLinkOnPageFilter = async url => {
  const response = await fetch(forumForSaleURL);
  const $ = cheerio.load(await response.text());
  // here's the filter
  return url => $(`a[href*="${url}"]`).length > 0;
};

const parseResult = $result => {
  const url = 'https://www.mountainproject.com' + $result('a').attr('href');
  const data = $result('body')
    .text()
    .split('\n')
    .map(x => x.trim())
    .filter(x => x !== '');
  const [title, timestamp] = data.slice(0, 2);
  const match = data.slice(2).join(' ');

  return {
    url,
    title,
    timestamp,
    match,
    id: extractPath($result),
  };
};

async function searchForSale(query) {
  const [json, isForSaleLink] = await Promise.all([
    fetch(
      `https://www.mountainproject.com/ajax/public/search/results/category?q=${query}&c=Forums&o=0&s=Newest`
    ).then(response => response.json()),
    makeLinkOnPageFilter(forumForSaleURL),
  ]);

  const postsByPath = (json.results.Forums || [])
    .map(cheerio.load)
    .reduce((acc, $result) => {
      acc[extractPath($result)] = parseResult($result);
      return acc;
    }, {});

  const paths = Object.keys(postsByPath);
  // work through the results and keep ones that are "for sale" forum posts
  const forSalePaths = paths.filter(isForSaleLink);

  // return the path and post data put together again
  return forSalePaths.map(path => postsByPath[path]);
}

module.exports = {
  searchForSale,
};
