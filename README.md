# BCtraefik (WiP - well actually not, I have it working, but for this open repo I had to remove some things, so not sure if it will work "as is")

Due to some lucky circumstances I ended up to write this article about my journey with traefik and business Central. I think I am not the only one and there is @tfenster and many others that touched that. However it never made it back into bccontainerhelper to support a newer version of traefik. In the meantime we have reached version 3. 

So, to move along I will first describe my way to run v2 and how to make use of v3 in legacy mode ( simply because I did not managed to rewrite my configs).

First things first: works for, in my circumstances it does what it should do. no guarantee it will for you :P this is based on windows containers. And all my machines are "AD joined" which is important to know when it comes to certificates, routing and FQNs. 
using: 
- Docker Compose version v2.29.1
- Server: Docker Engine - Community Version: 23.0.3

One of my goals was: this should work local. So no need for any fancy AzureVM or URL registration to get some LetsEncypt stuff working. I wanted this local. On a server, on my laptop. 

In order to achive this, just for a simple first container running traefik: 
- configuration
- certificates
- docker stuff ( in my case I use compose, as I like the way to setup things)

## Let's start with the [docker-compose.yml](https://github.com/KristofKlein/BCtraefik/blob/main/traefik/docker-compose.yml) for traefik:

So this files duty is, to get you a service started. As expected in that scenario the service is traefik. In order to let traefik function you need to set some details it needs. Those are:
- EntryPoints (Ports)
- Docker Engine Access (volume)
- elegant way to configure traefik without detroying the container again and again (volume)
- enable traefik for the trafik container itself (labels)
- and some other fancy stuff ( network, image policies) 

Just check the file, it should explain itself. However have special attention to:
traefik.http.routers.api.rule=Host(`${COMPUTERNAME}.mylocal.domain`) 
compose has a build in variable replacement engine. There are some predefined values, but also some, that you can just hand in! I will make use of this going along quite often. So be prepared. But no matter what, this is the URL that you want to reach your BC Service later. My machines are all domain joined, so this is what this article is using, it might also be op you just make use of ${COMPUTERNAME} - never tried. 

Anyway, run docker-compose up in the traefik folder !! (Small tip: you can also first run docker-compose.exe config - that will show what the replacements will be looking)

anway - UP! So that gives you a container with traefik, that will not work correctly as you need to have configs available while it starts, and not only that, also certificates!

You see me mentioning that I mapped a local folder: config into the container. so lets have a look at the content of that folder:
there are 4 files for me: 
- server.crt
- server.key
- traefik.yml
- flexconfig.yml

Obviously key and crt are certificate details we need to offer our host to others with "somewhat" valid certifiacte details to offer secure https services (traefik has its build in certificate stuff, but I was not really lucky with that). If you have a managed CA in your network you might have even a simpler live! 

So how do you get those certificats for your host? Well, I found the answer to that in bccontainerhelper, just tweaked a bit:
you need openssl, that will help you to create the files needed together with New-SelfSignedCertificate & Export-PfcCertificate pwsh command. 

