/*
 * Reuse the C test transport so every language suite exercises the same
 * cross-platform, blocking duplex stream behavior.
 */
[CCode (cname = "create_test_stream_pair", cheader_filename = "test-stream.h")]
private extern void create_test_stream_pair (
    out IOStream server_stream,
    out IOStream client_stream
);
