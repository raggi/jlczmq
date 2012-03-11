#!/usr/bin/env julia

ZMQ_PAIR = 0
ZMQ_PUB = 1
ZMQ_SUB = 2
ZMQ_REQ = 3
ZMQ_REP = 4
ZMQ_DEALER = 5
ZMQ_ROUTER = 6
ZMQ_PULL = 7
ZMQ_PUSH = 8
ZMQ_XPUB = 9
ZMQ_XSUB = 10

# TODO : namespace these somewhere else, or maybe just macro the whole thing to
# the edge of ccall(
czmq = dlopen("libczmq")
czmq_zctx_new = dlsym(czmq, :zctx_new)
czmq_zctx_destroy = dlsym(czmq, :zctx_destroy)
czmq_zsocket_new = dlsym(czmq, :zsocket_new)
czmq_zsocket_bind = dlsym(czmq, :zsocket_bind)
czmq_zsocket_connect = dlsym(czmq, :zsocket_connect)
czmq_zstr_send = dlsym(czmq, :zstr_send)
czmq_zstr_recv = dlsym(czmq, :zstr_recv)

function zctx_new()
    ccall(czmq_zctx_new, Ptr{Void}, (), )
end

function zctx_destroy(ctx::Ptr{Void})
    ptr_ctx = Array(Ptr{Void}, 1)
    ptr_ctx[1] = ctx
    ccall(czmq_zctx_destroy, Void, (Ptr{Ptr{Void}}, ), ptr_ctx)
end

function zsocket_new(ctx, sock_type)
    ccall(czmq_zsocket_new, Ptr{Void}, (Ptr{Void}, Int), ctx, sock_type)
end

function zsocket_bind(sock, uri)
    ccall(czmq_zsocket_bind, Void, (Ptr{Void}, Ptr{Uint8}), sock, uri)
end

function zsocket_connect(sock, uri)
    ccall(czmq_zsocket_connect, Void, (Ptr{Void}, Ptr{Uint8}), sock, uri)
end

function zstr_send(sock::Ptr{Void}, str::String)
    ccall(czmq_zstr_send, Int, (Ptr{Void}, Ptr{Uint8}), sock, cstring(str))
end

function zstr_recv(sock)
    cstr = ccall(czmq_zstr_recv, Ptr{Uint8}, (Ptr{Void}, ), sock)
    str = cstring(cstr)
    _c_free(cstr)
    str
end

##
# Implementation of zstr_test

function jz_zstr_test()
    ctx = zctx_new()
    @assert ctx != C_NULL

    output = zsocket_new(ctx, ZMQ_PAIR)

    @assert output != C_NULL

    zsocket_bind(output, "inproc://zstr.test")

    input = zsocket_new(ctx, ZMQ_PAIR)

    @assert input != C_NULL

    zsocket_connect(input, "inproc://zstr.test")

    for string_nbr = 0:9
        println("zstr_send: this is string $string_nbr")
        res = zstr_send(output, "this is string $string_nbr")
        @assert res != C_NULL
    end
    println("zstr_send: END")
    zstr_send(output, "END")

    string_nbr = 0
    while true
        str = zstr_recv(input)
        println("zstr_recv: $str")
        if str == "END"
            break
        end
        string_nbr = string_nbr + 1
    end

    @assert string_nbr == 10

    zctx_destroy(ctx)
end

jz_zstr_test()
