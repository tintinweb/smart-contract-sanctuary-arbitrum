// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

/**
 * @title Binary search for arrays
 */
library BinarySearch {
  function findInternal(uint256[] calldata data, uint256 begin, uint256 end, uint256 value) internal pure returns (uint256 ret) {
    uint256 len = end - begin;
    if (len == 0 || (len == 1 && data[begin] != value)) {
      return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }
    uint256 mid = begin + len / 2;
    uint256 v = data[mid];
    if (value < v)
      return findInternal(data, begin, mid, value);
    else if (value > v)
      return findInternal(data, mid + 1, end, value);
    else
      return mid;
  }
  
  /**
   * @notice Binary search for given sorted array by given integer value
   */
  function bsearch(uint256[] calldata sortedArray, uint256 value) public pure returns (uint256 ret) {
    return findInternal(sortedArray, 0, sortedArray.length, value);
  }
}