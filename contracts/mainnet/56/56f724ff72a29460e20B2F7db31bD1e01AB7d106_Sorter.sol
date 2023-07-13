// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

contract Sorter  {
    function quickSort(uint[] memory arr, uint left, uint right) public pure {
        uint i = left;
        uint j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function quickSort1(uint[] memory arr, uint left, uint right) public pure {
        if (left >= right)
            return;
        uint p = arr[(left + right) / 2];   // p = the pivot element
        uint i = left;
        uint j = right;
        while (i < j) {
            while (arr[i] < p) ++i;
            while (arr[j] > p) --j;         // arr[j] > p means p still to the left, so j > 0
            if (arr[i] > arr[j])
                (arr[i], arr[j]) = (arr[j], arr[i]);
            else
                ++i;
        }

        // Note --j was only done when a[j] > p.  So we know: a[j] == p, a[<j] <= p, a[>j] > p
        if (j > left)
            quickSort(arr, left, j - 1);    // j > left, so j > 0
        quickSort(arr, j + 1, right);
    }

    function sort(uint[] memory data) private pure returns (uint[] memory) {
        quickSort(data, 0, data.length - 1);
        return data;
    }

    function sort1(uint[] memory data) public pure returns (uint[] memory) {
        quickSort1(data, 0, data.length - 1);
        return data;
    }
}