// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import "./IAllowlistPurchaseHook.sol";
import "./IAccountList.sol";
import "./SafeOwnable.sol";

contract AllowlistPurchaseHook is IAllowlistPurchaseHook, SafeOwnable {
  IAccountList private _allowlist;

  constructor() {}

  function hook(
    address _purchaser,
    address _recipient,
    uint256 _amount,
    uint256 _price,
    bytes calldata _data
  ) public virtual override {
    require(_allowlist.isIncluded(_recipient), "Recipient not allowed");
  }

  function setAllowlist(IAccountList _newAllowlist)
    external
    override
    onlyOwner
  {
    _allowlist = _newAllowlist;
    emit AllowlistChange(_newAllowlist);
  }

  function getAllowlist() external view override returns (IAccountList) {
    return _allowlist;
  }
}