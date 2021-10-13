#!/usr/bin/env node

const dynamodb = require('./db').dynamodb;

var params = {
  TableName: 'Posts',
  KeySchema: [
    { AttributeName: 'path', KeyType: 'HASH' }, //Partition key
  ],
  AttributeDefinitions: [{ AttributeName: 'path', AttributeType: 'S' }],
  ProvisionedThroughput: {
    ReadCapacityUnits: 1,
    WriteCapacityUnits: 1,
  },
};

dynamodb.createTable(params, function(err, data) {
  if (err) {
    console.error(
      'Unable to create table. Error JSON:',
      JSON.stringify(err, null, 2)
    );
  } else {
    console.log(
      'Created table. Table description JSON:',
      JSON.stringify(data, null, 2)
    );
  }
});
