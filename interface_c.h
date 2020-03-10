#pragma once

#include <stdio.h> // FILE
#include <error.h> // return types

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
typedef void* (*process_t)();

//=========================================================================
/**
 * @brief these two types represent a a communication canal:
 * in_port is where we can read data.
 * out_port is where can write data.
 */
typedef void* in_port;
typedef void* out_port;

//=========================================================================
/**
 * @brief Encapsulation in a tuple for the communication channel.
 */
typedef struct {
    in_port in;
    out_port out;
} communication_channel_t;

//=========================================================================
/**
 * @brief Initialize communication_channel_t structure.
 * @param communication_channel_t** to allocate
 */
void allocate_channel (communication_channel_t**); 

//=========================================================================
/**
 * @brief Put a value in the out_port of a communication channel.
 * @param Element to put in the out_port.
 * @param The out_port of the communication channel
 */
void put (void*, out_port);

//=========================================================================
/**
 * @brief Get a value from the in_port of a communication channel.
 * @param The in_port of the communication_channel_t.
 * @return The value in the in_port of the communication channel.
 */
void* get (in_port);

//=========================================================================
/**
 * @brief Creates a process that executes a list of processess in parrallel.
 * @param A pointer of processes.
 * @param The size of the array.
 */
void doco (process_t*, size_t n);

//=========================================================================
/**
 * @brief Creates a process that evaluates the first process then executes the second one using 
 * the return value of the first one.
 * @param The first process.
 * @param The second process.
 * @return The return value of the second process.
 */
void* bind (process_t, process_t);


//=========================================================================
/**
 * @brief Executes a process and returns its return value.
 * @param The process.
 * @return The return value of the process.
 */
void* run (process_t);

