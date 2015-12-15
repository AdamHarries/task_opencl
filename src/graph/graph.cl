typedef struct graph {
	unsigned int * data;
	unsigned int * adj_offsets;
	unsigned int * adjacent;
	unsigned int * locks;
} graph;

/*
  attempt to lock a vertex - i.e. get exclusive access to the
  we do this by attempting an atomic CAS with a locked or not 
  locked value


Read the 32-bit value (referred to as old) stored at location pointed by p. 
Compute (old == cmp) ? val : old and store result at location pointed by p. 
The function returns old.

unsigned int atomic_cmpxchg (	volatile __global unsigned int *p ,
 	unsigned int cmp,
 	unsigned int val)

*/
#ifndef LOCKS
	#define LOCKS
	#define UNLOCKED_VAL (0xFF)
	#define LOCKED_VAL   (0x00)
#endif
int lock_vertex(unsigned int vertex, graph g) {
	// attempt to write a lock value to the lock
	unsigned int old = atomic_cmpxchg( &(g.locks[vertex]), UNLOCKED_VAL, LOCKED_VAL);
	// check old to see if we've locked it - i.e. it was previously unlocked
	return (old == UNLOCKED_VAL);
}