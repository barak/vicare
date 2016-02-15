/*
 * Ikarus Scheme -- A compiler for R6RS Scheme.
 * Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
 * Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
 *
 * This program is free software:  you can redistribute it and/or modify
 * it under  the terms of  the GNU General  Public License version  3 as
 * published by the Free Software Foundation.
 *
 * This program is  distributed in the hope that it  will be useful, but
 * WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
 * MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
 * General Public License for more details.
 *
 * You should  have received  a copy of  the GNU General  Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/* The garbage collector has a mechanism similar (but not exactly equal)
 * to the one described in the paper:
 *
 *    R. Kent Dybvig, David Eby, Carl Bruggeman.  "Don't Stop the BIBOP:
 *    Flexible and  Efficient Storage  Management for  Dynamically Typed
 *    Languages".   Indiana  University   Computer  Science  Department.
 *    Technical Report #400.  March 1994.
 *
 */


/** --------------------------------------------------------------------
 ** Headers.
 ** ----------------------------------------------------------------- */

#include "internals.h"
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/time.h>


/** --------------------------------------------------------------------
 ** Constants.
 ** ----------------------------------------------------------------- */

#define meta_ptrs	0
#define meta_code	1
#define meta_data	2
#define meta_weak	3
#define meta_pair	4
#define meta_symbol	5
#define meta_count	6


/** --------------------------------------------------------------------
 ** Type definitions.
 ** ----------------------------------------------------------------- */

/* This data structure is a node  in a simply linked list; it references
   one or more generational pages in which live objects are moved during
   a garbage collection run; such pages are also referenced by the PCB's
   segments  vector.  When  generational  pages are  registered in  this
   struct: they  are considered filled  with Scheme objects.   The pages
   are scanned by the  function "collect_loop()".  See the documentation
   of the  functions "gc_alloc_new_*" for  further details on  this data
   structure.  */
typedef struct qupages_t {
  ikptr p;    /* pointer to the scan start */
  ikptr q;    /* pointer to the scan end */
  struct qupages_t* next;
} qupages_t;

/* This struct references a generational  page in which live objects are
   moved during a  garbage collection run; such page  is also referenced
   by  the PCB's  segments vector.   The page  is gradually  filled, one
   object  after  the other,  until  no  more  room is  available;  then
   references to the  page are moved in a "qupages_t"  struct.  The page
   is scanned  by the function "collect_loop()".   See the documentation
   of the  functions "gc_alloc_new_*" for  further details on  this data
   structure.

   FIXME Is the "base" field actually needed?  It seems to me that it is
   always equal to "aq".  (Marco Maggi; Mon Dec 16, 2013) */
typedef struct {
  ikptr ap;	/* allocation pointer, references the next free word */
  ikptr aq;	/* pointer to the first allocated word */
  ikptr ep;	/* end pointer, references a word past the end */
  ikptr base;	/* pointer to the first allocated word */
} meta_t;

/* This structure represents the state of the garbage collector. */
typedef struct gc_t {
  meta_t	meta[meta_count];
  qupages_t *	queues[meta_count];

  ikpcb *	pcb;

  /* FIXME This field is always kept equal to the corresponding field in
     the PCB;  IMHO it should be  safe to remove it.   (Marco Maggi; Mon
     Dec 16, 2013) */
  uint32_t *	segment_vector;

  int		collect_gen;
  uint32_t	collect_gen_tag;

  /* These fields are for the hash tables. */
  ikptr		tconc_ap;
  ikptr		tconc_ep;
  ikptr		tconc_base;
  ikmemblock *	tconc_queue;
  ik_ptr_page *	forward_list;
} gc_t;


/** --------------------------------------------------------------------
 ** Function prototypes.
 ** ----------------------------------------------------------------- */

static ikptr	gather_live_code_entry	(gc_t* gc, ikptr entry);

static void	scan_dirty_pages	(gc_t*);
static void	handle_guardians	(gc_t* gc);

static void	collect_stack(gc_t*, ikptr top, ikptr base);
static void	collect_loop(gc_t*);

static void	ik_munmap_from_segment (ikptr base, ik_ulong size, ikpcb* pcb);

static void	relocate_new_code (ikptr p_X, gc_t* gc);

static void	register_to_collect_count (ikpcb* pcb, int bytes);


/** --------------------------------------------------------------------
 ** Global variables.
 ** ----------------------------------------------------------------- */

/* If accounting  is defined  as true:  "gather_live_object_proc()" will
   increment the  appropriate counter whenever  it moves a  live object;
   later  "ik_collect()" will  print a  report to  stderr and  reset the
   counters. */
#define ACCOUNTING 0
#if ACCOUNTING
static int pair_count		= 0;
static int symbol_count		= 0;
static int closure_count	= 0;
static int vector_count		= 0;
static int record_count		= 0;
static int continuation_count	= 0;
static int string_count		= 0;
static int htable_count		= 0;
#endif

static const unsigned int META_MT[meta_count] = {
  POINTERS_MT,
  CODE_MT,
  DATA_MT,
  WEAK_PAIRS_MT,
  POINTERS_MT,
  SYMBOLS_MT
};

/* ------------------------------------------------------------------ */

static int verify_gc_integrity_option = 0;

ikptr
ikrt_enable_gc_integrity_checks (ikpcb * pcb) {
  verify_gc_integrity_option = 1;
  return IK_VOID;
}
ikptr
ikrt_disable_gc_integrity_checks (ikpcb * pcb) {
  verify_gc_integrity_option = 0;
  return IK_VOID;
}


/** --------------------------------------------------------------------
 ** Helpers.
 ** ----------------------------------------------------------------- */

static void
ik_munmap_from_segment (ikptr base, ik_ulong size, ikpcb* pcb)
/* Given a block of memory starting at BASE and SIZE bytes wide:
 *
 * - Mark all its pages as "holes" in the segment vector.
 *
 * - Mark all its pages as pure in the dirty vector.
 *
 * - Either register it  in the uncached pages or unmap  it.  The memory
 *   in the cached pages  is NOT reset in any way:  its contents is what
 *   it is.
 */
{
  assert(base >= pcb->memory_base);
  assert((base+size) <= pcb->memory_end);
  assert(size == IK_ALIGN_TO_NEXT_PAGE(size));
  /* Mark all the  pages as holes in  the segment vector and  as pure in
     the dirty vector. */
  {
    uint32_t *	segme = ((uint32_t *)(pcb->segment_vector)) + IK_PAGE_INDEX(base);
    uint32_t *	dirty = ((uint32_t *)(pcb->dirty_vector))   + IK_PAGE_INDEX(base);
    uint32_t *	past  = segme + IK_PAGE_INDEX_RANGE(size);
    for (; segme < past; ++segme, ++dirty) {
      assert(*segme != HOLE_MT);
      *segme = HOLE_MT;
      *dirty = IK_PURE_WORD;
    }
  }
  /* If  possible: store  the pages  referenced  by BASE  in PCB's  page
     cache.  If the page cache is already full or we fill it: just unmap
     the  leftover pages.   Remember that  the page  cache has  constant
     size: it is never enlarged. */
  {
    ikpage *	free_cache_nodes = pcb->uncached_pages;
    if (free_cache_nodes) {
      ikpage *	used_cache_nodes = pcb->cached_pages;
      ikpage *	next_free_node;
      do {
	/* Split  the BASE  and SIZE  block  into cached  pages.  Pop  a
	   struct from "free_cached_nodes", store  a pointer to the page
	   in the struct, push the struct in "used_cache_nodes". */
	free_cache_nodes->base	= base;
	next_free_node		= free_cache_nodes->next;
	free_cache_nodes->next	= used_cache_nodes;
	used_cache_nodes	= free_cache_nodes;
	free_cache_nodes	= next_free_node;
	base			+= IK_PAGESIZE;
	size			-= IK_PAGESIZE;
      } while (free_cache_nodes && size);
      pcb->cached_pages   = used_cache_nodes;
      pcb->uncached_pages = free_cache_nodes;
    }
    /* Unmap the leftovers. */
    if (size)
      ik_munmap(base, size);
  }
}


/** --------------------------------------------------------------------
 ** Main collect function.
 ** ----------------------------------------------------------------- */

/* Prototypes for subroutines of "ik_collect()". */
static int		collection_id_to_gen	(int id);
static void		fix_weak_pointers	(gc_t *gc);
static inline void	collect_locatives	(gc_t*, ik_callback_locative*);
static void		deallocate_unused_pages	(gc_t*);
static void		fix_new_pages		(gc_t* gc);
static void		gc_finalize_guardians	(gc_t* gc);
static void		gc_add_tconcs		(gc_t*);

/* The function "gather_live_object_proc()" is the one that moves a live
   Scheme object from its pre-GC location to its after-GC location.  The
   macro "gather_live_object()" is a convenience interface to it. */
#undef DEBUG_GATHER_LIVE_OBJECT
#if (((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC)) || (defined DEBUG_GATHER_LIVE_OBJECT))
static ikptr gather_live_object_proc(gc_t* gc, ikptr x, char* caller);
#  define gather_live_object(gc,x,caller) gather_live_object_proc(gc,x,caller)
#else
static ikptr gather_live_object_proc(gc_t* gc, ikptr x);
#  define gather_live_object(gc,x,caller) gather_live_object_proc(gc,x)
#endif

/* This is the entry point of garbage collection.  The roots are:
 *
 * 0. dirty pages not collected in this run
 * 1. the stack
 * 2. the next continuation
 * 3. the symbol-table
 * 4. the "root" fields of the PCB
 *
 *   Notice that the heap is NOT a  GC root; so if we leave some machine
 * word  uninitialised on  the heap:  nothing bad  happens, because  the
 * garbage collector never sees them.
 *
 * "ik_collect()" is called from scheme under the following constraints:
 *
 * 1..An attempt is  made to allocate a small object  and the allocation
 *    pointer is above the red line.
 *
 * 2..The  current frame  of  the call  is dead,  so,  upon return  from
 *    "ik_collect()", the caller returns to its caller.
 *
 * 3..The  frame-pointer  of  the  caller   to  S_collect  is  saved  at
 *    pcb->frame_pointer.  No  variables are  live at that  frame except
 *    for the return point (at *(pcb->frame_pointer)).
 *
 * 4.."ik_collect()"   must  return   a  new   allocation  pointer   (in
 *    "pcb->allocation_pointer") followed  by at  least 2 pages  of free
 *    memory.
 *
 * 5.."ik_collect()" must update "pcb->allocaton_redline"  to be 2 pages
 *    below the real end of heap.
 *
 * 6. "ik_collect()" must not move the stack.
 */
