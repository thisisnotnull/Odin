package slice

import "core:builtin"
import "core:mem"

ptr_add :: proc(p: $P/^$T, x: int) -> ^T {
	return ([^]T)(p)[x:]
}
ptr_sub :: proc(p: $P/^$T, x: int) -> ^T {
	return ([^]T)(p)[-x:]
}

ptr_swap_non_overlapping :: proc(x, y: rawptr, len: int) {
	if len <= 0 {
		return
	}
	if x == y { // Ignore pointers that are the same
		return
	}

	Block :: distinct [4]u64
	BLOCK_SIZE :: size_of(Block)

	i := 0
	t := &Block{}
	for ; i + BLOCK_SIZE <= len; i += BLOCK_SIZE {
		a := rawptr(uintptr(x) + uintptr(i))
		b := rawptr(uintptr(y) + uintptr(i))

		mem.copy(t, a, BLOCK_SIZE)
		mem.copy(a, b, BLOCK_SIZE)
		mem.copy(b, t, BLOCK_SIZE)
	}

	if i < len {
		rem := len - i

		a := rawptr(uintptr(x) + uintptr(i))
		b := rawptr(uintptr(y) + uintptr(i))

		mem.copy(t, a, rem)
		mem.copy(a, b, rem)
		mem.copy(b, t, rem)
	}
}

ptr_swap_overlapping :: proc(x, y: rawptr, len: int) {
	if len <= 0 {
		return
	}
	if x == y {
		return
	}
	
	N :: 512
	buffer: [N]byte = ---
	
	a, b := ([^]byte)(x), ([^]byte)(y)
	
	for n := len; n > 0; n -= N {
		m := builtin.min(n, N)
		mem.copy(&buffer, a, m)
		mem.copy(a, b, m)
		mem.copy(b, &buffer, m)
		
		a, b = a[N:], b[N:]
	}
}


ptr_rotate :: proc(left: int, mid: ^$T, right: int) {
	when size_of(T) != 0 {
		left, mid, right := left, mid, right

		// TODO(bill): Optimization with a buffer for smaller ranges
		if left >= right {
			for {
				ptr_swap_non_overlapping(ptr_sub(mid, right), mid, right)
				mid = ptr_sub(mid, right)

				left -= right
				if left < right {
					break
				}
			}
		} else {
			for {
				ptr_swap_non_overlapping(ptr_sub(mid, left), mid, left)
				mid = ptr_add(mid, left)

				right -= left
				if right < left {
					break
				}
			}
		}
	}
}
