/*
 * A small, cross-platform duplex stream used by protocol tests.
 *
 * GMemoryInputStream is finite and cannot wait for data written by a peer.
 * These streams provide the blocking pipe behavior required by Jsonrpc.Client
 * without depending on Unix file descriptors or opening network sockets.
 */

private class TestPipe : Object {
    Mutex mutex;
    Cond data_available;
    ByteArray pending = new ByteArray ();
    bool closed;

    public ssize_t read (uint8[] buffer, Cancellable? cancellable) throws IOError {
        ulong cancelled_id = 0;
        if (cancellable != null) {
            cancelled_id = cancellable.cancelled.connect (() => {
                mutex.lock ();
                data_available.broadcast ();
                mutex.unlock ();
            });
        }

        mutex.lock ();
        while (pending.len == 0 && !closed &&
               (cancellable == null || !cancellable.is_cancelled ())) {
            data_available.wait (mutex);
        }

        bool was_cancelled = cancellable != null && cancellable.is_cancelled ();
        uint bytes_read = uint.min (pending.len, (uint) buffer.length);
        for (uint i = 0; i < bytes_read; i++)
            buffer[i] = pending.data[i];
        if (bytes_read > 0)
            pending.remove_range (0, bytes_read);
        mutex.unlock ();

        if (cancelled_id != 0)
            ((!) cancellable).disconnect (cancelled_id);
        if (was_cancelled)
            ((!) cancellable).set_error_if_cancelled ();

        return bytes_read;
    }

    public ssize_t write (uint8[] buffer, Cancellable? cancellable) throws IOError {
        if (cancellable != null)
            cancellable.set_error_if_cancelled ();

        mutex.lock ();
        if (closed) {
            mutex.unlock ();
            throw new IOError.CLOSED ("test pipe is closed");
        }

        pending.append (buffer);
        data_available.signal ();
        mutex.unlock ();
        return buffer.length;
    }

    public void close () {
        mutex.lock ();
        closed = true;
        data_available.broadcast ();
        mutex.unlock ();
    }
}

private class TestPipeInputStream : InputStream {
    TestPipe pipe;

    public TestPipeInputStream (TestPipe pipe) {
        this.pipe = pipe;
    }

    public override ssize_t read (
        uint8[] buffer,
        Cancellable? cancellable = null
    ) throws IOError {
        return pipe.read (buffer, cancellable);
    }

    public override bool close (Cancellable? cancellable = null) throws IOError {
        pipe.close ();
        return true;
    }
}

private class TestPipeOutputStream : OutputStream {
    TestPipe pipe;

    public TestPipeOutputStream (TestPipe pipe) {
        this.pipe = pipe;
    }

    public override ssize_t write (
        uint8[] buffer,
        Cancellable? cancellable = null
    ) throws IOError {
        return pipe.write (buffer, cancellable);
    }

    public override bool close (Cancellable? cancellable = null) throws IOError {
        pipe.close ();
        return true;
    }
}

private void create_test_stream_pair (
    out IOStream server_stream,
    out IOStream client_stream
) {
    var client_to_server = new TestPipe ();
    var server_to_client = new TestPipe ();

    server_stream = new SimpleIOStream (
        new TestPipeInputStream (client_to_server),
        new TestPipeOutputStream (server_to_client));
    client_stream = new SimpleIOStream (
        new TestPipeInputStream (server_to_client),
        new TestPipeOutputStream (client_to_server));
}
