extern crate opencl;

use opencl::mem::CLBuffer;
use std::fmt;

fn main()
{
	let ker = include_str!("queue.cl");
	let (device, ctx, queue) = opencl::util::create_compute_context().unwrap();
	let program = ctx.create_program_from_source(ker);
	program.build(&device).ok().expect("Couldn't build program.");
	let kernel = program.create_kernel("queue_test");
	
	
	for exp in 1u32..26 {
		let queue_length : usize = 2usize.pow(exp);
	    
	    // println!("ker {}", ker);

	    let mut q_vec : Vec<isize> = Vec::with_capacity(queue_length);
	    for i in 0..queue_length {
	    	q_vec.push(0isize);
	    }
	    let qlock_vec : Vec<i32> = vec![0xFFi32];
	    let qlen_vec : Vec<usize> = vec![queue_length];
	    let qhead_vec : Vec<usize> = vec![0usize];

	    

	    // println!("{}", device.name());

	    let qu: CLBuffer<isize> = ctx.create_buffer(q_vec.len(), opencl::cl::CL_MEM_READ_WRITE);
	    let qlock: CLBuffer<i32> = ctx.create_buffer(qlock_vec.len(), opencl::cl::CL_MEM_READ_WRITE);
	    let qlen: CLBuffer<usize> = ctx.create_buffer(qlen_vec.len(), opencl::cl::CL_MEM_READ_ONLY);
	    let qhead: CLBuffer<usize> = ctx.create_buffer(qhead_vec.len(), opencl::cl::CL_MEM_READ_WRITE);

	    queue.write(&qu, &&q_vec[..], ());
	    queue.write(&qlock, &&qlock_vec[..], ());
	    queue.write(&qlen, &&qlen_vec[..], ());
	    queue.write(&qhead, &&qhead_vec[..], ());


	    

	    kernel.set_arg(0, &qu);
	    kernel.set_arg(1, &qlock);
	    kernel.set_arg(2, &qlen);
	    kernel.set_arg(3, &qhead);

	    let event = queue.enqueue_async_kernel(&kernel, 32usize, None, ());

	    let mut res_vec: Vec<isize> = queue.get(&qu, &event);

	    let elapsed_time = event.end_time() - event.start_time();
	    println!("Queue length {} : Kernel took {} ms",queue_length,  elapsed_time/1000);
	    // println!("{}", string_from_slice(&res_vec[..]));
	    res_vec.sort();
	    for i in 1..res_vec.len()+1 {
	    	assert!(i as isize == res_vec[i-1]);
	    }
	}
}

fn string_from_slice<T: fmt::Display>(slice: &[T]) -> String {
    let mut st = String::from("[");
    let mut first = true;

    for i in slice.iter() {
        if !first {
            st.push_str(", ");
        }
        else {
            first = false;
        }
        st.push_str(&*i.to_string())
    }

    st.push_str("]");
    return st
}
