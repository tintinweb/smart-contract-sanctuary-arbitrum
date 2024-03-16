// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract ParamsController is Ownable {
    uint256 public gushRatioBp;
    uint256 public esGushRatioBp;
    uint256 public gushPerSec;
    uint256 public gushReleaseRatioBp;
    uint256 public feeDistributionForStakingBp;
    uint256 public feeDistributionForLockingBp;
    uint256 public feeChargeBp;
    uint256 public gusherBalancerVaultHarvesterFeeBp;

    address public gushAddr;
    address public esGushAddr;
    address public gushyUSHStakingAddr;
    address public votingEscrowAddr;
    address public treasuryAddr;

    event SetGushRatioBp(uint256 _gushRatioBp, uint256 _esGushRatioBp);
    event SetGushPerSec(uint256 _gushPerSec);
    event SetGushReleaseRatioBp(uint256 _gushReleaseRatioBp);
    event SetFeeDistributionBp(
        uint256 _feeDistributionForStakingBp, uint256 _feeDistributionForLockingBp, uint256 _feeChargeBp
    );
    event SetGushyUSHStakingAddr(address _gushyUSHStakingAddr);
    event SetVotingEscrowAddr(address _votingEscrowAddr);
    event SetTreasuryAddr(address _treasuryAddr);
    event SetGushAddr(address _gushAddr);
    event SetEsGushAddr(address _esGushAddr);

    constructor(
        uint256 _gushRatioBp,
        uint256 _esGushRatioBp,
        uint256 _gushPerSec,
        uint256 _gushReleaseRatioBp,
        uint256 _feeDistributionForStakingBp,
        uint256 _feeDistributionForLockingBp,
        uint256 _feeChargeBp,
        uint256 _gusherBalancerVaultHarvesterFeeBp
    ) {
        require(_gushRatioBp + _esGushRatioBp == 10000, "Invalid gush, esGush ratio!");
        require(
            _feeDistributionForStakingBp + _feeDistributionForLockingBp + _feeChargeBp == 10000,
            "Invalid fee distribution ratio!"
        );
        gushRatioBp = _gushRatioBp;
        esGushRatioBp = _esGushRatioBp;
        gushPerSec = _gushPerSec;
        gushReleaseRatioBp = _gushReleaseRatioBp;
        feeDistributionForStakingBp = _feeDistributionForStakingBp;
        feeDistributionForLockingBp = _feeDistributionForLockingBp;
        feeChargeBp = _feeChargeBp;
        gusherBalancerVaultHarvesterFeeBp = _gusherBalancerVaultHarvesterFeeBp;
    }

    function setGushRatioBp(uint256 _gushRatioBp, uint256 _esGushRatioBp) external onlyOwner {
        require(_gushRatioBp + _esGushRatioBp == 10000, "Invalid gush, esGush ratio!");
        gushRatioBp = _gushRatioBp;
        esGushRatioBp = _esGushRatioBp;
        emit SetGushRatioBp(_gushRatioBp, _esGushRatioBp);
    }

    function setGushPerSec(uint256 _gushPerSec) external onlyOwner {
        gushPerSec = _gushPerSec;
        emit SetGushPerSec(_gushPerSec);
    }

    function setGushReleaseRatioBp(uint256 _gushReleaseRatioBp) external onlyOwner {
        gushReleaseRatioBp = _gushReleaseRatioBp;
        emit SetGushReleaseRatioBp(_gushReleaseRatioBp);
    }

    function setFeeDistributionBp(
        uint256 _feeDistributionForStakingBp,
        uint256 _feeDistributionForLockingBp,
        uint256 _feeChargeBp
    ) external onlyOwner {
        require(
            _feeDistributionForStakingBp + _feeDistributionForLockingBp + _feeChargeBp == 10000,
            "Invalid fee distribution ratio!"
        );
        feeDistributionForStakingBp = _feeDistributionForStakingBp;
        feeDistributionForLockingBp = _feeDistributionForLockingBp;
        feeChargeBp = _feeChargeBp;
        emit SetFeeDistributionBp(_feeDistributionForStakingBp, _feeDistributionForLockingBp, _feeChargeBp);
    }

    function setGushyUSHStakingAddr(address _gushyUSHStakingAddr) external onlyOwner {
        gushyUSHStakingAddr = _gushyUSHStakingAddr;
        emit SetGushyUSHStakingAddr(_gushyUSHStakingAddr);
    }

    function setVotingEscrowAddr(address _votingEscrowAddr) external onlyOwner {
        votingEscrowAddr = _votingEscrowAddr;
        emit SetVotingEscrowAddr(_votingEscrowAddr);
    }

    function setTreasuryAddr(address _treasuryAddr) external onlyOwner {
        treasuryAddr = _treasuryAddr;
        emit SetTreasuryAddr(_treasuryAddr);
    }

    function setGushAddr(address _gushAddr) external onlyOwner {
        gushAddr = _gushAddr;
        emit SetGushAddr(_gushAddr);
    }

    function setEsGushAddr(address _esGushAddr) external onlyOwner {
        esGushAddr = _esGushAddr;
        emit SetEsGushAddr(_esGushAddr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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