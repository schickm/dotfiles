#!/usr/bin/env node

const fetch = require('node-fetch');
const cheerio = require('cheerio');
const wrap = require('word-wrap');
const screenCols = process.stdout.columns;

const query = process.argv[2];
const url = `https://www.mountainproject.com/ajax/public/search/results/category?q=${query}&c=Forums&o=0&s=Newest`;

const main = async () => {
  const response = await fetch(url);
  const json = await response.json();
  json.results.Forums.forEach(printResult);
};

const printResult = html => {
  const $ = cheerio.load(html);
  const url = 'https://www.mountainproject.com' + $('a').attr('href');
  const data = $('body')
    .text()
    .split('\n')
    .map(x => x.trim())
    .filter(x => x !== '');
  const [title, timestamp] = data.slice(0, 2);
  const match = data.slice(2).join(' ');

  console.log(`${title + timestamp.padStart(screenCols - title.length)}
${wrap(match, { width: screenCols })}
${url}
`);
};

main();
