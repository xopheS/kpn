#pragma once

#include <stdarg.h>
#include <stdio.h> // FILE
#include <error.h> // return types
#include <pthread.h>

/**
 * @file interface.h
 * @brief recoded the provided ocaml interface in C.
 *
 * @date 2020-03-10
 */

//=========================================================================
/**
 * @brief This is the abstraction we are using to represent a process: 
 * A process is either a function that returns something (void*) or that
 * doesn't have a return type. 
 * Thus we use the following structure to represent the abstraction of a process
 * it's a union of the two previously described pointers and a test_type defining if we have a 
 * return type or not.  
 * first implementation !
 */
// typedef void* (*process_with_return)();
// typedef void (*process_without_return)();

// typedef union {
//     process_with_return pwr;
//     process_without_return pwtr;
// } u_process_t;

// typedef enum {WITH_RETURN, WITHOUT_RETURN} test_type; 

// typedef struct {
//     u_process_t process; 
//     test_type type; 
// } process_t;

/**
 * @brief This is the abstraction we are using to represent a process: 
 * A process is always a function that returns something (void*). 
 * if you want to implement a function that returns no value (void) then we return
 * the NO_RETURN_VALUE.
 * second implementation !
 */
#define NO_RETURN_VALUE NULL
#define MAX_ARGS 15
#define CLOSED_PORT -1
typedef enum {FUNCTION, COMMAND, PROGRAM} process_types; 

typedef struct {
    const char* source;
    char** argv;
    size_t number_of_argv;
} program_t;

typedef union {
    void* (*function)();
    program_t program; 
    char* command;
} process;
typedef struct {
    process proc;
    process_types type;
} process_t;



//=========================================================================
/**
 * @brief these two types represent a a communication canal:
 * in_port is where we can read data.
 * out_port is where can write data.
 */

typedef int port;
typedef int in_port;
typedef int out_port;

typedef struct {
    in_port in;
    out_port out;
} pipe_t;

typedef struct {
    const char * source;
    port p;
} fifo_t;

typedef union {
    fifo_t fifo;
    pipe_t pipe;
} channel_t;
//=========================================================================
/**
 * @brief Encapsulation in a tuple for the communication channel.
 */
typedef struct {
    channel_t channel;
    communication_t type;
} communication_channel_t;



//=========================================================================
/**
 * @brief Specifies the communication type desired between subprocesses.
 * ANY applies to any subprocess although requieres additional work for some cases. 
 * SUBPROCESS makes the pipe the standard I/O in the subprocess.
 * TWO_WAY creates a FIFO file that can only with the streams that can only be 
 * started if there are two process one reading and the other writing.
 */
typedef enum {PIPE, FIFO} communication_t; 



//=========================================================================
/**
 * @brief Initialize communication_channel_t structure.
 * @return communication_channel_t* allocated.
 */
communication_channel_t* allocate_channel (communication_t); 



// // //=========================================================================
// // /**
// //  * @brief opens a communication_stream_t.
// //  * @return communication_stream_t* opened.
// //  */
// // communication_stream_t* open_named_communictaion_stream ()

// //=========================================================================
// /**
//  * @brief closes a communication_stream_t.
//  * @param communication_stream_t* to be closed.
//  */
// void close_named_communication_channel (communication_stream_t**);

//=========================================================================
/**
 * @brief frees a communication_channel_t.
 * @param communication_stream_t* to be freed.
 */
void free_commmunication_channel (communication_channel_t**);

//=========================================================================
/**
 * @brief closes a port of the communication channel.
 * @param port to be closed.
 */
void close_channel_port (communication_channel_t*, int);

//=========================================================================
/**
 * @brief Put a value in the out_port of a communication channel.
 * @param Element to put in the out_port.
 * @param The out_port of the communication channel
 */
void put (const void*,  size_t, communication_channel_t*);

//=========================================================================
/**
 * @brief Get a value from the in_port of a communication channel.
 * @param The in_port of the communication_channel_t.
 * @return The value in the in_port of the communication channel.
 */
void* get (size_t, communication_channel_t*);

//=========================================================================
/**
 * @brief Creates a process that executes a list of processess in parrallel.
 * @param A pointer of processes.
 * @param The size of the array.
 */
void doco (process_t**, size_t n);

//=========================================================================
/**
 * @brief Creates a process that evaluates the first process then executes the second one using 
 * the return value of the first one.
 * @param The first process.
 * @param The second process.
 * @return The return value of the second process.
 */
void* bind (process_t*, process_t*);


//=========================================================================
/**
 * @brief Executes a process and returns its return value.
 * @param The process.
 * @return The return value of the process.
 */
void* run (process_t*);

