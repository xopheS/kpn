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
#include <string.h>

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
    M_REQUIRE (chunk > 0, ERR_BAD_PARAMETER, "chunkk must be > 0");
    M_REQUIRE_NON_NULL(channel);
    port fd;
    switch(channel->type){
        case PIPE:
            M_REQUIRE_NON_CLOSED(channel->channel.pipe.out);
            fd = channel->channel.pipe.out;
        break;
        case FIFO:
            M_REQUIRE_NON_NULL(channel->channel.fifo.source);
            if(channel->channel.fifo.p == CLOSED_PORT){
                channel->channel.fifo.p = open(channel->channel.fifo.source, O_RDONLY);
            }
            fd = channel->channel.fifo.p;
        break;
    }
    errno = 0;
    void* buffer = NULL;
    buffer = buffer = malloc(chunk);
    M_REQUIRE_NON_NULL_CUSTOM_ERR(buffer, ERR_MEM);
    ssize_t read_bytes = read(fd, buffer, chunk);
    M_REQUIRE_NO_ERRNO(ERR_PIPELINE_FIFO);
    M_REQUIRE(read_bytes == chunk, ERR_IO, "read failed");
    return buffer;
}

static void* run_non_waiting (process_t* p) {
    M_REQUIRE_NON_NULL(p);
    switch (p->type)
    {
    case COMMAND:
        M_REQUIRE_NON_NULL(p->proc.command);
        system(p->proc.command);   
        return NO_RETURN_VALUE;
    case FUNCTION:
        M_REQUIRE_NON_NULL(p->proc.function);
        return *p->proc.function();
    case PROGRAM:
        M_REQUIRE_NON_NULL(p->proc.program.source);
        errno = 0; 
        execv(p->proc.program.source, p->proc.program.argv);
        M_REQUIRE_NO_ERRNO(ERR_PROCESS);
        return NO_RETURN_VALUE;
    }

}

void* run (process_t *p) {return NULL;}


void doco (process_t** list, size_t n){
    M_REQUIRE_NON_NULL(list);
    for (size_t i = 0; i < n; i++) {
        errno = 0;
        pid_t pid = fork();
        M_REQUIRE_NO_ERRNO(ERR_PROCESS);
        if(!pid){
            run(p[i]);
            exit(0);
        }
    }
    while (wait(NULL) > 0); 
}

void* bind (process_t* f, process_t* s) {
    M_REQUIRE_NON_NULL(f);
    M_REQUIRE_NON_NULL(s);
    M_REQUIRE(f->type == FUNCTION);
    void* return_value = run(f);
    switch(s->type){
        case FUNCTION:
            M_REQUIRE_NON_NULL(s->proc.function);
            return *s->proc.function(return_value); 
        case PROGRAM:
            M_REQUIRE_NON_NULL(s->proc.program.source);
            M_REQUIRE_NON_NULL(s->proc.program.argv);
            M_REQUIRE (s->proc.program.number_of_argv < MAX_ARGS, ERR_BAD_PARAMETER, "too many arguments");
            s->proc.program.argv[s->proc.program.number_of_argv++] = (char*) return_value;
            errno = 0; 
            execv(p->proc.program.source, p->proc.program.argv);
            M_REQUIRE_NO_ERRNO(ERR_PROCESS);
            return NO_RETURN_VALUE;
        case COMMAND:
            M_REQUIRE_NON_NULL(s->proc.command);
            strcat(s->proc.command, (char*) return_value);
            system(p->proc.command);   
            return NO_RETURN_VALUE;
    }   
}