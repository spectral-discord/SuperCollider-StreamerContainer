SCStreamerStatus {
	classvar <success;
	classvar <failure;
	classvar <ready;
	classvar <finished;
	classvar <received;

	*initClass {
		success = "SUCCESS";
		failure = "FAILURE";
		ready = "READY";
		finished = "FINISHED";
		received = "RECEIVED";
	}
}

SCStreamerVerbosity {
	classvar <debug;
	classvar <info;
	classvar <warning;
	classvar <error;

	*initClass {
		debug = 10;
		info = 20;
		warning = 30;
		error = 40;
	}
}

SCStreamerServer {
	var <name;
	var <synthPort;
	var <langPort;

	var <janusOutPort;
	var <janusInPort;
	var <janusOutRoom;
	var <janusInRoom;
	var <janusPublicIP;

	var <useInput;

	var <>verbosity;

	// private
	var <>environment; // shall this be a proxy space?
	var <>server;

	// basically a constructor which allows us to set
	// the necessary values directly or via env variables
	// as fallback - a "bit" verbose, but well
	*new {arg
		name = nil,
		synthPort = nil,
		langPort = nil,
		janusOutPort = nil,
		janusInPort = nil,
		janusOutRoom = nil,
		janusInRoom = nil,
		janusPublicIP = nil,
		useInput = nil,
		verbosity = nil;

		name = name ? "SC_NAME".getenv ? "STREAMER_LOCAL";
		synthPort = synthPort ? ("SC_SYNTH_PORT".getenv ? 57110).asInteger;
		langPort = langPort ? NetAddr.langPort ? 57120;
		janusOutPort = janusOutPort ? ("JANUS_OUT_PORT".getenv ? 0).asInteger;
		janusInPort = janusInPort ? ("JANUS_IN_PORT".getenv ? 0).asInteger;
		janusOutRoom = janusOutRoom ? "JANUS_OUT_ROOM".getenv;
		janusInRoom = janusInRoom ? "JANUS_IN_ROOM".getenv;
		janusPublicIP = janusPublicIP ? "JANUS_PUBLIC_IP".getenv;
		useInput = useInput ? ("SUPERCOLLIDER_USE_INPUT".getenv ? 0).asInteger;
		verbosity = verbosity ? ("SC_VERBOSITY".getenv ? SCStreamerVerbosity.info).asInteger;

		^super.newCopyArgs(
			name,
			synthPort,
			langPort,
			janusOutPort,
			janusInPort,
			janusOutRoom,
			janusInRoom,
			janusPublicIP,
			useInput,
			verbosity,
		).init;
	}

	init {
		environment = this.serverInfo;
		environment[\this] = this;
	}

	num {
		synthPort%16;
	}

	serverInfo {
		^(
			name: name,
			synth_port: synthPort,
			lang_port: langPort,
			janus_out_port: janusOutPort,
			janus_in_port: janusInPort,
			janus_out_room: janusOutRoom,
			janus_in_room: janusInRoom,
			janus_public_ip: janusPublicIP,
			use_input: useInput,
		);
	}

	postServerInfo {
		"### SuperCollider server ###".postln;
		this.serverInfo.pairsDo({|k, v|
			"%: %".format(k, v).postln;
		});
		"### /SuperCollider server ###".postln;
	}

	startServer {
		server = Server(
			name: name,
			addr: NetAddr(hostname: "127.0.0.1", port: synthPort),
		);
		server.options.sampleRate_(48000).memoryLocking_(true).memSize_(8192*4);
		server.options.numOutputBusChannels = 2;
		server.options.device = "default:%".format(name);
		server.options.bindAddress = "0.0.0.0";
		server.options.maxLogins = 2;
		Server.default = server;

		"Booting server % on port %".format(name, synthPort).postln;
		server.waitForBoot(onComplete: this.postStartServer);
	}

	postStartServer {
		"Finished booting server".postln;
	}
}
