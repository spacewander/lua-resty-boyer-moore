#include <stdlib.h>
#include <string.h>

#ifndef BM_GOOD_SUFFIX_ENABLED
/* The preprocession of the good suffix rule is expensive. But it might be
 * suitable for your case. */
#define BM_GOOD_SUFFIX_ENABLED 0
#endif

#define ERR_NOT_FOUND   -1
#define ERR_NO_MEMORY   -2

#define uchar unsigned char
#define likely(x) __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)
#define UCHARS 256
#define GOOD_SUFFIX_BUFSIZE 512

/* as thread unsafe as the Lua VM */
int bad_chars[UCHARS];
int *good_suffix;
int *good_suffix_buf[GOOD_SUFFIX_BUFSIZE];


int *fetch_good_suffix_buf(int needle_len)
{
    if (needle_len <= GOOD_SUFFIX_BUFSIZE) {
        return (int *) good_suffix_buf;
    }

    return (int *) malloc(needle_len * sizeof(int));
}

void release_good_suffix_buf(int *buf)
{
    if (buf != (int *) good_suffix_buf) {
        free(buf);
    }
}

/* int is slightly faster than size_t, and LuaJIT uses int too */
int bm_find(const uchar *haystack, int haystack_len,
            const uchar *needle, int needle_len, int start)
{
    if (needle_len == 0) {
        return 0;
    }

    haystack += start;
    haystack_len -= start;

    const uchar *p = haystack;
    const uchar *q = haystack + haystack_len - needle_len;
    int i;
    for (i = 0; i < UCHARS; i++) {
        bad_chars[i] = needle_len;
    }

#if BM_GOOD_SUFFIX_ENABLED
    good_suffix = fetch_good_suffix_buf(needle_len);
    if (good_suffix == NULL) {
        return ERR_NO_MEMORY;
    }

    int last_prefix_index = needle_len - 1;
    for (i = needle_len - 1; i >= 0; i--) {
        if (memcmp(needle, needle + i + 1, needle_len - i - 1)) {
            last_prefix_index = i + 1;
        }

        good_suffix[i] = last_prefix_index + (needle_len - 1 - i);
    }
#endif

    for (i = 0; likely(i < needle_len - 1); i++) {
#if BM_GOOD_SUFFIX_ENABLED
        int len;

        for (len = 0; len < i; len++) {
            if (needle[i - len] != needle[needle_len - 1 - len]) {
                good_suffix[needle_len - 1 - len] = needle_len - 1 - i + len;
                break;
            }
        }
#endif

        bad_chars[needle[i]] = needle_len - 1 - i;
    }

    while (p <= q) {
#if BM_GOOD_SUFFIX_ENABLED
        i = needle_len - 1;
        while (needle[i] == p[i]) {
            if (i == 0) {
                release_good_suffix_buf(good_suffix);
                return p - haystack + start;
            }

            i--;
        }
#else
        if (unlikely(memcmp(p, needle, needle_len) == 0))
            return p - haystack + start;
#endif

        int bad_chars_skip = bad_chars[*(p + needle_len - 1)];

#if BM_GOOD_SUFFIX_ENABLED
        int good_suffix_skip = good_suffix[i];

        if (bad_chars_skip > good_suffix_skip) {
            p += bad_chars_skip;

        } else {
            p += good_suffix_skip;
        }
#else
        p += bad_chars_skip;
#endif
    }

#if BM_GOOD_SUFFIX_ENABLED
    release_good_suffix_buf(good_suffix);
#endif
    return ERR_NOT_FOUND;
}
