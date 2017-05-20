# node-api-starter
A project starter for an API server based on node, express, passport, mongoose, coffee-script


## How to setup and run the project
- git clone [node-api-starter](git@github.com:eperico/node-api-starter.git)
- cd `your_working_folder`
- Install node modules, node 6.10.2 LTS is currently used:
`npm install`
- launch mongDB instance:
`mongod`
- run the API
```
coffee servers/api.coffee
```
- The server is running on port 3000:
http://localhost:3000


## Project structure
- config:      the configuration for the different platforms
- cron:        all the cron tasks for the API
- deployment:  deployment script to used on a server or with a integration tool
- nginx:       a basic example of nginx configuration to serve the API
- pm2:         example of process management configuration
- controllers: the business logic code
- models:      the schema definitions for the DB models
- presenters:  the code that formats the data for the client
- routers:     the URL definitions + the handlers that connect the route to the presenters
