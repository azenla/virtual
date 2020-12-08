# Website

This website is built using [Docusaurus 2](https://v2.docusaurus.io/), a modern static website generator.

## Install dependencies

```console
npm i
```

## Start local development server

```console
npm run start
```

This command starts a local development server and open up a browser window. Most changes are reflected live without having to restart the server.

## Deploy to GitHub pages

Compile and deploy by committing to `gh-pages` branch. 

To staging (https://cblackcom.github.io/virtual):
```console
GIT_USER=<Your GitHub username> USE_SSH=true ORGANIZATION_NAME=cblackcom npm run deploy
```

To production (https://kendfinger.github.io/virtual):
```console
GIT_USER=<Your GitHub username> USE_SSH=true npm run deploy
```

For more info:  
https://v2.docusaurus.io/docs/deployment#deploying-to-github-pages