ikpcb *
ik_collect (ik_ulong mem_req, ikpcb* pcb)
{
  static const uint32_t NEXT_GEN_TAG[IK_GC_GENERATION_COUNT] = {
    (4 << META_DIRTY_SHIFT) | 1 | NEW_GEN_TAG,
    (2 << META_DIRTY_SHIFT) | 2 | NEW_GEN_TAG,
    (1 << META_DIRTY_SHIFT) | 3 | NEW_GEN_TAG,
    (0 << META_DIRTY_SHIFT) | 4 | NEW_GEN_TAG,
    (0 << META_DIRTY_SHIFT) | 4 | NEW_GEN_TAG
  };
  struct rusage		t0, t1;		/* for GC statistics */
  struct timeval	rt0, rt1;	/* for GC statistics */
  gc_t			gc;
  ikmemblock *		old_heap_pages;

  /* fprintf(stderr, "%s: enter\n", __func__); */
#if (0 || (defined VICARE_GC_INTEGRITY) || (defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
  verify_gc_integrity_option = 1;
#endif
  if (verify_gc_integrity_option) {
    ik_verify_integrity(pcb, "entry");
  }
  { /* accounting */
    long bytes = ((long)pcb->allocation_pointer) - ((long)pcb->heap_base);
    register_to_collect_count(pcb, bytes);
  }

  { /* initialise GC statistics */
    gettimeofday(&rt0, 0);
    getrusage(RUSAGE_SELF, &t0);
  }

  pcb->collect_key	= IK_FALSE_OBJECT;
  bzero(&gc, sizeof(gc_t));
  gc.pcb		= pcb;
  gc.segment_vector	= pcb->segment_vector;
  gc.collect_gen	= collection_id_to_gen(pcb->collection_id);
  gc.collect_gen_tag	= NEXT_GEN_TAG[gc.collect_gen];
  pcb->collection_id++;
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
  ik_debug_message("ik_collect entry %ld free=%ld (collect gen=%d/id=%d)",
		   mem_req, pcb->allocation_redline - pcb->allocation_pointer,
		   gc.collect_gen, pcb->collection_id-1);
#endif

  /* Save  the linked  list  referencing memory  blocks  that once  were
     nursery hot  memory, and are now  fully used; they will  be deleted
     later. */
  old_heap_pages  = pcb->heap_pages;
  pcb->heap_pages = NULL;

  /* Scan GC roots. */
  {
    scan_dirty_pages(&gc);
    collect_stack(&gc, pcb->frame_pointer, pcb->frame_base - wordsize);
    collect_locatives(&gc, pcb->callbacks);

    { /* Scan the collection  of words not to be  collected because they
	 are referenced somewhere outside the Scheme heap and stack. */
      ik_gc_avoidance_collection_t *	C;
      for (C = pcb->not_to_be_collected; C; C = C->next) {
	int	i;
	for (i=0; i<IK_GC_AVOIDANCE_ARRAY_LEN; ++i) {
	  if (C->slots[i])
	    C->slots[i] = gather_live_object(&gc, C->slots[i], "not_to_be_collected");
	}
      }
    }

    pcb->next_k		= gather_live_object(&gc, pcb->next_k,		"next_k");
    pcb->symbol_table	= gather_live_object(&gc, pcb->symbol_table,	"symbol_table");
    pcb->gensym_table	= gather_live_object(&gc, pcb->gensym_table,	"gensym_table");
    pcb->arg_list	= gather_live_object(&gc, pcb->arg_list,	"args_list_foo");
    pcb->base_rtd	= gather_live_object(&gc, pcb->base_rtd,	"base_rtd");

    if (pcb->root0) *(pcb->root0) = gather_live_object(&gc, *(pcb->root0), "root0");
    if (pcb->root1) *(pcb->root1) = gather_live_object(&gc, *(pcb->root1), "root1");
    if (pcb->root2) *(pcb->root2) = gather_live_object(&gc, *(pcb->root2), "root2");
    if (pcb->root3) *(pcb->root3) = gather_live_object(&gc, *(pcb->root3), "root3");
    if (pcb->root4) *(pcb->root4) = gather_live_object(&gc, *(pcb->root4), "root4");
    if (pcb->root5) *(pcb->root5) = gather_live_object(&gc, *(pcb->root5), "root5");
    if (pcb->root6) *(pcb->root6) = gather_live_object(&gc, *(pcb->root6), "root6");
    if (pcb->root7) *(pcb->root7) = gather_live_object(&gc, *(pcb->root7), "root7");
    if (pcb->root8) *(pcb->root8) = gather_live_object(&gc, *(pcb->root8), "root8");
    if (pcb->root9) *(pcb->root9) = gather_live_object(&gc, *(pcb->root9), "root9");
  }

  /* Trace all live objects. */
  collect_loop(&gc);

  /* Next  all  guardian/guarded   objects.   "handle_guadians()"  calls
     "collect_loop()" in its body. */
  handle_guardians(&gc);

#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
  ik_debug_message("finished scan of GC roots");
#endif

  collect_loop(&gc);

  /* Does  not  allocate,  only  sets  to  BWP  the  locations  of  dead
     pointers. */
  fix_weak_pointers(&gc);

  /* Now deallocate all unused pages. */
  deallocate_unused_pages(&gc);

  fix_new_pages(&gc);
  gc_finalize_guardians(&gc);

  pcb->allocation_pointer = pcb->heap_base;
  /* does not allocate */
  gc_add_tconcs(&gc);
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
  ik_debug_message("done");
#endif
  pcb->weak_pairs_ap = 0;
  pcb->weak_pairs_ep = 0;

#if ACCOUNTING
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
  ik_debug_message("[%d cons|%d sym|%d cls|%d vec|%d rec|%d cck|%d str|%d htb]\n",
		   pair_count,		symbol_count,	closure_count,
		   vector_count,	record_count,	continuation_count,
		   string_count,	htable_count);
#endif
  pair_count		= 0;
  symbol_count		= 0;
  closure_count		= 0;
  vector_count		= 0;
  record_count		= 0;
  continuation_count	= 0;
  string_count		= 0;
  htable_count		= 0;
#endif /* end of #if ACCOUNTING */

  /* ik_dump_metatable(pcb); */

#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
  ik_debug_message("finished garbage collection");
#endif

  /* Delete the  linked list  referencing memory  blocks that  once were
     nursery  hot memory,  and are  now fully  used; the  blocks' memory
     pages are cached in the PCB to be recycled later. */
  if (old_heap_pages) {
    ikmemblock* p = old_heap_pages;
    do {
      ikmemblock* next = p->next;
      ik_munmap_from_segment(p->base, p->size, pcb);
      ik_free(p, sizeof(ikmemblock));
      p=next;
    } while(p);
    old_heap_pages = NULL;
  }

  /* Release the  old nursery  heap hot  block and  allocate a  new one.
     Notice that the allocated memory is NOT initialised to safe values:
     its contents have to be  considered invalid and initialised to safe
     values before being scanned by the garbage collector. */
  {
    ik_ulong free_space = ((ik_ulong)pcb->allocation_redline) - ((ik_ulong)pcb->allocation_pointer);
    if ((free_space <= mem_req) || (pcb->heap_size < IK_HEAPSIZE)) {
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
      fprintf(stderr, "REQ=%ld, got %ld\n", mem_req, free_space);
#endif
      long	memsize;
      long	new_heap_size;
      ikptr	ap;
      memsize       = (mem_req > IK_HEAPSIZE)? mem_req : IK_HEAPSIZE;
      memsize	    = IK_ALIGN_TO_NEXT_PAGE(memsize);
      new_heap_size = memsize + 2 * IK_PAGESIZE;
      /* Release the old nursery heap hot block. */
      ik_munmap_from_segment(pcb->heap_base, pcb->heap_size, pcb);
      ap = ik_mmap_mainheap(new_heap_size, pcb);
      pcb->allocation_pointer = ap;
      pcb->allocation_redline = ap + memsize;
      pcb->heap_base = ap;
      pcb->heap_size = new_heap_size;
    }
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
    { /* Reset the free space to a magic number. */
      ikptr	X;
      for (X=pcb->allocation_pointer; X<pcb->allocation_redline; X+=wordsize)
	IK_REF(X, 0) = (ikptr)(0x1234FFFF);
    }
#endif
  } /* Finished allocating a new nursery heap hot block. */

#if (0 || (defined VICARE_GC_INTEGRITY) || (defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
  verify_gc_integrity_option = 1;
#endif
  if (verify_gc_integrity_option) {
    ik_verify_integrity(pcb, "exit");
  }
  { /* for GC statistics */
    getrusage(RUSAGE_SELF, &t1);
    gettimeofday(&rt1, 0);
    pcb->collect_utime.tv_usec += t1.ru_utime.tv_usec - t0.ru_utime.tv_usec;
    pcb->collect_utime.tv_sec  += t1.ru_utime.tv_sec - t0.ru_utime.tv_sec;
    if (pcb->collect_utime.tv_usec >= 1000000) {
      pcb->collect_utime.tv_usec -= 1000000;
      pcb->collect_utime.tv_sec  += 1;
    } else if (pcb->collect_utime.tv_usec < 0) {
      pcb->collect_utime.tv_usec += 1000000;
      pcb->collect_utime.tv_sec  -= 1;
    }
    pcb->collect_stime.tv_usec += t1.ru_stime.tv_usec - t0.ru_stime.tv_usec;
    pcb->collect_stime.tv_sec += t1.ru_stime.tv_sec - t0.ru_stime.tv_sec;
    if (pcb->collect_stime.tv_usec >= 1000000) {
      pcb->collect_stime.tv_usec -= 1000000;
      pcb->collect_stime.tv_sec  += 1;
    } else if (pcb->collect_stime.tv_usec < 0) {
      pcb->collect_stime.tv_usec += 1000000;
      pcb->collect_stime.tv_sec  -= 1;
    }
    pcb->collect_rtime.tv_usec += rt1.tv_usec - rt0.tv_usec;
    pcb->collect_rtime.tv_sec += rt1.tv_sec - rt0.tv_sec;
    if (pcb->collect_rtime.tv_usec >= 1000000) {
      pcb->collect_rtime.tv_usec   -= 1000000;
      pcb->collect_rtime.tv_sec    += 1;
    } else if (pcb->collect_rtime.tv_usec < 0) {
      pcb->collect_rtime.tv_usec += 1000000;
      pcb->collect_rtime.tv_sec  -= 1;
    }
  }
  /* fprintf(stderr, "%s: leave\n", __func__); */
  return pcb;
}
static int
collection_id_to_gen (int id)
/* Subroutine  of "ik_collect()".   Convert  a collection  counter to  a
   generation number determining which objects generation to inspect. */
{
  if ((id & 255) == 255) { return 4; }	/* 255 == #b11111111 */
  if ((id &  63) == 63)  { return 3; }	/*  63 == #b00111111 */
  if ((id &  15) == 15)  { return 2; }	/*  15 == #b00001111 */
  if ((id &   3) == 3)   { return 1; }	/*   3 == #b00000011 */
  return 0;
}
static inline void
collect_locatives (gc_t* gc, ik_callback_locative* loc)
/* Subroutine of "ik_collect()". */
{
  for (; loc; loc = loc->next) {
    loc->data = gather_live_object(gc, loc->data, "locative");
  }
}
static void
fix_weak_pointers (gc_t* gc)
/* Subroutine of "ik_collect()".  Fix the cars of the weak pairs. */
{
  uint32_t *	segment_vec = gc->segment_vector;
  long		lo_idx      = IK_PAGE_INDEX(gc->pcb->memory_base);
  long		hi_idx      = IK_PAGE_INDEX(gc->pcb->memory_end);
  long		page_idx    = lo_idx;
  int		collect_gen = gc->collect_gen;
  /* Iterate over the pages referenced by the segments vector. */
  for (; page_idx < hi_idx; ++page_idx) {
    uint32_t	page_sbits = segment_vec[page_idx];
    /* Visit this page if it is marked as containing weak pairs. */
    if ((page_sbits & (TYPE_MASK|NEW_GEN_MASK)) == (WEAK_PAIRS_TYPE|NEW_GEN_TAG)) {
      //int gen = t & GEN_MASK;
      if (1) { //(gen > collect_gen) {
        ikptr	p = IK_PAGE_POINTER_FROM_INDEX(page_idx);
        ikptr	q = p + IK_PAGESIZE;
        for (; p < q; p += pair_size) {
          ikptr X = IK_REF(p, 0);
          if (! IK_IS_FIXNUM(X)) {
            int tag = IK_TAGOF(X);
            if (tag != immediate_tag) {
              ikptr first_word = IK_REF(X, -tag);
              if (first_word == IK_FORWARD_PTR) {
		/* The car of this pair is still alive: retrieve its new
		   tagged pointer and store it in the car slot. */
                IK_REF(p, disp_car) = IK_REF(X, wordsize-tag);
              } else {
                int X_gen = segment_vec[IK_PAGE_INDEX(X)] & GEN_MASK;
                if (X_gen <= collect_gen) {
		  /* The car of  this pair is dead: set the  car slot to
		     the BWP object. */
                  IK_REF(p, disp_car) = IK_BWP_OBJECT;
                }
              }
            }
          }
        }
      }
    }
  }
}
static void
deallocate_unused_pages (gc_t* gc)
/* Subroutine of "ik_collect()". */
{
  ikpcb *	pcb         = gc->pcb;
  int		collect_gen = gc->collect_gen;
  uint32_t *	segment_vec = pcb->segment_vector;
  ikptr		lo_idx      = IK_PAGE_INDEX(pcb->memory_base);
  ikptr		hi_idx      = IK_PAGE_INDEX(pcb->memory_end);
  ikptr		page_idx    = lo_idx;
  for (; page_idx<hi_idx; ++page_idx) {
    uint32_t	page_sbits = segment_vec[page_idx];
    if (page_sbits & DEALLOC_MASK) {
      int gen = page_sbits & OLD_GEN_MASK;
      if (gen <= collect_gen) {
        /* we're interested */
        if (page_sbits & NEW_GEN_MASK) {
          /* do nothing yet */
        } else {
          ik_munmap_from_segment(IK_PAGE_POINTER_FROM_INDEX(page_idx), IK_PAGESIZE, pcb);
        }
      }
    }
  }
}
static void
fix_new_pages (gc_t* gc)
/* Subroutine of "ik_collect()". */
{
  ikpcb *	pcb         = gc->pcb;
  uint32_t *	segment_vec = pcb->segment_vector;
  ikptr		lo_idx      = IK_PAGE_INDEX(pcb->memory_base);
  ikptr		hi_idx      = IK_PAGE_INDEX(pcb->memory_end);
  ikptr		page_idx;
  for (page_idx=lo_idx; page_idx<hi_idx; ++page_idx) {
    segment_vec[page_idx] &= ~NEW_GEN_MASK;
    /*
      uint32_t t = segment_vec[i];
      if (t & NEW_GEN_MASK) {
      segment_vec[i] = t & ~NEW_GEN_MASK;
      }
    */
  }
}
static void
gc_finalize_guardians (gc_t* gc)
{
  ik_ptr_page*	ls = gc->forward_list;
  int		tconc_count = 0;
  uint32_t *	dirty_vec = (uint32_t *)(long)(gc->pcb->dirty_vector);
  while(ls) {
    int i;
    for(i=0; i<ls->count; i++) {
      tconc_count++;
      ikptr p = ls->ptr[i];
      ikptr tc = IK_REF(p, off_car);
      ikptr obj = IK_REF(p, off_cdr);
      ikptr last_pair = IK_REF(tc, off_cdr);
      IK_REF(last_pair, off_car) = obj;
      IK_REF(last_pair, off_cdr) = p;
      IK_REF(p, off_car) = IK_FALSE_OBJECT;
      IK_REF(p, off_cdr) = IK_FALSE_OBJECT;
      IK_REF(tc, off_cdr) = p;
      dirty_vec[IK_PAGE_INDEX(tc)]        = IK_DIRTY_WORD;
      dirty_vec[IK_PAGE_INDEX(last_pair)] = IK_DIRTY_WORD;
    }
    ik_ptr_page* next = ls->next;
    ik_munmap((ikptr)ls, IK_PAGESIZE);
    ls = next;
  }
}


/** --------------------------------------------------------------------
 ** Auxiliary collection function.
 ** ----------------------------------------------------------------- */

ikptr
ik_collect_check (unsigned long req, ikpcb* pcb)
/* Check if there  are REQ bytes already allocated and  available on the
   heap; return #t if there are, run a GC and return #f otherwise. */
{
  long bytes = ((long)pcb->allocation_redline) - ((long)pcb->allocation_pointer);
  if (bytes >= req) {
    return IK_TRUE_OBJECT;
  } else {
    ik_collect(req, pcb);
    return IK_FALSE_OBJECT;
  }
}


/** --------------------------------------------------------------------
 ** Collection subroutines: Scheme stack.
 ** ----------------------------------------------------------------- */

#define DEBUG_STACK 0

