Running DokuWiki over I2P with Docker
=====================================

**UNFINISHED.**

How to host a DokuWiki as an I2P Site, using Docker and Java I2P. Writing
with a slightly different tone than my other guides, today I want to talk
a little more about "why" and it's going to give us a different take on
"how." This is not going to be my most "Professional" article ever, today
we're in this together and I'm making a case for my plan.

Docker is your f'in friend.
---------------------------

### Docker can make your life easier. Yes you.

Docker isn't just for systems administrators. If you let your computer run
any programs while you're not sitting there watching it, then Docker can
probably offer you something worthwhile. Besides "containing" your applications
within a stable, predictable, environment, which you can rebuild without interfering
with the environment in a running container, Docker provides a general way of
managing the lifecycle of your applications and dealing with crashes, sets up
containers on a network Bridge where they do not share the localhost address of the
host machine, and can manage data by attaching directories on the host to
directories within the container. Learning some basic Docker usage will help
you if it's your job(or hobby, whatever) to host a bunch of hidden services.
Besides that, if you're the type to share your hidden service setup instructions
with the community, it means that anyone on any OS can use them, as long
as they can install Docker. Oh also there's a freaking enormous community, every
question you ever had has probably already been asked and answered on some(probably
the wrong) StackExchange-adjacent site already.

So it pays to learn Docker. Or don't, its your life. But I would.

