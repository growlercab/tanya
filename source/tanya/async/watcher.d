/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Copyright: Eugene Wissner 2016-2017.
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/,
 *                  Mozilla Public License, v. 2.0).
 * Authors: $(LINK2 mailto:info@caraus.de, Eugene Wissner)
 */
module tanya.async.watcher;

import std.functional;
import std.exception;
import tanya.async.loop;
import tanya.async.protocol;
import tanya.async.transport;
import tanya.container.buffer;
import tanya.container.queue;
import tanya.memory;
import tanya.memory.mmappool;
import tanya.network.socket;

version (Windows)
{
	import core.sys.windows.basetyps;
	import core.sys.windows.mswsock;
	import core.sys.windows.winbase;
	import core.sys.windows.windef;
	import core.sys.windows.winsock2;
}

/**
 * A watcher is an opaque structure that you allocate and register to record
 * your interest in some event. 
 */
abstract class Watcher
{
	/// Whether the watcher is active.
	bool active;

	/**
	 * Invoke some action on event.
	 */
	void invoke() @nogc;
}

class ConnectionWatcher : Watcher
{
	/// Watched socket.
	private Socket socket_;

	/// Protocol factory.
	protected Protocol delegate() @nogc protocolFactory;

	package Queue!IOWatcher incoming;

	/**
	 * Params:
	 * 	socket = Socket.
	 */
	this(Socket socket) @nogc
	{
		incoming = Queue!IOWatcher(MmapPool.instance);
		socket_ = socket;
	}

	/// Ditto.
	protected this() pure nothrow @safe @nogc
	{
	}

	~this() @nogc
	{
		foreach (w; incoming)
		{
			MmapPool.instance.dispose(w);
		}
	}

	/**
	 * Params:
	 * 	P = Protocol should be used.
	 */
	void setProtocol(P : Protocol)() @nogc
	{
		this.protocolFactory = () @nogc => cast(Protocol) MmapPool.instance.make!P;
	}

	/**
	 * Returns: Socket.
	 */
	@property Socket socket() pure nothrow @nogc
	{
		return socket_;
	}

	/**
	 * Returns: New protocol instance.
	 */
	@property Protocol protocol() @nogc
	in
	{
		assert(protocolFactory !is null, "Protocol isn't set.");
	}
	body
	{
		return protocolFactory();
	}

	/**
	 * Invokes new connection callback.
	 */
	override void invoke() @nogc
	{
		foreach (io; incoming)
		{
			io.protocol.connected(cast(DuplexTransport) io.transport);
		}
	}
}

/**
 * Contains a pending watcher with the invoked events or a transport can be
 * read from.
 */
class IOWatcher : ConnectionWatcher
{
	/// If an exception was thrown the transport should be already invalid.
	private union
	{
		StreamTransport transport_;
		SocketException exception_;
	}

	private Protocol protocol_;

	/**
	 * Returns: Underlying output buffer.
	 */
	package ReadBuffer!ubyte output;

	/**
	 * Params:
	 * 	transport = Transport.
	 * 	protocol  = New instance of the application protocol.
	 */
	this(StreamTransport transport, Protocol protocol) @nogc
	in
	{
		assert(transport !is null);
		assert(protocol !is null);
	}
	body
	{
		super();
		transport_ = transport;
		protocol_ = protocol;
		output = ReadBuffer!ubyte(8192, 1024, MmapPool.instance);
		active = true;
	}

	/**
	 * Destroys the watcher.
	 */
	~this() @nogc
	{
		MmapPool.instance.dispose(protocol_);
	}

	/**
	 * Assigns a transport.
	 *
	 * Params:
	 * 	transport = Transport.
	 * 	protocol  = Application protocol.
	 *
	 * Returns: $(D_KEYWORD this).
	 */
	IOWatcher opCall(StreamTransport transport, Protocol protocol)
	pure nothrow @nogc
	in
	{
		assert(transport !is null);
		assert(protocol !is null);
	}
	body
	{
		transport_ = transport;
		protocol_ = protocol;
		active = true;
		return this;
	}

	/**
	 * Returns: Transport used by this watcher.
	 */
	@property inout(StreamTransport) transport() inout pure nothrow @nogc
	{
		return transport_;
	}

	/**
	 * Sets an exception occurred during a read/write operation.
	 *
	 * Params:
	 * 	exception = Thrown exception.
	 */
	@property void exception(SocketException exception) pure nothrow @nogc
	{
		exception_ = exception;
	}

	/**
	 * Returns: Application protocol.
	 */
	override @property Protocol protocol() pure nothrow @safe @nogc
	{
		return protocol_;
	}

	/**
	 * Returns: Socket.
	 */
	override @property Socket socket() pure nothrow @nogc
	{
		return transport.socket;
	}

	/**
	 * Invokes the watcher callback.
	 */
	override void invoke() @nogc
	{
		if (output.length)
		{
			protocol.received(output[0 .. $]);
			output.clear();
		}
		else
		{
			protocol.disconnected(exception_);
			active = false;
		}
	}
}