static void
collect_stack (gc_t* gc, ikptr top, ikptr end)
/* This function is used to scan for live objects both the current stack
 * segment and  the array of  freezed stack frames referenced  by Scheme
 * continuation objects.
 *
 * Let's remember  how the current Scheme  stack looks when it  has some
 * frames in it:
 *
 *    high memory addresses
 *  |                      |
 *  |----------------------|
 *  |                      | <- pcb->frame_base
 *  |----------------------|
 *  | ik_underflow_handler | <- end
 *  |----------------------|
 *    ... other frames ...
 *  |----------------------|         --
 *  |     local value      |         .
 *  |----------------------|         .
 *  |     local value      |         . upper frame
 *  |----------------------|         .
 *  |    return address    |         .
 *  |----------------------|         --
 *  |     local value      |         .
 *  |----------------------|         .
 *  |     local value      |         . topmost frame
 *  |----------------------|         .
 *  |    return address    | <- top  .
 *  |----------------------|         --
 *     ... free words ...
 *  |----------------------|
 *  |                      | <- pcb->stack_base
 *  |----------------------|
 *  |                      |
 *    low memory addresses
 *
 * now let's  remember how  the current  Scheme stack  looks when  it is
 * empty (no frames):
 *
 *    high memory addresses
 *  |                      |
 *  |----------------------|
 *  |                      | <- pcb->frame_base
 *  |----------------------|
 *  | ik_underflow_handler | <- top = end
 *  |----------------------|
 *     ... free words ...
 *  |----------------------|
 *  |                      | <- pcb->stack_base
 *  |----------------------|
 *  |                      |
 *    low memory addresses
 *
 * now let's  remember how the  freezed frames in a  continuation object
 * look:
 *
 *    high memory addresses
 *  |                      |
 *  |----------------------|
 *  |                      | <- end
 *  |----------------------|
 *    ... other frames ...
 *  |----------------------|         --
 *  |     local value      |         .
 *  |----------------------|         .
 *  |     local value      |         . upper freezed frame
 *  |----------------------|         .
 *  |    return address    |         .
 *  |----------------------|         --
 *  |     local value      |         .
 *  |----------------------|         .
 *  |     local value      |         . topmost freezed frame
 *  |----------------------|         .
 *  |    return address    | <- top  .
 *  |----------------------|         --
 *  |                      |
 *    low memory addresses
 *
 * a continuation  object is  never empty:  it always  has at  least one
 * freezed frame.
 *
 * The argument END  is a raw memory pointer referencing  a machine word
 * past the lowest frame on the region to scan.
 *
 * When the region to scan is the current Scheme stack: the argument TOP
 * is "pcb->frame_pointer",  a raw memory  pointer.  When the  region to
 * scan  the array  of  freezed  frames in  a  continuation object:  the
 * argument TOP is the value of the field TOP in the continuation object
 * data structure.
 *
 * TOP is used as iterator to climb  the stack, frame by frame, from low
 * memory addresses to high memory addresses until END is reached.
 *
 *            frame   frame   frame   frame   frame
 *   lo mem |-+-----|-+-----|-+-----|-+-----|-+-----|-| hi mem
 *           ^       ^       ^       ^       ^       ^
 *          top     top1    top2    top3     |       |
 *                                         top4     end
 */
{
  if (0 || DEBUG_STACK) {
    ik_debug_message_start("%s: enter (size=%ld) from 0x%016lx to 0x%016lx",
			   __func__, (long)end - (long)top, (long) top, (long) end);
  }
  while (top < end) {
    /* A Scheme stack frame looks like this:
     *
     *          high memory
     *   |----------------------|         --
     *   |      local value     |         .
     *   |----------------------|         .
     *   |      local value     |         . framesize = 3 machine words
     *   |----------------------|         .
     *   |    single_value_rp   | <- top  .
     *   |----------------------|         --
     *   |                      |
     *         low memory
     *
     * and the return address SINGLE_VALUE_RP  is an assembly label (for
     * single  return values)  right after  the "call"  instruction that
     * created this stack frame:
     *
     *     ;; low memory
     *
     *     subl framesize, FPR		;adjust FPR
     *     jmp L0
     *     livemask-bytes		;array of bytes
     *     framesize			;data word, a "long"
     *     offset_field			;data word, a fixnum
     *     multi_value_rp		;data word, assembly label
     *     pad-bytes
     *   L0:
     *     call function-address
     *     addl framesize, FPR		;restore FPR
     *   single_value_rp:		;single value return point
     *     ... instructions...
     *   multi_value_rp:		;multi value return point
     *     ... instructions...
     *
     *     ;; high memory
     *
     * The "long"  word FRAMESIZE is an  offset to add to  TOP to obtain
     * the  top  of  the  uplevel   frame;  interpreted  as  fixnum:  it
     * represents  the number  of  machine words  on  this stack  frame;
     * interpreted as an  integer: it represents the number  of bytes on
     * this stack frame.
     *
     * Exception:  if the  data word  FRAMESIZE is  zero, then  the true
     * frame size  could not be computed  at compile time, and  so it is
     * stored on the stack itself:
     *
     *         high memory
     *   |                      |
     *   |----------------------|
     *   |      framesize       | <-- top + wordsize
     *   |----------------------|
     *   |   single_value_rp    | <-- top
     *   |----------------------|
     *   |                      |
     *         low memory
     *
     * also in this case all the words  on this frame are live, the live
     * mask in the code object is unused.
     *
     * The fixnum "offset_field"  is the number of bytes  between the first
     * byte of binary code in this code object and the location in which
     * "offset_field" itself is stored:
     *
     *    metadata                    binary code
     *   |--------|-------------+-+----------------------| code object
     *            |.............|^
     *             offset_field  |
     *                  |        |
     *                   --------
     *
     * NOTE The  preprocessor symbol  "disp_call_table_offset" is  a negative
     * integer.
     */
    ikptr	single_value_rp	= IK_REF(top, 0);
    long	offset_field	= IK_UNFIX(IK_CALLTABLE_OFFSET(single_value_rp));
    if (DEBUG_STACK) {
      ik_debug_message("collecting frame at 0x%016lx: rp=0x%016lx, offset_field=%ld",
		       (long) top, single_value_rp, offset_field);
    }
    if (offset_field <= 0) {
      ik_abort("invalid offset_field %ld\n", offset_field);
    }
    /* Since the return point is alive,  we need to find the code object
       containing it and  mark it live as well.   The SINGLE_VALUE_RP in
       the stack frame is updated to reflect the new code object. */
    long	code_offset	= offset_field - disp_call_table_offset;
    ikptr	code_entry	= single_value_rp - code_offset;
    ikptr	new_code_entry	= gather_live_code_entry(gc, code_entry);
    ikptr	new_sv_rp	= new_code_entry + code_offset;
    IK_REF(top, 0) = new_sv_rp;
    single_value_rp = new_sv_rp;

    /* now for some livemask action.
     * every return point has a live mark above it.  the live mask
     * is a sequence of bytes (every byte for 8 frame cells).  the
     * size of the live mask is determined by the size of the frame.
     * this is how the call frame instruction sequence looks like:
     *
     *   |    ...     |
     *   | code  junk |
     *   +------------+
     *   |   byte 0   |   for fv0 .. fv7
     *   |   byte 1   |   for fv8 .. fv15
     *   |    ...     |   ...
     *   +------------+
     *   |  framesize |
     *   |    word    |
     *   +------------+
     *   | frameoffst |  the frame offset determines how far its
     *   |    word    |  address is off from the start of the code
     *   +------------+
     *   | multivalue |
     *   |    word    |
     *   +------------+
     *   |  padding   |  the size of this part is fixed so that we
     *   |  and call  |  can correlate the frame info (above) with rp
     *   +------------+
     *   |   code     | <---- rp
     *   |    ...     |
     *
     *   WITH ONE EXCEPTION:
     *   if the framesize is 0, then the actual frame size is stored
     *   on the stack immediately below the return point.
     *   there is no live mask in this case, instead all values in the
     *   frame are live.
     */
    long framesize =  IK_CALLTABLE_FRAMESIZE(single_value_rp);
    if (DEBUG_STACK) {
      ik_debug_message("fs=%ld", (long)framesize);
    }
    if (framesize < 0) {
      ik_abort("invalid frame size %ld\n", (long)framesize);
    } else if (0 == framesize) {
      /* Keep alive all the objects on the stack. */
      framesize = IK_REF(top, wordsize);
      if (framesize <= 0) {
        ik_abort("invalid redirected framesize=%ld\n", (long)framesize);
      }
      /*
       *       high memory
       *   |----------------|
       *   | return address | <-- uplevel top
       *   |----------------|                                --
       *   | Scheme object  | <-- top + framesize - wordsize .
       *   |----------------|                                .
       *   | Scheme object  |                                . framesize
       *   |----------------|                                .
       *   | return address | <-- top                        .
       *   |----------------|                                --
       *      low memory
       */
      ikptr base;
      for (base=top+framesize-wordsize; base > top; base-=wordsize) {
        ikptr new_obj = gather_live_object(gc,IK_REF(base,0), "frame");
        IK_REF(base,0) = new_obj;
      }
    } else {
      /* Keep alive only the objects selected by the livemask. */
      /* Number of Scheme objects on this stack frame. */
      long	frame_cells	= framesize >> fx_shift;
      /* Number of  bytes in the  livemask array, knowing that  there is
	 one bit for  every frame cell.  When the framesize  is 4 (there
	 is only one machine word on  the stack) the livemask array must
	 contain a single byte. */
      long	bytes_in_mask	= (frame_cells+7) >> 3;
      /* Pointer to the livemask bytevector */
      char *	mask = (char*)(long)(single_value_rp + disp_call_table_size - bytes_in_mask);
      /* Pointer to the Scheme objects on the stack. */
      ikptr *	fp   = (ikptr*)(long)(top + framesize);
      long	i;
      for (i=0; i<bytes_in_mask; i++, fp-=8) {
        unsigned char m = mask[i];
#if DEBUG_STACK
        ik_debug_message("m[%ld]=0x%x", i, m);
#endif
        if (m & 0x01) { fp[-0] = gather_live_object(gc, fp[-0], "frame0"); }
        if (m & 0x02) { fp[-1] = gather_live_object(gc, fp[-1], "frame1"); }
        if (m & 0x04) { fp[-2] = gather_live_object(gc, fp[-2], "frame2"); }
        if (m & 0x08) { fp[-3] = gather_live_object(gc, fp[-3], "frame3"); }
        if (m & 0x10) { fp[-4] = gather_live_object(gc, fp[-4], "frame4"); }
        if (m & 0x20) { fp[-5] = gather_live_object(gc, fp[-5], "frame5"); }
        if (m & 0x40) { fp[-6] = gather_live_object(gc, fp[-6], "frame6"); }
        if (m & 0x80) { fp[-7] = gather_live_object(gc, fp[-7], "frame7"); }
      }
    }
    top += framesize;
  }
  if (top != end)
    ik_abort("frames did not match up 0x%016lx .. 0x%016lx", (long)top, (long)end);
  if (DEBUG_STACK) {
    ik_debug_message("%s: leave\n", __func__);
  }
}


/** --------------------------------------------------------------------
 ** Collection subroutines: tconcs for hash tables.
 ** ----------------------------------------------------------------- */

static void	add_one_tconc (ikpcb* pcb, ikptr p);

static void
gc_add_tconcs(gc_t* gc)
{
  if (gc->tconc_base == 0) {
    return;
  }
  ikpcb* pcb = gc->pcb;
  {
    ikptr p = gc->tconc_base;
    ikptr q = gc->tconc_ap;
    for (; p<q; p+=pair_size) {
      add_one_tconc(pcb, p);
    }
  }
  ikmemblock* blk = gc->tconc_queue;
  while (blk) {
    ikptr p = blk->base;
    ikptr q = p + blk->size;
    for (; p<q; p+=pair_size) {
      add_one_tconc(pcb, p);
    }
    ikmemblock* next = blk->next;
    ik_free(blk, sizeof(ikmemblock));
    blk = next;
  }
}
static void
add_one_tconc(ikpcb* pcb, ikptr p)
{
  ikptr tcbucket = IK_REF(p,0);
  ikptr tc = IK_REF(tcbucket, off_tcbucket_tconc);
  assert(IK_TAGOF(tc) == pair_tag);
  ikptr d = IK_REF(tc, off_cdr);
  assert(IK_TAGOF(d) == pair_tag);
  ikptr new_pair = p | pair_tag;
  IK_REF(d, off_car) = tcbucket;
  IK_REF(d, off_cdr) = new_pair;
  IK_REF(new_pair, off_car) = IK_FALSE_OBJECT;
  IK_REF(new_pair, off_cdr) = IK_FALSE_OBJECT;
  IK_REF(tc, off_cdr) = new_pair;
  IK_REF(tcbucket, -vector_tag) = (ikptr)(tcbucket_size - wordsize);
  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, tc);
  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, d);
}


/** --------------------------------------------------------------------
 ** Collection subroutines: guardians handling.
 ** ----------------------------------------------------------------- */

static ik_ptr_page *	move_tconc (ikptr tc, ik_ptr_page* ls);
static inline int	is_live (ikptr x, gc_t* gc);
static inline int	next_gen (int i);

static void
handle_guardians (gc_t* gc)
{
  ikpcb *	pcb = gc->pcb;
  ik_ptr_page *	pend_hold_list = 0;
  ik_ptr_page *	pend_final_list = 0;
  int		gen;
  /* Sort protected pairs into PEND_HOLD and PEND_FINAL lists. */
  for (gen=0; gen<=gc->collect_gen; gen++) {
    /* PROT_LIST references a NULL-terminated linked list of pages. */
    ik_ptr_page *	prot_list = pcb->protected_list[gen];
    pcb->protected_list[gen] = 0;
    while (prot_list) {
      int	i;
      /* Scan the words in this page. */
      for(i=0; i<prot_list->count; i++) {
        ikptr	p   = prot_list->ptr[i];
        ikptr	tc  = IK_CAR(p);
        ikptr	obj = IK_CDR(p);
        if (IK_FORWARD_PTR == tc) {
          ikptr np = IK_CDR(p);
          tc  = IK_CAR(np);
          obj = IK_CDR(np);
        }
        if (is_live(obj, gc))
          pend_hold_list  = move_tconc(p, pend_hold_list);
	else
          pend_final_list = move_tconc(p, pend_final_list);
      }
      { /* Deallocate this node in the PROT_LIST linked list. */
	ik_ptr_page *	next = prot_list->next;
	ik_munmap((ikptr)prot_list, IK_PAGESIZE);
	prot_list = next;
      }
    }
  }
  /* Here we know that  the array PCB->PROTECTED_LIST[...] holds invalid
     words. */

  { /* Move  live tc  PEND_FINAL_LIST  pairs into  FINAL_LIST, the  rest
       remain in  PEND_FINAL_LIST; FINAL_LIST objects are  made live and
       collected in GC->FORWARD_LIST.  */
    gc->forward_list = 0;
    int done = 0;
    while (!done) {
      ik_ptr_page* final_list = 0;
      ik_ptr_page* ls = pend_final_list;
      pend_final_list = 0;
      while (ls) {
	int i;
	for (i=0; i<ls->count; i++) {
	  ikptr p = ls->ptr[i];
	  ikptr tc = IK_REF(p, off_car);
	  if (tc == IK_FORWARD_PTR) {
	    ikptr np = IK_REF(p, off_cdr);
	    tc = IK_REF(np, off_car);
	  }
	  if (is_live(tc, gc)) {
	    final_list = move_tconc(p, final_list);
	  } else {
	    pend_final_list = move_tconc(p, pend_final_list);
	  }
	}
	ik_ptr_page* next = ls->next;
	ik_munmap((ikptr)ls, IK_PAGESIZE);
	ls = next;
      }
      if (final_list == NULL) {
	done = 1;
      } else {
	ls = final_list;
	while (ls) {
	  int i;
	  for (i=0; i<ls->count; i++) {
	    ikptr p = ls->ptr[i];
	    gc->forward_list = move_tconc(gather_live_object(gc, p, "guardian"), gc->forward_list);
	  }
	  ik_ptr_page* next = ls->next;
	  ik_munmap((ikptr)ls, IK_PAGESIZE);
	  ls = next;
	}
	collect_loop(gc);
      }
    }
  }
  /* PEND_FINAL_LIST now contains things  that are dead and their tconcs
     are also dead, deallocate. */
  while (pend_final_list) {
    ik_ptr_page* next = pend_final_list->next;
    ik_munmap((ikptr)pend_final_list, IK_PAGESIZE);
    pend_final_list = next;
  }
  /* pend_hold_list pairs with live tconcs are moved to
     the protected list of next generation. */
  ik_ptr_page* target = pcb->protected_list[next_gen(gc->collect_gen)];
  while(pend_hold_list) {
    int i;
    for(i=0; i<pend_hold_list->count; i++) {
      ikptr p = pend_hold_list->ptr[i];
      ikptr tc = IK_REF(p, off_car);
      if (tc == IK_FORWARD_PTR) {
        ikptr np = IK_REF(p, off_cdr);
        tc = IK_REF(np, off_car);
      }
      if (is_live(tc, gc)) {
        target = move_tconc(gather_live_object(gc, p, "guardian"), target);
      }
    }
    ik_ptr_page* next = pend_hold_list->next;
    ik_munmap((ikptr)pend_hold_list, IK_PAGESIZE);
    pend_hold_list = next;
  }
  collect_loop(gc);
  pcb->protected_list[next_gen(gc->collect_gen)] = target;
}
static inline int
is_live (ikptr x, gc_t* gc)
{
  int		tag;
  int		gen;
  if (IK_IS_FIXNUM(x))
    return 1;
  tag = IK_TAGOF(x);
  if (tag == immediate_tag)
    return 1;
  if (IK_FORWARD_PTR == IK_REF(x, -tag))
    return 1;
  gen = gc->segment_vector[IK_PAGE_INDEX(x)] & GEN_MASK;
  return (gen > gc->collect_gen)? 1 : 0;
}
static inline int
next_gen (int i)
{
  return ((i == (IK_GC_GENERATION_COUNT-1))? i : (i+1));
}
static ik_ptr_page *
move_tconc (ikptr tc, ik_ptr_page* ls)
/* Store TC in the  first node of the linked list LS.   If LS is NULL or
   the first node of  LS is full: allocate a new node  and prepend it to
   LS; then store TC in it.  Return the, possibly new, first node of the
   linked list. */
{
  if ((NULL == ls) || (IK_PTR_PAGE_NUMBER_OF_GUARDIANS_SLOTS == ls->count)) {
    ik_ptr_page* page = (ik_ptr_page*)ik_mmap(IK_PAGESIZE);
    page->count = 0;
    page->next  = ls;
    ls = page;
  }
  ls->ptr[ls->count++] = tc;
  return ls;
}


