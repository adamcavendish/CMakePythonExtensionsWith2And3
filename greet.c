#include <Python.h>

static PyObject* hello(PyObject* self) {
  return Py_BuildValue("s", "Hello, Python extensions!!");
}

static char hello_docs[] =
  "hello(): hello\n";

static PyMethodDef hello_funcs[] = {
  {"hello", (PyCFunction)hello, METH_NOARGS, hello_docs},
  {NULL}
};

#if PY_MAJOR_VERSION >= 3
  PyMODINIT_FUNC PyInit_libgreet(void) {
      static struct PyModuleDef moduledef = {
        PyModuleDef_HEAD_INIT,
        "libgreet",
        hello_docs,
        -1,
        hello_funcs,
        NULL,
        NULL,
        NULL,
        NULL
      };
      PyObject *module = PyModule_Create(&moduledef);
  }
#else
  void initlibgreet(void) {
      Py_InitModule3("libgreet", hello_funcs, "Extension module example!");
  }
#endif

