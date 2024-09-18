# BCtraefik

Due to some lucky circumstances I ended up to write this article about my journey with traefik and business Central. I think I am not the only one and there is @tfenster and many others that touched that. However it never made it back into bccontainerhelper to support a newer version of traefik. In the meantime we have reached version 3. 

So, to move along I will first describe my way to run v2 and how to make use of v3 in legacy mode ( simply because I did not managed to rewrite my configs).

First things first: works for, in my circumstances it does what it should do. no guarantee it will for you :P this is based on windows containers.

One of my goals was: this should work local. So no need for any fancy AzureVM or URL registration to get some LetsEncypt stuff working. I wanted this local. On a server, on my laptop. 

In order to achive this, just for a simple first container running traefik: 
- configuration
- certificates
- docker stuff ( in my case I use compose, as I like the way to setup things)

Let's with the docker-compose.yml:
services:
  traefik: # what we wanna call the service
      networks:
      - defaultnat # the network we want the container to work with
      image: traefik:windowsservercore-1809 # traefik image that fits your host
      restart: 'always'
      ports: # or in terms of traefik: EntryPoints: 
        - "443:443" # we want to access BC via https
        - "80:80" # we want to access BCs Fileshare via http
        - "8080:8080" # we want to access traefiks UI via Http
        - "7047:7047" # we want access to BC via 7047 Soap
        - "7048:7048" # we want access to BC via 7048 OData
      volumes:
        - D:\Docker\traefik\config:c:\etc\traefik # we want to the local folder D:...\config mapped into the containers C:\etc folder
        - type: npipe # traefik needs to be able to listen to the docker engine so, share it! 
          source: \\.\pipe\docker_engine
          target: \\.\pipe\docker_engine
      labels: # labels control traefiks behaviour! so lets make the traefik container, traefik aware
        - traefik.enable=true
        - traefik.http.routers.api.entrypoints=websecure
        - traefik.http.routers.api.rule=Host(`${COMPUTERNAME}.mylocal.domain`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))
        - traefik.http.routers.api.service=api@internal
  networks:
  defaultnat: # made my live simple to just map the default docker network nat to be used within compose 
    name: nat
    external: true

So that gives you a container with traefik, that will not work correctly as you need to have configs available while it starts, and not only what, also certificates!
You see me mentioning that I mapped a local folder: config into the container. so lets have a look at the content of that folder:
there are 4 files for me: 
- server.crt
- server.key
- traefik.yml
- flexconfig.yml

Obviously key and crt are certificate details we need to offer our host to others with "somewhat" valid certifiacte details to offer secure https services (traefik has its build in certificate stuff, but I was not really lucky with that). If you have a managed CA in your network you might have even a simpler live! 

So how do you get those certificats for your host? Well, I found the answer to that in bccontainerhelper, just tweaked a bit:
you need openssl, that will help you to create the files needed together with New-SelfSignedCertificate & Export-PfcCertificate pwsh command. 

