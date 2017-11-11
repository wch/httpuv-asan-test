httpuv crash with background thread
===================================

R is crashing in weird ways with the background-thread branch of httpuv. Sometimes the errors are just weird, like:

```
Error in tryCatch(evalq(sys.calls(), <environment>), error = function (x)  : 
  Evaluation error: use of NULL environment is defunct.
```

and

```
Error in tryCatch(evalq(sys.calls(), <environment>), error = function (x)  : 
  Evaluation error: attempt to apply non-function.
In addition: Warning message:
An unusual circumstance has arisen in the nesting of readline input. Please report using bug.report() 
```

Other times, it segfaults.

I've tested at it with an ASAN build of R, and I've saved the output from multiple runs in sample_output.txt.


Based on the stack traces, it looks like R is GC'ing objects before it should, but I'm not completely sure.



## Steps to reproduce

Build Docker image:

```
docker build -t r-asan .
```


In one terminal, start a basic web server:

```
docker run --rm -ti --name ra r-asan /bin/bash

RD
library(httpuv)
library(promises)
content <- list(
  status = 200L,
  headers = list('Content-Type' = 'text/html'),
  body = "abc"
)

startBackgroundServer("0.0.0.0", 5000,
  list(
    onHeaders = function(req) {
      if (req$PATH_INFO == "/header") {
        return(content)
      } else {
        return(NULL)
      }
    },
    call = function(req) {      
      if (req$PATH_INFO %in% c("/", "/sync")) {
        return(content)
      } else if (req$PATH_INFO == "/async") {
        promise(function(resolve, reject) {
          resolve(content)
        })
      } else {
        stop("Unknown request path:", req$PATH_INFO)
      }
    } 
  )
)
```


In another terminal, hit the server with a lot of requests. The `/async` path seems to reliably generate the error. With `/`, it happens less frequently. With `/header`, I haven't seen it error.

```
docker exec -ti ra /bin/bash
# Reliably triggers error
ab -n 5000 -c 50 http://127.0.0.1:5000/async

# Might need to run this a bunch of times before getting error
ab -n 20000 -c 100 http://127.0.0.1:5000/

# I haven't seen it error with this
ab -n 20000 -c 100 http://127.0.0.1:5000/header
```

