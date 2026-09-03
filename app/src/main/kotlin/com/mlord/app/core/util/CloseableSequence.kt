package com.mlord.app.core.util

interface CloseableSequence<T> : Sequence<T>, AutoCloseable
