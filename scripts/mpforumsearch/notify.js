const AWS = require('./aws');
const screenCols = process.stdout.columns;
const wrap = require('word-wrap');

const sendSMS = body =>
  new AWS.SNS()
    .publish({
      Message: body,
      PhoneNumber: '+17736271015',
    })
    .promise();

// 140 is the SMS limit, minus 2 line breaks.
const charMax = 138;

const formatPostForSMS = ({ title, url, match }) => {
  const availableChars = charMax - title.length - url.length - 1;
  const body =
    availableChars < match.length
      ? match.substring(0, availableChars) + '…'
      : match;

  return `${title}
${body}
${url} `;
};

const printResult = ({ url, title, timestamp, match }) => {
  console.log(`${title + timestamp.padStart(screenCols - title.length)}
${wrap(match, { width: screenCols })}
${url}
`);
};

module.exports = {
  notify: process.env.DEBUG
    ? printResult
    : post => sendSMS(formatPostForSMS(post)),
};
