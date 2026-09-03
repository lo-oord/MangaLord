package com.mlord.core.util

interface CloseableSequence<T> : Sequence<T>, AutoCloseable
