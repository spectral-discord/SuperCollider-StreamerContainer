# SuperCollider Streaming Container

SCSC is a web-based audio live coding environment in a docker container.

Features:
- A [SuperCollider](https://supercollider.github.io) instance, with [sc3-plugins](https://supercollider.github.io/sc3-plugins) and [Tidal Cycles](https://tidalcycles.org)
- Emacs, with SuperCollider and Tidal modes
- A web-based terminal ([ttyd](https://github.com/tsl0922/ttyd))
- SuperCollider's audio output is streamed to your browser via low-latency [WebRTC](https://janus.conf.meetecho.com)

## Deploying

### Hosting on the web

Don't. You'll be giving a shell to whoever finds it. Access it through a secure, private VPN if you must.

plz thx ok?

&ensp;🥺<br>👉👈

### docker compose

```yaml
scsc:
  image: hobgoblina/scsc:latest
  container_name: scsc
  ports:
    - 1312:1312
  volumes:
    - /some/path/on/your/machine:/config  # optional
  restart: unless-stopped
```

## Usage

Visit [localhost:1312](http://localhost:1312)

The first time you visit the page, some Emacs dependencies will install. Be patient, it won't take long.

Upon starting a new session, you'll be entered into `sclang-mode`. Check out [SCEL](https://github.com/supercollider/scel) to get started.

### Tidal Cycles

`C-c C-s` will put you into Tidal Cycles mode. Check out [Tidal Emacs](https://tidalcycles.org/docs/getting-started/editor/Emacs#test-tidal-with-emacs) to get started.

### Start fresh

Exiting emacs via `C-x C-c` will kill the stream/synth/etc and end your ttyd session. It should immediately reconnect, and you'll have a fresh new session to play with.

### Customization

By mounting the `/config` volume like in the `docker compose` example above, you can: 
- edit `init.el` and `tmux.conf` to get a more preferred terminal experience
- put SuperCollider dependency files in the `sclang-includes` directory (they'll get loaded when you start a fresh session)
- edit the webpage and nginx configs in the `web` directory
- edit the scripts that get run when you start or exit an emacs session
- edit the SuperCollider startup file that gets run when you start an emacs session

## Issues

### "I had sound before but now I don't"

Try refreshing the page. You might just need to reestablish the WebRTC connection.

### "There's a little latency between running code and hearing the output"

See how it says `Couldn't set realtime scheduling priority 1: Operation not permitted` in the post window? I haven't worked that out yet. Also, the stream currently uses a large buffer size to prevent skipping, due to the container's limited resources. I'll optimize it at some point.

### "My issues isn't listed here"

Open an [issue](https://github.com/spectral-discord/SuperCollider-StreamerContainer/issues) and I'll try to help!

## Services

Service | Comment
--- | ---
[Supervisor](http://supervisord.org/) | As we need multiple services in this container we use this for service management - something like systemd
[SuperCollider](https://supercollider.github.io) | Audio engine
[PipeWire](https://pipewire.org) | Acts as a virtual soundcard
[GStreamer](https://gstreamer.freedesktop.org) | Swiss army knife for converting media - converts the SuperCollider output to an Opus RTP stream which is sent to *Janus*
[Janus](https://janus.conf.meetecho.com) | WebRTC server for streaming audio to your browser
[ttyd](https://github.com/tsl0922/ttyd) | A terminal in the browser
[nginx](https://nginx.org/en) | Web server and reverse proxy for hosting the webpage

For delivering audio to your browser, the services are chained like this:

```text
SuperCollider --> Pipewire --> GStreamer --> Janus --> nginx --> your browser
```

## Contributing

Know how to make SCSC better, or just wish it was in some way? Open a [PR](https://github.com/spectral-discord/SuperCollider-StreamerContainer/pulls) or [issue](https://github.com/spectral-discord/SuperCollider-StreamerContainer/issues)!

## TODO

- optimizations + realtime priority
- add Vim support
  - allow users to choose between Vim & Emacs via env variable
- update Alpine version
  - resolve [this pipewire-jack/gstreamer issue](https://gitlab.freedesktop.org/gstreamer/gstreamer/-/issues/3092)
- streaming static compositions, with code displayed in plaintext
  - streams defined via config file & generated on container startup
- audio & data inputs via WebRTC
- add WebRTC video streaming of the ttyd session, for streaming live coding performances over the net
  - [getViewportMedia](https://w3c.github.io/mediacapture-viewport/) would be sick... Chrome supports some [stopgaps](https://developer.chrome.com/docs/web-platform/screen-sharing-controls/)

## Remarks

This project builds on the [caster-sound](https://github.com/Gencaster/gencaster/tree/main/caster-sound) container from the [Gencaster](https://github.com/Gencaster/gencaster) project. Big thanks to [Vinzenz Aubry](https://github.com/vin-ni) and [Dennis Scheiba](https://github.com/capital-G) for their great work!
