# BCtraefik

Due to some lucky circumstances I ended up to write this article about my journey with traefik and business Central. I think I am not the only one and there is @tfenster and many others that touched that. However it never made it back into bccontainerhelper to support a newer version of traefik. In the meantime we have reached version 3. 

So, to move along I will first describe my way to run v2 and how to make use of v3 in legacy mode ( simply because I did not managed to rewrite my configs).

First things first: works for, in my circumstances it does what it should do. no guarantee it will for you :P this is based on windows containers. And all my machines are "AD joined" which is important to know when it comes to certificates, routing and FQNs. 

One of my goals was: this should work local. So no need for any fancy AzureVM or URL registration to get some LetsEncypt stuff working. I wanted this local. On a server, on my laptop. 

In order to achive this, just for a simple first container running traefik: 
- configuration
- certificates
- docker stuff ( in my case I use compose, as I like the way to setup things)

## Let's start with the docker-compose.yml for traefik:

So this files duty is, to get you a service started. As expected in that scenario the service is traefik. In order to let traefik function you need to set some details it needs. Those are:
- EntryPoints (Ports)
- Docker Engine Access (volume)
- elegant way to configure traefik without detroying the container again and again (volume)
- enable traefik for the trafik container itself (labels)
- and some other fancy stuff ( network, image policies) 

Just check the file, it should explain itself. 

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

