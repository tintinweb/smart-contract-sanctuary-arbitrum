// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {HaiProxy} from '@contracts/proxies/HaiProxy.sol';

contract HaiProxyFactory {
  event Created(address indexed _sender, address indexed _owner, address _proxy);

  mapping(address => bool) public isProxy;

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() external returns (address payable _proxy) {
    _proxy = _build(msg.sender);
  }

  // deploys a new_ proxy instance
  // sets custom owner of proxy
  function build(address _owner) external returns (address payable _proxy) {
    _proxy = _build(_owner);
  }

  function _build(address _owner) internal returns (address payable _proxy) {
    _proxy = payable(address(new HaiProxy(_owner)));
    isProxy[_proxy] = true;
    emit Created(msg.sender, _owner, address(_proxy));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {Ownable} from '@contracts/utils/Ownable.sol';

contract HaiProxy is Ownable {
  error TargetAddressRequired();
  error TargetCallFailed(bytes _response);

  constructor(address _owner) Ownable(_owner) {}

  function execute(address _target, bytes memory _data) external payable onlyOwner returns (bytes memory _response) {
    if (_target == address(0)) revert TargetAddressRequired();

    bool _succeeded;
    (_succeeded, _response) = _target.delegatecall(_data);

    if (!_succeeded) {
      revert TargetCallFailed(_response);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IOwnable} from '@interfaces/utils/IOwnable.sol';

abstract contract Ownable is IOwnable {
  address public owner;

  // --- Init ---
  constructor(address _owner) {
    _setOwner(_owner);
  }

  function setOwner(address _owner) external onlyOwner {
    _setOwner(_owner);
  }

  // --- Internal ---
  // TODO: make 2-step ownership transfer
  function _setOwner(address _newOwner) internal {
    owner = _newOwner;
    emit SetOwner(_newOwner);
  }

  // --- Modifiers ---
  /**
   * @notice Checks whether msg.sender can call an owned function
   */
  modifier onlyOwner() {
    if (msg.sender != owner) revert OnlyOwner();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IOwnable {
  // --- Events ---
  event SetOwner(address _newOwner);

  // --- Errors ---
  error OnlyOwner();

  // --- Data ---
  function owner() external view returns (address _owner);

  // --- Admin ---
  function setOwner(address _newOwner) external;
}