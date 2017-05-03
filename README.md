# Tanya

[![Build Status](https://travis-ci.org/caraus-ecms/tanya.svg?branch=master)](https://travis-ci.org/caraus-ecms/tanya)
[![Dub version](https://img.shields.io/dub/v/tanya.svg)](https://code.dlang.org/packages/tanya)
[![Dub downloads](https://img.shields.io/dub/dt/tanya.svg)](https://code.dlang.org/packages/tanya)
[![License](https://img.shields.io/badge/license-MPL_2.0-blue.svg)](https://raw.githubusercontent.com/caraus-ecms/tanya/master/LICENSE)

Tanya is a general purpose library for D programming language.

Its aim is to simplify the manual memory management in D and to provide a
guarantee with @nogc attribute that there are no hidden allocations on the
Garbage Collector heap. Everything in the library is usable in @nogc code.
Tanya extends Phobos functionality and provides alternative implementations for
data structures and utilities that depend on the Garbage Collector in Phobos.

* [Bug tracker](https://issues.caraus.io/projects/tanya)
* [Documentation](https://docs.caraus.io/tanya)

## Overview

Tanya consists of the following packages:

* `async`: Event loop (epoll, kqueue and IOCP).
* `container`: Queue, Vector, Singly linked list, buffers.
* `crypto`: HMAC.
* `math`: Arbitrary precision integer and a set of functions.
* `memory`: Tools for manual memory management (allocator, reference counting,
helper functions).
* `network`: URL-Parsing, sockets, utilities.

### Supported compilers

| dmd     |
|:-------:|
| 2.074.0 |
| 2.073.2 |
| 2.072.2 |
| 2.071.2 |

### Current status

The library is currently under development, but the API is becoming gradually
stable.

Following modules are coming soon:

| Feature      | Branch     | Build status                                                                                                            |
|--------------|:----------:|:-----------------------------------------------------------------------------------------------------------------------:|
| UTF-8 string | utf8string | [![utf8string](https://travis-ci.org/caraus-ecms/tanya.svg?branch=utf8string)](https://travis-ci.org/caraus-ecms/tanya) |
| BitVector    | bitvector  | [![bitvector](https://travis-ci.org/caraus-ecms/tanya.svg?branch=bitvector)](https://travis-ci.org/caraus-ecms/tanya)   |
| TLS          | crypto     | [![crypto](https://travis-ci.org/caraus-ecms/tanya.svg?branch=crypto)](https://travis-ci.org/caraus-ecms/tanya)         |
| Hash table   | N/A        | N/A                                                                                                                     |

### Further characteristics

* Tanya is a native D library.

* Tanya is cross-platform. The development happens on a 64-bit Linux, but it
is being tested on Windows and FreeBSD as well.

* The library isn't thread-safe. Thread-safity should be added later.

## Release management

4-week release cycle.

## Contributing

Since I'm mostly busy writing new code and implementing new features I would
appreciate, if anyone uses the library. It would help me to improve the
codebase and fix issues.

Feel free to contact me if you have any questions.