Highlights of Docker include:

 - Run on [Linux](https://docs.docker.com/get-docker/), [Mac OSX](https://docs.docker.com/docker-for-mac/install/),
  and [Windows](https://docs.docker.com/docker-for-windows/install/) without modification(Usually).
 - [An absolutely enormous repository of community packages, Dockerhub](https://hub.docker.com)
 - Automatically restart applications when they crash by passing `--restart=always`
  `docker run`
 - Volume management using either "named" volumes or directories on the
  host machine by passing the `--volume` and `--mount` flags
 - Network "Bridge" which attaches to the host indirectly, containers have
  their own IP addresses on this bridge, own ports, may have their own hostnames.
  Ports can be forwarded to the host machine using the `-p` flag.
 - Among many, many more reasons why Docker is pretty much ideal for hosting
  small hidden services.

Docker is really just another application, on most levels. Once you've used
it a few times it ceases to be confusing, you'll be passing pretty similar flags
to every single container you ever build or run, and only very rarely does it
ever get any more complex than the stuff you learn your first few weeks. It's like
`git`, it has lots of stuff to work with, but you end up using about the same six
options every time.

### Dockerhub maybe isn't always your best friend, but that's OK

Dockerhub could be considered a sort of Man in the Middle. Most of the
containers are build automatically on Docker's infrastructure, which means
that Dockerhub could in theory serve you up a bad image. This is pretty
unlikely, though, and not at all the biggest risk. The biggest risk is
that anybody can create a namespace and push an image to this infrastructure.
That namespace can't be racist, and it can't be occupied by another user
already, and I'm like, 85% sure it can't contain your typical "lookalike"
characters(Cyrillic O's and whatnot). Nothing stops anyone from registering
the namespace `mozzilla` though, or `mozil1a` or other legal characters that
resemble eachother.

The part of dockerhub which is undeniably useful, though, is the statistics
it generates on image usage, and its search capabilities. These are accessible
via the `docker search` command.

Here's a `docker search` example:

```bash
docker search dokuwiki
```

        NAME                           DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
        mprasil/dokuwiki               Container running DokuWiki with nice URLs an…   97                   [OK]
        linuxserver/dokuwiki                                                           59                   
        istepanov/dokuwiki             Docker image with dokuwiki and nginx. Suppor…   43                   [OK]
        vimagick/dokuwiki              A wiki application licensed under GPL 2 and …   14                   [OK]
        bambucha/dokuwiki              Alpine DokuWiki Docker Container                8                    [OK]
        crazymax/dokuwiki              DokuWiki image based on Alpine Linux            7                    
        plaguedr/dokuwiki              DokuWiki is a wiki application licensed unde…   2                    
        dtwardow/dokuwiki              DokuWiki Docker Container                       1                    [OK]

To avoid the risk of using a compromised upstream container, research the
source of the docker image. Pay attention to the `FROM` line of the `Dockerfile`, and
make sure that it corresponds to an "Official" signed base image from
a distro like Ubuntu, Debian, or Alpine Linux, or that it is from `SCRATCH`.
If it does not, find the source of the parent image, and repeat this process
until the whole stack of images is analyzed. In practice, this is rarely more
than one image.

To avoid the risk of using an out-of-date upstream container, build your image
locally, and all of the parent images as well, unless you are confident in the
upstream image being consistently maintained.

DokuWiki Decisions:
-------------------

### Why I chose DokuWiki

Choosing software which is easy to maintain an instance of is setting yourself
up for success. Many hidden services are run by one person, if one is
lucky one has a backup or possibly a skeleton crew. Only a handful of
well-organized, mostly non-anonymous organizations have really reliable
teams of people to operate and maintain their sites and the hardware
that runs them.

This isn't wrong, and it doesn't have to be dangerous. It's also true
that many hidden services are operated by hobbyists, researchers, and
enthusiasts who simply want to host their services in a way which
transparently evades NAT difficulties. Many of them have small audiences
and even smaller numbers of contributors. It's not really my business to
know why they want to use the I2P network, my business it to show them
why it's a good option(Which it is). As long as the software you are
hosting is something you can keep up-to-date without breaking your back
or losing your job, then it's perfectly reasonable for just one person
to manage and host a hidden service, even on a residential connection.

This is the chief advantage of DokuWiki, especially combined with
Docker. There are no databases to set up, you can pre-configure the
administrative user and password, it honors the `http_proxy` environment
variable. There has never been a situation in which I had to lost
data stored in a DokuWiki to an update.

### Finding a DokuWiki Docker Image

Let's return to the `docker search` output from earlier for a moment,
because that's where we're going to start.

        NAME                           DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
        mprasil/dokuwiki               Container running DokuWiki with nice URLs an…   97                   [OK]
        linuxserver/dokuwiki                                                           59                   
        istepanov/dokuwiki             Docker image with dokuwiki and nginx. Suppor…   43                   [OK]
        vimagick/dokuwiki              A wiki application licensed under GPL 2 and …   14                   [OK]
        bambucha/dokuwiki              Alpine DokuWiki Docker Container                8                    [OK]

So what is this telling us, and what conclusions should we be drawing
from it?

 - `[Name]` This is just the name of the image, in the form `[namespace]/[name]`.
Often, this will be identical to the github or bitbucket namespace where the
image source is available. The namespace tends to reveal if the image is
maintained by an organization or by an individual. Obviously there are
advantages to choosing an image maintained by an organization.

 - `[Description]` The description of the image contains information additional
to the name. It's usually not the most interesting part of the `docker search`
output.

 - `[Stars]` As a rule, if only one person is using an image, it's probably
not up to date. Prioritize images with more users for research, stars will
be positively correlated to users, and users will be positively correlated
to eyes on the image, so prioritize images with the most stars.

 - `[Official]` Docker only has a handful of "official" images which are provided
by upstream distributions and software packages. Ubuntu, for instance, has an
official image:

        NAME                                                      DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
        ubuntu                                                    Ubuntu is a Debian-based Linux operating sys…   12481     [OK]       


 - `[Automated]` This means that the image was built on Docker's automated build
system, and not built on the developer's machine and pushed up to Dockerhub.

So, what images will we evaluate? The two that look the most promising are
`mprasil/dokuwiki`, and `linuxserver/dokuwiki`. `mprasil/dokuwiki` has a
[docker hub page here](https://hub.docker.com/r/mprasil/dokuwiki). At the top
it says "Updated a year ago" which is maybe not the best sign ever. On the other
hand, [linuxserver/dokuwiki](https://hub.docker.com/r/linuxserver/dokuwiki) was
updated less than a week ago. That's the one we need.

Before we continue, let's look at the `Dockerfile`s that describe the containers
which we will be running. First, the docker-dokuwiki `Dockerfile`:

 - [`Dockerfile 1`](https://github.com/linuxserver/docker-dokuwiki/blob/master/Dockerfile)

Uh-oh, looks like it's *not* from an official image or a `SCRATCH` image as we
recommended earlier. Instead, it modifies another image, the name suggests
that it combines `Alpine Linux` with an `nginx` web server. Let's look one level
deeper at the parent `Dockerfile`.

 - [`Dockerfile 2`](https://github.com/linuxserver/docker-baseimage-alpine-nginx/blob/master/Dockerfile)

Examining this `Dockerfile` confirms the suspicion that it combines Alpine linux witn
nginx and some modules. But we still haven't reached the base image, that's another level
down.

 - [`Dockerfile 3`](https://github.com/linuxserver/docker-baseimage-alpine/blob/master/Dockerfile)

At last we're here, and indeed each of the `Dockerfiles` looks non-malicious.

### Getting DokuWiki Configured

Setting up DokuWiki in a Docker container can be done in a couple simple steps.
The quickest way to get started is to just run a modified version of the command
from the linuxserver.io readme:

```bash
docker run -d \
  --name=dokuwiki \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -p 127.0.0.1:8080:80 \
  -v $HOME/.config/dokuwiki:/config \
  --restart always \
  ghcr.io/linuxserver/dokuwiki
```

In this command, we remove the HTTPS port forward since it won't work over I2P
(for now) and we explicitly specifiy that we want to *only* listen on the localhost
with the HTTP port. This will allow us to safely listen locally without exposing our
service to devices on the LAN or on the Internet. It also specifies that the container
should always restart if it crashes, which will also cause it to start with the docker
daemon, and places the config directory in your `$HOME/.config/` directory.

But let's suppose that you want to re-build the whole stack of containers locally. In
order to do this, clone each individual parent container and re-build it with the same
name as it has on `ghcr.io`.

Start with the base image:

```bash
#! /bin/sh
WD=$(pwd)
git clone https://github.com/linuxserver/docker-baseimage-alpine
cd docker-baseimage-alpine
docker build -t ghcr.io/linuxserver/baseimage-alpine:3.14 .
cd "$WD"
```

Then the parent image:

```bash
#! /bin/sh
WD=$(pwd)
git clone https://github.com/linuxserver/docker-baseimage-alpine-nginx
cd docker-baseimage-alpine-nginx
docker build -t ghcr.io/linuxserver/baseimage-alpine-nginx:3.13 .
cd "$WD"
```

Finally, you can build the application image:

```bash
#! /bin/sh
WD=$(pwd)
git clone https://github.com/linuxserver/docker-dokuwiki
cd docker-dokuwiki
docker build -t ghcr.io/linuxserver/dokuwiki
cd "$WD"
```

And the run command will be identical to the one shown above. Once your container is
running, wait a few seconds and visit the
[http://127.0.0.1:8080/install.php](http://127.0.0.1:8080/install.php) to continue
setting up your DokuWiki. Finalizing the installation requires you to fill out one page
with information:

 - ![install.php](install.php.png)

Be sure to disable reporting anonymous usage information. It's probably not anonymous
enough, and we don't want to phone home to anywhere.

### Getting I2P Configured

Now that you've got DokuWiki configured locally, you can add an I2P Tunnel to connect
it to the I2P network. DokuWiki is an HTTP Service, so we'll use an I2P HTTP Tunnel to
create our I2P Site. Navigate to the [Hidden Services Manager](http://127.0.0.1:7657/i2ptunnelmgr/)
to get started configuring the I2P Tunnel. I2P has extensive tools in place for
helping set up different types of hidden services interactively.

The tool for configuring I2P Tunnels is the Hidden Services Manager, which is an
I2P Application you can access by visiting the URL [http://127.0.0.1:7657/i2ptunnelmgr](http://127.0.0.1:7657/i2ptunnelmgr)
in a web browser. Because DokuWiki is a regular HTTP service, with no federation
or anything like that to worry about, you probably won't need to change *any*
of the defaults to effectively run your DokuWiki service. So, start the
[Setup Wizard](http://127.0.0.1:7657/i2ptunnel/wizard) to begin the process of
tunnel configuration.

1. Since DokuWiki is a server application, we need a server tunnel.  
![Server Tunnel](i2ptunnel(0).png)
2. It's an HTTP Server, so we should take advantage of I2P's tunnel for HTTP Servers.  
![HTTP Server](i2ptunnel(1).png)
3. Give your HTTP Server Tunnel a descriptive name related to the DokuWiki it is serving.  
![Tunnel Name](i2ptunnel(2).png)
4. Point the hidden service at the DokuWiki service. In this example, that is 127.0.0.1:8080.  
![Tunnel Host](i2ptunnel(3).png)
5. Configure the tunnel to start automatically.  
![Start Automatically](i2ptunnel(4).png)
6. Review and save the defaults.  
![Review](i2ptunnel(5).png)

#### Sharing Addresses

##### Sharing a Base32 Address:

After these basic steps, your hidden service will become available in a few
seconds. You can find the address by returning to [http://127.0.0.1:7657/i2ptunnelmgr](http://127.0.0.1:7657/i2ptunnelmgr)
and finding the tunnel in the top section, labeled "I2P Hidden Services."

 - Here's what it looks like:  
 ![Base32 and description only](address.png)

Copy-and-Paste the line ending with `.b32.i2p` into your I2P browser, or click
the "Preview" button to visit your DokuWiki server using I2P. You can share
this "Base32 Address" with other I2P users to allow them to access your
DokuWiki.

##### Sharing an Unregistered Hostname:

I2P has a flexible system for sharing human-readable addresses built-in. The
Address Book is available to every I2P application that wants it. In order to
share a site with a human-readable hostname, you'll need to generate an
"Address Helper" link and share it with your peers. The Hidden Services Manager
can help you with this. Return to [http://127.0.0.1:7657/i2ptunnelmgr](http://127.0.0.1:7657/i2ptunnelmgr)
and click the link to your DokuWiki tunnel's Configuration Page. You'll see
something that looks like this:

 - Fill in your hostname where you see the red circle, then click "Save" at the
 bottom of the page:  
 ![hostname](hostname.png)

Once you have saved the settings, you will be returned to the Hidden Services
Manager home page. A new element will be visible on the DokuWiki section of the
Hidden Services listing:

 - The new Text Area contains a pre-generated Address Helper link for you to
 share.  
 ![addresshelper](addresshelper.png)

When you share a link like this, the recipient is prompted to add the address
to their Address Book, making it accessible at the human-readable URL.

##### Registering a Hostname*

If you want to register a hostname, and thus propagate it out to the various
hostname subscription providers, the best place to do that right now is
[stats.i2p](http://stats.i2p/i2p/addkey.html). Registries are run by peers in
the I2P network, in this case a prominent, long-time I2P developer who has
earned immense trust in the community.

 - zzz's Terms of Service. They're important, if you don't like them then run
 your own registry.  
 ![stats.i2p TOS](statstos.png)

In order to carry out your registration, you will need to copy an
"Authentication string" from within the Hidden Service Manager. Go to the
DokuWiki tunnel configuration page in the Hidden Service Manager and click the
button that says "Registration Authentication." This will reveal the required
authentication strings.

 - Register your hostname using these authentication strings.  
 ![Authentication Strings](authstrings.png)

Once you have your authentication string, add it to the form on stats.i2p:

 - ![Register](statsreg.png)

\* It is not recommended to use Registered Hostnames in combination with
Encrypted LeaseSets.

#### I2P Pro Tips:

I2P has several features which appeal to certain use-cases and niches, in
particular it has options for imposing cryptographic requirements on the ability
to discover a tunnel endpoint and connect to it, and the ability to accept as
input packaged configuration files(And applications, but that's a discussion for
another day).

##### Use Blinded or Encrypted LeaseSets

Blinded LeaseSets are roughly equivalent to blinding in Tor's onionv3 services,
but for I2P. It's used to prevent Floodfills which distribute information about
I2P destinations in the NetDB from being able to discover a hidden service in
floodfill data. If you don't want other people to be able to know your site
exists without you telling them, blinded LeaseSets would likely be a necessary
part of this strategy.

Encrypted LeaseSets are LeaseSets which are published to the NetDB encrypted, so
that only a person who is in possession of the correct keys can decrypt the
LeaseSet and discover the information required to connect to a site. If you want
to have access-controls on your site which prevent unauthorized users from
discovering how to connect to your I2P Site, use Encrypted LeaseSets.

##### Use i2ptunnel.config.d

Once you have a Hidden Service set up, the nice thing to do is to document your
configuration and share it with the rest of the world. One thing you can do
which makes this easier for people who are reviewing, modifying, or reproducing
your service is to look in your i2ptunnel.config.d directory and find the file 
that configures the hidden service tunnel, remove any superfluous or sensitive
information, and publish it somewhere anyone can use it. Here is such a config
file for the DokuWiki service which we just set up.

```ini
description=Serves a DokuWiki, perhaps for your project
name=DokuWiki Server
option.enableUniqueLocal=false
option.i2cp.destination.sigType=7
option.i2cp.leaseSetEncType=4,0
option.i2cp.reduceIdleTime=1200000
option.i2cp.reduceOnIdle=false
option.i2cp.reduceQuantity=1
option.inbound.backupQuantity=0
option.inbound.length=3
option.inbound.lengthVariance=0
option.inbound.nickname=DokuWiki Server
option.inbound.quantity=2
option.outbound.backupQuantity=0
option.outbound.length=3
option.outbound.lengthVariance=0
option.outbound.nickname=DokuWiki Server
option.outbound.quantity=2
option.rejectInproxy=false
option.rejectReferer=false
option.rejectUserAgents=false
option.shouldBundleReplyInfo=false
option.useSSL=false
privKeyFile=i2ptunnel17-privKeys.dat
spoofedHost=wiki.idk.i2p
startOnLoad=true
targetHost=127.0.0.1
targetPort=8080
type=httpserver
```
