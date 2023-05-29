// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
pragma solidity 0.8.18;

import {ERC20} from "./ERC20.sol";
import {Ownable} from "./Ownable.sol";

contract LHMX is ERC20, Ownable {
  mapping(address => bool) public isTransferor;
  mapping(address => bool) public isMinter;

  // Events
  event LHMX_SetMinter(address minter, bool prevAllow, bool newAllow);
  event LHMX_SetTransferor(address transferor, bool prevAllow, bool newAllow);

  // Errors
  error LHMX_NotMinter();
  error LHMX_IsNotTransferrer();

  modifier onlyMinter() {
    if (!isMinter[msg.sender]) revert LHMX_NotMinter();
    _;
  }

  constructor() ERC20("Locked HMX", "LHMX") {}

  /// @notice Set minter.
  /// @param minter The address of the minter.
  /// @param allow Whether to allow the minter.
  function setMinter(address minter, bool allow) external onlyOwner {
    emit LHMX_SetMinter(minter, isMinter[minter], allow);
    isMinter[minter] = allow;
  }

  function setTransferror(address transferor, bool isActive) external onlyOwner {
    emit LHMX_SetTransferor(transferor, isTransferor[transferor], isActive);
    isTransferor[transferor] = isActive;
  }

  function mint(address to, uint256 amount) public onlyMinter {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public onlyMinter {
    _burn(from, amount);
  }

  function _beforeTokenTransfer(
    address, /* from */
    address, /* to */
    uint256 /*amount*/
  ) internal virtual override {
    if (!isTransferor[msg.sender]) revert LHMX_IsNotTransferrer();
  }
}