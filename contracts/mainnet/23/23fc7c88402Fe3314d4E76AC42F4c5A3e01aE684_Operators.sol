// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract Operators is Context {
    // level 1: normal operator
    // level 2: rewards and feed manager
    // level 3: admin
    // level 4: owner
    mapping(address => uint256) operatorLevel;

    address public oldOwner;
    address public pendingOwner;

    modifier onlyOperator(uint256 level) {
        require(operatorLevel[_msgSender()] >= level, "invalid operator");
        _;
    }

    constructor() {
        operatorLevel[_msgSender()] = 4;
    }

    function setOperator(address op, uint256 level) external onlyOperator(4) {
        operatorLevel[op] = level;
    }

    function getOperatorLevel(address op) public view returns (uint256) {
        return operatorLevel[op];
    }

    function transferOwnership(address newOwner) external onlyOperator(4) {
        require(newOwner != address(0), "zero address");

        oldOwner = _msgSender();
        pendingOwner = newOwner;
    }

    function acceptOwnership() external {
        require(_msgSender() == pendingOwner, "not pendingOwner");

        operatorLevel[_msgSender()] = 4;
        operatorLevel[oldOwner] = 0;

        pendingOwner = address(0);
        oldOwner = address(0);
    }
}