/** --------------------------------------------------------------------
 ** Keeping alive objects: main function.
 ** ----------------------------------------------------------------- */

/* Prototypes for subroutines of "gather_live_object()". */
static void		gather_live_list	(gc_t* gc, unsigned segment_bits, ikptr X, ikptr* loc);
static inline void	gc_tconc_push		(gc_t* gc, ikptr tcbucket);

static inline ikptr	gc_alloc_new_data	(ik_ulong aligned_size, gc_t* gc);
static inline ikptr	gc_alloc_new_ptr	(ik_ulong aligned_size, gc_t* gc);
static inline ikptr	gc_alloc_new_large_ptr	(ik_ulong number_of_bytes, gc_t* gc);
static inline void	enqueue_large_ptr	(ikptr mem, ik_ulong aligned_size, gc_t* gc);
static inline ikptr	gc_alloc_new_symbol_record (gc_t* gc);
static inline ikptr	gc_alloc_new_pair	(gc_t* gc);
static inline ikptr	gc_alloc_new_weak_pair	(gc_t* gc);
static inline ikptr	gc_alloc_new_code	(ik_ulong aligned_size, gc_t* gc);

static ikptr
#if (((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC)) || (defined DEBUG_GATHER_LIVE_OBJECT))
gather_live_object_proc (gc_t* gc, ikptr X, char* caller IK_UNUSED)
#else
gather_live_object_proc (gc_t* gc, ikptr X)
#endif
/* Vicare implements a moving and compacting garbage collector; whenever
 * the collector, while scanning memory pages from the GC roots, finds a
 * live  Scheme  object: it  moves  its  data  area to  another  storage
 * location.
 *
 *   The argument  X must  be an  immediate object  or a  tagged pointer
 * referencing a live  non-immediate object.  If X  is immediate nothing
 * is  done.   If  X  is  a tagged  pointer:  this  function  moves  the
 * referenced  data area  to a  new memory  location and  returns a  new
 * tagged pointer  Y which  must replace  every occurrence  of X  in the
 * memory used by the Scheme program.
 *
 *   Remember that:
 *
 * - Every  non-immediate  Scheme  object  is represented  by  a  tagged
 *   pointer and a data area; the data area is always at least 2 machine
 *   words wide.
 *
 * - The old data area of live objects is copied to a new data area; the
 *   old  data  area  is  no  more  used in  the  course  of  a  garbage
 *   collection, and its memory is released at the end of a GC.
 *
 * with this we can understand why the old data area referenced by X can
 * be mutated as follows:
 *
 * - The first word  is set to the constant  IK_FORWARD_PTR: this allows
 *   future identification of references to already moved objects.
 *
 * - The second  word is set  to Y, the tagged  pointer to the  new data
 *   area: this allows future substitution  of the occurrences of X with
 *   Y.
 *
 *   The new data area is reserved  in newly allocated memory pages; the
 * allocation  and  bookkeeping  of  such  pages  is  performed  by  the
 * "gc_alloc_new_*()" functions; see the documentation of such functions
 * for  more details.   The new  pages end  up referenced  by the  PCB's
 * segments vector and are registered in  the GC struct; later they will
 * be scanned  by the function  "collect_loop()", so we should  not scan
 * them here.
 *
 *   *WARNING* When this function is  called recursively: it is safer to
 * first  update the  memory block  referenced  by X,  then perform  the
 * recursive  call; this  way  the  recursive call  will  see X  already
 * collected.
 */
{
  int		tag;		/* tag bits of X */
  ikptr		first_word;	/* first word in the block referenced by X */
  uint32_t	page_sbits;	/* status bits for memory page holding X */

  /* Fixnums and other  immediate objects (self contained  in the single
     machine word  X) do  not need  to be moved.   So identify  them and
     return. */
  {
    if (IK_IS_FIXNUM(X))
      return X;
    assert(IK_FORWARD_PTR != X);
    tag = IK_TAGOF(X);
    if (immediate_tag == tag)
      return X;
  }

  /* If X  has already been moved  in a previous call  to this function:
     the first  word in the data  area is IK_FORWARD_PTR and  the second
     word is the new reference Y: return the new reference Y. */
  {
    first_word = IK_REF(X, -tag);
    if (IK_FORWARD_PTR == first_word)
      return IK_REF(X, wordsize-tag);
  }

  /* If X does not belong to a generation examined in this GC run: leave
     it alone. */
  {
    int		generation;
    page_sbits = gc->segment_vector[IK_PAGE_INDEX(X)];
    generation = page_sbits & GEN_MASK;
    if (generation > gc->collect_gen)
      return X;
  }

  /* If we are  here X must be moved  to a new location; this  is a type
     specific operation,  so we branch  by tag value. */
  switch (tag) {

  case pair_tag: {
    /* Pair object,  either weak or strong.   It goes in the  pairs meta
       page. */
    ikptr Y;
    gather_live_list(gc, page_sbits, X, &Y);
#if ACCOUNTING
    pair_count++;
#endif
    return Y;
  }

  case closure_tag: {
    /* Closure object.  It goes in the pointers meta page.

       Notice that we visit here  the referenced code object, because it
       needs some special handling; also  remember that a closure object
       does not reference the code object itself, rather FIRST_WORD is a
       raw memory pointer  to the entry point in the  executable code of
       the code object.

       S_NUM_OF_FREEVARS  is a  fixnum representing  the number  of free
       variables  associated to  the code  object.  As  raw integer:  it
       represents the  number bytes used  in the closure object  to hold
       the actual free variables' values (one machine word for each free
       variable). */
    ikptr s_num_of_freevars = IK_REF(first_word, disp_code_freevars - disp_code_data);
    ikptr size              = disp_closure_data + s_num_of_freevars;
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
    if (size > 1024) {
      ik_debug_message("large closure size=0x%016lx", (long)size);
    }
#endif
    ikptr asize = IK_ALIGN(size);
    ikptr Y     = gc_alloc_new_ptr(asize, gc) | closure_tag;
    IK_REF(Y, asize - closure_tag - wordsize) = 0;
    memcpy((char*)(long)(Y - closure_tag),
           (char*)(long)(X - closure_tag),
           size);
    /* First     process      the     old     memory,      then     call
       "gather_live_code_entry()". */
    IK_REF(X,          - closure_tag) = IK_FORWARD_PTR;
    IK_REF(X, wordsize - closure_tag) = Y;
    IK_REF(Y,          - closure_tag) = gather_live_code_entry(gc, IK_REF(Y,-closure_tag));
#if ACCOUNTING
    closure_count++;
#endif
    return Y;
  }

  case vector_tag: {
    /* Gather  an  object whose  reference  is  tagged as  vector;  such
       objects  are "vector  like" in  that they  are arrays  of machine
       words each  representing an immediate  Scheme object or  a tagged
       pointer to the data area of a Scheme object. */

    switch (first_word) {

    case symbol_tag: {
      /* Symbol object.  It goes in the symbols meta page. */
      ikptr	Y = gc_alloc_new_symbol_record(gc) | record_tag;
      IK_REF(Y, off_symbol_record_tag)	   = symbol_tag;
      IK_REF(Y, off_symbol_record_string)  = IK_REF(X, off_symbol_record_string);
      IK_REF(Y, off_symbol_record_ustring) = IK_REF(X, off_symbol_record_ustring);
      IK_REF(Y, off_symbol_record_value)   = IK_REF(X, off_symbol_record_value);
      IK_REF(Y, off_symbol_record_proc)    = IK_REF(X, off_symbol_record_proc);
      IK_REF(Y, off_symbol_record_plist)   = IK_REF(X, off_symbol_record_plist);
      IK_REF(X,          - record_tag)     = IK_FORWARD_PTR;
      IK_REF(X, wordsize - record_tag)     = Y;
#if ACCOUNTING
      symbol_count++;
#endif
      return Y;
    }

    case code_tag: {
      /* Code object.  It goes in the code meta page. */
      ikptr	entry     = X + off_code_data;
      ikptr	new_entry = gather_live_code_entry(gc, entry);
      return new_entry - off_code_data;
    }

    case continuation_tag: {
      /* Scheme  continuation object.   The  object itself  goes in  the
	 pointers meta page; the  referenced freezed Scheme stack frames
	 go in the data meta pages.

	 NOTE Why  the Scheme continuation  object goes in  the pointers
	 meta page?  Putting aside the next continuation, all its fields
	 are raw values; should it not go in the data meta pages?  No it
	 should not.   Objects stored in  the data meta pages  are never
	 scanned,  and  the  Scheme continuation  objects  are  mutable:
	 continuations  referencing  multiple  Scheme stack  frames  are
	 split and  split until they  reference one stack frame  and the
	 data structure representing a continuation is recycled.  (Marco
	 Maggi; Tue Dec 17, 2013) */
      ikptr	top  = IK_REF(X, off_continuation_top);
      ikptr	size = IK_REF(X, off_continuation_size);
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
      if (size > IK_PAGESIZE)
        ik_debug_message("large cont size=0x%016lx", size);
#endif
      ikptr	next = IK_REF(X, off_continuation_next);
      ikptr	Y    = gc_alloc_new_ptr(continuation_size, gc) | vector_tag;
      /* Process the  old data area  BEFORE scanning the  current Scheme
	 stack. */
      IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - vector_tag) = Y;
      ikptr	new_top = gc_alloc_new_data(IK_ALIGN(size), gc);
      memcpy((char*)(long)new_top, (char*)(long)top, size);
      collect_stack(gc, new_top, new_top + size);
      IK_REF(Y, off_continuation_tag)  = continuation_tag;
      IK_REF(Y, off_continuation_top)  = new_top;
      IK_REF(Y, off_continuation_size) = size;
      IK_REF(Y, off_continuation_next) = next;
      if (0) {
	ik_debug_message("gc compacted continuation 0x%016lx to 0x%016lx, next 0x%016lx",
			 X, Y, gc->pcb->next_k);
      }
#if ACCOUNTING
      continuation_count++;
#endif
      return Y;
    }

    case system_continuation_tag: {
      /* System (C language)  continuation object.  It goes  in the data
	 meta pages.   Why it goes in  the data page?  Because  it is an
	 immutable object with a single  field holding a tagged pointer.
	 Notice  that  we  gather  the next  continuation  object  here,
	 because "collect_loop()" does not scan data meta pages. */
      ikptr	Y    = gc_alloc_new_data(system_continuation_size, gc) | vector_tag;
      ikptr	top  = IK_REF(X, off_system_continuation_top);
      ikptr	next = IK_REF(X, off_system_continuation_next);
      /* First     process     the     old     memory,     then     call
	 "gather_live_object()". */
      IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - vector_tag) = Y;
      IK_REF(Y,          - vector_tag) = first_word;
      IK_REF(Y, off_system_continuation_top)  = top;
      IK_REF(Y, off_system_continuation_next) = gather_live_object(gc, next, "next_k");
      return Y;
    }

    case flonum_tag: {
      /* Flonum object.  It goes in the data meta page. */
      ikptr	Y = gc_alloc_new_data(flonum_size, gc) | vector_tag;
      IK_REF(Y,          - vector_tag) = flonum_tag;
      IK_FLONUM_DATA(Y)                = IK_FLONUM_DATA(X);
      IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - vector_tag) = Y;
      return Y;
    }

    case ratnum_tag: {
      /* Ratnum object.   It goes in  the data meta page,  the numerator
	 and denominator objects are gathered here.

         NOTE The only reason I can  think of for putting ratnums in the
         data meta page (rather than the  pointers meta page) is that we
         know that the numerator and denominator objects are numbers, so
         they  do  not  further   reference  other  Scheme  objects;  by
         gathering the numerator and denominator here we spare some work
         to "collect_loop()".  (Marco Maggi; Tue Dec 17, 2013) */
      ikptr Y   = gc_alloc_new_data(ratnum_size, gc) | vector_tag;
      ikptr num = IK_REF(X, off_ratnum_num);
      ikptr den = IK_REF(X, off_ratnum_den);
      /* First     process     the     old     memory,     then     call
	 "gather_live_object()". */
      IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - vector_tag) = Y;
      IK_REF(Y,          - vector_tag) = first_word;
      IK_REF(Y, off_ratnum_num) = gather_live_object(gc, num, "num");
      IK_REF(Y, off_ratnum_den) = gather_live_object(gc, den, "den");
      return Y;
    }

    case compnum_tag: {
      /* Compnum object.   It goes in the  data meta page, the  real and
	 imag part objects are gathered here.

         NOTE The only reason I can think of for putting compnums in the
         data meta page (rather than the  pointers meta page) is that we
         know that the  real and imag part objects are  real numbers, so
         even if  they do  further reference  other Scheme  objects, the
         depth is  small; by gathering the  real and imag parts  here we
         spare some work to "collect_loop()".  (Marco Maggi; Tue Dec 17,
         2013) */
      ikptr Y  = gc_alloc_new_data(compnum_size, gc) | vector_tag;
      ikptr rl = IK_REF(X, off_compnum_real);
      ikptr im = IK_REF(X, off_compnum_imag);
      /* First     process     the     old     memory,     then     call
	 "gather_live_object()". */
      IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - vector_tag) = Y;
      IK_REF(Y,          - vector_tag) = first_word;
      IK_REF(Y, off_compnum_real) = gather_live_object(gc, rl, "real");
      IK_REF(Y, off_compnum_imag) = gather_live_object(gc, im, "imag");
      return Y;
    }

    case cflonum_tag: {
      /* Cflonum object.   It goes in the  data meta page, the  real and
	 imag part objects are gathered here.

         NOTE The only reason I can think of for putting cflonums in the
         data meta page (rather than the  pointers meta page) is that we
         know that the real and imag part objects are flonum numbers, so
         they  do  not  further   reference  other  Scheme  objects;  by
         gathering the  real and imag parts  here we spare some  work to
         "collect_loop()".  (Marco Maggi; Tue Dec 17, 2013) */
      ikptr Y  = gc_alloc_new_data(cflonum_size, gc) | vector_tag;
      ikptr rl = IK_REF(X, off_cflonum_real);
      ikptr im = IK_REF(X, off_cflonum_imag);
      /* First     process     the     old     memory,     then     call
	 "gather_live_object()". */
      IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - vector_tag) = Y;
      IK_REF(Y,          - vector_tag) = first_word;
      IK_REF(Y, off_cflonum_real) = gather_live_object(gc, rl, "real");
      IK_REF(Y, off_cflonum_imag) = gather_live_object(gc, im, "imag");
      return Y;
    }

    case pointer_tag: {
      /* Foreign pointer object.  It goes in the data meta page. */
      ikptr	Y = gc_alloc_new_data(pointer_size, gc) | vector_tag;
      IK_REF(Y,          - vector_tag) = pointer_tag;
      IK_REF(Y, wordsize - vector_tag) = IK_REF(X, wordsize - vector_tag);
      IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - vector_tag) = Y;
      return Y;
    }

    default: {
      if (IK_IS_FIXNUM(first_word)) {
	/* Vector object.  It goes in the pointers meta page.

	   Notice that FIRST_WORD is a fixnum  and we use it directly as
	   number of bytes to allocate for  the data area of the vector;
	   this is because  the fixnum tag is composed of  zero bits and
	   they are in such a number that multiplying the fixnum's value
	   by the wordsize is  equivalent to right-shifting the fixnum's
	   value by the fixnum tag. */
	ikptr	s_length = first_word;
	ikptr	nbytes   = s_length + disp_vector_data; /* not aligned */
	ikptr	memreq   = IK_ALIGN(nbytes);
	if (memreq >= IK_PAGESIZE) { /* big vector */
	  if (LARGE_OBJECT_TAG == (page_sbits & LARGE_OBJECT_MASK)) {
	    /* Big  vector  already stored  in  pages  marked as  "large
	       object".  We  do not move  it around, rather  we register
	       the  data area  in the  queues of  objects to  be scanned
	       later by "collect_loop()". */
	    enqueue_large_ptr(X - vector_tag, nbytes, gc);
	    return X;
	  } else {
	    /* Big  vector not  yet  stored in  pages  marked as  "large
	       object". */
	    /* "gc_alloc_new_large_ptr()" wants the real number of bytes
	       as argument, not the aligned size. */
	    ikptr Y = gc_alloc_new_large_ptr(nbytes, gc) | vector_tag;
	    IK_REF(Y, off_vector_length) = first_word;
	    /* Set to  the fixum  zero the  last word  in the  data area
	       reserved  for  the  vector.   This is  to  avoid  leaving
	       uninitialised  a machine  word  right  after the  vector;
	       setting this in any case is safe either the vector has an
	       even or odd number of slots. */
	    IK_REF(Y, memreq - vector_tag - wordsize) = 0;
	    /* Copy all the vector items from source to dest. */
	    memcpy((char*)(long)(Y + off_vector_data),
		   (char*)(long)(X + off_vector_data),
		   s_length);
	    IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
	    IK_REF(X, wordsize - vector_tag) = Y;
	    return Y;
	  }
	} else { /* small vector */
	  /* "gc_alloc_new_ptr()" wants an aligned size as argument. */
	  ikptr Y = gc_alloc_new_ptr(memreq, gc) | vector_tag;
	  IK_REF(Y, off_vector_length) = first_word;
	  /* Set  to the  fixum  zero the  last word  in  the data  area
	     reserved  for  the  vector.    This  is  to  avoid  leaving
	     uninitialised  a  machine  word  right  after  the  vector;
	     setting this in  any case is safe either the  vector has an
	     even or odd number of slots. */
	  IK_REF(Y, memreq - vector_tag - wordsize) = 0;
	  /* Copy all the vector items from source to dest. */
	  memcpy((char*)(long)(Y + off_vector_data),
		 (char*)(long)(X + off_vector_data),
		 s_length);
	  IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
	  IK_REF(X, wordsize - vector_tag) = Y;
	  return Y;
	}
#if ACCOUNTING
	vector_count++;
#endif
      }
      else if (IK_TAGOF(first_word) == rtd_tag) {
	/* Vicare  struct  or  R6RS   record,  including  the  structure
	 * descriptor and  the record type  descriptor.  It goes  in the
	 * pointers meta page.
	 *
	 *   The  layout  of  Vicare struct-type  descriptors  and  R6RS
	 * record-type descriptors is as follows:
	 *
	 *     RTD  name length  other fields
	 *    |----|----|------|------------	struct descriptor
	 *
	 *     RTD  name length  other fields
	 *    |----|----|------|------------	R6RS descriptor
	 *
	 * the  layout  of Vicare's  struct  instances  and R6RS  record
	 * instances is as follows:
	 *
	 *     RTD   fields
	 *    |----|---------			struct instance
	 *
	 *     RTD   fields
	 *    |----|---------			R6RS record instance
	 *
	 * the type descriptors are special cases of struct instance.
	 *
	 *   Both  Vicare struct-type  descriptors and  R6RS record-type
	 * descriptors have the  total number of fields  (length) at the
	 * same offset.   The value  in the  length word  represents: as
	 * fixnum, the  number of fields  in an instance; as  C integer,
	 * the  number  of  bytes  needed  to store  the  fields  of  an
	 * instance.
	 */
	ikptr		s_rtd    = first_word;
	ikptr		s_length = IK_REF(s_rtd, off_rtd_length);
	ikptr		Y;
	ik_ulong	requested_size = disp_record_data + s_length;
	ik_ulong	aligned_size   = IK_ALIGN(requested_size);
	Y = gc_alloc_new_ptr(aligned_size, gc) | record_tag;
	IK_REF(Y, off_record_rtd) = s_rtd;
	{
	  uint8_t * dst = (uint8_t *)(Y + off_record_data); /* untagged pointer */
	  uint8_t * src = (uint8_t *)(X + off_record_data); /* untagged pointer */
	  /* Copy the struct fields */
	  memcpy(dst, src, s_length);
	  /* Reset the  additional machine word, if  any, allocated when
	     converting  from the  requested size  to the  aligned size;
	     this memory is  part of the generational  pages (scanned by
	     the collector), so we must do it. */
	  if (requested_size < aligned_size)
	    memset(dst + s_length, 0, wordsize);
	}
	IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
	IK_REF(X, wordsize - vector_tag) = Y;
	return Y;
#if 0 /* NOTE  The following,  excluded,  version of  the code  handling
	 structs is derived  from the original Ikarus code.   It is more
	 complicated, but more verified.  I am keeping it here as future
	   reference.  (Marco Maggi; Wed Dec 18, 2013) */
	ikptr		s_rtd    = first_word;
	ikptr		s_length = IK_REF(s_rtd, off_rtd_length);
	ikptr		Y;
	if (s_length & ((1<<IK_ALIGN_SHIFT)-1)) {
	  // fprintf(stderr, "%lx align size %ld\n", X, IK_UNFIX(s_length));
	  /* The number of  fields is odd, which means  that the number of
	     words needed to store this record is even.

	     s_length = n * object_alignment + 4
	     => memreq = n * object_alignment + 8 = (n+1) * object_alignment
	     => aligned */
	  Y = gc_alloc_new_ptr(s_length+disp_record_data, gc) | vector_tag;
	  IK_REF(Y, off_record_rtd) = s_rtd;
	  {
	    ikptr i;
	    ikptr dst = Y + off_record_data; /* DST is untagged */
	    ikptr src = X + off_record_data; /* SRC is untagged */
	    IK_REF(dst, 0) = IK_REF(src, 0);
	    for (i=wordsize; i<s_length; i+=(2*wordsize)) {
	      IK_REF(dst, i)          = IK_REF(src, i);
	      IK_REF(dst, i+wordsize) = IK_REF(src, i+wordsize);
	    }
	  }
	} else {
	  // fprintf(stderr, "%lx padded size %ld\n", X, IK_UNFIX(s_length));
	  /* The number of fields is  even, which means that the number of
	     words needed to store this record is odd.

	     s_length = n * object_alignment
	     => memreq = n * object_alignment + 4 + 4 (pad) */
	  Y = gc_alloc_new_ptr(s_length+(2*wordsize), gc) | vector_tag;
	  IK_REF(Y, off_record_rtd) = s_rtd;
	  {
	    ikptr i;
	    ikptr dst = Y + off_record_data; /* DST is untagged */
	    ikptr src = X + off_record_data; /* SRC is untagged */
	    for (i=0; i<s_length; i+=(2*wordsize)) {
	      IK_REF(dst, i)          = IK_REF(src, i);
	      IK_REF(dst, i+wordsize) = IK_REF(src, i+wordsize);
	    }
	  }
	  IK_REF(Y, s_length + off_record_data) = 0;
	}
	IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
	IK_REF(X, wordsize - vector_tag) = Y;
	return Y;
#endif /* end of excluded code handling structs */
      }
      else if (IK_TAGOF(first_word) == pair_tag) {
	/* tcbucket object.  It goes in the pointers meta page.

	   The first word of a tcbucket is a tagged pointer to pair. */
	ikptr	Y   = gc_alloc_new_ptr(tcbucket_size, gc) | vector_tag;
	ikptr	key = IK_REF(X, off_tcbucket_key);
	IK_REF(Y, off_tcbucket_tconc) = first_word;
	IK_REF(Y, off_tcbucket_key)  = key;
	IK_REF(Y, off_tcbucket_val)  = IK_REF(X, off_tcbucket_val);
	IK_REF(Y, off_tcbucket_next) = IK_REF(X, off_tcbucket_next);
	if ((! IK_IS_FIXNUM(key)) && (IK_TAGOF(key) != immediate_tag)) {
	  int gen = gc->segment_vector[IK_PAGE_INDEX(key)] & GEN_MASK;
	  if (gen <= gc->collect_gen) {
	    /* key will be moved */
	    gc_tconc_push(gc, Y);
	  }
	}
	IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
	IK_REF(X, wordsize - vector_tag) = Y;
	return Y;
      }
      else if (port_tag == (((long)first_word) & port_mask)) {
	/* Port object.  It goes in the pointers meta page. */
	ikptr		Y = gc_alloc_new_ptr(port_size, gc) | vector_tag;
	ik_ulong	i;
	IK_REF(Y, -vector_tag) = first_word;
	for (i=wordsize; i<port_size; i+=wordsize) {
	  IK_REF(Y, i-vector_tag) = IK_REF(X, i-vector_tag);
	}
	IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
	IK_REF(X, wordsize - vector_tag) = Y;
	return Y;
      }
      else if (bignum_tag == (first_word & bignum_mask)) {
	/* Bignum object.  It goes in the data meta page. */
	long	len    = ((ik_ulong)first_word) >> bignum_nlimbs_shift;
	long	memreq = IK_ALIGN(disp_bignum_data + len*wordsize);
	ikptr	Y      = gc_alloc_new_data(memreq, gc) | vector_tag;
	memcpy((char*)(long)(Y - vector_tag),
	       (char*)(long)(X - vector_tag),
	       memreq);
	IK_REF(X,          - vector_tag) = IK_FORWARD_PTR;
	IK_REF(X, wordsize - vector_tag) = Y;
	return Y;
      }
      else {
	ik_abort("unhandled vector with first_word=0x%016lx\n", (long)first_word);
      }
    } /* end of "default:" */
    } /* end of "switch (first_word)" */
  } /* end of "case vector_tag:" */

  case string_tag: {
    if (IK_IS_FIXNUM(first_word)) {
      long	len    = IK_UNFIX(first_word);
      long	memreq = IK_ALIGN(len * IK_STRING_CHAR_SIZE + disp_string_data);
      ikptr	Y      = gc_alloc_new_data(memreq, gc) | string_tag;
      IK_REF(Y, off_string_length) = first_word;
      memcpy((char*)(long)(Y + off_string_data),
             (char*)(long)(X + off_string_data),
             len * IK_STRING_CHAR_SIZE);
      IK_REF(X,          - string_tag) = IK_FORWARD_PTR;
      IK_REF(X, wordsize - string_tag) = Y;
#if ACCOUNTING
      string_count++;
#endif
      return Y;
    } else
      ik_abort("unhandled string 0x%016lx with first_word=0x%016lx\n", (long)X, (long)first_word);
  }

  case bytevector_tag: {
    long	len    = IK_UNFIX(first_word);
    long	memreq = IK_ALIGN(len + disp_bytevector_data + 1);
    ikptr	Y = gc_alloc_new_data(memreq, gc) | bytevector_tag;
    IK_REF(Y, off_bytevector_length) = first_word;
    memcpy((char*)(long)(Y + off_bytevector_data),
           (char*)(long)(X + off_bytevector_data),
           len + 1);
    IK_REF(X,          - bytevector_tag) = IK_FORWARD_PTR;
    IK_REF(X, wordsize - bytevector_tag) = Y;
    return Y;
  }
  default:
    return ik_abort("%s: unhandled tag: %d\n", __func__, tag);
  } /* end of "switch(tag)" */
}