just check it out [Create-Certificate.ps1](https://github.com/KristofKlein/BCtraefik/blob/main/traefik/create-certificate.ps1)

if you keep the folder structure alive, it should place you the needed files right in the config folder. 

so now the two yml. So the thing here is: traefik has a static file and a dynamic file. static means: loading it once with the service. If you chance that file, you have to restart the container. the dynamic file however gets constantly monitored by traefik. so If you change it, it will notice, and adjust accordingly. 

One thing that killed me in the beginning was the "where should stuff go" topic on traefic. Is it static, is it dynmic, is it even docker label dynamic. That took me some time. Also if you want to have something in dynamic, that the even more dynamic containers make use of ( because it somewhat gets "static" again, but more within the BC compose files).

Anyway, if you kept all in place, used the files needed you should have traefik up and running! and you should be able to reach the UI.

## BC Container time! Almost

Now what you have been waiting for. get BC container and traefik to work. The first thing we need to take care of is an image for BC. There are some ways to achive this, but I went an easy route: bccontainerhelper. It has what it needs to create images in the correct way. It even has, what it needs to make stuff work proper thanks to the brillant file overload. Because there is one thing that is "anoying". A hen - egg problem:

Traefik only routes containers in healthy state! ok, so in order to get our bc container healthy it does a http request "itself" 200 we are healty, anything else, not so good. The twist here is: if traefik is the one that does the http stuff for the container, and if the container is not healty, how can bc check against its url if it is reachable? you got it, it can't. So this where this "we need to fool the healthcheck" comes into play. 

The way I solved this leans towards what was already made for traefik v1.7 but a biiiit different.
So I have file called "CheckHealth.ps1" thisone I will hand into the image creation process. my healtcheck will be able to detect the circumstances the container was started : like should it use ssl? -> http vs https, is it even offering a webserivces -> yes: ask localhost no: fallback and check the service is running. 

the final thing you have to do, tell the new-BCImage where it can find the script and there you go. 

[Build-BcContainerImage](https://github.com/KristofKlein/BCtraefik/blob/b8350dd21fcbf788c30c0deb39760904e77ff260/BusinessCentral/image/Build-BCContainerImage.ps1)

## BC Container time! Now for real

So my idea was to make use of docker compose ( guess I mentioned this now just often enough), and I wanted to use sort of a template for all upcoming situations. So this is what made me to come around with one docker-compose.yml while injecting the needed details via env files. those are just smart replacements while compose starts up. they overwrite each other based on loaded order. With newer compose versions they also support some smart "syntax" like : do not work if a value is missing, or if no value is set, take a default. Kind of nice. 

In the end I created two env files. One is like global. E.g. the the full qulified host name (FQN). that is not to change normally. Than there is a second file within a subfolder ( not sure why I did this, as you can name those files what you want...). Anyway. so after I have the global env, I apply the special one as second. There I control stuff that I want to happen for that particular instance. As you can see I have a folder BC231, you could think og BC2310 or vNext or what ever suites you best here. My Setup is normally build around an onPrem hosted SQL Server, which makes stuff more complicated, but is a quite common scenario I guess for OG's. 
I am quite sure it will also work with the SQL Server within the container (IF YOUR IMAGE CREATION ADDED IT!). 

the compose file for BC...
It has quiet some common stuff you saw already in the one for traefik, like network, restart policies etc. But there is more, quite a lot more ( this is the moment to lift your virtual hat to Freddy, as BC container simply takes care of all that things for you in the new-bccontainer cmd... took a while to replay that).

The main sections are the following:

### environment
Here we set all the things we need for bccontainerhelper - or more precious - docker-nav. What is set here gets used while the container starts up regulr but also first time. 

### customNavSettings
so customNavSettings is in fact also an evironment, but it applies to the BC Service itself, to change settings of it. The way you need to enter it is a bit strange, but works the way presented in the file. the Whole element needs to have " around it and every new key=value needs to have a new line ,\ - besides the last one.

### labels
this is where traefik kicks in once more. Here you control, how traefik has to deal with the routing.
normally you will see at least two things for traefik to work: a route and a service. And if need be a middleware. the way this works you better get from traefiks pages rather from me trying to explain. 
But what I want to mention is the following:

#### pure container self driven setup 
This setup is completly controlled by what the container will ship.
What is the router called, what is the rule we should use to pick this particular service, etc.

#### dynamic config related setup 
This setup is given by traefik, but gets used by our containers

An example here is 

- traefik.http.routers.${COMPOSE_PROJECT_NAME}ui.middlewares=sslHeader@file
or
- traefik.http.services.${COMPOSE_PROJECT_NAME}ui.loadbalancer.serverstransport=BCHTTP@file

Notice this @file? this is there to tell traefik, that it find those elements sslheaders or BCHTTP in a file...now remember the dynamic content? there I have those two things defined and setup. 

And that should be it - in the end you will call something like

`docker-compose.exe --env-file .env --env-file .\bc231\.env up bc`

