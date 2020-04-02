
#include <stdio.h>
#include <stdlib.h>

#define total 317080
struct graph
{
    struct node **list;
};

struct node 
{
   struct node *next;
    int val;
};

struct objects
{
    int len;
    int author;
};

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

void
printGraph(struct graph* g)
{
    int v;
    for (v = 0; v < total; v++)
    {
        struct node* temp = g->list[v];
        printf("\n Adjacency list of vertex %d\n ", v);
        while (temp)
        {
            printf("%d -> ", temp->val);
            temp = temp->next;
        }
        printf("\n");
    }
}

void
add_edge(struct graph *g, int x, int y)
{
    struct node *newnode = malloc(sizeof(struct node));
    newnode->val = y; 
    newnode->next = g->list[x];
    g->list[x] = newnode;
    
    
    newnode = malloc(sizeof(struct node));
    newnode->val = x; 
    newnode->next = g->list[y];
    g->list[y] = newnode;
}

struct graph* 
create_graph()
{
    struct graph *g = malloc(total*sizeof(struct graph));
    g->list = malloc(total*sizeof(struct node*));
    
    for(int i=0; i<total; i++)
    {
        g->list[i] = NULL;
    }
    return g;
}
struct objects*
find_length(struct graph *g)
{
    //int *len = malloc(total*sizeof(int));
    struct objects *obj = malloc(total * sizeof(struct objects));
    int l;

    for(int i=0; i<total; i++)
    {
        l = 0;
       struct node *temp = g->list[i];
        while(temp != NULL)
        {
            temp = temp->next;
            l++;
        }
        obj[i].len = l;
        obj[i].author = i+1;
    }
    return obj;
}

int main()
{
    FILE *in = fopen("dblp-co-authors.txt", "r");
    int x, y;
    char name[52];
    for(int i=0; i<5; i++)
        fgets(name, 52, in);
    struct graph *g = create_graph();
    while(fscanf(in, "%d %d", &x, &y) == 2)
    {
        add_edge(g, x-1, y-1);
    }
    
    struct objects *obj = find_length(g);
    qsort(obj, total, sizeof(obj[0]), comparator);

    //int len = find_length(g->list[3335]);
    //printGraph(g);
    printf("len = %d, author = %d\n", obj[0].len, obj[0].author);
    return 0;
}
