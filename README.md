# proxybitssh

Simple Docker image configured to run SSH over HTTPS. Use with a `proxytunnel` client to get around layer 7 firewalls in public WiFi access points that only allow outbound HTTPS traffic.

I really hate when cafés do this because it's not going to stop actual hackers from abusing their bandwidth (because they can do exactly what I'm doing), but it stops real people (like me) from getting shit done.

Consider this a middle finger.

## Usage

Run this container in an EC2 (or similar) with a public IP somewhere, or maybe at home on your Raspberry Pi4. Take a look at the [`docker-compose.yaml`](./docker-compose.yaml) file for super-basic usage.

### Bindmounting `path/to/your/public/ssh-keys:/etc/ssh/keys-pub`

This isn't very useful if you can't add your SSH keys to this container, so bindmounting a folder containing your SSH public keys to `/etc/ssh/keys-pub/` will populate the `authorized_keys` file in the container. See the `entrypoint.sh` script for details on how that works. It's not magic.

### Example on EC2, AmazonLinux 2023

```bash
# become root
sudo su -

# install docker
dnf update && dnf install -y docker
service docker start

# setup your ssh keys
cd /root
mkdir -p ssh-keys
cp path/to/your/ssh-public-keys ssh-keys/

# start container
docker run --rm -d \
  -v $PWD/ssh-keys:/etc/ssh/keys-pub \
  --name proxybitssh \
  -p 443:443 \
  invid/proxybitssh:latest
```

### Testing your connection with `proxytunnel`

First install `proxytunnel`. With homebrew, this is basically:

```bash
brew install proxytunnel
```

If you aren't using homebrew, I'm sure you're smart enough to Google around to find installation instructions. I've already spent too much time writing this README, so you'll have to do some RTFM lol. Big papa already has real work to do.

```bash
# obviously, replace your-server-ip with the host you are running this on
# and if you're just testing this on your laptop before deploying, this this of
# course would be the loopback IP (127.0.0.1).
proxytunnel -zvE \
  -p <your-server-ip>:443 \
  -d 127.0.0.1:22 \
  -H "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Win32)\n"
```

## Connecting

### Step 1: edit `~/.ssh/config`:

```bash
# obviously, substitute yourserverip
cat <<-SSHCONF >>~/.ssh/config

Host yourserverip
  HostName yourserverip
  ProxyCommand proxytunnel -q -z -E -p yourserverip:443 -d 127.0.0.1:22
  DynamicForward 1080
  ServerAliveInterval 60
SSHCONF
```
### Step 2: connect via SSH (and start your tunnels and/or SOCKS5 proxies!)

This is an example of how to get `git pull` working on github when using SSH repository URLs:

```bash
# you are using ssh-agent aren't you???
# or if you're just using your default key, you probably don't need this, but
# dude, just be cool and use `ssh-agent` already. it's good for you.
ssh-add path/to/your/key

# starts a socks5 proxy on local port 5555, and a local port-forward for
# github connecting through https port and runs in the background
ssh -p 443 -o 'StrictHostKeyChecking=no' -D 5555 -L2200:github.com:22 -fNT tunnel@yourserverip

# edit your /etc/hosts to alias your hostnames that you want to forward as
# 127.0.0.1, e.g., github.com
#
# <---- inside /etc/hosts ---->
# 127.0.0.1 localhost github.com

# Now, you'll want to set GIT_SSH_COMMAND to use port 2200 and ignore
# the new host keys
# export GIT_SSH_COMMAND='ssh -p 2200 -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'

# finally...
git pull
```

## Building and pushing this image

Actually, this is only for me since only I have permissions to push to the current docker hub repo.

If you want to build a non-multiarch image on your own, see the next section.

```bash
VERSION="<semver-string>" make push
```

## Building the image locally

```bash
# pretty simple, really. you won't be able to push this to docker hub unless you
# change the tag name and create your own repo on docker hub, and with your own
# tokens.
#
# But this will load the newly built image into your local cache/registry.
docker build . -t invid/proxybitssh
```
