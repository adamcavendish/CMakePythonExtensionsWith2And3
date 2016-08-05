# FindPython: Find Python Interpreters and Libraries
#             Enables working with both python 2 and python 3

# Documentation:
#   refer to the function's documentation
#
# Demo usage without hint:
#   find_python(3.2 PYTHON3_FOUND PYTHON3_EXECUTABLE
#               PYTHON3_VERSION PYTHON3_VERSION_MAJOR PYTHON3_VERSION_MINOR
#               PYTHON3_LIBRARIES PYTHON3_INCLUDE_DIRS PYTHON3_PACKAGES_DIR)
# Demo usage with hint via environment variable
#   $ export PYTHON_EXECUTABLE="/opt/anaconda/bin/python"
#   find_python(3.2 PYTHON3_FOUND PYTHON3_EXECUTABLE
#               PYTHON3_VERSION PYTHON3_VERSION_MAJOR PYTHON3_VERSION_MINOR
#               PYTHON3_LIBRARIES PYTHON3_INCLUDE_DIRS PYTHON3_PACKAGES_DIR)
# Demo usage with hint via cmake variable
#   set(PYTHON_EXECUTABLE "/opt/anaconda/bin/python")
#   find_python(3.2 PYTHON3_FOUND PYTHON3_EXECUTABLE
#               PYTHON3_VERSION PYTHON3_VERSION_MAJOR PYTHON3_VERSION_MINOR
#               PYTHON3_LIBRARIES PYTHON3_INCLUDE_DIRS PYTHON3_PACKAGES_DIR)
#   unset(PYTHON_EXECUTABLE)


