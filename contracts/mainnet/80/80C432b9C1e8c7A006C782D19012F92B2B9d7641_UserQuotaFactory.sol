/**
 *Submitted for verification at Arbiscan on 2022-03-23
*/

// File: contracts/lib/CloneFactory.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/lib/InitializableOwnable.sol

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/DODOFee/UserQuotaFactory.sol


interface IQuota {
    function initOwner(address newOwner) external;
    function getUserQuota(address user) external view returns (int);
}


/**
 * @title DODO UserQuotaFactory
 * @author DODO Breeder
 *
 */
contract UserQuotaFactory is InitializableOwnable{
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public immutable _USER_QUOTA_TEMPLATE_;

    // ============ Events ============

    event NewQuota(address quota);

    // ============ Functions ============

    constructor(
        address cloneFactory,
        address quotaTemplate
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _USER_QUOTA_TEMPLATE_ = quotaTemplate;
    }

    function createQuota(
        address quotaOwner
    ) external onlyOwner returns(address newQuota){
        newQuota = ICloneFactory(_CLONE_FACTORY_).clone(_USER_QUOTA_TEMPLATE_);
        IQuota(newQuota).initOwner(quotaOwner);
        emit NewQuota(newQuota);
    }
}