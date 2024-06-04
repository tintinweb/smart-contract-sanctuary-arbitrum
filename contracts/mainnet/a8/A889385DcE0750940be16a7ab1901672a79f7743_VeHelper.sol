/**
 *Submitted for verification at Arbiscan.io on 2024-06-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract TokenHelper is Ownable {
    struct LocalVars {
        address to;
        uint256 amount;
    }

    constructor() {}

    function safeTransfer(address token, LocalVars[] calldata list)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < list.length; i++) {
            LocalVars memory info = list[i];
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                info.to,
                info.amount
            );
        }
    }

    function safeTransferETH(LocalVars[] calldata list)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < list.length; i++) {
            LocalVars memory info = list[i];
            TransferHelper.safeTransferETH(info.to, info.amount);
        }
    }
}

interface IVotingEscrow {
    function create_lock_for(
        address addr,
        uint256 value,
        uint256 lock_cycle
    ) external;
}

contract VeHelper is Ownable {
    address ve;
    address rwas;

    struct LocalVars {
        address to;
        uint256 amount;
    }

    constructor() {
        ve = 0xE5bebBD2579133C01bFfb5bCbCFE3418B41F4eBB;
        rwas = 0x1F2b426417663Ac76eB92149a037753a45969F31;
    }

    function _createLockFor(uint256 lock_cycle, LocalVars[] calldata list)
        internal
    {
        uint256 amount = 0;
        for (uint256 i = 0; i < list.length; i++) {
            LocalVars memory info = list[i];
            amount += info.amount;
        }
        TransferHelper.safeTransferFrom(
            rwas,
            tx.origin,
            address(this),
            amount 
        );
        TransferHelper.safeApprove(rwas, ve, amount);
        for (uint256 i = 0; i < list.length; i++) {
            LocalVars memory info = list[i];
            IVotingEscrow(ve).create_lock_for(info.to, info.amount, lock_cycle);
        }
    }

    function createLockFor1(LocalVars[] calldata list) external onlyOwner {
        uint256 lock_cycle = 86400 * 365;
        _createLockFor(lock_cycle, list);
    }

    function createLockFor2(LocalVars[] calldata list) external onlyOwner {
        uint256 lock_cycle = 86400 * 365 * 2;
        _createLockFor(lock_cycle, list);
    }

    function createLockFor4(LocalVars[] calldata list) external onlyOwner {
        uint256 lock_cycle = 86400 * 365 * 4;
        _createLockFor(lock_cycle, list);
    }
}