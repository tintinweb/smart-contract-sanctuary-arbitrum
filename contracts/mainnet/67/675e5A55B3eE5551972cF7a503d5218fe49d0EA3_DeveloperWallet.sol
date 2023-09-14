// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interface/IDatabase.sol";

/// @title   Developer Wallet
/// @notice  Contract that a developer is deployed upon minting of Proof of Developer NFT
/// @author  Hyacinth
contract DeveloperWallet {
    /// EVENTS ///

    /// @notice             Emitted after bounty has been added to
    /// @param token        Address of token added to bounty
    /// @param auditId      Audit id of audit bounty is being added to
    /// @param amountAdded  Amount added to bounty
    event AddedToBounty(address indexed token, uint256 indexed auditId, uint256 indexed amountAdded);

    /// ERRORS ///

    /// @notice Error for if audit id is not being audited
    error NotBeingAudited();
    /// @notice Error for if msg.sender is not database
    error NotDatabase();
    /// @notice Error for if contrac was not developed by developer
    error NotDeveloper();
    /// @notice Error for if bounty has been paid out already
    error BountyPaid();
    /// @notice Error for if USDC balance too low
    error BalanceTooLow();

    /// STATE VARIABLES ///

    /// @notice Address of developer
    address public immutable owner;
    /// @notice Address of USDC
    address public immutable USDC;
    /// @notice Address of database contract
    address public immutable database;

    /// @notice Amount of tokens on bounties
    mapping(address => uint256) public tokenOnBounties;

    /// @notice Bounty amount of token on audit
    mapping(uint256 => mapping(address => uint256)) public bountyOnContract;

    /// @notice Token addresses on bounty
    mapping(uint256 => address[]) public tokenAddressOnBounty;

    /// @notice Bool if bounty has been paid out
    mapping(uint256 => bool) public bountyPaidOut;

    /// CONSTRUCTOR ///

    constructor(address owner_, address database_) {
        owner = owner_;
        database = database_;
        USDC = IDatabase(database_).USDC();
    }

    /// EXTERNAL FUNCTION ///

    /// @notice           Add to bounty of `auditId_`
    /// @param auditId_   Audit id to add bounty to
    /// @param amount_    Amount of stable to add to bounty
    /// @param transfer_  Bool if transferring token in or using what has been transferred directly
    /// @param token_     Address of token on bounty
    function addToBounty(uint256 auditId_, uint256 amount_, bool transfer_, address token_) external {
        (, address developer_, , , , ) = IDatabase(database).audits(auditId_);
        if ((developer_ != owner || developer_ != msg.sender) && database != msg.sender) revert NotDeveloper();
        (, , IDatabase.STATUS status_, , , ) = IDatabase(database).audits(auditId_);
        if (status_ != IDatabase.STATUS.PENDING) revert NotBeingAudited();
        if (transfer_) IERC20(token_).transferFrom(msg.sender, address(this), amount_);
        else {
            uint256 avail_ = IERC20(token_).balanceOf(address(this)) - tokenOnBounties[token_];
            if (avail_ < amount_) revert BalanceTooLow();
        }

        if (bountyOnContract[auditId_][token_] == 0) tokenAddressOnBounty[auditId_].push(token_);
        bountyOnContract[auditId_][token_] += amount_;
        tokenOnBounties[token_] += amount_;

        emit AddedToBounty(token_, auditId_, amount_);
    }

    /// DATABASE FUNCTION ///

    /// @notice                   Pays out bounty of `auditId_`
    /// @param auditId_           Id of audit to pay bounty out for
    /// @param collaborators_     Array of collaborators for `auditId_`
    /// @param percentsOfBounty_  Array of corresponding percents of bounty for `collaborators_`
    /// @return level_            Level of bounty
    function payOutBounty(
        uint256 auditId_,
        address[] calldata collaborators_,
        uint256[] calldata percentsOfBounty_
    ) external returns (uint256 level_) {
        if (msg.sender != database) revert NotDatabase();
        if (bountyPaidOut[auditId_]) revert BountyPaid();

        bountyPaidOut[auditId_] = true;

        (address auditor_, , , , , ) = IDatabase(database).audits(auditId_);

        (level_, ) = currentBountyLevel(auditId_);

        for (uint i; i < tokenAddressOnBounty[auditId_].length; ++i) {
            address token_ = tokenAddressOnBounty[auditId_][i];
            uint256 bounty_ = bountyOnContract[auditId_][token_];
            tokenOnBounties[token_] -= bounty_;
            bountyOnContract[auditId_][token_] = 0;
            uint256 bountyToDistribute_ = ((bounty_ * (100 - IDatabase(database).HYACINTH_FEE())) / 100);
            uint256 hyacinthReceives_ = bounty_ - bountyToDistribute_;
            IERC20(token_).transfer(IDatabase(database).hyacinthWallet(), hyacinthReceives_);

            uint256 collaboratorsReceived_;
            for (uint256 n; n < collaborators_.length; ++n) {
                uint256 collaboratorsReceives_ = (bountyToDistribute_ * percentsOfBounty_[n]) / 100;
                IERC20(token_).transfer(collaborators_[n], collaboratorsReceives_);
                collaboratorsReceived_ += collaboratorsReceives_;
            }

            uint256 auditorReceives_ = bountyToDistribute_ - collaboratorsReceived_;
            IERC20(token_).transfer(auditor_, auditorReceives_);
        }
    }

    /// @notice           Rolls over bounty of `previous_` to `new_`
    /// @param previous_  Audit id of roll overed audit
    /// @param new_       Audsit id of new audit after roll over
    function rollOverBounty(uint256 previous_, uint256 new_) external {
        if (msg.sender != database) revert NotDatabase();

        for (uint i; i < tokenAddressOnBounty[previous_].length; ++i) {
            address token_ = tokenAddressOnBounty[previous_][i];
            uint256 bounty_ = bountyOnContract[previous_][token_];

            bountyOnContract[previous_][token_] = 0;
            bountyOnContract[new_][token_] = bounty_;
        }

        tokenAddressOnBounty[new_] = tokenAddressOnBounty[previous_];
    }

    /// @notice           Function that allows developer to get a refund for bounty if no auditor or past deadline
    /// @param auditId_   Audit id to get refund for
    function refundBounty(uint256 auditId_) external {
        if (msg.sender != database) revert NotDatabase();
        for (uint i; i < tokenAddressOnBounty[auditId_].length; ++i) {
            address token_ = tokenAddressOnBounty[auditId_][i];
            uint256 bounty_ = bountyOnContract[auditId_][token_];
            bountyOnContract[auditId_][token_] = 0;
            tokenOnBounties[token_] -= bounty_;
            IERC20(token_).transfer(owner, bounty_);
        }
    }

    /// VIEW FUNCTIONS ///

    /// @notice          Returns current `level_` and `bounty_` of `auditId_`
    /// @param auditId_  Audit to check bounty for
    /// @return level_   Current level of `contract_` bounty
    /// @return bounty_  Current bouty of `contract_`
    function currentBountyLevel(uint256 auditId_) public view returns (uint256 level_, uint256 bounty_) {
        bounty_ = bountyOnContract[auditId_][USDC];

        uint256 decimals_ = 10 ** IERC20Metadata(USDC).decimals();
        if (bounty_ >= 1000 * decimals_) {
            if (bounty_ < 10000 * decimals_) level_ = 1;
            else if (bounty_ < 100000 * decimals_) level_ = 2;
            else level_ = 3;
        }
    }
}

pragma solidity ^0.8.0;

interface IDatabase {
    enum STATUS {
        NOTAUDITED,
        PENDING,
        PASSED,
        FAILED,
        REFUNDED
    }

    function HYACINTH_FEE() external view returns (uint256);

    function USDC() external view returns (address);

    function audits(uint256 auditId_) external view returns (address, address, STATUS, string memory, uint256, bool);

    function auditors(address auditor_) external view returns (uint256, uint256, uint256, uint256);

    function approvedAuditor(address auditor_) external view returns (bool isAuditor_);

    function hyacinthWallet() external view returns (address);

    function beingAudited() external;

    function mintPOD() external returns (uint256 id_, address developerWallet_);

    function addApprovedAuditor(address[] calldata auditors_) external;

    function removeApprovedAuditor(address[] calldata auditors_) external;

    function giveAuditorFeedback(uint256 auditId_, bool positive_) external;

    function refundBounty(uint256 auditId_) external;

    function submitResult(uint256 auditId_, STATUS result_, string memory description_) external;

    function rollOverExpired(uint256 auditId_) external;

    function levelsCompleted(address auditor_) external view returns (uint256[4] memory);

    function auditStatus(address contractAddress_) external view returns (STATUS status_);
}