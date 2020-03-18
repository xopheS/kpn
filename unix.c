#include "error.h"
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include "interface_c.h"
#include <errno.h> 

#define STANDARD_PIPE_SIZE 2
#define INPORT_ID 0
#define OUTPORT_ID 1



communication_channel_t* allocate_channel () {
    int pipe_ [STANDARD_PIPE_SIZE];
    errno = 0; 
    pipe(pipe_);
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
    communication_channel_t* com = NULL;
    com = malloc(sizeof(communication_channel_t));
    M_REQUIRE_NON_NULL_CUSTOM_ERR(com, ERR_MEM);
    com->in = pipe_[INPORT_ID]; 
    com->out = pipe_[OUTPORT_ID];
    return com;
}

void free_commmunication_channel (communication_channel_t** channel) {
    M_REQUIRE_NON_NULL(channel);
    M_REQUIRE_NON_NULL(*channel);
    free(*channel); 
    *channel = NULL;
}

void close_channel_port (communication_channel_t* channel, int input) {
    M_REQUIRE_NON_NULL(channel);
    errno = 0;
    if (input) {
        int test = close(channel->in);
        M_REQUIRE(test == 0, ERR_IO, "close failed");
        channel->in = CLOSED_PORT;
    }
    else {
        int test = close(channel->out);
        M_REQUIRE(test == 0, ERR_IO, "close failed");
        channel->out = CLOSED_PORT;
    }
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
}

//TODO: PIPE_BUFF non atomicity issue 

void put (const void* data, size_t chunk, communication_channel_t* channel) {
    M_REQUIRE_NON_NULL(data);
    M_REQUIRE (chunk <= PIPE_BUF && chunk > 0, ERR_BAD_PARAMETER, "chunkk must be between 0 and PIPE_BUFF for atomicity");
    M_REQUIRE_NON_NULL(channel);
    M_REQUIRE_NON_CLOSED(channel->out);
    errno = 0;
    ssize_t written_bytes = write(channel->out, data, chunk);
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
    M_REQUIRE(written_bytes == chunk, ERR_IO, "write failed");
}

void* get (size_t chunk, communication_channel_t* channel) {
    M_REQUIRE (chunk <= PIPE_BUF && chunk > 0, ERR_BAD_PARAMETER, "chunkk must be between 0 and PIPE_BUFF for atomicity");
    M_REQUIRE_NON_NULL(channel);
    M_REQUIRE_NON_CLOSED(channel->out);
    errno = 0;
    void* buffer = NULL;
    buffer = buffer = malloc(chunk);
    M_REQUIRE_NON_NULL_CUSTOM_ERR(buffer, ERR_MEM);
    ssize_t read_bytes = read(channel->out, buffer, chunk);
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
    M_REQUIRE(read_bytes == chunk, ERR_IO, "read failed");
    return buffer;
}

void* run (process_t* p) {
    M_REQUIRE_NON_NULL(p);
    switch (p->type)
    {
    case COMMAND:
        system(p->proc.command);    
        break;
    case FUNCTION:
        break;
    case PROGRAM:
        break;
    default:
        break;
    }

}