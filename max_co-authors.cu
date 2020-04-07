
#include <stdio.h>
#include <stdlib.h>

#define total 317080
#define N 2099732

extern __managed__ int *list;

struct objects
{
    int len;
    int author;
};
extern __managed__ struct objects *pair;

int comparator (const void * a, const void * b)
{
    struct objects *a1 = (struct objects *)a;
    struct objects *a2 = (struct objects *)b;
    if ((*a1).len > (*a2).len)
        return -1;
    else if ((*a1).len < (*a2).len)
        return 1;
    else
        return 0;
}
/*
int comparator (const void* p1, const void* p2)
{ 
     return (*(int*)p2 - *(int*)p1);    
}
*/

__global__ void co_authors(int *list, struct objects *pair)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    {
        for (int i = index; i < N; i += stride)
        {
            int index1 = list[i]-1;
            pair[index1].author = index1+1;
            atomicAdd(&(pair[index1].len), 1);
        }
    }
}

int main()
{
    FILE *in = fopen("authors.txt", "r");
    int x, y;
   cudaMallocManaged(&list, 2099732*sizeof(int), (unsigned int)cudaMemAttachGlobal);
   cudaMemAdvise(list, 2099732*sizeof(int), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);

   cudaMallocManaged(&pair, 317080*sizeof(struct objects), (unsigned int)cudaMemAttachGlobal);
   cudaMemAdvise(pair, 317080*sizeof(struct objects), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);
  
    char name[52];
    for(int i=0; i<5; i++)
        fgets(name, 52, in);

    int index = 0;
    while(fscanf(in, "%d %d", &x, &y) == 2)
    {
        list[index] = x;
        list[index+1] = y;
        index = index + 2;
    }
    
    int blockSize = 256;
    int numBlocks = (N + blockSize - 1) / blockSize;

    printf("first = %d, last = %d\n", list[0], list[2099731]);
 
   
    co_authors<<<numBlocks,blockSize>>>(list, pair);
    cudaDeviceSynchronize();
    
    qsort(pair, total, sizeof(pair[0]), comparator);
    printf("len1 = %d,  author = %d\n", pair[0].len, pair[0].author);
      
    return 0;
}
