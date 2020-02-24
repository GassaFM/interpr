import random
random.seed (2362362362)

n = 200000
print (n)
p = list (range (n))
random.shuffle (p)
print (' '.join (map (str, p)))
