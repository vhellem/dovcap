def f(n):
  if n<= 0:
    return 0
  return n + f(int(n/2))

def f1(x):
    return x*2

def f2(n):
    return f1(n) + 1

def max_height(node):
    if not node:
        return 0
    left = max_height(node.left)
    right = max_height(node.right)
    return max(left, right)
