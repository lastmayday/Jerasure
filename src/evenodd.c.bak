#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "galois.h"
#include "jerasure.h"
#include "evenodd.h"

#define talloc(type, num) (type *) malloc(sizeof(type)*(num))


// 分别从src_index和dest_index开始对per位异或, 结果保存在dest中
int evenodd_xor(int src_index, int dest_index, char *src, char *dest, int per)
{
    int i, src_tmp, dest_tmp;
    for (i = 0; i < per; i++) {
        src_tmp = src_index * per + i;
        dest_tmp = dest_index * per + i;
        dest[dest_tmp] ^= src[src_tmp];
    }
    return 1;
}

// 分别从src_index和dest_index开始将src的per位复制到dest
int evenodd_copy(int src_index, int dest_index, char *src, char *dest, int per)
{
    int i, src_tmp, dest_tmp;
    for (i = 0; i < per; i++) {
        src_tmp = src_index * per + i;
        dest_tmp = dest_index * per + i;
        dest[dest_tmp] = src[src_tmp];
    }
    return 1;
}

int get_s0(int k, char **data_ptrs, char **coding_ptrs, char *s0, int u, int per, int a, int b)
{
    int i;
    evenodd_copy(u, 0, coding_ptrs[0], s0, per);
    for (i = 0; i < k; i++) {
        if (i == a || i == b) continue;
        evenodd_xor(u, 0, data_ptrs[i], s0, per);
    }
    return 1;
}

int get_s1(int k, char **data_ptrs, char **coding_ptrs, char *s, char *s1, int u, int per, int a, int b)
{
    int i, tmp;
    evenodd_copy(0, 0, s, s1, per);
    evenodd_xor(u, 0, coding_ptrs[1], s1, per);
    for (i = 0; i < k; i++) {
        if (i == a || i == b) continue;
        tmp = u - i;
        while (tmp < 0) tmp += k;
        if (tmp > k-2) continue;
        evenodd_xor(tmp, 0, data_ptrs[i], s1, per);
    }
    return 1;
}

int evenodd_encode(int k, char **data_ptrs, char **coding_ptrs, int size)
{
    int i, j;
    int per, tmp;
    char *s;

    // 构造 P
    memcpy(coding_ptrs[0], data_ptrs[0], size);
    for (i = 1; i < k; i++) galois_region_xor(data_ptrs[i], coding_ptrs[0], size);

    // 构造 s
    per = size / (k - 1);
    s = talloc(char, per);
    if (s == NULL) return -1;

    evenodd_copy(k-2, 0, data_ptrs[1], s, per);
    for (i = 2; i < k; i++) {
        evenodd_xor(k-1-i, 0, data_ptrs[i], s, per);
    }

    // 构造 Q
    for (i = 0; i < k-1; i++) {
        evenodd_copy(0, i, s, coding_ptrs[1], per);
    }
    for (i = 0; i < k-1; i++) {
        for (j = 0; j < k; j++) {
            tmp = i - j;
            while (tmp < 0) tmp += k;
            if (tmp > k-2) continue;
            evenodd_xor(tmp, i, data_ptrs[j], coding_ptrs[1], per);
        }
    }

    free(s);
    return 1;
}

