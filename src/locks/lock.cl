// give a type definition for a lock
typedef unsigned int* cl_lock;

// define some values for a lock
#ifndef LOCKS
	#define LOCKS
	#define UNLOCKED_VAL (0xFF)
	#define LOCKED_VAL   (0x00)
#endif

/*
  attempt to lock a vertex - i.e. get exclusive access to the
  we do this by attempting an atomic CAS with a locked or not 
  locked value

  returns: whether or not the lock succeeded (boolean)
*/

unsigned int lock_value(cl_lock lock) {
	// attempt to write a lock value to the lock
	unsigned int old = atomic_cmpxchg(cl_lock, UNLOCKED_VAL, LOCKED_VAL);
	// check old to see if we've locked it - i.e. it was previously unlocked
	return (old == UNLOCKED_VAL);
}

/* 
  unlock a vertex, if we own it - we _must_ do this after locking
  otherwise other threads will not be able to read/write the value

  returns: whether or not it was lock in the first place (boolean)
 */

unsigned int unlock_value(cl_lock lock) {
	// attempt to write a lock value to the lock
	unsigned int old = atomic_cmpxchg(cl_lock, LOCKED_VAL, UNLOCKED_VAL);
	// check old to see if we've unlockd it - i.e. it was previously locked
	return (old == LOCKED_VAL);
}