/** --------------------------------------------------------------------
 ** Keeping alive objects: list objects.
 ** ----------------------------------------------------------------- */

static void
gather_live_list (gc_t* gc, uint32_t page_sbits, ikptr X, ikptr* loc)
/* Move the spine of the proper or improper list object X (whose head is
   a pair) to a new location and store in LOC a new tagged pointer which
   must  replace  every  occurrence  of X.   See  the  documentation  of
   "gather_live_object_proc()" for the full details.

     This function  takes care of  processing adequately the  weak pairs
   and the strong pairs.

     This function processes  only the spine of the list:  it does *not*
   apply "gather_live_object()"  to the cars  of the pairs;  however, it
   does apply "gather_live_object()"  to the cdr of the  last pair, when
   the list is improper.  About  this: notice that when "collect_loop()"
   scans a  page of pairs,  it scans only the  cars and leaves  the cdrs
   alone.

     PAGE_SBITS is the  word from the slot in the  PCB's segments vector
   describing  the   page  in  which   the  pair  referenced  by   X  is
   allocated. */
{
  int collect_gen = gc->collect_gen;
  for (;;) {
    ikptr first_word      = IK_CAR(X);
    ikptr second_word     = IK_CDR(X);
    int   second_word_tag = IK_TAGOF(second_word);
    ikptr Y;
    if ((page_sbits & TYPE_MASK) != WEAK_PAIRS_TYPE)
      Y = gc_alloc_new_pair(gc)      | pair_tag;
    else
      Y = gc_alloc_new_weak_pair(gc) | pair_tag;
    *loc = Y;
    IK_CAR(X) = IK_FORWARD_PTR;
    IK_CDR(X) = Y;
    /* X is gone.  From now on we care about Y. */
    IK_CAR(Y) = first_word;
    if (pair_tag == second_word_tag) {
      /* The cdr of Y is a pair, too. */
      if (IK_FORWARD_PTR == IK_CAR(second_word)) {
	/* The cdr of Y has been already collected.  This means the rest
	   of the list has already been collected, too. */
        IK_CDR(Y) = IK_CDR(second_word);
        return;
      } else {
        uint32_t	generation;
        page_sbits = gc->segment_vector[IK_PAGE_INDEX(second_word)];
	generation = page_sbits & GEN_MASK;
	/* If the cdr  of Y does not belong to  a generation examined in
	   this GC run: leave it alone. */
        if (generation > collect_gen) {
          IK_CDR(Y) = second_word;
          return;
        } else {
	  /* Prepare  for  the next  for(;;)  loop  iteration.  We  will
	     process the cdr  of Y (a pair) and update  the reference to
	     it in  the cdr slot of  Y.  Notice that the  next iteration
	     will use the value of PAGE_SBITS we have set above. */
          X   = second_word;
          loc = (ikptr*)(ik_ulong)(Y + off_cdr);
        }
      }
    }
    else if ((second_word_tag == immediate_tag) ||
	     /* If the 3 least significant bits of SECOND_WORD are zero:
		SECOND_WORD  is  a  fixnum  on both  32-bit  and  64-bit
		platforms. */
	     (second_word_tag == 0) ||
	     /* If the 3 least significant bits of SECOND_WORD are:
	      *
	      *    #b100 == (1 << fx_shift)
	      *
	      * then SECOND_WORD is a fixnum on a 32-bit platform.  This
	      * case never happens on a  64-bit platform because the tag
	      * values have been chosen appropriately.
	      */
	     (second_word_tag == (1<<fx_shift))) {
      /* Y is a pair not starting a  list: its cdr is an immediate value
	 (boolean, character, fixnum, transcoder, ...). */
      IK_CDR(Y) = second_word;
      return;
    }
    else if (IK_REF(second_word, -second_word_tag) == IK_FORWARD_PTR) {
      /* The cdr of Y has already been collected.  Store in the cdr slot
	 the reference to the moved object. */
      IK_CDR(Y) = IK_REF(second_word, wordsize - second_word_tag);
      return;
    }
    else {
      /* X is  a pair not  starting a list:  its cdr is  a non-immediate
	 value (vector, record, port, ...). */
      IK_CDR(Y) = gather_live_object(gc, second_word, "gather_live_list");
      return;
    }
  } /* end of for(;;) */
}


