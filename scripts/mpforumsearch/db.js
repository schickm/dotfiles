const fs = require('fs/promises');
const path = require('path');
const md5 = require('md5');

const makePost = path => ({ path: { S: path } });

const DB_DIR = path.join(__dirname, 'database');

const pathExists = pathQuery =>
  fs
    .access(path.join(DB_DIR, md5(pathQuery)))
    .then(() => pathQuery)
    .catch(() => false);

/**
 * Gets posts with matching paths
 * @param {Array<String>} paths
 */
const getPostsByPath = paths =>
  Promise.all(paths.map(pathExists)).then(lookups => lookups.filter(x => x));

/*
  request('batchGetItem', {
    RequestItems: {
      Posts: {
        Keys: paths.map(makePost),
      },
    },
  }).then(response => response.Responses.Posts.map(post => post.path.S));
  */

const writePosts = paths => Promise.resolve();
/*
  paths.length > 0
    ? request('batchWriteItem', {
        RequestItems: {
          Posts: paths.slice(0, BATCH_WRITE_LIMIT - 1).map(path => ({
            PutRequest: {
              Item: makePost(path),
            },
          })),
        },
      }).then(() => writePosts(paths.slice(BATCH_WRITE_LIMIT)))
    : Promise.resolve();
    */

module.exports = {
  makePost,
  getPostsByPath,
  writePosts,
};
