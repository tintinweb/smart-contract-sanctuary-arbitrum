// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {HaiProxyFactory} from '@contracts/proxies/HaiProxyFactory.sol';
import {HaiProxy} from '@contracts/proxies/HaiProxy.sol';
import {Assertions} from '@libraries/Assertions.sol';

contract HaiProxyRegistry {
  using Assertions for address;

  mapping(address _owner => HaiProxy) public proxies;
  HaiProxyFactory public factory;

  // --- Events ---
  event Build(address _usr, address _proxy);

  constructor(address _factory) {
    factory = HaiProxyFactory(_factory.assertNonNull());
  }

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() public returns (address payable _proxy) {
    _proxy = _build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address _owner) public returns (address payable _proxy) {
    _proxy = _build(_owner);
  }

  function _build(address _owner) internal returns (address payable _proxy) {
    // Not allow new _proxy if the user already has one and remains being the owner
    require(proxies[_owner] == HaiProxy(payable(address(0))) || proxies[_owner].owner() != _owner);
    _proxy = factory.build(_owner);
    proxies[_owner] = HaiProxy(_proxy);
    emit Build(_owner, _proxy);
  }
}

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

library Assertions {
  error NotGreaterThan(uint256 _x, uint256 _y);
  error NotLesserThan(uint256 _x, uint256 _y);
  error NotGreaterOrEqualThan(uint256 _x, uint256 _y);
  error NotLesserOrEqualThan(uint256 _x, uint256 _y);
  error IntNotGreaterThan(int256 _x, int256 _y);
  error IntNotLesserThan(int256 _x, int256 _y);
  error IntNotGreaterOrEqualThan(int256 _x, int256 _y);
  error IntNotLesserOrEqualThan(int256 _x, int256 _y);
  error NullAmount();
  error NullAddress();

  // --- Assertions ---

  function assertGt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x <= _y) revert NotGreaterThan(_x, _y);
    return _x;
  }

  function assertGt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x <= _y) revert IntNotGreaterThan(_x, _y);
    return _x;
  }

  function assertGtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x < _y) revert NotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  function assertGtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x < _y) revert IntNotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  function assertLt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x >= _y) revert NotLesserThan(_x, _y);
    return _x;
  }

  function assertLt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x >= _y) revert IntNotLesserThan(_x, _y);
    return _x;
  }

  function assertLtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x > _y) revert NotLesserOrEqualThan(_x, _y);
    return _x;
  }

  function assertLtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x > _y) revert IntNotLesserOrEqualThan(_x, _y);
    return _x;
  }

  function assertNonNull(uint256 _x) internal pure returns (uint256 __x) {
    if (_x == 0) revert NullAmount();
    return _x;
  }

  function assertNonNull(address _address) internal pure returns (address __address) {
    if (_address == address(0)) revert NullAddress();
    return _address;
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