"""Generate and manipulate persistence landscapes."""

from math import inf
import bisect
import numpy as np
import matplotlib.pyplot as plt

def linear_integral(a, b, c, d, p):
    """Computes the integral of |ax+b|^p from c to d.

    Assumes that ax+b doesn't change sign in this region.
    """
    if a == 0:
        return abs((b ** p) * (d - c))
    y0 = a * c + b
    y1 = a * d + b
    return abs((y1**(p+1) - y0**(p+1))/(a*(p+1)))

def linear_interpolate(x0, x1, y0, y1, x):
    """The value of f(x), where x0<=x<=x1, if f is linear with f(x_i) = y_i."""
    return y0 + (x - x0)*(y1 - y0)/(x1 - x0)

class PersistenceLandscape:
    """A persistence landscape.

    Attributes:
        critical_numbers:
            A list of arrays containing the critical numbers X_k for each k.
        critical_values:
            A list of arrays containing the critical values Y_k for each k.
    """

    def __init__(self, critical_numbers, critical_values):
        """Inits PersistenceLandscape with critical numbers and values."""
        self.critical_numbers = list(map(np.array, critical_numbers))
        self.critical_values = list(map(np.array, critical_values))

    def X(self, k):
        """Returns the critical numbers X_k for any k>0."""
        if k > self.max_k():
            return np.array([-inf, inf])
        return self.critical_numbers[k-1]

    def Y(self, k):
        """Returns the critical values Y_k for any k>0."""
        if k > self.max_k():
            return np.array([0, 0])
        return self.critical_values[k-1]

    def max_k(self):
        """The largest value of k for which lambda_k is nonzero."""
        return len(self.critical_numbers)

    def lambda_k_vect(self, k, v):
        """Vectorised computation of lambda_k.

        Args:
            k: The level of persistence to compute.
            v: A 1d numpy array of input floats.

        Returns:
            A numpy array containing the values lambda_k(x) for each x in v.
        """
        X = self.X(k)
        Y = self.Y(k)
        indices = np.searchsorted(X, v, side='right') - 1
        X0, X1, Y0, Y1 = np.zeros((4, len(v))) 
        for j in range(len(v)):
            i = indices[j]
            if i == 0 or i >= len(X) - 2:
                X1[j] = 1
            else:
                X0[j] = X[i]
                X1[j] = X[i+1]
                Y0[j] = Y[i]
                Y1[j] = Y[i+1]
        output = linear_interpolate(X0, X1, Y0, Y1, v)
        output[0] = output[-1] = 0
        return output

    def lambda_k(self, k, x):
        """Compute lambda_k(x)."""
        X = self.X(k)
        Y = self.Y(k)
        i = bisect.bisect(X, x) -1
        if i == 0 or i >= len(X) - 2:
            return 0
        return linear_interpolate(X[i], X[i+1], Y[i], Y[i+1], x)

    def plot(self, colors = None, linewidths = None, labels=None, max_k = None, show_zero = False, **kwargs):
        """Plot the persistence landscape.

        Args:
            show_zero:
                Optional: If True, then the zero values of the landscape
                are plotted. Must be set to True if the landscape takes
                negative values, or bad things will happen.

        Returns:
            A matplotlib figure containing the landscape plot.
        """
        if colors is None:
            colors = [None] * self.max_k()
        if linewidths is None:
            linewidths = [None] * self.max_k()
        if labels is None:
            labels = [None] * self.max_k()

        fig, ax = plt.subplots(1)

        left_bound = self.X(1)[0]
        right_bound = self.X(1)[-1]
        for k in range(1, (self.max_k() if max_k is None else max_k) + 1):
            X_k = list(self.X(k))
            Y_k = list(self.Y(k))
            if show_zero:
                X_k[0] = left_bound
                X_k[-1] = right_bound
            else:
                # Very ugly. We push regions under the axis if we don't want to
                # show them. The obvious alternative of just doing two plots
                # would require us to manually set colours, which is a lot of
                # extra work.
                i = 2
                while i < len(Y_k) - 2:
                    if Y_k[i] == 0 and Y_k[i+1] == 0:
                        X_k.insert(i+1, X_k[i+1])
                        Y_k.insert(i+1, -1)
                        X_k.insert(i+1, X_k[i])
                        Y_k.insert(i+1, -1)
                        i += 2
                    i += 1
            ax.plot(X_k, Y_k, color=colors[k-1], linewidth=linewidths[k-1], label=labels[k-1], **kwargs)
        if not show_zero:
            ax.set_ylim(bottom=0)
        return fig, ax

    def integral(self, k, p):
        """The integral |lambda_k|^p from -inf to inf."""
        X = self.X(k)
        Y = self.Y(k)
        integrals = np.empty(len(X) - 3)
        for i in range(1, len(X) - 2):
            if X[i] == X[i+1]:
                integrals[i-1] = 0
            else:
                a = (Y[i+1] - Y[i])/(X[i+1] - X[i])
                b = Y[i] - a * X[i]
                # in this region we have y = ax + b
                if Y[i] * Y[i+1] < 0:
                    # we need to split into two integrals:
                    m = -b / a
                    integrals[i-1] = (linear_integral(a, b, X[i], m, p)
                            + linear_integral(a, b, m, X[i+1], p))
                else:
                    integrals[i-1] = linear_integral(a, b, X[i], X[i+1], p)
        return integrals.sum()

    def norm(self, p):
        """The Lp norm of the landscape."""
        if p == inf:
            return np.max(np.abs(self.Y(1)))
        max_k = self.max_k()
        integrals = np.empty(max_k)
        for k in range(max_k):
            integrals[k] = self.integral(k+1, p)
        return (integrals.sum())**(1/p)

    def save(self, fname):
        """Save the landscape to storage."""
        f = open(fname, 'w')
        k = 1
        for k in range(1, self.max_k() + 1):
            f.write("#lambda_{}\n".format(k))
            X_k = self.X(k)
            Y_k = self.Y(k)
            for i in range(1, len(X_k)-1):
                f.write("{} {}\n".format(X_k[i], Y_k[i]))
        f.close()