/** --------------------------------------------------------------------
 ** Keeping alive objects: code objects.
 ** ----------------------------------------------------------------- */

static int alloc_code_count = 0;

static ikptr
gather_live_code_entry (gc_t* gc, ikptr entry)
/* Move the data  area of the code  object referenced by ENTRY  to a new
   memory location and return a  new untagged pointer which must replace
   every occurrence of  ENTRY in the memory used by  the Scheme program.
   See  the documentation  of "gather_live_object_proc()"  for the  full
   details. */
{
  ikptr		X = entry - disp_code_data; /* UNtagged pointer to code object */
  ik_ulong	page_idx;
  /* If X  has already been moved  in a previous call  to this function:
     the first  word in the data  area is IK_FORWARD_PTR and  the second
     word is the new reference Y: compute the pointer to the entry point
     of Y and return it. */
  if (IK_FORWARD_PTR == IK_REF(X,0)) {
    return IK_REF(X,wordsize) + off_code_data;
  }
  /* If X does not belong to a generation examined in this GC run: leave
     it alone. */
  {
    page_idx   = IK_PAGE_INDEX(X);
    uint32_t	page_sbits = gc->segment_vector[page_idx];
    int		generation = page_sbits & GEN_MASK;
    if (generation > gc->collect_gen)
      return entry;
  }

  /* The number of bytes used in the data area of the code object. */
  long		binary_code_size= IK_UNFIX(IK_REF(X, disp_code_code_size));
  /* The number of bytes actually used by the code object. */
  long		code_object_size= disp_code_data + binary_code_size;
  /* The total number of allocated bytes for this code object. */
  long		required_mem	= IK_ALIGN(code_object_size);
  /* The relocation vector. */
  ikptr		s_reloc_vec	= IK_REF(X, disp_code_reloc_vector);
  /* A fixnum representing the number of free variables. */
  ikptr		s_freevars	= IK_REF(X, disp_code_freevars);
  /* An object that annotates the code object. */
  ikptr		s_annotation	= IK_REF(X, disp_code_annotation);
  if (required_mem >= IK_PAGESIZE) {
    /* This is a "large" code object and we do *not* move it around.  */
    { /* Tag all  the pages  in the  data area of  the code  object: the
	 first  page as  code, the  subsequent  pages as  data; all  the
	 tagged pointers  in a code object  are in the first  page.  The
	 pages are already tagged in the segments vector, but we need to
	 update the generation number for each page. */
      uint32_t	new_tag  = gc->collect_gen_tag;
      long	page_idx = IK_PAGE_INDEX(X);
      long	mem;
      gc->segment_vector[page_idx] = new_tag | CODE_MT;
      for (mem=IK_PAGESIZE, page_idx++; mem<required_mem; mem+=IK_PAGESIZE, page_idx++) {
	gc->segment_vector[page_idx] = new_tag | DATA_MT;
      }
    }
    /* Push a new node on the  linked list of GC's queues pointer memory
       blocks.  This  allows the  function "collect_loop()" to  scan the
       object. */
    {
      qupages_t *	qu = ik_malloc(sizeof(qupages_t));
      qu->p    = X;
      qu->q    = X+required_mem;
      qu->next = gc->queues[meta_code];
      gc->queues[meta_code] = qu;
    }
    return entry;
  } else {
    /* Only one memory page allocated.  The object is moved like all the
       others.   "gc_alloc_new_code()" registers  the  data  area to  be
       scanned by the function "collect_loop()". */
    ikptr	Y = gc_alloc_new_code(required_mem, gc); /* UNtagged pointer */
    IK_REF(Y, disp_code_tag)		= code_tag;
    IK_REF(Y, disp_code_code_size)	= IK_FIX(binary_code_size);
    IK_REF(Y, disp_code_reloc_vector)	= s_reloc_vec;
    IK_REF(Y, disp_code_freevars)	= s_freevars;
    IK_REF(Y, disp_code_annotation)	= s_annotation;
    IK_REF(Y, disp_code_unused)		= IK_FIX(0);
    memcpy((char*)(long)(Y+disp_code_data),
           (char*)(long)(X+disp_code_data),
           binary_code_size);
    IK_REF(X, 0)	= IK_FORWARD_PTR;
    IK_REF(X, wordsize)	= Y | vector_tag;
    return Y+disp_code_data;
  }
}


/** --------------------------------------------------------------------
 ** Keeping alive objects: tconcs for hash tables.
 ** ----------------------------------------------------------------- */

static void	gc_tconc_push_extending (gc_t* gc, ikptr tcbucket);

static inline void
gc_tconc_push (gc_t* gc, ikptr tcbucket)
{
  ikptr ap  = gc->tconc_ap;
  ikptr nap = ap + pair_size;
  if (nap > gc->tconc_ep) {
    gc_tconc_push_extending(gc, tcbucket);
  } else {
    gc->tconc_ap = nap;
    IK_REF(ap, disp_car) = tcbucket;
    /* The cdr of the pair referenced  by AP is automatically set to the
       fixnum zero  because tconc  memory pages are  reset to  zero when
       allocated. */
  }
}
static void
gc_tconc_push_extending (gc_t* gc, ikptr tcbucket)
{
  if (gc->tconc_base) {
    /* Push  a new  node in  the linked  list "pcb->tconc_queue".   Save
       references to the current PCB tconc page in the new node. */
    ikmemblock *	blk = ik_malloc(sizeof(ikmemblock));
    blk->base = gc->tconc_base;
    blk->size = IK_PAGESIZE;
    blk->next = gc->tconc_queue;
    gc->tconc_queue = blk;
  }
  /* Allocate a new page for tconc  pairs; store references to it in the
     PCB. */
  {
    ikptr	mem;
    mem = ik_mmap_typed(IK_PAGESIZE, META_MT[meta_ptrs] | gc->collect_gen_tag, gc->pcb);
    bzero((char*)mem, IK_PAGESIZE);
    /* gc statistics */
    register_to_collect_count(gc->pcb, IK_PAGESIZE);
    /* Retake   the  segment   vector   because   memory  allocated   by
       "ik_mmap_typed()" might have caused  the reallocation of the page
       vectors. */
    gc->segment_vector = gc->pcb->segment_vector;
    /* Store references to the allocated page in the GC struct.  Reserve
       room for a pair at the beginning of the page. */
    gc->tconc_base = mem;		/* pointer to allocated page */
    gc->tconc_ap   = mem + pair_size;	/* alloc pointer */
    gc->tconc_ep   = mem + IK_PAGESIZE;	/* end pointer */
    IK_REF(mem, disp_car) = tcbucket;
    /* The cdr of the  first pair is set to the fixnum  zero by the call
       to "bzero()" above. */
  }
}


/** --------------------------------------------------------------------
 ** Keeping alive objects: allocating memory for moved live objects.
 ** ----------------------------------------------------------------- */

/* Vicare implements a moving and compacting garbage collector; whenever
 * the collector, while scanning memory pages from the GC roots, finds a
 * live  Scheme  object: it  moves  its  data  area to  another  storage
 * location.
 *
 *   Small Scheme objects are stored,  one after the other, in dedicated
 * memory pages:  a page for  pairs, a page for  weak pairs, a  page for
 * symbol records, a  page for code objects, a page  for pointer objects
 * (that  hold  immediate  values  or tagged  pointers;  like:  vectors,
 * structs, records, ratnums,  compnums, cflonums); a page  for raw data
 * (the  data area  of  bytevectors, strings,  flonums,  etc.).  When  a
 * dedicated page is full: a new one is allocated.
 *
 *   The  garbage collector  keeps references  to the  current dedicated
 * pages in  the array field "meta"  of the struct "gc_t".   The garbage
 * collection core  function will  scan the meta  pages by  calling thhe
 * function "collect_loop()".
 *
 *   Some objects  are not  stored in  the meta  pages, rather  in pages
 * allocated just for them; in this  case a reference to their data area
 * is stored  in the "queues"  field of the  gc_t struct, so  that later
 * such objects can be scanned by "collect_loop()".
 */

static inline ikptr	meta_alloc           (ik_ulong aligned_size, gc_t* gc, int meta_id);
static ikptr		meta_alloc_extending (ik_ulong aligned_size, gc_t* gc, int meta_id);

static inline ikptr
gc_alloc_new_ptr (ik_ulong aligned_size, gc_t* gc)
/* Reserve enough room in the current  meta page for pointers to hold an
   object  of ALIGNED_SIZE  bytes.  Return  an untagged  pointer to  the
   first word of reserved memory. */
{
  assert(aligned_size == IK_ALIGN(aligned_size));
  return meta_alloc(aligned_size, gc, meta_ptrs);
}
static inline ikptr
gc_alloc_new_large_ptr (ik_ulong number_of_bytes, gc_t* gc)
/* Alloc memory pages  in which a large object will  be stored; return a
   pointer to  the first allocated  page.  The  pages are marked  in the
   segments  vector as  "large  object", this  will  prevent later  such
   object to be  moved around.  The object's data area  is registered in
   the queues of objects to be scanned later by "collect_loop()". */
{
  ik_ulong	memreq;
  ikptr		mem;
  memreq = IK_ALIGN_TO_NEXT_PAGE(number_of_bytes);
  mem    = ik_mmap_typed(memreq, POINTERS_MT | LARGE_OBJECT_TAG | gc->collect_gen_tag, gc->pcb);
  /* Reset to zero  the portion of memory  that will not be  used by the
     large object. */
  bzero((char*)(long)(mem+number_of_bytes), memreq-number_of_bytes);
  /* Retake   the   segments   vector  because   memory   allocated   by
     "ik_mmap_typed()" might  have caused  the reallocation of  the page
     vectors. */
  gc->segment_vector = gc->pcb->segment_vector;
  /* Push a new  node on the linked list of  meta pointer memory blocks.
     This allows the function "collect_loop()" to scan the object. */
  {
    qupages_t *	qu;
    qu       = ik_malloc(sizeof(qupages_t));
    qu->p    = mem;
    qu->q    = mem+number_of_bytes;
    qu->next = gc->queues[meta_ptrs];
    gc->queues[meta_ptrs] = qu;
  }
  return mem;
}
static inline void
enqueue_large_ptr (ikptr mem, ik_ulong aligned_size, gc_t* gc)
/* Assume that "mem" references a large object that is already stored in
   memory pages  marked as "large  object".  Such objects are  not moved
   around by the garbage collector, rather  we register the data area in
   the queues of objects to be scanned later by "collect_loop()". */
{
  ik_ulong	page_idx = IK_PAGE_INDEX(mem);
  ik_ulong	page_end = IK_PAGE_INDEX(mem+aligned_size-1);
  for (; page_idx <= page_end; ++page_idx) {
    gc->segment_vector[page_idx] = POINTERS_MT | LARGE_OBJECT_TAG | gc->collect_gen_tag;
  }
  {
    qupages_t *	qu;
    qu       = ik_malloc(sizeof(qupages_t));
    qu->p    = mem;
    qu->q    = mem+aligned_size;
    qu->next = gc->queues[meta_ptrs];
    gc->queues[meta_ptrs] = qu;
  }
}
static inline ikptr
gc_alloc_new_symbol_record (gc_t* gc)
/* Reserve enough  room in the current  meta page for symbols  to hold a
   Scheme symbol's record.  Return an untagged pointer to the first word
   of reserved memory. */
{
  assert(symbol_record_size == IK_ALIGN(symbol_record_size));
  return meta_alloc(symbol_record_size, gc, meta_symbol);
}
static inline ikptr
gc_alloc_new_pair(gc_t* gc)
/* Reserve enough  room in  the current  meta page for  pairs to  hold a
   Scheme pair object.  Return an untagged  pointer to the first word of
   reserved memory. */
{
  return meta_alloc(pair_size, gc, meta_pair);
}
static inline ikptr
gc_alloc_new_weak_pair(gc_t* gc)
/* Reserve enough room in the current meta page for weak pairs to hold a
   Scheme weak  pair object.   Return an untagged  pointer to  the first
   word of reserved memory.

     If the meta page is full: allocate  a new one, store a reference to
   it in the GC  struct, reserve room for a pair in  it.  We perform the
   allocation  of  a  new  meta   page  here  (rather  than  by  calling
   "meta_alloc()")  because we  have to  tag the  page specially  in the
   segments vector. */
{
  meta_t *	meta = &gc->meta[meta_weak];
  ikptr		ap  = meta->ap;		/* meta page alloc pointer */
  ikptr		ep  = meta->ep;		/* meta page end pointer */
  ikptr		nap = ap + pair_size;	/* meta page new alloc pointer */
  if (nap > ep) {
    /* There is not  enough room, in the current meta  page, for another
       pair; we have to allocate a new page. */
    ikptr mem = ik_mmap_typed(IK_PAGESIZE, META_MT[meta_weak] | gc->collect_gen_tag, gc->pcb);
    /* Retake   the  segments   vector  because   memory  allocated   by
       "ik_mmap_typed()" might have caused  the reallocation of the page
       vectors. */
    gc->segment_vector = gc->pcb->segment_vector;
    /* Store references to the new meta  page in the GC struct.  Reserve
       enough room at the beginning for a pair object. */
    meta->ap   = mem + pair_size;	/* alloc pointer */
    meta->aq   = mem;			/* pointer to first allocated word */
    meta->ep   = mem + IK_PAGESIZE;	/* end pointer */
    meta->base = mem;			/* pointer to first allocated word */
    return mem;
  } else {
    /* There  is enough  room, in  the  current meta  page, for  another
       pair. */
    meta->ap = nap;
    return ap;
  }
}
static inline ikptr
gc_alloc_new_data (ik_ulong aligned_size, gc_t* gc)
/* Reserve enough room in  the current meta page for raw  data to hold a
   data area of  ALIGNED_SIZE bytes.  Return an untagged  pointer to the
   first word of reserved memory. */
{
  assert(aligned_size == IK_ALIGN(aligned_size));
  return meta_alloc(aligned_size, gc, meta_data);
}
static inline ikptr
gc_alloc_new_code (ik_ulong aligned_size, gc_t* gc)
/* Alloc memory  pages in which a  code object will be  stored; return a
   pointer  to the  first allocated  page.   The object's  data area  is
   registered  in  the  queues  of   objects  to  be  scanned  later  by
   "collect_loop()". */
{
  assert(aligned_size == IK_ALIGN(aligned_size));
  if (aligned_size < IK_PAGESIZE) {
    return meta_alloc(aligned_size, gc, meta_code);
  } else { /* More than one page needed. */
    ik_ulong	memreq	= IK_ALIGN_TO_NEXT_PAGE(aligned_size);
    ikptr	mem	= ik_mmap_code(memreq, gc->collect_gen, gc->pcb);
    /* Reset to  zero the portion of  allocated memory that will  not be
       used by the code object. */
    bzero((char*)(ik_ulong)(mem+aligned_size), memreq-aligned_size);
    /* Retake   the  segment   vector   because   memory  allocated   by
       "ik_mmap_code()" might  have caused the reallocation  of the page
       vectors. */
    gc->segment_vector = gc->pcb->segment_vector;
    {
      qupages_t *	qu = ik_malloc(sizeof(qupages_t));
      qu->p    = mem;
      qu->q    = mem+aligned_size;
      qu->next = gc->queues[meta_code];
      gc->queues[meta_code] = qu;
    }
    return mem;
  }
}

