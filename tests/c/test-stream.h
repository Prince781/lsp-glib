#pragma once

#include <gio/gio.h>

void create_test_stream_pair (GIOStream **server_stream,
                              GIOStream **client_stream);
