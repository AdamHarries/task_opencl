// define some values for a lock
#define UNLOCKED_VAL (0xFF)
#define LOCKED_VAL   (0x00)


/*
  attempt to lock a vertex - i.e. get exclusive access to the
  we do this by attempting an atomic CAS with a locked or not 
  locked value

  returns: whether or not the lock succeeded (boolean)
*/

int glb_lock_value(__global int* lock) {
	// attempt to write a lock value to the lock
	int old = atomic_cmpxchg(lock, UNLOCKED_VAL, LOCKED_VAL);

	// check old to see if we've locked it - i.e. it was previously unlocked
	return (old == UNLOCKED_VAL);
}

/* 
  unlock a vertex, if we own it - we _must_ do this after locking
  otherwise other threads will not be able to read/write the value

  returns: whether or not it was lock in the first place (boolean)
 */

int glb_unlock_value(__global int* lock) {
	// attempt to write a lock value to the lock
	int old = atomic_cmpxchg(lock, LOCKED_VAL, UNLOCKED_VAL);
	// check old to see if we've locked it - i.e. it was previously unlocked
	return (old == LOCKED_VAL);
}


typedef struct cl_queue {
	__global long * mem;
	__global int * lock;
 	__global const unsigned long * len;
 	__global unsigned long * head;
} cl_queue;


int cl_queue_push(cl_queue queue, long value){
	// first, get a lock on the queue, using a dumb spinlock
	int locked = glb_lock_value(queue.lock);
	while( ! locked ){
		locked = glb_lock_value(queue.lock);
	}
	// we've locked the queue, if the head isn't past the end of the array 
	// increment, and write our value
	
	if((*queue.head) >= (*queue.len)){
		// we can't write anything - unlock the queue and fail
		return 1 + glb_unlock_value(queue.lock);
	}else{
		// write the value to the end of the queue
		queue.mem[*queue.head] = value;
		// increment the head
		(*queue.head)++;
		// unlock the queue
		glb_unlock_value(queue.lock);
	}
	return 0;
}

__kernel void queue_test(__global long *QUEUE, 
	__global int * lock, 
	__global const unsigned long * len, 
	__global unsigned long * head) {
	cl_queue glb_queue = {QUEUE, lock, len, head};
	for( int i = get_global_id(0); i<(*len); i+= get_global_size(0) ){
		// QUEUE[i] = i;
		cl_queue_push(glb_queue, (long)(i+1));
	}
}
