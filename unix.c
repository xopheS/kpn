#include <error.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include interface_c.h


#define STANDARD_PIPE_SIZE 2
#define INPORT_ID 0
#define OUTPORT_ID 1



communication_channel_t* allocate_channel () {
    int pipe [STANDARD_PIPE_SIZE];
    errno = 0; 
    pipe(pipe);
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO)
    communication_channel_t* com = NULL;
    com = malloc(sizeof(*com));
    M_REQUIRE_NON_NULL(com)
    com->in_port = pipe[INPORT_ID]; 
    com->out_port = pipe[OUTPORT_ID];
    return com;
} 

communication_stream_t* open_communictaion_stream (out_port pipe_direction, const char* mode, communication_type t) {
    M_REQUIRE_NON_NULL(pipe_output)
    M_REQUIRE_WRITE_MODE(mode)
    M_REQUIRE_READ_MODE(mode)
    switch (t)
    {
    case FILE:
        FILE* stream = fdopen (pipe_output, mode);
        M_REQUIRE_NON_NULL (stream)
        break;
    case PIPE:
        FILE* stream = fdopen (pipe_output, mode);
        M_REQUIRE_NON_NULL (stream)
        break;
    default:
        break;
    }
    
    communication_stream_t* com = malloc(sizeof(*com));
    M_REQUIRE_NON_NULL(com)
    com->stream = stream; 
    com->mode = mode;
    com->type = t;
    return com;
}


//TODO: PIPE_BUFF non atomicity issue 

void put (const void* data, size_t n, size_t chunk, communication_stream_t* stream) {
    M_REQUIRE_NON_NULL(data)
    M_REQUIRE (chunk <= PIPE_BUF)
    M_REQUIRE_NON_NULL(stream)
    M_REQUIRE_NON_NULL(stream->stream)
    M_REQUIRE_WRITE_MODE(stream->mode)
    M_REQUIRE (n > 0, ERR_BAD_PARAMETER, "input value (%i) is null (= 0)", n);
    switch (stream->type)
    {
    case ANY:
        M_REQUIRE (chunk*n == fwrite(data, chunk, n, stream));
        break;
    
    default:
        break;
    }
    
}

void* get (in_port pipe_input, size_t n, size_t chunk) {
    M_REQUIRE_NON_NULL(data);
    M_REQUIRE_NON_NULL(pipe_output);
    M_REQUIRE (chunk <= PIPE_BUF);
    FILE *stream = NULL;
    stream = fdopen (pipe_output, "w")
    M_REQUIRE_NON_NULL (stream);
    fwrite(data, chunk, n, stream);
    fclose (stream);
}