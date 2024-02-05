---
layout: post
title: Randomized Exact Median
tags:   [median, randomized-algorithm]
---

Median finding problem is easy to describe. In a given set of numbers of size say $n$, it is simply finding a $(n/2)^{th}$ largest element. Efficient (linear time) deterministic algorithm for solving this problem have been there for a while. Asymptotically we have achieved the best we could, but when processing large data set constant improvements makes a difference. When we say large data set one should not limit the count to few thousands, but it can be thought on the scales of applications used by statistician and machine learning folks - millions and trillions. Generally speaking, for problems like sorting and median finding, number of comparisons becomes a leading measure for comparing the running time as it turns out to be the major operation in solving the problem. So now when we ask how fast we can find the median element, we would mean to optimise the number of comparisons the algorithm would take.

## DETERMINISTIC ALGORITHM AND ITS MEASURE

In 1985 Bent and John in a paper titled "Finding the median requires $2n$ comparisons" proved that any deterministic algorithm that solves the median finding algorithm would need at least $2n$ comparisons, where $n$ is the size of input set of numbers. Later in 2001 Dor D, Håstad, Ulfberg & Zwick reformulated it in a paper titled "On lower bounds for selecting the median".

Quick-Select is one of best known median finding algorithm which works very similar to Quick-Sort and takes $2.75n+o(n)$ comparisons on average. Later after presenting randomized algorithm for median finding lookout for the comparison with Quick-Select.

## MOTIVATION AND INTUITION

The algorithm which will be presented ahead takes its shape from a simple question. What if we could narrow down our search domain to find median element? Suppose we could do that with absolute guarantee then probably we could hope to use our favorite deterministic algorithm like Quick-Select to find the median. Now this isn't the end, as that just raises more questions, like -

- How much smaller our search space need to improve over number of comparisons required in usual way of finding median?
- What would be the overhead of this preprocessing?

Well, all in due time. But to realise that we can really narrow down of search space with a good guarantee we lookout for approximate version of this algorithm. Now suppose we randomly pick $k$ elements from an array $A[0,\dots,n-1]$, sort it and can call it $S$. Median of those $k$ elements, let's refer it by $e$, has a rank in the range $\left[\frac{n}{4},\frac{3n}{4} \right]$ in array $X$ with probability $1-\left(\frac{1}{2}\right)^{k/5}$. This means if we appropriately choose value $k$ (not way up in the sky nor too grounded) we will have an element which is will be close to median element in $X$, sorted version of $A$. To give you a prospective, suppose $n = 1000$ and we choose $k=100$ then the median of $k$ elements will be in the expected range with a guarantee of $99.99\%$. Now we could hope to get somewhere with this considering the scale of data on which we want to solve the problem.

Suppose we consider two elements around the element $e$ in $S$ and refer them as $u$ and $v$. Now, if we partition the array $A$ in a way that all elements less than $u$ are on its left, all elements greater than $v$ are on its right and all those which are greater than $u$ but less than $v$ are in between the two. If we make are choice for $u$ and $v$ right, then the median of $A$ must be within $u$ and $v$ after this partitioning. Now we may simply consider to sort elements within $u$ and $v$ to get the median element or we may also opt for better alternative, as discussed later.

## Multi- Partition

Partitioning of array simply means that we re-arrange the elements of that array under some constraints. For instance we can partition an array around an element such that all elements less than are on its left and remaining on the right. This idea is the backbone of a widely use sorting algorithm - QuickSort. A similar idea would also would be an integral part of main algorithm we will be presenting later. We call it Multi-Partition as it partition the given array not just around one but two (or more, if generalized) elements. 

The algorithm is provided with an array we want to partition, and three elements $e$, $u$ and $v$. Where, $e$ is the median of the sorted random sample $S$, $u$ is an element from to the left of $e$ and $v$ from the right. Now we partition the array around $e$ using usual partitioning approach. And from discussion in previous section we know it is suppose to be very close to the actual median we are searching. Use this partition as a clue and see if its rank after partitioning is more than $n/2$ or less than that. Suppose it is more than $n/2$ then we partition the left side elements (which are less than $e$) around $u$. If its less than $n/2$ then we partition the right side of elements (which are more than $e$) around $v$. We do this slightly intricate step to ensure that at the end of the procedure we can hope to find the median element within $e$ and $u$ or $e$ and $v$ based on rank of $e$.

Notice that we could have simply partitioned around $u$ and $v$, that too just by running two instance of regular partitioning algorithm. But we take a subtle route to optimize the procedure that reduces the number of comparisons. To justify our choice of partition around $e$, realise that it supposedly closest to the median element in input array, as discuss in previous section. As to why we are not simply using usual partitioning algorithm twice, you have to wait until the analysis part.

```
MULTI-PARTITION(A, e, u, v)
n = A.length()
PARTITION(A[1...n],e)
if rank(e,A) < n/2
    PARTITION(A[rank(e,A)...n],v)
    u = e
else
    PARTITION(A[0...rank(e,A)],u)
    v = e
```

Notice the renaming of variables on line $x$ and $y$. It is done for the sake of explanation, as it will be clear later.

