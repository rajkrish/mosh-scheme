#include "Object.h"
#include "Object-inl.h"
#include "Pair.h"
#include "Pair-inl.h"
#include "SString.h"
#include "ByteVector.h"
#include "VM.h"
#include "ByteVectorProcedures.h"
#include "ErrorProcedures.h"
#include "PortProcedures.h"
#include "ByteArrayBinaryInputPort.h"
#include "BinaryInputPort.h"
#include "Symbol.h"
#include "ProcedureMacro.h"
#include "Transcoder.h"
#include "UTF8Codec.h"
#include "UTF16Codec.h"
#include "UTF32Codec.h"
#include "Ratnum.h"
#include "Flonum.h"
#include "Bignum.h"
#include "Arithmetic.h"
#include "TextualOutputPort.h"
#include "FFI.h"
#include "Gloc.h"
#include "Closure.h"
#include "VM-inl.h"

#if not defined(_WIN32) && not defined(MONA)
#include "mosh_terminal.h"
#endif

using namespace scheme;

#ifdef _WIN32
Object stub_win32_process_pipe(VM* theVM, int argc, const Object* argv);
Object stub_win32_process_redirected_child(VM* theVM, int argc, const Object* argv);
Object stub_win32_handle_read(VM* theVM, int argc, const Object* argv);
Object stub_win32_handle_write(VM* theVM, int argc, const Object* argv);
Object stub_win32_handle_close(VM* theVM, int argc, const Object* argv);
Object stub_win32_process_wait(VM* theVM, int argc, const Object* argv);
Object stub_win32_named_pipe_create(VM* theVM, int argc, const Object* argv);
Object stub_win32_named_pipe_wait(VM* theVM, int argc, const Object* argv);
#endif

#define NIL Object::Nil
#define CONS(x,y) Object::cons((x),(y))
#define SYM(x) Symbol::intern(UC(x))
#define PTR(x) Object::makePointer((void*)x)
#define FUNC(x,y) CONS(SYM(x),PTR(y))

#ifndef WIN32
#define LIBDATA_TERMINAL CONS(SYM("terminal"), \
CONS(FUNC("terminal_acquire",terminal_acquire), \
CONS(FUNC("terminal_release",terminal_release), \
CONS(FUNC("terminal_getsize",terminal_getsize), \
CONS(FUNC("terminal_isatty",terminal_isatty),NIL)))))
#endif

Object
stub_get_pffi_feature_set(VM* theVM, int argc, const Object* argv){
    //DeclareProcedureName("%get-pffi-feature-set");
    Object tmp;

    tmp = Object::Nil;
#if not defined(WIN32) && not defined(MONA)
    tmp = Object::cons(LIBDATA_TERMINAL,tmp);
#endif
    return tmp;
}

#undef NIL
#undef CONS
#undef SYM
#undef PTR

void
register_stubs(VM* theVM){
    theVM->setValueString(UC("%get-pffi-feature-set"),Object::makeCProcedure(stub_get_pffi_feature_set));
#ifdef _WIN32
    theVM->setValueString(UC("%win32_process_pipe"),Object::makeCProcedure(stub_win32_process_pipe));
    theVM->setValueString(UC("%win32_process_redirected_child"),Object::makeCProcedure(stub_win32_process_redirected_child));
    theVM->setValueString(UC("%win32_handle_read"),Object::makeCProcedure(stub_win32_handle_read));
    theVM->setValueString(UC("%win32_handle_write"),Object::makeCProcedure(stub_win32_handle_write));
    theVM->setValueString(UC("%win32_handle_close"),Object::makeCProcedure(stub_win32_handle_close));
    theVM->setValueString(UC("%win32_process_wait"),Object::makeCProcedure(stub_win32_process_wait));
    theVM->setValueString(UC("%win32_named_pipe_create"),Object::makeCProcedure(stub_win32_named_pipe_create));
    theVM->setValueString(UC("%win32_named_pipe_wait"),Object::makeCProcedure(stub_win32_named_pipe_wait));
#endif
}
