# agent-catalyst
Bootstrap a basic project with prod and dev environments to enable agents to build out the differing functionality

## Basic Pieces

This template will setup:

- A local development and cloud-based production environment for all the below componenets.

- A database
- A server that will function as both our frontend and backend
  - Backend will be Python/Flask
  - Frontend will be node.js (or maybe vanilla JavaScript?)

## 

I'll be outlining how to do this on MacOS using homebrew. Mainly because I believe that to be a pretty common setup for developers. However, this should be doable in other setups with minimal adaptations/changes.

## Let's go


1. Docker
   
Docker is what is going to allow us to setup the same local environment regardless of what base OS (MacOS, Windows, etc.) you are coming from. Install it for whatever Operating System you are on:
 - [Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
 - [Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
 - [Linux](https://docs.docker.com/desktop/setup/install/linux/)

Once it is installed make sure Docker Desktop is running.
   
2. Standup your local environment
   
Build your local environment by running `docker compose build` in the command line from the root of this project. This will take a few minutes the first time. Once that is done run `docker compose up` and navigate to localhost:8080. You should see our generic landing page.

3. Stand up your production environment

1. 




2.


 [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli). If you aren't familiar with Terraform it's probably helpful to walk through the tutorials in the link above so you have a working mental model of how the different pieces of this project work together