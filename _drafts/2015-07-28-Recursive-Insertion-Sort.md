---
layout: post
title: Recursive-Insertion-Sort
tags:   [insertion-sort, recursion]
---

It's hard to point merits of recursive procedures. But if one has to then it is the elegance and clarity of algorithms. For most of problems, recursive solution gives an intuition of the working of the algorithm. Though we have a very nice intuitive understanding of (usual) insertion sort, courtesy CLRS, that may not be the case always. For Insertion sort, recursive algorithm really gives a different prospective to working of insertion sort.

## INSERTION-SORT Analogy

>"We start with an empty left hand and the cards face down on the table. We then remove one card at a time from the table and insert it into the correct position in the left hand. To find the correct position for a card, we compare it with each of the cards already in the hand, from right to left, as illustrated in figure above. At all times, the cards held in the left hand are sorted, and these cards were originally the top cards of the pile on the table."
>-CLRS

## ITERATIVE INSERTION-SORT ALGORITHM

```
INSERTION-SORT(A) 
1 for j = 2 to length[A] 
2 do key = A[j] 
3   Insert A[j] into the sorted sequence A[1 . . j − 1]. 
4   i = j − 1 
5   while i > 0 and A[i] > key 
6     do A[i + 1] = A[i] 
7     i = i − 1 
8   A[i + 1] = key
```

## Recursive insertion-sort

Insertion sort can be expressed as a recursive procedure as follows. In order to sort $A[1 . . n]$, we recursively sort $A[1 . . n−1]$ and then insert $A[n]$ into the sorted array $A[1 . . n − 1]$.

### Algorithm
```
INSERT(element, A, n)
1. if n < 1
2.   A[0] = element
3. else if element >= A[n]
4.   A[n+1] = element
5. else
6.   A[n+1] = A[n]
7.   INSERT(element, A, n-1)

RECURSIVE-INSERTION-SORT(A,n)
1. if n < 2
2.   return A
3. else
4.   RECURSIVE-INSERTION-SORT(A,n-1)
5.   INSERT(A[n], A, n-1)
```

### Implementation in Python
```python
import time

def insert(element, A, n):
    if n &amp;lt; 0:
        A[0] = element
    elif element &amp;gt;= A[n]:
        if n == len(A)-1:
            A.append(element)
        else:
            A[n+1] = element
    else:
        if n == len(A)-1:
            A.append(A[n])
        else:
            A[n+1] = A[n]
            insert(element, A, n-1)

def insertion_sort(A,n):
    if n &amp;lt; 1:
        return A
    else:
        insertion_sort(A,n-1)
        insert(A[n], A, n-1)

A = [5,4,3,2,1]
start_time = time.time()
print(&quot;Unsorted Array: %s&quot; %A)
insertion_sort(A,len(A)-1)
print(&quot;Sorted Array: %s&quot; %A)
print(&quot;--- %s seconds ---&quot; % (time.time() - start_time))
```

## Explanation
Insert is a utility function which recursively adds element in the given array A of size n in order. For example if we use insert to add 1 in an array $A = [2]$ or if we use it to add 2 in an array $A = [1]$; in both the cases we get $A = [1,2]$. In the algorithm above we use this function to insert an element $A[i]$ in sorted array $A[1..i-1]$.

Insertion-Sort is a function which takes an array A to be sorted and n (number of element in A). The function recursively call itself to sort sub-array $A[1..n-1]$ and then insert $A[n]$ in  $A[1..n-1]$. This recursive call maintain that insertion of element is performed on a sorted array

### DEMONSTRATION OF RECURSIVE CALL
```
Call INSERTION-SORT with A = [5,4,3,2,1], n = 5
  Call INSERTION-SORT with A = [5,4,3,2], n = 4
    Call INSERTION-SORT with A = [5,4,3], n = 3
      Call INSERTION-SORT with A = [5,4], n = 2
        INSERT 4 in A = [5] and n = 1
        return A = [4,5]
      INSERT 3 IN A = [4,5] and n = 2
      return A = [3,4,5]
    INSERT 2 in A = [3,4,5] and n = 3
    return A = [2,3,4,5]
  INSERT 1 in A = [2,3,4,5] and n = 4
  return A = [1,2,3,4,5]
```

## Analysis
Let $T(n)$ be the running time on a problem of size n. 

When $n = 1, \ T(n) = \Theta (1)$. However, when $n > 1, \ T(n)$ is the sum of time taken to sort the array of size n-1 and time taken to insert the last element in the sorted array.

Next question to trigger on is what is the running time of Insert? If we try to analyse we see that the method recursively reduce the array by one to find the right place to fit in the element. For that, in worst case the method will go through each element in the array; which will cost $\Theta (n)$

Thus $T(n) = T(n-1) + \Theta (n)$ for $n > 1$. Expand it out few times, observe the pattern. Use the tools of geometric progression to convince yourself that $T(n)=O\left(n^2\right)$.

## CONCLUSION
After understanding Recursive Insertion-Sort algorithm read the analogy mentioned at the start of this post from the book Introduction to Algorithm. You will find that even in case of Recursive algorithm we maintain that analogy but now our view point is upside-down.

There is no extra work to do in case of Recursive Insertion-Sort. Algorithm will first pick up the second element from the array and insert it in the sorted array to its left, currently with only one element. Next it will pick the third element and inserted it in the sorted array to its left which now have 2 element in sorted order. We do this until the last element of array. At last we have a sorted array.