/* ------------------------------------------------------------------ */

static inline ikptr
meta_alloc (ik_ulong aligned_size, gc_t* gc, int meta_id)
/* Reserve enough room in the current meta page of type "meta_id" for an
   object of  size ALIGNED_SIZE  bytes.  Return a  pointer to  the first
   word of reserved space.

   If the meta page is full: allocate a new one. */
{
  assert(aligned_size == IK_ALIGN(aligned_size));
  meta_t *	meta = &gc->meta[meta_id];
  ikptr		ap   = meta->ap;		/* allocation pointer */
  ikptr		ep   = meta->ep;		/* end pointer */
  ikptr		nap  = ap + aligned_size;	/* new alloc pointer */
  if (nap > ep) {
    /* Not enough room. */
    return meta_alloc_extending(aligned_size, gc, meta_id);
  } else {
    /* Enough room. */
    meta->ap = nap;
    return ap;
  }
}
static ikptr
meta_alloc_extending (ik_ulong aligned_size, gc_t* gc, int meta_id)
/* Allocate one or move new meta  pages of type "meta_id", so that there
   is enough  room to hold  the data area  of an object  of ALIGNED_SIZE
   bytes.  Return a pointer to the first word of allocated memory. */
{
  static const int const EXTENSION_AMOUNT[meta_count] = {
    1 * IK_PAGESIZE,
    1 * IK_PAGESIZE,
    1 * IK_PAGESIZE,
    1 * IK_PAGESIZE,
    1 * IK_PAGESIZE,
    1 * IK_PAGESIZE,
  };
  ik_ulong	mapsize;
  meta_t *	meta;
  ikptr		mem;
  mapsize = IK_ALIGN_TO_NEXT_PAGE(aligned_size);
  if (mapsize < EXTENSION_AMOUNT[meta_id]) {
    mapsize = EXTENSION_AMOUNT[meta_id];
  }
  meta = &gc->meta[meta_id];
  /* If the  old meta pages are  not of type  raw data: store it  in the
     queues to be scanned by "collect_loop()". */
  if ((meta_id != meta_data) && meta->base) {
    ikptr	aq = meta->aq;
    ikptr	ap = meta->ap;
    ikptr	ep = meta->ep;
    { /* Register the old meta pages  to be scanned by "collect_loop()";
	 only the portion actually used needs to be registered. */
      qupages_t *	qu  = ik_malloc(sizeof(qupages_t));
      qu->p    = aq;
      qu->q    = ap;
      qu->next = gc->queues[meta_id];
      gc->queues[meta_id] = qu;
    }
    { /* Reset to zero all the unused words in the old meta pages. */
      ikptr	X;
      for (X=ap; X<ep; X+=wordsize) {
	IK_REF(X, 0) = 0;
      }
    }
  }
  /* Allocate one or more new meta pages. */
  mem = ik_mmap_typed(mapsize, META_MT[meta_id] | gc->collect_gen_tag, gc->pcb);
  /* Retake   the   segment   vector   because   memory   allocated   by
     "ik_mmap_typed()" might  have caused  the reallocation of  the page
     vectors. */
  gc->segment_vector = gc->pcb->segment_vector;
  /* Store references to  the new meta pages in the  GC struct.  Reserve
     ALIGNED_SIZE bytes for the object. */
  meta->ap   = mem + aligned_size;	/* alloc pointer */
  meta->aq   = mem;			/* beginning of allocated meta pages */
  meta->ep   = mem + mapsize;		/* end pointer */
  meta->base = mem;			/* beginning of allocated meta pages */
  return mem;
}


/** --------------------------------------------------------------------
 ** Collect loop.
 ** ----------------------------------------------------------------- */

static void
collect_loop (gc_t* gc)
/* The  garbage collector  main  function scans  the garbage  collection
   roots  and moves  the live  Scheme objects  into newly  allocated (or
   recycled) generational pages referenced by the PCB's segments vector.

     The objects in the new pages have to be scanned, too, to keep alive
   referenced Scheme  objects; this is  what this function  does.  Every
   tagged  pointer found  while scanning  a new  page references  a live
   object: such object must itself be  moved to a new generational page,
   and so on recursively.

     After calling one or  multiple time "gather_live_object()" at least
   one call  to this function must  be performed.  This function  can be
   called any number of times.

     The new generational pages are  also referenced by the "queues" and
   "meta" fields  of the GC struct.   The "meta" pages are  half filled,
   while  the "queues"  pages are  full of  machine words  that must  be
   scanned. */
{
  int	done;
  do {
    done = 1;

    /* First iterate  over all the  nodes in the "queues"  linked lists,
       until there are no more of them. */

    /* Scan the pending  pair pages.  QU references the first  node in a
       simply linked list  of structures; each node  references a memory
       range in  which live  Scheme pairs  are stored;  we want  to keep
       alive the cars  of such pairs.  After scanning QU  we pop it from
       the linked  list and  process the  next node,  until the  list is
       empty. */
    {
      qupages_t *	qu = gc->queues[meta_pair];
      if (qu) {
	/* There is at least one  node in the "queues[meta_pair]" field:
	   we will have to perform another full iteration. */
        done = 0;
	/* Remove  the  list   from  the  GC  struct.    Every  call  to
	   "gather_live_object()" in this function  might push new nodes
	   in the "queues[meta_pair]" field; we will process these nodes
	   later.  If no new  nodes are pushed: "queues[meta_pair]" will
	   be left NULL. */
        gc->queues[meta_pair] = NULL;
        do {
          ikptr p_pair = qu->p;
          ikptr p_end  = qu->q;
          for (; p_pair < p_end; p_pair += pair_size) {
            IK_REF(p_pair, disp_car) = gather_live_object(gc, IK_REF(p_pair, disp_car), "loop");
	  }
          qupages_t * next = qu->next;
          ik_free(qu, sizeof(qupages_t));
          qu = next;
        } while (qu);
      }
    }

    /* Scan the pending pointer pages.   QU references the first node in
       a simply linked list of structures; each node itself references a
       memory  range in  which  tagged pointers  to  Scheme objects  are
       stored.  We want to keep alive such objects. */
    {
      qupages_t *	qu = gc->queues[meta_ptrs];
      if (qu) {
	/* There is at least one  node in the "queues[meta_ptrs]" field:
	   we will have to perform another full iteration. */
        done = 0;
	/* Remove  the  list   from  the  GC  struct.    Every  call  to
	   "gather_live_object()" in this function  might push new nodes
	   in the "queues[meta_ptrs]" field; we will process these nodes
	   later.  If no new  nodes are pushed: "queues[meta_ptrs]" will
	   be left NULL. */
        gc->queues[meta_ptrs] = NULL;
        do {
          ikptr p_word = qu->p;
          ikptr p_end  = qu->q;
          for (; p_word < p_end; p_word += wordsize) {
            IK_REF(p_word, 0) = gather_live_object(gc, IK_REF(p_word, 0), "pending");
          }
          qupages_t * next = qu->next;
          ik_free(qu, sizeof(qupages_t));
          qu = next;
        } while (qu);
      }
    }

    /* Scan the pending symbols pages.   QU references the first node in
       a simply linked list of structures; each node itself references a
       memory  range in  which  tagged pointers  to  Scheme objects  are
       stored.  We want to keep alive such objects. */
    {
      qupages_t *	qu = gc->queues[meta_symbol];
      if (qu) {
	/* There  is  at least  one  node  in the  "queues[meta_symbol]"
	   field: we will have to perform another full iteration. */
        done = 0;
	/* Remove  the  list   from  the  GC  struct.    Every  call  to
	   "gather_live_object()" in this function  might push new nodes
	   in  the "queues[meta_symbol]"  field; we  will process  these
	   nodes    later.     If    no   new    nodes    are    pushed:
	   "queues[meta_symbol]" will be left NULL. */
        gc->queues[meta_symbol] = NULL;
        do {
          ikptr p_word = qu->p;
          ikptr p_end  = qu->q;
          for (; p_word < p_end; p_word += wordsize) {
            IK_REF(p_word, 0) = gather_live_object(gc, IK_REF(p_word, 0), "symbols");
          }
          qupages_t *	next = qu->next;
          ik_free(qu, sizeof(qupages_t));
          qu = next;
        } while (qu);
      }
    }

    /* Scan the  pending code  objects pages.   QU references  the first
       node  in a  simply linked  list of  structures; each  node itself
       references  a memory  range in  which tagged  pointers to  Scheme
       objects are stored.  We want to keep alive such objects. */
    {
      qupages_t *	codes = gc->queues[meta_code];
      if (codes) {
	/* There is at least one  node in the "queues[meta_code]" field:
	   we will have to perform another full iteration. */
        done = 0;
	/* Remove  the  list   from  the  GC  struct.    Every  call  to
	   "gather_live_object()" in this function  might push new nodes
	   in the "queues[meta_code]" field; we will process these nodes
	   later.  If no new  nodes are pushed: "queues[meta_code]" will
	   be left NULL. */
        gc->queues[meta_code] = NULL;
        do {
          ikptr p_code = codes->p;
          ikptr p_end  = codes->q;
          while (p_code < p_end) {
            relocate_new_code(p_code, gc);
            alloc_code_count--;
            p_code += IK_ALIGN(disp_code_data + IK_UNFIX(IK_REF(p_code, disp_code_code_size)));
          }
          qupages_t *	next = codes->next;
          ik_free(codes, sizeof(qupages_t));
          codes = next;
        } while (codes);
      }
    }

    /* Then  iterate  over  all  the half-filled  pages  in  the  "meta"
       fields. */
    {
      {
        meta_t* meta = &gc->meta[meta_pair];
        ikptr p = meta->aq;
        ikptr q = meta->ap;
        if (p < q) {
	  /* There  is  at least  one  object  in the  "meta[meta_pair]"
	     field: we will have to perform another full iteration. */
          done = 0;
          do {
            meta->aq = q;
            for (; p < q; p += pair_size) {
              IK_REF(p,0) = gather_live_object(gc, IK_REF(p,0), "rem");
            }
            p = meta->aq;
            q = meta->ap;
          } while (p < q);
        }
      }
      {
        meta_t* meta = &gc->meta[meta_symbol];
        ikptr p = meta->aq;
        ikptr q = meta->ap;
        if (p < q) {
	  /* There  is at  least one  object in  the "meta[meta_symbol]"
	     field: we will have to perform another full iteration. */
          done = 0;
          do {
            meta->aq = q;
            for (; p < q; p += wordsize) {
              IK_REF(p,0) = gather_live_object(gc, IK_REF(p,0), "sym");
	    }
            p = meta->aq;
            q = meta->ap;
          } while (p < q);
        }
      }
      {
        meta_t* meta = &gc->meta[meta_ptrs];
        ikptr p = meta->aq;
        ikptr q = meta->ap;
        if (p < q) {
	  /* There  is  at least  one  object  in the  "meta[meta_ptrs]"
	     field: we will have to perform another full iteration. */
          done = 0;
          do {
            meta->aq = q;
            for (; p < q; p += wordsize) {
              IK_REF(p,0) = gather_live_object(gc, IK_REF(p,0), "rem2");
            }
            p = meta->aq;
            q = meta->ap;
          } while (p < q);
        }
      }
      {
        meta_t* meta = &gc->meta[meta_code];
        ikptr p = meta->aq;
        ikptr q = meta->ap;
        if (p < q) {
	  /* There  is  at least  one  object  in the  "meta[meta_code]"
	     field: we will have to perform another full iteration. */
          done = 0;
          do {
            meta->aq = q;
            do {
              alloc_code_count--;
              relocate_new_code(p, gc);
              p += IK_ALIGN(disp_code_data + IK_UNFIX(IK_REF(p, disp_code_code_size)));
            } while (p < q);
            p = meta->aq;
            q = meta->ap;
          } while (p < q);
        }
      }
    }
    /* phew */
  } while (! done);

  /* Reset to the  fixnum zero all the machine words  in the unused tail
     of  the   meta  pages.   This  is   just  in  case  this   call  to
     "collect_loop()" is the last one in this garbage collection run and
     the meta pages will not be touched anymore. */
  {
    int		i;
    for (i=0; i<meta_count; ++i) {
      uint8_t *	begin = (uint8_t *)gc->meta[i].ap; /* allocation pointer */
      uint8_t *	past  = (uint8_t *)gc->meta[i].ep; /* end pointer */
      memset(begin, 0, past - begin);
    }
  }
}


/** --------------------------------------------------------------------
 ** Scanning dirty pages.
 ** ----------------------------------------------------------------- */

/* Notice that:
 *
 *   CARDSIZE * CARDS_PER_PAGE = 4098 = IK_PAGESIZE
 */
#define CARDSIZE		512
#define CARDS_PER_PAGE		8

/* Every memory  page is divided into  8 cards, of 512  bytes each.  The
 * dirty vector has slots of 32 bits, a nibble of 4 bits for every card.
 *
 *   If a nibble  in the dirty vector is set  to zero: the corresponding
 * card  is clean,  it  has no  pointers to  Scheme  objects in  younger
 * generations.
 *
 *   If a  nibble in the dirty  vector is set to  0xF: the corresponding
 * card is  dirty, at least one  of its words  is a tagged pointer  to a
 * Scheme object in a younger generation.
 *
 *   Bit twiddling:
 *
 * - If CARD_DBITS is  a nibble of bits (in the  least significant bits)
 *   representing the  state of the  card at  index CARD_IDX in  a given
 *   page, the operation:
 *
 *      card_dbits << (card_idx * META_DIRTY_SHIFT)
 *
 *   shifts CARD_DBITS in  the nibble associated to the card  in a value
 *   for the dirty vector slots.
 */