# function find_python: Find minimum required version of python
#                       You may provide a executable hint via environmental variable
#                       "PYTHON_EXECUTABLE" or cmake variable "PYTHON_EXECUTABLE"
# min_version    (value)   : minimum supported version of python
# found          (variable): variable to set to true if found
# executable     (variable): variable to set to python executable's path if found
# version_string (variable): variable to set to python's version if found
# version_major  (variable): variable to set to python's version major if found
# version_minor  (variable): variable to set to python's version minor if found
# version_patch  (variable): variable to set to python's version patch if found
# libraries      (variable): variable to set to python's library path if found
# include_dirs   (variable): variable to set to python's include path if found
# packages_dir   (variable): variable to set to python's packages path if found
function(find_python min_version found executable
         version_string version_major version_minor version_patch
         libraries include_dirs packages_dir)

  # macro set_from_env: set a cmake variable to the environment variable
  #                     if available
  # var     (variable): variable to set to if the environment variable is available
  # env_var (value)   : the environment variable name
  macro(set_from_env var env_var)
    if(DEFINED ENV{${env_var}})
      set(${var} $ENV{${env_var}})
    endif()
  endmacro()

  # macro set_ifndef: set a cmake variable if the variable is not defined
  # var (variable): variable to set to if empty
  # val (value)   : value to set to the variable if empty
  macro(set_ifndef var val)
    if(NOT ${var})
      set(${var} ${val})
    endif()
  endmacro()

  # use PYTHON_EXECUTABLE as a hint for find_package(PythonInterp)
  if(NOT PYTHON_EXECUTABLE)
    set_from_env(PYTHON_EXECUTABLE "PYTHON_EXECUTABLE")
  endif()
  set(_executable ${PYTHON_EXECUTABLE})

  find_package(PythonInterp "${min_version}")
  if(PYTHONINTERP_FOUND)
    set(_found ${PYTHONINTERP_FOUND})
    set(_executable ${PYTHON_EXECUTABLE})
    set(_version_string ${PYTHON_VERSION_STRING})
    set(_version_major ${PYTHON_VERSION_MAJOR})
    set(_version_minor ${PYTHON_VERSION_MINOR})
    set(_version_patch ${PYTHON_VERSION_PATCH})

    # unset the variables to cleanup side effects from calling find_package
    unset(PYTHONINTERP_FOUND)
    unset(PYTHON_EXECUTABLE CACHE)
    unset(PYTHON_VERSION_STRING)
    unset(PYTHON_VERSION_MAJOR)
    unset(PYTHON_VERSION_MINOR)
    unset(PYTHON_VERSION_PATCH)
  endif()

  if(_found)
    set(_version_combined "${_version_major}.${_version_minor}")

    find_package(PythonLibs "${_version_combined}")
    if(PYTHONLIBS_FOUND)
      set_ifndef(_libraries ${PYTHON_LIBRARIES})
      set_ifndef(_include_dirs ${PYTHON_INCLUDE_PATH})
      set_ifndef(_include_dirs ${PYTHON_INCLUDE_DIRS})

      # unset the variables to cleanup side effects from calling find_package
      unset(PYTHONLIBS_FOUND)
      unset(PYTHON_LIBRARIES)
      unset(PYTHON_INCLUDE_PATH)
      unset(PYTHON_INCLUDE_DIRS)
      unset(PYTHON_DEBUG_LIBRARIES)
      unset(PYTHONLIBS_VERSION_STRING)
      unset(PYTHON_LIBRARY)
      unset(PYTHON_INCLUDE_DIR)
    else()
      unset(_found)
    endif()
  endif()

  if(NOT _found AND _executable)
    set_ifndef(_version_combined ${min_version})
    string(REPLACE "." "" _version_combined_no_dots ${_version_combined})

    # tackle the libraries
    execute_process(COMMAND ${_executable} -c
                    "from distutils.sysconfig import get_config_var; print(get_config_var('LIBDIR'))"
                    RESULT_VARIABLE __
                    OUTPUT_VARIABLE _unchecked_libraries
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    find_library(_libraries_found
                 NAMES
                   python${_version_combined_no_dots}
                   python${_version_combined}mu
                   python${_version_combined}m
                   python${_version_combined}u
                   python${_version_combined}
                 PATHS ${_unchecked_libraries}
                 NO_SYSTEM_ENVIRONMENT_PATH)
    find_library(_libraries_found
                 NAMES
                   python${_version_combined_no_dots}
                   python${_version_combined}
                 NO_SYSTEM_ENVIRONMENT_PATH
                 PATH_SUFFIXES "python${_version_combined}/config")
    # clean up find_library side effects
    set(_libraries ${_libraries_found})
    unset(_libraries_found CACHE)

    # tackle the include_dirs
    execute_process(COMMAND ${_executable} -c
                    "from distutils.sysconfig import get_python_inc; print(get_python_inc())"
                    RESULT_VARIABLE __
                    OUTPUT_VARIABLE _unchecked_include_dirs
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    find_path(_include_dirs_found
              NAMES Python.h
              PATHS ${_unchecked_include_dirs}
              PATH_SUFFIXES
                python${_version_combined}mu
                python${_version_combined}m
                python${_version_combined}u
                python${_version_combined})
    # clean up find_library side effects
    set(_include_dirs ${_include_dirs_found})
    unset(_include_dirs_found CACHE)
  endif()

  # if both valid, set found
  if(_libraries AND _include_dirs)
    set(_found TRUE)
  endif()

  if(_found)
    if(CMAKE_HOST_UNIX)
      # setup package_path
      execute_process(COMMAND ${_executable} -c
                      "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
                      RESULT_VARIABLE __
                      OUTPUT_VARIABLE _full_packages_path
                      OUTPUT_STRIP_TRAILING_WHITESPACE)
      if("${_full_packages_path}" MATCHES "site-packages")
        set(_packages_dir "python${_version_combined}/site-packages")
      elseif("${_full_packages_path}" MATCHES "dist-packages")
        set(_packages_dir "python${_version_combined}/dist-packages")
      else()
        message(WARNING "Unknown python package path format: ${_full_packages_path}")
      endif()
    elseif(CMAKE_HOST_WIN32)
      # @TODO
      message(WARNING "Finding packages dir on WIN32 is not currently supported")
    endif()
  endif()

  # return
  set(${found} "${_found}" PARENT_SCOPE)
  if(_found)
    set(${executable} "${_executable}" CACHE FILEPATH "Path to Python interpretor")
    set(${version_string} "${_version_string}" CACHE STRING "Python version")
    set(${version_major} "${_version_major}" PARENT_SCOPE)
    set(${version_minor} "${_version_minor}" PARENT_SCOPE)
    set(${version_patch} "${_version_patch}" PARENT_SCOPE)
    set(${libraries} "${_libraries}" CACHE FILEPATH "Path to Python library")
    set(${include_dirs} "${_include_dirs}" CACHE PATH "Python include dir")
    set(${packages_dir} "${_packages_dir}" CACHE STRING "Python partial packages dir for install")
  endif()
endfunction(find_python)
