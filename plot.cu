#include <stdio.h>
#include <stdlib.h>
#define total 317080
#define N 2099732

extern __managed__ int *list;
extern __managed__ int *plot_data;

// A structure to hold a pair of data (in this case, the author number and the corresponding number of co-authors)
struct objects
{
    int len;
    int author;
};
extern __managed__ struct objects *pair;

// eomparator function to sort the object structure so that we retain the author number as we start based on the number of co-authors
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

// this CUDA kernel calculates the number of co-authors for each author in parallel
__global__ void co_authors(int *list, struct objects *pair)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < N; i += stride)
      {
          int index1 = list[i]-1;
          pair[index1].author = index1+1;
          atomicAdd(&(pair[index1].len), 1);
      }
}

// Kernel to generate the data to plot (the number of authors with exactly "d" number of co-authors) in parallel
__global__ void plot(struct objects *pair, int *plot_data)
{
     int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < total; i += stride)
      {
        int index1 = pair[i].len;
        atomicAdd(&(plot_data[index1]), 1);
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

   // open the file read the contents and store them in an array (list)
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
    
    // Number of threads is 256 and number of blocks is calculated based on that
    int blockSize = 256;
    int numBlocks = (N + blockSize - 1) / blockSize;

   // Calculate the number of co-authors and it will be stored in the pair
    co_authors<<<numBlocks,blockSize>>>(list, pair);
    cudaDeviceSynchronize();
   
    // sort the pair structure
    qsort(pair, total, sizeof(pair[0]), comparator); 

    // print all those authors who have the maximum number of co-authors
    int max = pair[0].len;
    int i = 0;
    while(pair[i].len == max)
    {
        printf("Maximum number of co-authors = %d,  Author = %d\n", pair[i].len, pair[i].author);
        i++;
    }

   cudaMallocManaged(&plot_data, max+1*sizeof(int), (unsigned int)cudaMemAttachGlobal);
   cudaMemAdvise(plot_data, max+1*sizeof(int), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);

    // call plot CUDA kernel that generates the data to plot and stores them in the plot_data array
    numBlocks = (total + blockSize - 1) / blockSize;
    plot<<<numBlocks, blockSize>>>(pair, plot_data);
    cudaDeviceSynchronize();

    // write the contents in the plot_data array to an output file
    FILE *out = fopen("output.txt", "w");
    for(int i=0; i<max; i++)
    {
        fprintf(out, "%d  %d\n", i, plot_data[i]);
    }
        return 0;
 
}