def generate_landscape(diagram):
    """Generate a landscape from a persistence diagram/barcode.

    Implements Algorithm 1 from [BP17].

    Args:
        diagram: a 2d numpy array of birth/death pairs.

    Returns:
        The persistence landscape of the diagram.
    """

    critical_numbers = []
    critical_values = []

    A = diagram.copy()
    A.sort(key=lambda p: (p[0],-p[1]))

    k = 1

    while len(A) > 0:

        b, d = A.pop(0)
        p = 0

        X_k = [-inf, b, (b+d)/2]
        Y_k = [0, 0, (d-b)/2]

        while X_k[-1] != inf:
            i = p
            while i < len(A) and A[i][1] <= d:
                i+=1
            if i == len(A):
                X_k += [d, inf]
                Y_k += [0, 0]
            else:
                b1, d1 = A[i]
                del A[i]
                p = i
                if b1 > d:
                    X_k.append(d)
                    Y_k.append(0)
                if b1 >= d:
                    X_k.append(b1)
                    Y_k.append(0)
                else:
                    X_k.append((b1+d)/2)
                    Y_k.append((d-b1)/2)
                    i = p
                    while i < len(A) and A[i][0] < b1:
                        i += 1
                    if i == len(A):
                        A.append((b1, d))
                        p = len(A)
                    else:
                        if A[i][0] > b1:
                            A.insert(i, (b1, d))
                            p = i+1
                        else:
                            while i < len(A) and A[i][1] > d:
                                i += 1
                            if i == len(A):
                                A.append((b1, d))
                                p = len(A)
                            else:
                                A.insert(i, (b1, d))
                                p = i+1
                X_k.append((b1+d1)/2)
                Y_k.append((d1-b1)/2)
                b, d = b1, d1
        critical_numbers.append(X_k)
        critical_values.append(Y_k)
        k+= 1

    return PersistenceLandscape(critical_numbers, critical_values)

def load(fname):
    """Load a persistence landscape from storage."""
    f = open(fname, 'r')
    k = 0
    critical_numbers = []
    critical_values = []
    for line in f.readlines():
        if line[0] == '#':
            if k > 0:
                X_k.append(inf)
                Y_k.append(0)
                critical_numbers.append(X_k)
                critical_values.append(Y_k)
            X_k = [-inf]
            Y_k = [0]
            k += 1
        else:
            x, y = line.split()
            X_k.append(float(x))
            Y_k.append(float(y))
    return PersistenceLandscape(critical_numbers, critical_values)

def linear_combination(landscapes, weights, max_k = None):
    """Computes a linear combination of persistence landscapes.

    Implements Algorithm 3 from [BP17].

    Args:
        landscapes:
            An iterable of persistence landscapes.
        weights:
            An iterable of weights of the same length as landscapes.
        max_k:
            Optional: The largest value of k for which we consider lambda_k.
            If max_k is None then all the lambda_k's are used.

    Returns:
        The linear combination of the landscapes with the given weights.
    """
    if max_k is None:
        max_k = max([landscape.max_k() for landscape in landscapes])
    critical_numbers = []
    critical_values = []

    for k in range(1, max_k+1):
        list_of_Xs = [landscape.X(k) for landscape in landscapes]
        X_k = sorted({x for X in list_of_Xs for x in X})
        Z = np.empty((len(landscapes), len(X_k)))
        with np.errstate(invalid='ignore'):
            for i, landscape in enumerate(landscapes):
                Z[i] = landscape.lambda_k_vect(k, X_k) * weights[i]
        Y_k = np.sum(Z, axis=0)
        critical_numbers.append(X_k)
        critical_values.append(Y_k)

    return PersistenceLandscape(critical_numbers, critical_values)

def average(landscapes, max_k = None):
    """Computes an average of persistence landscapes.

    Args:
        landscapes:
            An iterable of persistence landscapes.
        max_k:
            Optional: The largest value of k for which we consider lambda_k.
            If max_k is None then all the lambda_k's are used.

    Returns:
        The average persistence landscape.
    """
    N = len(landscapes)
    if N == 1:
        landscape = landscapes[0]
        return PersistenceLandscape(landscape.critical_numbers[:max_k],
                                    landscape.critical_values[:max_k])
    return linear_combination(landscapes, [1/N] * N, max_k)

def distance(landscape1, landscape2, p):
    """Computes the Lp distance between two landscapes."""
    max_k = 1 if p == inf else None
    diff = linear_combination([landscape1, landscape2], [1, -1], max_k = max_k)
    return diff.norm(p)

def weighted_integral(landscape, weights, p = 1):
    """Computes a linear combination of the Lp norms of each lambda_k."""
    x = np.zeros(len(weights))
    for k, w in enumerate(weights):
        if w != 0:
            x[k] = w * landscape.integral(k+1, p)
    return x.sum()