Well without getting into the detailed analysis on number comparisons we can sketch it roughly and that would suffice.  Now, the `PARTITION`  function is simply borrowed from the one used in Quick Sort. Number of comparison done by this function is the size of the array on which the partition is perform. Since, $rank(e,A)$ will be in the range $[n/4,3n/4]$, number of comparisons required for second partition will be at most $3n/4$. In total with very high probability the number of comparisons needed by this procedure is at most $7n/4$. Later with are more sophisticated choice of parameters this will even reduce and becomes closer and closer to $3n/2$.

## Randomized Exact Median Algorithm

With `MULTI-PARTITION` at its core, we present the complete algorithm to find the median of input array.

```
EXACT-MEDIAN(A)
S = RANDOM-SAMPLE(A,k)
QUICKSORT(S,0,k-1)
Let e be the median of S.
Let u and v be elements of S, g elements away from e.
MULTI-PARTITION(A,e,u,v)
QUICKSORT(A,rank(u,A)+1,rank(v,A)-1)
return A[n/2]
```

#### Explanation

There are two parameters $k$ which would be the size of sample we will pick from input array and $g$ which is the number of elements between $u$ and $e$ and similarly $e$ and $v$. We will be choosing them later, for now lets just assume them to be there. After random sampling we are sorting the array so as to quickly pick $e$, $u$ and $v$. Then we use the `MULTI-PARITION` which would partition the array in a way that all elements less than $u$ are on its left, all elements greater than $v$ are on its right and the remaining in between. Remember that in `MULTI-PARTITION` we renamed in a way that after this procedure we could hope that the median should be in between $u$ and $v$. Hence, we simply sort everything that is in between them and return the median.

### Parameter

It better readability we will just try to justify our choice of parameter to some extent. One may prefer to experiment with implemented code to find a suitable parameter as we also did, and that would also suffice the purpose of this post. Now first lets recall few notations and assign a few new ones - 

- k: It is the size of random sample we choose from input array.
- g: It is the gap of number of elements between the median of random sample $e$ and $u$, similarly $v$.
- $\ell$: Number of elements between $u$ and $v$ in input array after `MULTI-PARTITION` step.

With `MULTI-PARTITION` taking at most $1.75n$ comparisons, we know the entire procedure would take atmost

$$1.75n + \underbrace{k \log k}_{QuickSort Sample} + \overbrace{\ell \log \ell}^{QuickSort}$$

That gives us a direction that our choice of $k$ and $\ell$ needs a balancing, so as to reduce the overall number of comparison. A stricter analysis involving $g$ would reveal that $k$ are $\ell$ are inversely proportional, but we just leave it here as a note. Emphatically, it can be validated that if we choose $k = n^{2/3}$ then the rank of median of random sample in the input array is much stricter than $[n/4,2n/4]$. Which reduces our estimate of $1.75n$ comparisons in `MULTI-PARTITION` considerably.

We don't want the gap of $u$ and $v$ from $e$ to be too much, as that would mean that $\ell \log \ell$ would increase which we really don't want. Indicating our choice of $g$ has impact on $\ell$, hence we arbitrarily pick $g = n^{1/3}$.

### Obvious Improvement
QUICKSELECT(S,0,k-1,n/2)
Sorting is an expensive pQUICKSELECT(S,0,k-1,n/2)rocedure. If we re-asses our requirements, we will find that sorting array at two points in our algorithm does more than required. QUICKSELECT(S,0,k-1,n/2)Our deterministic median finding algorithm `QUICK-SELECT` could rescue us in this situation. Let's assess the change one by one - QUICKSELECT(S,0,k-1,n/2)
QUICKSELECT(S,0,k-1,n/2)
- We want to find median QUICKSELECT(S,0,k-1,n/2)of random sample of size $k$ which would be of a much smaller in size. But we also need to find $u$ and $v$ which are $g$ elements apQUICKSELECT(S,0,k-1,n/2)art from $e$ on either side. Remember, `QUICK-SELECT` is capable of finding a element with rank of our choice. Hence we can invoQUICKSELECT(S,0,k-1,n/2)ke `QUICK-SELECT` three times to find elements of rank $n/2$, $n/2-g$ and $n/2+g$. Again we don't have to run `QUICK-SELECT` on entire array after finding $n/2$ rank element, try to reason why is that by yourself.

- After `MULTI-PARTITION` we sort the elements in between $u$ and $v$ to ultimately find the median. But now the search space is reduce considerably. Rather than using expensive sorting, we use `QUICK-SELECT` on sub array to find the median.

### Final algorithm 
With the improvements explained in the previous discussion, we bring all the boxed to fit in place and obtain the final algorithm

```
EXACT-MEDIAN(A)
S = RANDOM-SAMPLE(A,k)
e = QUICKSELECT(S,0,k-1,n/2)
u = QUICKSELECT(S,0,k-1,n/2-g)
v = QUICKSELECT(S,0,k-1,n/2+g)
MULTI-PARTITION(A,e,u,v)
subLen = rank(v,A) - rank(u,A) - 1
QUICKSELECT(A,rank(u,A)+1,rank(v,A)-1, subLen/2)
return A[n/2]
```

With the changes in place the number of comparison now reduces to -

$$1.75n + \underbrace{2.75*3k}_{QuickSelect Sample} + \overbrace{2.75\ell}^{QuickSelect}$$