int evenodd_decode(int k, int *erasures, char **data_ptrs, char **coding_ptrs, int size)
{
    int *erased;
    int m = 2;
    int i, j, edd, per;
    int a, b; // 被损坏的盘符
    int tmp, tmp_s;
    char *s, *z;
    char *s0, *s1;

    erased = jerasure_erasures_to_erased(k, m, erasures);
    if (erased == NULL) return -1;

    edd = 0;
    a = b = k;
    for (i = 0; i < k+m; i++) {
        if (erased[i]) {
            edd++;
            if (a == k) a = i;
            else b = i;
        }
    }

    per = size / (k - 1);
    s = talloc(char, per);
    z = talloc(char, per);
    s0 = talloc(char, per);
    s1 = talloc(char, per);
    if (s == NULL || s0 == NULL || s1 == NULL) return -1;
    for (i = 0; i < per; i++) {
        z[i] = 0;
    }

    // 没有损坏, 直接恢复
    if (edd == 0) return 0;
    // 一个损坏
    else if (edd == 1) {
        // 校验数据 P 或 Q 损坏, 直接恢复
        if (erased[k] || erased[k+1]) return 0;
        // 否则根据 P 恢复原始数据
        else {
            memcpy(data_ptrs[a], coding_ptrs[0], size);
            for (i = 0; i < k; i++){
                if (i == a) continue;
                galois_region_xor(data_ptrs[i], data_ptrs[a], size);
            }
        }
    }
    // 两个损坏
    else if (edd == 2) {
        // 校验数据 P 和 Q 都损坏, 直接恢复
        if (erased[k] && erased[k+1]) return 0;
        // 校验数据 P 和一个原始数据损坏
        else if (erased[k]) {
            // 先恢复参数 S
            tmp = a - 1;
            while (tmp < 0) tmp += k;
            evenodd_copy(tmp, 0, coding_ptrs[1], s, per);
            for (i = 0; i < k; i++) {
                tmp = a - i -1;
                while (tmp < 0) tmp += k;
                if (tmp > k-2) continue;
                evenodd_xor(tmp, 0, data_ptrs[i], s, per);
            }

            // 再恢复数据块
            for (i = 0; i < k-1; i++) {
                evenodd_copy(0, i, s, data_ptrs[a], per);
                tmp = a + i;
                if (tmp < k-1)
                    evenodd_xor(tmp, i, coding_ptrs[1], data_ptrs[a], per);
                for (j = 0; j < k; j++) {
                    if (j == a) continue;
                    tmp = i + a - j;
                    while (tmp < 0) tmp += k;
                    if (tmp > k-2) continue;
                    evenodd_xor(tmp, i, data_ptrs[j], data_ptrs[a], per);
                }
            }
        }
        // 校验数据 Q 和一个原始数据损坏, 通过 P 直接恢复
        else if (erased[k+1]) {
            memcpy(data_ptrs[a], coding_ptrs[0], size);
            for (i = 0; i < k; i++){
                if (i == a) continue;
                galois_region_xor(data_ptrs[i], data_ptrs[a], size);
            }
        }
        // 两个原始数据损坏
        else {
            // 先由 P 和 Q 计算出 S
            evenodd_copy(0, 0, coding_ptrs[0], s, per);
            evenodd_xor(0, 0, coding_ptrs[1], s, per);
            for (i = 1; i < k-1; i++) {
                evenodd_xor(i, 0, coding_ptrs[0], s, per);
                evenodd_xor(i, 0, coding_ptrs[1], s, per);
            }

            for (i = 0; i < k; i++) {
                evenodd_copy(0, k-1, z, data_ptrs[i], per);
            }

            tmp_s = -(b - a) - 1;
            while (tmp_s < 0) tmp_s += k;
            while (tmp_s != k-1) {
                tmp = (b + tmp_s) % k;
                get_s1(k, data_ptrs, coding_ptrs, s, s1, tmp, per, a, b);
                evenodd_copy(0, tmp_s, s1, data_ptrs[b], per);
                tmp = (tmp_s + b - a) % k;
                evenodd_xor(tmp, tmp_s, data_ptrs[a], data_ptrs[b], per);

                get_s0(k, data_ptrs, coding_ptrs, s0, tmp_s, per, a, b);
                evenodd_copy(0, tmp_s, s0, data_ptrs[a], per);
                evenodd_xor(tmp_s, tmp_s, data_ptrs[b], data_ptrs[a], per);

                tmp_s = tmp_s - (b - a);
                while(tmp_s < 0) tmp_s += k;
                while(tmp_s > k) tmp_s -= k;
            }
        }
    }
    else {
        free(erased);
        return -1;
    }

    free(s);
    free(z);
    free(s0);
    free(s1);
    return 0;
}
