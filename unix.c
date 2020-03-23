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
#include<stdatomic.h>
#include <sys/mman.h>

#define ALL_RIGHTS 0777
#define STANDARD_PIPE_SIZE 2
#define INPORT_ID 0
#define OUTPORT_ID 1
#define PATH_SIZE 10
#define generate(arg) \
 __sync_fetch_and_add(&gen, arg)

pthread_mutex_t commmunication_mutex = (pthread_mutex_t) mmap(NULL, sizeof(atomic_int), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
static atomic_int gen = (atomic_int) mmap(NULL, sizeof(atomic_int), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);

static communication_channel_t* allocate_pipe ();
static communication_channel_t* allocate_fifo ();

communication_channel_t* allocate_channel (communication_t type) {
   switch(type) 
   {
       case PIPE:
        return allocate_pipe();
       case FIFO:
        return allocate_fifo(); 
   }
   int test = pthread_mutex_init(&commmunication_mutex, NULL);
   M_REQUIRE(test != 0, ERR_MEM, "mutex cannot be initialized");
}

static communication_channel_t* allocate_pipe () {
    int pipe_ [STANDARD_PIPE_SIZE];
    errno = 0; 
    pipe(pipe_);
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
    communication_channel_t* com = NULL;
    com = malloc(sizeof(communication_channel_t));
    M_REQUIRE_NON_NULL_CUSTOM_ERR(com, ERR_MEM);
    com->channel.pipe.in = pipe_[INPORT_ID]; 
    com->channel.pipe.out = pipe_[OUTPORT_ID];
    com->type = PIPE;
    return com;
}

static communication_channel_t* allocate_fifo () {
    char* path = NULL;
    path = calloc(PATH_SIZE, sizeof(char));
    M_REQUIRE_NON_NULL_CUSTOM_ERR(path, ERR_MEM);
    sprintf(path, "fifo%i", generate(1));
    errno = 0;
    mkfifo(path, ALL_RIGHTS);
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
    communication_channel_t* com = NULL;
    com = malloc(sizeof(communication_channel_t));
    M_REQUIRE_NON_NULL_CUSTOM_ERR(com, ERR_MEM);
    com->channel.fifo.source = path;
    com->channel.fifo.p = CLOSED_PORT; 
    com->type = FIFO;
    return com;
}

void close_channel_port (communication_channel_t* channel, int input) {
    M_REQUIRE_NON_NULL(channel);
    errno = 0;
    switch (channel->type){
        case PIPE:
            if (input) {
                M_REQUIRE_NON_CLOSED(channel->channel.pipe.in);
                int test = close(channel->channel.pipe.in);
                M_REQUIRE(test == 0, ERR_IO, "close failed");
                channel->channel.pipe.in = CLOSED_PORT;
            }
            else {
                M_REQUIRE_NON_CLOSED(channel->channel.pipe.out);
                int test = close(channel->channel.pipe.out);
                M_REQUIRE(test == 0, ERR_IO, "close failed");
                channel->channel.pipe.out = CLOSED_PORT;
            }
            M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
        break;
        case FIFO: 
            M_REQUIRE_NON_CLOSED(channel->channel.fifo.p);
            int test = close(channel->channel.fifo.p);
            M_REQUIRE(test == 0, ERR_IO, "close failed");
            channel->channel.fifo.p = CLOSED_PORT;
        break;
    }
}

void free_commmunication_channel (communication_channel_t** channel) {
    M_REQUIRE_NON_NULL(channel);
    M_REQUIRE_NON_NULL(*channel);
    switch(*channel->type){
        case PIPE:
            if (*channel->channel.pipe.in != CLOSED_PORT){close_channel_port(*channel, 1);}
            if (*channel->channel.pipe.out != CLOSED_PORT){close_channel_port(*channel, 0);}
        break;
        case FIFO:
            if (*channel->channel.fifo.p != CLOSED_PORT){close_channel_port(*channel, 0);}
            free(*channel->channel.fifo.source);
            *channel->channel.fifo = NULL;
        break;
    }
    free(*channel); 
    *channel = NULL;
    pthread_mutex_destroy(communication_mutex);
}

void put (const void* data, size_t chunk, communication_channel_t* channel){
    M_REQUIRE_NON_NULL(data);
    M_REQUIRE (chunk > 0, ERR_BAD_PARAMETER, "chunk must be more than 0");
    M_REQUIRE_NON_NULL(channel);
    pthread_mutex_lock(communication_mutex);
    port fd;
    switch(channel->type){
        case PIPE:
            M_REQUIRE_NON_CLOSED(channel->channel.pipe.out);
            fd = channel->channel.pipe.out;
        break;
        case FIFO:
            M_REQUIRE_NON_NULL(channel->channel.fifo.source);
            channel->channel.fifo.p = open(channel->channel.fifo.source, O_WRONLY);
            fd = channel->channel.fifo.p;
        break;
    }
    errno = 0;
    ssize_t written_bytes = write(channel->channel.pipe.out, data, chunk);
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