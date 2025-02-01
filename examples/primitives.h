#ifndef KEIN_PRIMITIVES_H
#define KEIN_PRIMITIVES_H


typedef __UINT8_TYPE__ u8;
typedef __UINT16_TYPE__ u16;
typedef __UINT32_TYPE__ u32;
typedef __UINT64_TYPE__ u64;
typedef __INT8_TYPE__ s8;
typedef __INT16_TYPE__ s16;
typedef __INT32_TYPE__ s32;
typedef __INT64_TYPE__ s64;
#define U8_MIN (-__UINT8_MAX__ - 1)
#define U8_MAX __UINT8_MAX__
#define U16_MIN (-__UINT16_MAX__ - 1)
#define U16_MAX __UINT16_MAX__
#define U32_MIN (-__UINT32_MAX__ - 1)
#define U32_MAX __UINT32_MAX__
#define U64_MIN (-__UINT64_MAX__ - 1)
#define U64_MAX __UINT64_MAX__
#define S8_MIN (-__INT8_MAX__ - 1)
#define S8_MAX __INT8_MAX__
#define S16_MIN (-__INT16_MAX__ - 1)
#define S16_MAX __INT16_MAX__
#define S32_MIN (-__INT32_MAX__ - 1)
#define S32_MAX __INT32_MAX__
#define S64_MIN (-__INT64_MAX__ - 1)
#define S64_MAX __INT64_MAX__


typedef float f32;
typedef double f64;
#define F32_MIN __FLT_MIN__
#define F32_MAX __FLT_MAX__
#define F64_MIN __DBL_MIN__
#define F64_MAX __DBL_MAX__
static_assert(sizeof(f32) == 4);
static_assert(sizeof(f64) == 8);


typedef char c8;
#define C8_MIN (-__SCHAR_MAX__ - 1)
#define C8_MAX __SCHAR_MAX__
#ifdef __APPLE__
	typedef __UINT16_TYPE__ c16;
	typedef __UINT32_TYPE__ c32;
#else
	typedef __CHAR16_TYPE__ c16;
	typedef __CHAR32_TYPE__ c32;
#endif
#define C16_MIN (-__UINT16_MAX__ - 1)
#define C16_MAX __UINT16_MAX__
#define C32_MIN (-__UINT32_MAX__ - 1)
#define C32_MAX __UINT32_MAX__

typedef __PTRDIFF_TYPE__ saddr;
#define SADDR_MIN (-__PTRDIFF_MAX__ - 1)
#define SADDR_MAX __PTRDIFF_MAX__
typedef __SIZE_TYPE__ uaddr;
#define UADDR_MIN (-__SIZE_MAX__ - 1)
#define UADDR_MAX __SIZE_MAX__


#define countof(a) (uaddr) (sizeof(a) / sizeof(*(a)))


/*
 * https://c0x.shape-of-code.com/5.2.4.2.1.html
 * CHAR_BIT is garuanteed to represent a byte and must be at least 8 bits.
 */
#if defined(CHAR_BIT)
#	define BYTE_BITS CHAR_BIT
#else
#	if defined(__CHAR_BIT__)
#		define BYTE_BITS __CHAR_BIT__
#	else
#		include <limits.h>
#		define BYTE_BITS CHAR_BIT
#	endif
#endif


#endif

