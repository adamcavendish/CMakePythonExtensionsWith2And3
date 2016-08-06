CMake Python Extensions with 2 And 3

Build Python 2 and 3 Extensions with CMake

---

# Requirements

cmake >= 2.8

# Info

`FindPython.cmake` Module requires the a newer [FindPythonInterp.cmake](https://github.com/Kitware/CMake/blob/master/Modules/FindPythonInterp.cmake)
and [FindPythonLibs.cmake](https://github.com/Kitware/CMake/blob/master/Modules/FindPythonLibs.cmake) from CMake (at least 3.4)

# Quick start:

```
# Get latest FindPythonInterp.cmake and FindPythonLibs.cmake
cd cmake/
wget -c "https://raw.githubusercontent.com/Kitware/CMake/master/Modules/FindPythonInterp.cmake"
wget -c "https://raw.githubusercontent.com/Kitware/CMake/master/Modules/FindPythonLibs.cmake"
cd ../

mkdir -p build
cd build
cmake ..
make
make install

cd ../py2/
python2 greet2.py

cd ../py3/
python3 greet3.py
```

