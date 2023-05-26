// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Constant.sol";


contract Approvable is Ownable {

    address public configurator;
    address public approver;

    modifier onlyConfigurator() {
        require(msg.sender == configurator, "Not configurator");
        _;
    }

    modifier onlyApprover() {
        require(msg.sender == approver, "Not approver");
        _;
    }

    event ChangeConfigurator(address oldAddress, address newAddress);
    event ChangeApprover(address oldAddress, address newAddress);

    constructor (address newConfigurator, address newApprover) {
        require(newConfigurator != Constant.ZERO_ADDRESS && newApprover != Constant.ZERO_ADDRESS, "Invalid Address");
        configurator = newConfigurator;
        approver = newApprover;
    }

    function changeConfigurator(address newConfigurator) external onlyOwner {
        require(newConfigurator != Constant.ZERO_ADDRESS, "Invalid Address");
        require(newConfigurator != approver, "Configurator and approver cannot be the same");

        emit ChangeConfigurator(configurator, newConfigurator);
        configurator = newConfigurator;
    }

    function changeApprover(address newApprover) external onlyOwner {
        require(newApprover != Constant.ZERO_ADDRESS, "Invalid Address");
        require(newApprover != configurator, "Creator and approver cannot be the same");

        emit ChangeApprover(approver, newApprover);
        approver = newApprover;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../base/Approvable.sol";
import "../interfaces/IParameterProvider.sol";
import "../Constant.sol";

// A contract to add a list of approved parameters for eVM chain
contract ProposalsEvmExecutor is Approvable {

    struct Changes {
        uint id;
        ParamKey[] keys;
        uint[] values;
        bool active;
    }

    IParameterProvider public paramProvider;

    Changes  changes;
    
    event ChangesAdded(uint id);
    event ChangesApproved(uint id);
    event ChangesRejected(uint id);


    constructor(address configurator, address approver, IParameterProvider  provider) Approvable(configurator, approver) {
        paramProvider = provider;
    }

    function addChanges(ParamKey[] calldata keys, uint[] calldata values) external onlyConfigurator {

        require(!changes.active, "Already active. Approve first");
        changes.id++;
        changes.keys = keys;
        changes.values = values;
        changes.active = true;

        emit ChangesAdded(changes.id);
    }

    function validateChanges(ParamKey[] calldata keys, uint[] calldata values) external returns (bool) {
        return paramProvider.validateChanges(keys, values);
    }

    function approveChanges() external onlyApprover {

        bool validated = paramProvider.validateChanges(changes.keys, changes.values);
        require(validated, "Validation failed");
        
        // Send the changes to ParameterProvider
        paramProvider.setValues(changes.keys, changes.values);
        _resetChanges();
        emit ChangesApproved(changes.id);
    }

    function rejectChanges() external onlyApprover {
        _resetChanges();
        emit ChangesRejected(changes.id);
    }

    function _resetChanges() private {
        delete changes.keys;
        delete changes.values;
        changes.active = false;
    }
}

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.8.15;

library Constant {

    address public constant ZERO_ADDRESS                        = address(0);
    uint    public constant E18                                 = 1e18;
    uint    public constant PCNT_100                            = 1e18;
    uint    public constant PCNT_50                             = 5e17;
    uint    public constant E12                                 = 1e12;
    
    // SaleTypes
    uint8    public constant TYPE_IDO                            = 0;
    uint8    public constant TYPE_OTC                            = 1;
    uint8    public constant TYPE_NFT                            = 2;

    uint8    public constant PUBLIC                              = 0;
    uint8    public constant STAKER                              = 1;
    uint8    public constant WHITELISTED                         = 2;

    // Misc
    bytes public constant ETH_SIGN_PREFIX                       = "\x19Ethereum Signed Message:\n32";

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum ParamKey {

        // There will only be 1 parameterProvders in the native chain.
        // The rest of the eVM contracts will retrieve from this single parameterProvider.

        ProposalTimeToLive,
        ProposalMinPower,
        ProposalMaxQueue,
        ProposalVotingDuration,
        ProposalLaunchCollateral,
        ProposalTimeLock,
        ProposalCreatorExecutionDuration,
        ProposalQuorumPcnt, // Eg 30% of total power voted (Yes, No, Abstain) to pass.
        ProposalDummy1, // For future
        ProposalDummy2, // For future

        StakerMinLaunch,        // Eg: Min 1000 vLaunch
        StakerCapLaunch,        // Eg: Cap at 50,000 vLaunch
        StakerDiscountMinPnct,  // Eg: 1000 vLaunch gets 0.6% discount on Fee. For OTC and NFT only.
        StakerDiscountCapPnct,  // Eg: 50,000 vLaunch gets 30%% discount on Fee. For OTC and NFT only.
        StakerDummy1,           // For future
        StakerDummy2,           // For future

        RevShareReferralPcnt,   // Fee% for referrals
        RevShareTreasuryPcnt,   // Fee% for treasury
        RevShareDealsTeamPcnt,  // Business & Tech .
        RevShareDummy1, // For future
        RevShareDummy2, // For future

        ReferralUplineSplitPcnt,    // Eg 80% of rebate goes to upline, 20% to user
        ReferralDummy1, // For future
        ReferralDummy2, // For future

        SaleUserMaxFeePcnt,         // User's max fee% for any sale
        SaleUserCurrentFeePcnt,     // The current user's fee%
        SaleChargeFee18Dp,          // Each time a user buys, there's a fee like $1. Can be 0.
        SaleMaxPurchasePcntByFund,  // The max % of hardCap that SuperLauncher Fund can buy in a sale.
        SaleDummy1, // For future
        SaleDummy2, // For future

        lastIndex
    }

interface IParameterProvider {

    function setValue(ParamKey key, uint value) external;
    function setValues(ParamKey[] memory keys, uint[] memory values) external;
    function getValue(ParamKey key) external view returns (uint);
    function getValues(ParamKey[] memory keys) external view returns (uint[] memory);

    // Validation
    function validateChanges(ParamKey[] calldata keys, uint[] calldata values) external returns (bool success);
}