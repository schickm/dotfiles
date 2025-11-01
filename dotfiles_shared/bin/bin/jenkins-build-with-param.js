#!/usr/bin/env node

const { parseArgs } = require("node:util");

const { values } = parseArgs({
  options: {
    job: {
      type: "string",
      short: "j",
    },
    param: {
      type: "string",
      short: "p",
    },
  },
});

const jobs = processJob(values.job);
const [paramName, paramValue] = processParam(values.param);

getBuildUrlWithParam(jobs, paramName, paramValue).then(console.log);

async function getBuildUrlWithParam(jobs, paramName, paramValue) {
  const builds = await getBuilds(jobs);

  const matchingBuild = builds.find((b) =>
    b.actions
      .find((a) => a._class === "hudson.model.ParametersAction")
      ?.parameters.find((p) => p.name === paramName && p.value === paramValue),
  ).id;

  return `${jobUrl(jobs)}/${matchingBuild}`;
}

function getBuilds(jobs) {
  const headers = new Headers();
  headers.set(
    "Authorization",
    "Basic " +
      Buffer.from(
        process.env.JENKINS_USER_ID + ":" + process.env.JENKINS_API_TOKEN,
      ).toString("base64"),
  );

  const params = new URLSearchParams({
    tree: "builds[number,status,timestamp,id,result,actions[parameters[*]]]",
  });

  const url = `${jobUrl(jobs)}/api/json?${params}`;

  return fetch(url, { headers })
    .then((r) => r.json())
    .then((j) => j.builds);
}

function jobUrl(jobs) {
  const jobPath = jobs.map((j) => `job/${j}`).join("/");
  return `https://build.jenkins.ghbeta.com/${jobPath}`;
}

function processParam(value) {
  const paramSplit = value.split(",").filter((x) => x);

  if (paramSplit.length !== 2) {
    console.error(
      `Invalid format recieved for param.  Expecting 'paramName,paramValue' but recieved: '${param}'`,
    );
    process.exit(1);
  }
  return paramSplit;
}

function processJob(value) {
  return value.split(",");
}
