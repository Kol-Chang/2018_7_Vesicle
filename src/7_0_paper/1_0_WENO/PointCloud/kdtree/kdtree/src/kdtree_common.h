// Guy Shechter
// October 20013
// 
// Uncomment one of these includes depending on your architecture.
// Your installation location may vary.
//
//
// For Linux use this line:
//
//#include "/usr/local/MATLAB/R2018a/extern/include/mex.h"
#include "/cm/shared/uaapps/matlab/r2018b/extern/include/mex.h"
//
//
// For Windows systems use this line:
//
//#include "c:\matlab_r2013b\extern\include\mex.h"
//
//
// For Mac Os X systems use this line :
//
//#include "/Applications/MATLAB_R2018a.app/extern/include/mex.h"
//
//



//
// Some Constants
//
#define RETURN_POINTS 101
#define RETURN_INDEX  102

//
//  Some Macros to make the code more readable 
//

#define EVAL_INDEX(X,Y,L) (reference[ (Y)*(L) +(X)])
int swap_tmp_int;
#define INT_SWAP(X,Y)  swap_tmp_int=X; X=Y; Y=swap_tmp_int;


//
//   The definition of a node in the k-d tree.
//
typedef struct node {
  double *pt;
  int orientation;
  unsigned int index;
  struct node *left, *right;
} Node;

//
//   The definition of the Tree root node
//
typedef struct tree {
  struct node *rootptr;
  int dims;
} Tree;



//
// Timing structures used to for debuging purposes
//
typedef struct timevalg {
  long    tv_sec;        /* seconds since Jan. 1, 1970 */
  long tv_usec;       /* and microseconds */
} TV;
typedef struct timezone {
  int  tz_minuteswest;     /* of Greenwich */
  int  tz_dsttime;    /* type of dst correction to apply */
} TZ;


/* PROTOTYPE DECLARATIONS */
double calcdistance  (double *pt1, double *pt2, int Dim);
Node*  rangeQuery    (Node *v, double distance, double *pt, int D);
Node*  pointLocation (Node *v, double *pt, int D);
void   display_tree  (Node *nodeptr, int D);
void   run_queries   (Node *pVertex, double *model, int M, int D, 
		      double *closest_pt, double *distance, short ReturnType);
void   free_tree     (Node *pVertex);
Tree*  build_kdtree  (double *reference, int N, int D, int *index, 
		      int L, int offset);
Node *build_kdtree_core (double *reference, int N, int D, int *index, 
			 int L, int offset);
void   quicksort     (int *ra, int p, int r, double *reference, 
		      int offset, int D);
int    partition     (int *a,  int p, int r, double *reference, 
		      int offset, int D);
void   run_range_search (Node *pVertex, double *model, int M, int D, 
			 double distlim, double **pts_in_range, unsigned int *L, 
			 unsigned int **indices);