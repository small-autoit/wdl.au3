# wdl.au3
[WinDrawLib](https://github.com/mity/windrawlib) wrapper for AutoIt3.

**Notice**: wdl.dll is built for x86 (32bit) only.

### Basic types

```c++
Point
    x, y : float
```

```c++
Rect
    x0, y0, x1, y1 : float
```

```c++
Matrix
    m11, m12: float
    m21, m22: float
    dx, dy : float
```

```c++
PathSink
    data : ptr
    x, y : float

```

### Functions

See [wdl.au3](https://github.com/small-autoit/wdl.au3/blob/master/wdl.au3)...

### Examples

See [tests](https://github.com/small-autoit/wdl.au3/tree/master/tests)...


<h3 align='center'>
    <a href='https://github.com/small-autoit/wdl.au3/blob/master/tests/flappy_bird.au3'>Simple Flappy Bird</a>
</h3>
<p align='center'>
    <img src='https://github.com/small-autoit/wdl.au3/blob/master/tests/falppy_bird_demo.png?raw=true'>
</p>