#define SHIFT_NIBBLE_AT_CARD_SLOT(NIBBLE, CARD_IDX) \
  ((NIBBLE) << ((CARD_IDX) * META_DIRTY_SHIFT))

static const uint32_t DIRTY_MASK[IK_GC_GENERATION_COUNT] = {
  0x88888888,	/* #x8 = #b1000 */
  0xCCCCCCCC,	/* #xC = #b1100 */
  0xEEEEEEEE,	/* #xE = #b1110 */
  0xFFFFFFFF,	/* #xF = #b1111 */
  0x00000000
};

static const uint32_t CLEANUP_MASK[IK_GC_GENERATION_COUNT] = {
  0x00000000,
  0x88888888,
  0xCCCCCCCC,
  0xEEEEEEEE,
  0xFFFFFFFF
};

static void scan_dirty_code_page     (gc_t* gc, ik_ulong page_idx);
static void scan_dirty_pointers_page (gc_t* gc, ik_ulong page_idx, uint32_t mask);

static void
scan_dirty_pages (gc_t* gc)
/* Iterate over the dirty vector and  operate on all the pages marked as
   dirty.  The problem solved by marking pages as dirty is: what happens
   when a Scheme object in an older generation is mutated to reference a
   Scheme  object in  a newer  generation?  How  can the  younger object
   survive a garbage  collection if the only reference to  it is from an
   older object?

   A  "dirty" page  is a  memory page  holding the  data area  of Scheme
   objects  themselves composed  of immediate  Scheme objects  or tagged
   pointers (pairs, vectors, structs, records, compnums, cflonums); such
   page becomes dirty when a word is mutated at run-time.
*/
{
  ikpcb *	pcb         = gc->pcb;
  ik_ulong	lo_idx      = IK_PAGE_INDEX(pcb->memory_base);
  ik_ulong	hi_idx      = IK_PAGE_INDEX(pcb->memory_end);
  uint32_t *	dirty_vec   = (uint32_t*)pcb->dirty_vector;
  uint32_t *	segment_vec = pcb->segment_vector;
  uint32_t	collect_gen = gc->collect_gen;
  uint32_t	mask        = DIRTY_MASK[collect_gen];
  ik_ulong	page_idx;
  for (page_idx = lo_idx; page_idx < hi_idx; ++page_idx) {
    if (dirty_vec[page_idx] & mask) {
      uint32_t page_bits               = segment_vec[page_idx];
      uint32_t page_generation_number  = page_bits & GEN_MASK;
      if (page_generation_number > collect_gen) {
        uint32_t type = page_bits & TYPE_MASK;
        if (type == POINTERS_TYPE) {
          scan_dirty_pointers_page(gc, page_idx, mask);
          dirty_vec   = (uint32_t*)pcb->dirty_vector;
          segment_vec = pcb->segment_vector;
        }
        else if (type == SYMBOLS_TYPE) {
          scan_dirty_pointers_page(gc, page_idx, mask);
          dirty_vec   = (uint32_t*)pcb->dirty_vector;
          segment_vec = pcb->segment_vector;
        }
        else if (type == WEAK_PAIRS_TYPE) {
          scan_dirty_pointers_page(gc, page_idx, mask);
          dirty_vec   = (uint32_t*)pcb->dirty_vector;
          segment_vec = pcb->segment_vector;
        }
        else if (type == CODE_TYPE) {
          scan_dirty_code_page(gc, page_idx);
          dirty_vec   = (uint32_t*)pcb->dirty_vector;
          segment_vec = pcb->segment_vector;
        }
        else if (page_bits & SCANNABLE_MASK) {
          ik_abort("unhandled dirty scan for page with segment bits 0x%08x", page_bits);
	}
      }
    }
  }
}
static void
scan_dirty_pointers_page (gc_t* gc, ik_ulong page_idx, uint32_t mask)
/* Subroutine of "scan_dirty_pages()".  It is  used to scan a dirty page
   containing  the data  area of  Scheme objects  composed of  immediate
   objects or tagged pointers, but not code objects.

   NOTE This function might  call "gather_live_object()", which means it
   might allocate  memory, which means:  after every call the  dirty and
   segments vector might have been reallocated. */
{
  uint32_t	new_page_dbits = 0;
  {
    uint32_t *	segment_vec  = gc->segment_vector;
    uint32_t *	dirty_vec    = (uint32_t*)gc->pcb->dirty_vector;
    uint32_t	page_dbits   = dirty_vec[page_idx];
    uint32_t	masked_dbits = page_dbits & mask;
    ikptr	word_ptr     = IK_PAGE_POINTER_FROM_INDEX(page_idx);
    uint32_t	card_idx;
    for (card_idx=0; card_idx<CARDS_PER_PAGE; ++card_idx) {
      if (masked_dbits & SHIFT_NIBBLE_AT_CARD_SLOT(0xF, card_idx)) {
	/* This is a dirty card: let's process its words. */
	uint32_t	card_sbits = 0;
	ikptr		card_end   = word_ptr + CARDSIZE;
	for (; word_ptr < card_end; word_ptr += wordsize) {
	  ikptr X = IK_REF(word_ptr, 0);
	  if (IK_IS_FIXNUM(X) || (IK_TAGOF(X) == immediate_tag)) {
	    /* do nothing */
	  } else {
	    ikptr Y = gather_live_object(gc, X, "nothing");
	    /* The call  to "gather_live_object()" might  have allocated
	       new memory, so we must retake the segment vector. */
	    segment_vec = gc->segment_vector;
	    IK_REF(word_ptr, 0) = Y;
	    card_sbits |= segment_vec[IK_PAGE_INDEX(Y)];
	  }
	}
	card_sbits      = (card_sbits & META_DIRTY_MASK) >> META_DIRTY_SHIFT;
	new_page_dbits |= SHIFT_NIBBLE_AT_CARD_SLOT(card_sbits, card_idx);
      } else {
	/* This is a pure card: let's skip to the next card. */
	word_ptr       += CARDSIZE;
	new_page_dbits |= page_dbits & SHIFT_NIBBLE_AT_CARD_SLOT(0xF, card_idx);
      }
    }
  }
  /* Update the dirty vector bits for this page. */
  {
    uint32_t	page_sbits  = gc->segment_vector[page_idx];
    uint32_t *	dirty_vec   = (uint32_t*)gc->pcb->dirty_vector;
    dirty_vec[page_idx] = new_page_dbits & CLEANUP_MASK[page_sbits & GEN_MASK];
  }
}
static void
scan_dirty_code_page (gc_t* gc, ik_ulong page_idx)
/* Subroutine of "scan_dirty_pages()".  It is  used to scan a dirty page
   containing the data area of Scheme code objects.

   NOTE This function might  call "gather_live_object()", which means it
   might allocate  memory, which means:  after every call the  dirty and
   segments vector might have been reallocated. */
{
  uint32_t	new_page_dbits  = 0;
  {
    ikptr	page_start  = IK_PAGE_POINTER_FROM_INDEX(page_idx);
    ikptr	page_end    = page_start + IK_PAGESIZE;
    ikptr	p_code      = page_start; /* untagged pointer to code object */
    /* Iterate over all the code objects in the page. */
    while (p_code < page_end) {
      if (IK_REF(p_code, 0) != code_tag) {
	p_code = page_end;
      } else {
	uint32_t *	segment_vec;
	ikptr		s_reloc_vec;
	ikptr		s_reloc_vec_len;
	long		card_idx    = ((ik_ulong)p_code - (ik_ulong)page_start) / CARDSIZE;
	uint32_t	code_dbits;
	relocate_new_code(p_code, gc);
	/* The call  to "relocate_new_code()"  might have  allocated new
	   memory, so we must take the segment vector after it. */
	segment_vec     = gc->segment_vector;
	s_reloc_vec     = IK_REF(p_code, disp_code_reloc_vector);
	s_reloc_vec_len = IK_VECTOR_LENGTH_FX(s_reloc_vec);
	code_dbits      = segment_vec[IK_PAGE_INDEX(s_reloc_vec)];
	/* Iterate over the words in the relocation vector. */
	for (ik_ulong i=0; i<s_reloc_vec_len; i+=wordsize) {
	  ikptr		s_item = IK_REF(s_reloc_vec, i+off_vector_data);
	  if (IK_IS_FIXNUM(s_item) || (IK_TAGOF(s_item) == immediate_tag)) {
	    /* do nothing */
	  } else {
	    s_item = gather_live_object(gc, s_item, "nothing2");
	    /* The call  to "gather_live_object()" might  have allocated
	       new memory,  so we must  retake the segment  vector after
	       it. */
	    segment_vec	= gc->segment_vector;
	    code_dbits	|= segment_vec[IK_PAGE_INDEX(s_item)];
	  }
	}
	new_page_dbits	|= SHIFT_NIBBLE_AT_CARD_SLOT(code_dbits, card_idx);
	{ /* Increment "p_code" to reference the next code object in the
	     page. */
	  long	code_size = IK_UNFIX(IK_REF(p_code, disp_code_code_size));
	  p_code += IK_ALIGN(code_size + disp_code_data);
	}
      }
    }
  }
  /* Update the dirty vector bits for this page. */
  {
    uint32_t *	segment_vec = gc->segment_vector;
    uint32_t	page_sbits  = segment_vec[page_idx];
    uint32_t *	dirty_vec   = (uint32_t *)gc->pcb->dirty_vector;
    dirty_vec[page_idx] = new_page_dbits & CLEANUP_MASK[page_sbits & GEN_MASK];
  }
}


/** --------------------------------------------------------------------
 ** Miscellaneous functions.
 ** ----------------------------------------------------------------- */

static void
relocate_new_code (ikptr p_X, gc_t* gc)
/* Process  the relocation  vector of  a code  object.  p_X  must be  an
  *untagged* pointer referencing the code object.

  This function has similarities with "ik_relocate_code()". */
{
  const ikptr	s_reloc_vec = gather_live_object(gc, IK_REF(p_X, disp_code_reloc_vector), "relocvec");
  IK_REF(p_X, disp_code_reloc_vector) = s_reloc_vec;
  IK_REF(p_X, disp_code_annotation)   = gather_live_object(gc, IK_REF(p_X, disp_code_annotation),
							   "annotation");
  /* The variable P_RELOC_VEC_CUR is an  *untagged* pointer to the first
     word in the data area of the relocation vector VEC. */
  ikptr		p_reloc_vec_cur = s_reloc_vec + off_vector_data;
  /* The variable P_RELOC_VEC_END  is an *untagged* pointer  to the word
     right after the data area of the relocation vector VEC.

     Remember  that the  fixnum representing  the number  of items  in a
     vector, taken as "long", also represents the number of bytes in the
     data area. */
  const ikptr	p_reloc_vec_end = p_reloc_vec_cur + IK_VECTOR_LENGTH_FX(s_reloc_vec);
  /* The variable P_DATA is an  *untagged* pointer referencing the first
     byte in the data area of the code object. */
  const ikptr	p_data = p_X + disp_code_data;
  /* Scan the records in the relocation vector. */
  while (p_reloc_vec_cur < p_reloc_vec_end) {
    const long	first_record_bits = IK_UNFIX(IK_RELOC_RECORD_1ST(p_reloc_vec_cur));
    const long	reloc_record_tag  = IK_RELOC_RECORD_1ST_BITS_TAG(first_record_bits);
    const long	disp_code_word    = IK_RELOC_RECORD_1ST_BITS_OFFSET(first_record_bits);
    switch (reloc_record_tag) {
    case IK_RELOC_RECORD_VANILLA_OBJECT_TAG: {
      /* This record represents a vanilla object; this record is 2 words
	 wide. */
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
      fprintf(stderr, "r=0x%08x disp_code_word=%d reloc_size=0x%08x\n",
	      first_record_bits, disp_code_word, IK_VECTOR_LENGTH_FX(s_reloc_vec));
#endif
      ikptr	s_old_object = IK_RELOC_RECORD_2ND(p_reloc_vec_cur);
      ikptr	s_new_object = gather_live_object(gc, s_old_object, "reloc1");
      IK_REF(p_data, disp_code_word) = s_new_object;
      p_reloc_vec_cur += (2*wordsize);
      break;
    }
    case IK_RELOC_RECORD_DISPLACED_OBJECT_TAG: {
      /* This record  represents a  displaced object;  this record  is 3
	 words wide. */
      long	obj_off      = IK_UNFIX(IK_RELOC_RECORD_2ND(p_reloc_vec_cur));
      ikptr	s_old_object =          IK_RELOC_RECORD_3RD(p_reloc_vec_cur);
      ikptr	s_new_object = gather_live_object(gc, s_old_object, "reloc2");
      IK_REF(p_data, disp_code_word) = s_new_object + obj_off;
      p_reloc_vec_cur += (3 * wordsize);
      break;
    }
    case IK_RELOC_RECORD_JUMP_LABEL_TAG: {
      /* This record  represents a  jump label; this  record is  3 words
	 wide. */
      long	obj_off = IK_UNFIX(IK_RELOC_RECORD_2ND(p_reloc_vec_cur));
      ikptr	s_obj   =          IK_RELOC_RECORD_3RD(p_reloc_vec_cur);
#if ((defined VICARE_DEBUGGING) && (defined VICARE_DEBUGGING_GC))
      fprintf(stderr, "obj=0x%08x, obj_off=0x%08x\n", (int)s_obj, obj_off);
#endif
      s_obj = gather_live_object(gc, s_obj, "reloc3");
      ikptr	displaced_object  = s_obj + obj_off;
      long	next_word         = p_data + disp_code_word + 4;
      ikptr	relative_distance = displaced_object - (long)next_word;
      if (((long)relative_distance) != ((long)((int)relative_distance)))
        ik_abort("relocation error with relative=0x%016lx", relative_distance);
      *((int*)(p_data + disp_code_word)) = (int)relative_distance;
      p_reloc_vec_cur += (3*wordsize);
      break;
    }
    case IK_RELOC_RECORD_FOREIGN_ADDRESS_TAG: {
      /* This record represents a foreign object; this record is 2 words
	 wide.  Do nothing. */
      p_reloc_vec_cur += (2 * wordsize);
      break;
    }
    default:
      ik_abort("invalid relocation record tag %ld in 0x%016lx",
	       reloc_record_tag, first_record_bits);
      break;
    } /* end of switch() */
  } /* end of while() */
}
static void
register_to_collect_count (ikpcb* pcb, int bytes)
/* This is  for accounting  purposes.  We  keep count  of all  the bytes
 * allocated for the heap, so that:
 *
 *   total_allocated_bytes = \
 *     IK_MOST_BYTES_IN_MINOR * pcb->allocation_count_major
 *     + pcb->allocation_count_minor
 *
 * both minor and major counters must fit into a fixnum.  These counters
 * are used by Scheme procedures like "time-it" and "time-and-gather".
 */
{
  int	minor = bytes + pcb->allocation_count_minor;
  while (minor >= IK_MOST_BYTES_IN_MINOR) {
    minor -= IK_MOST_BYTES_IN_MINOR;
    pcb->allocation_count_major++;
  }
  pcb->allocation_count_minor = minor;
}

/* end of file */
