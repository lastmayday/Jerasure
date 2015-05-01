#pragma once

#ifdef __cplusplus
extern "C" {
#endif

    extern int evenodd_encode(int k, char **data_ptrs, char **coding_ptrs, int size);
    extern int evenodd_decode(int k, int *erasures, char **data_ptrs, char **coding_ptrs, int size);
    extern int evenodd_xor(int src_index, int dest_index, char *src, char *dest, int per);
    extern int evenodd_copy(int src_index, int dest_index, char *src, char *dest, int per);

#ifdef __cplusplus
}
#endif
