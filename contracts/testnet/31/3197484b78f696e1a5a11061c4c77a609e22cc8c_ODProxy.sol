// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

contract ODProxy {
  error TargetAddressRequired();
  error TargetCallFailed(bytes _response);
  error OnlyOwner();

  address public immutable OWNER;

  constructor(address _owner) {
    OWNER = _owner;
  }

  /**
   * @notice Checks whether msg.sender can call an owned function
   */
  modifier onlyOwner() {
    if (msg.sender != OWNER) revert OnlyOwner();
    _;
  }

  function execute(address _target, bytes memory _data) external payable onlyOwner returns (bytes memory _response) {
    if (_target == address(0)) revert TargetAddressRequired();

    bool _succeeded;
    (_succeeded, _response) = _target.delegatecall(_data);

    if (!_succeeded) {
      revert TargetCallFailed(_response);
    }
  }
}