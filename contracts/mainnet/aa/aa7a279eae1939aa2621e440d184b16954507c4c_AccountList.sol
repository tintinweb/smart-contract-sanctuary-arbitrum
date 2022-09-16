// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import "./IAccountList.sol";
import "./SafeOwnable.sol";

contract AccountList is IAccountList, SafeOwnable {
  uint256 private _resetIndex;
  mapping(uint256 => mapping(address => bool))
    private _resetIndexToAccountToIncluded;

  constructor() {}

  function set(address[] calldata _accounts, bool[] calldata _included)
    external
    override
    onlyOwner
  {
    require(_accounts.length == _included.length, "Array length mismatch");
    uint256 _arrayLength = _accounts.length;
    for (uint256 i; i < _arrayLength; ) {
      _resetIndexToAccountToIncluded[_resetIndex][_accounts[i]] = _included[i];
      unchecked {
        ++i;
      }
    }
  }

  function reset(address[] calldata _newIncludedAccounts)
    external
    override
    onlyOwner
  {
    _resetIndex++;
    uint256 _arrayLength = _newIncludedAccounts.length;
    for (uint256 i; i < _arrayLength; ) {
      _resetIndexToAccountToIncluded[_resetIndex][
        _newIncludedAccounts[i]
      ] = true;
      unchecked {
        ++i;
      }
    }
  }

  function isIncluded(address _account) external view override returns (bool) {
    return _resetIndexToAccountToIncluded[_resetIndex][_account];
  }
}