// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { BaalAllowlist } from "src/core/allowlists/BaalAllowlist.sol";
import { ZodiacCookieJar } from "./ZodiacCookieJar.sol";

/**
 * @title ZodiacBaalCookieJar
 * @dev This contract extends BaalAllowlist and ZodiacCookieJar to provide a mechanism for maintaining a cookie jar with
 * an allowlist.
 */
contract ZodiacBaalCookieJar is BaalAllowlist, ZodiacCookieJar {
    /**
     * @notice Sets up the ZodiacBaalCookieJar contract.
     * @dev This function is public and overrides the base contracts' setup functions.
     * It first calls the __Allowlist_init function with the provided initialization parameters, then calls the base
     * contracts' setup functions.
     * @param _initializationParams The initialization parameters as bytes.
     */
    function setUp(bytes memory _initializationParams) public override {
        __Allowlist_init(_initializationParams);
        super.setUp(_initializationParams);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { IBaalToken } from "@daohaus/baal-contracts/contracts/interfaces/IBaalToken.sol";
import { IBaal } from "@daohaus/baal-contracts/contracts/interfaces/IBaal.sol";
import { AllowlistBase } from "./AllowlistBase.sol";

/**
 * @title BaalAllowlist
 * @dev This contract implements the IAllowlist interface and provides a mechanism for maintaining an allowlist of
 * addresses based on the Baal DAO's shares and loot tokens.
 */
contract BaalAllowlist is AllowlistBase {
    /// @notice The address of the Baal DAO.
    address public dao;

    /// @notice The minimum balance of shares or loot tokens required to be in the allowlist.
    uint256 public threshold;

    /// @notice A boolean indicating whether shares are used for the allowlist.
    bool public useShares;

    /// @notice A boolean indicating whether loot tokens are used for the allowlist.
    bool public useLoot;

    /**
     * @notice Sets up the allowlist that allows access to the cookie jar based on DAO token balances.
     * @dev This function decodes the initialization parameters and sets the state variables accordingly.
     * @param _initializationParams The parameters to initialize the allowlist. It should be encoded as (address,
     * uint256, uint256, address, address, uint256, bool, bool).
     */
    function __Allowlist_init(bytes memory _initializationParams) public virtual override {
        (,,,, address _dao, uint256 _threshold, bool _useShares, bool _useLoot) =
            abi.decode(_initializationParams, (address, uint256, uint256, address, address, uint256, bool, bool));

        dao = _dao;
        threshold = _threshold;
        useShares = _useShares;
        useLoot = _useLoot;
    }

    /**
     * @notice Checks if an address has the required token balances.
     * @dev This function checks the balance of shares and/or loot tokens of the user in the Baal DAO. If the balance is
     * greater than or equal to the threshold, the user is in the allowlist.
     * @param user The address to check.
     * @return A boolean indicating whether the address is in the allowlist.
     */
    function _isAllowList(address user) internal view override returns (bool) {
        if (useShares && useLoot) {
            return IBaalToken(IBaal(dao).sharesToken()).balanceOf(user) >= threshold
                || IBaalToken(IBaal(dao).lootToken()).balanceOf(user) >= threshold;
        }
        if (useLoot) {
            return IBaalToken(IBaal(dao).lootToken()).balanceOf(user) >= threshold;
        }
        return IBaalToken(IBaal(dao).sharesToken()).balanceOf(user) >= threshold;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { CookieJarCore } from "src/core/CookieJarCore.sol";
import { GiverZodiac } from "src/core/givers/GiverZodiac.sol";
import { CookieUtils } from "src/lib/CookieUtils.sol";

/**
 * @title ZodiacCookieJar
 * @dev This abstract contract extends GiverZodiac to provide a base for contracts that manage a cookie jar.
 */
abstract contract ZodiacCookieJar is GiverZodiac {
    /**
     * @notice Sets up the ZodiacCookieJar contract.
     * @dev This function is public and virtual, and it overrides the base contract's setup function.
     * It first calls the base contract's setUp function with the provided initialization parameters, then transfers the
     * ownership to the target.
     * @param _initializationParams The initialization parameters as bytes.
     */
    function setUp(bytes memory _initializationParams) public virtual override {
        super.setUp(_initializationParams);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBaalToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function setUp(string memory _name, string memory _symbol) external;

    function mint(address recipient, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
    
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function snapshot() external returns(uint256);

    function getCurrentSnapshotId() external returns(uint256);

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);

    // below is shares token specific
    struct Checkpoint {
        uint32 fromTimePoint;
        uint256 votes;
    }

    function getPastVotes(address account, uint256 timePoint) external view returns (uint256);

    function numCheckpoints(address) external view returns (uint256);

    function getCheckpoint(address, uint256)
        external
        view
        returns (Checkpoint memory);

    function getVotes(address account) external view returns (uint256);

    function delegates(address account) external view returns (address);

    function delegationNonces(address account) external view returns (uint256);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBaal {
    function lootToken() external view returns (address);
    function sharesToken() external view returns (address);
    function votingPeriod() external view returns (uint32);
    function gracePeriod() external view returns (uint32);
    function proposalCount() external view returns (uint32);
    function proposalOffering() external view returns (uint256);
    function quorumPercent() external view returns (uint256);
    function sponsorThreshold() external view returns (uint256);
    function minRetentionPercent() external view returns (uint256);
    function latestSponsoredProposalId() external view returns (uint32);

    function setUp(bytes memory initializationParams) external;
    function multisendLibrary() external view returns (address);
    // Module
    function avatar() external view returns (address);
    function target() external view returns (address);
    function setAvatar(address avatar) external;
    function setTarget(address avatar) external;
    // BaseRelayRecipient
    function trustedForwarder() external view returns (address);
    function setTrustedForwarder(address trustedForwarderAddress) external;

    function mintLoot(address[] calldata to, uint256[] calldata amount) external;
    function burnLoot(address[] calldata from, uint256[] calldata amount) external;
    function mintShares(address[] calldata to, uint256[] calldata amount) external;
    function burnShares(address[] calldata from, uint256[] calldata amount) external;
    function totalLoot() external view returns (uint256);
    function totalShares() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function lootPaused() external view returns (bool);
    function sharesPaused() external view returns (bool);
    
    function shamans(address shaman) external view returns (uint256);
    function setShamans(address[] calldata shamans, uint256[] calldata permissions) external;
    function isAdmin(address shaman) external view returns (bool);
    function isManager(address shaman) external view returns (bool);
    function isGovernor(address shaman) external view returns (bool);
    function lockAdmin() external;
    function lockManager() external;
    function lockGovernor() external;
    function adminLock() external view returns (bool);
    function managerLock() external view returns (bool);
    function governorLock() external view returns (bool);
    function setAdminConfig(bool pauseShares, bool pauseLoot) external;
    function setGovernanceConfig(bytes memory governanceConfig) external;

    function submitProposal(
        bytes calldata proposalData,
        uint32 expiration,
        uint256 baalGas,
        string calldata details
    ) external payable returns (uint256);
    function sponsorProposal(uint32 id) external;
    function processProposal(uint32 id, bytes calldata proposalData) external;
    function cancelProposal(uint32 id) external;
    function getProposalStatus(uint32 id) external returns (bool[4] memory);
    function submitVote(uint32 id, bool approved) external;
    function submitVoteWithSig(
        address voter,
        uint256 expiry,
        uint256 nonce,
        uint32 id,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function executeAsBaal(address to, uint256 value, bytes calldata data) external;
    function ragequit(address to, uint256 sharesToBurn, uint256 lootToBurn, address[] calldata tokens) external;

    function hashOperation(bytes memory transactions) external pure returns (bytes32);
    function encodeMultisend(bytes[] memory calls, address target) external pure returns (bytes memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { IAllowlist } from "../../interfaces/IAllowlist.sol";

/**
 * @title AllowlistBase
 * @dev This contract provides the basic implementation for an allowlist. All claims are allowed by default.
 */
abstract contract AllowlistBase is IAllowlist {
    /**
     * @notice Sets up the allowlist.
     * @dev This function decodes the initialization parameters and sets the state variables accordingly.
     * @param _initializationParams The parameters to initialize the allowlist.
     */
    function __Allowlist_init(bytes memory _initializationParams) public virtual;

    /**
     * @notice Checks if the caller is a member.
     * @dev In this base contract, it always returns true, but is expected to be overridden in a derived contract with
     * specific logic to determine membership.
     * @param user The address of the user to check membership. This parameter is not used in this base contract.
     * @return A boolean indicating whether the caller is a member. Always returns true in this base contract.
     */
    function isAllowList(address user) public view virtual override returns (bool) {
        return _isAllowList(user);
    }

    /**
     * @notice Checks if an address is in the allowlist.
     * @dev This function is an internal view function that always returns true, indicating that all addresses are in
     * the allowlist by default.
     * @param user The address to check.
     * @return A boolean indicating whether the address is in the allowlist. Always returns true.
     */
    function _isAllowList(address user) internal view virtual returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { ICookieJar } from "src/interfaces/ICookieJar.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { CookieUtils } from "src/lib/CookieUtils.sol";
import { GiverBase } from "src/core/givers/GiverBase.sol";

import { NOT_ALLOWED, CALL_FAILED } from "src/lib/Errors.sol";
import { IAllowlist } from "../interfaces/IAllowlist.sol";
import { FactoryFriendly } from "zodiac/factory/FactoryFriendly.sol";
import { AllowlistBase } from "./allowlists/AllowlistBase.sol";

/**
 * @title CookieJarCore
 * @notice A base contract for a cookie jar that distributes tokens according to an allow list.
 * @dev This contract is intended to be inherited by a derived contract that implements the logic for distributing
 * tokens according to checks against an allowlist. The derived contract should implement the giveCookie function to handle the logic of
 * transferring the specified amount of cookies to the given address and return a unique identifier for the cookie.
 */
abstract contract CookieJarCore is GiverBase, AllowlistBase, ICookieJar, Initializable, OwnableUpgradeable {
    /// @notice The amount of "cookie" that can be claimed.
    uint256 public cookieAmount;

    /// @notice The address of the token that is being distributed.
    address public cookieToken;

    /// @notice The length of the period between claims.
    uint256 public periodLength;

    // @notice The claiming address and the timestamp of the last claim.
    mapping(address claimer => uint256 dateTime) public claims;

    /**
     * @notice Sets up the contract with the given initialization parameters.
     * @dev The initialization parameters are decoded from a bytes array into the Safe target, period length, cookie
     * amount, and cookie token.
     * The Safe target is set as both the avatar and target for the module.  This means that the module cannot be
     * chained in a series of modules.
     * A check is done to ensure the cookie amount is greater than the percentage points constant.
     * The period length, cookie amount, and cookie token are then set as per the parameters.
     * An event is emitted with the initialization parameters.
     * @param _initializationParams The initialization parameters, encoded as a bytes array.
     */
    function setUp(bytes memory _initializationParams) public virtual initializer {
        (address target, uint256 _periodLength, uint256 _cookieAmount, address _cookieToken) =
            abi.decode(_initializationParams, (address, uint256, uint256, address));

        periodLength = _periodLength;
        cookieAmount = _cookieAmount;
        cookieToken = _cookieToken;

        _transferOwnership(target);

        emit Setup(_initializationParams);
    }

    /**
     * @notice Allows a member to make a claim and provides a reason for the claim.
     * @dev This function checks if the caller is a member and if the claim period is valid. If the requirements are
     * met, it calls the overloaded reachInJar function with the caller's address and the provided reason.
     * This function can only be called by the member themselves, and not on behalf of others.
     * @param reason The reason provided by the member for making the claim. This will be posted publicly.
     */
    function reachInJar(string calldata reason) public virtual {
        reachInJar(msg.sender, reason);
    }

    /**
     * @notice Allows a member to make a claim on behalf of another address and provides a reason for the claim.
     * @dev Checks if the caller is a member and if the claim period is valid. If the requirements are met,
     * it updates the last claim timestamp for the caller, gives a cookie to the specified address, and posts the reason
     * for the claim. This function can be called by a member on behalf of another address, allowing for more flexible
     * distribution.
     * @param cookieMonster The address to receive the cookie.
     * @param reason The reason provided by the member for making the claim. This will be posted publicly.
     */
    function reachInJar(address cookieMonster, string calldata reason) public virtual {
        if (!_isAllowList(msg.sender)) {
            revert NOT_ALLOWED("not a member");
        }
        if (!_isValidClaimPeriod(msg.sender)) {
            revert NOT_ALLOWED("not a valid claim period");
        }

        claims[msg.sender] = block.timestamp;

        bytes32 cookieUid = _giveCookie(cookieMonster, cookieAmount, cookieToken);

        emit GiveCookie(cookieUid, cookieMonster, cookieAmount, reason);
    }

    /**
     * @notice Allows a member to assess the reason for a claim.
     * @dev The member can give a thumbs up or thumbs down to a claim reason. The assessment is posted to the Poster
     * contract. This function can only be called by a member.
     * @param cookieUid The unique identifier of the claim reason to be assessed.
     * @param message The message to be posted with the assessment.
     * @param isGood A boolean indicating whether the assessment is positive (true) or negative (false).
     */
    function assessReason(bytes32 cookieUid, string calldata message, bool isGood) public {
        if (!_isAllowList(msg.sender)) {
            revert NOT_ALLOWED("not a member");
        }

        emit AssessReason(cookieUid, message, isGood);
    }

    /**
     * @notice Checks if the user is eligible to make a claim.
     * @dev This function checks if the user is a member and if the claim period is valid by calling the isAllowList and
     * isValidClaimPeriod functions.
     * @param user The address of the user to check eligibility.
     * @return allowed A boolean indicating whether the user is eligible to make a claim.
     */
    function canClaim(address user) public view returns (bool allowed) {
        return _isAllowList(user) && _isValidClaimPeriod(user);
    }

    /**
     *
     * INTERNAL  *
     *
     */

    /**
     * @notice Checks if the claim period for the user is valid.
     * @dev Returns true if the current time minus the last claim time of the user is greater than the period length,
     * or if the user has not made a claim yet (i.e., their last claim time is zero).
     * @param user The address of the user to check the claim period.
     * @return A boolean indicating whether the claim period for the user is valid.
     */
    function _isValidClaimPeriod(address user) internal view returns (bool) {
        return block.timestamp - claims[user] >= periodLength || claims[user] == 0;
    }

    /**
     *
     * CONFIG *
     *
     */
    /**
     * @notice Allows the owner to change the configuration of the contract.
     * @dev This function can only be called by the owner of the contract. It updates the period length, cookie amount,
     * and cookie token.
     * @param _periodLength The length of the period between claims.
     * @param _cookieAmount The amount of "cookie" that can be claimed.
     * @param _cookieToken The address of the token that is being distributed, zero address for native.
     */
    function setConfig(uint256 _periodLength, uint256 _cookieAmount, address _cookieToken) public virtual onlyOwner {
        periodLength = _periodLength;
        cookieAmount = _cookieAmount;
        cookieToken = _cookieToken;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { Module } from "@gnosis.pm/zodiac/contracts/core/Module.sol";
import { FactoryFriendly } from "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { CookieUtils } from "src/lib/CookieUtils.sol";
import { CookieJarCore } from "src/core/CookieJarCore.sol";

import { CALL_FAILED } from "src/lib/Errors.sol";
import { GiverBase } from "./GiverBase.sol";

/**
 * @title GiverZodiac
 * @dev This contract extends GiverBase and provides a mechanism for giving cookies using the Zodiac module.
 */
abstract contract GiverZodiac is Module, CookieJarCore {
    function setUp(bytes memory _initializationParams) public virtual override(FactoryFriendly, CookieJarCore) {
        __Giver_init(_initializationParams);
        CookieJarCore.setUp(_initializationParams);
    }

    function __Giver_init(bytes memory _initializationParams) public virtual override {
        (address _safeTarget) = abi.decode(_initializationParams, (address));

        avatar = _safeTarget;
        target = _safeTarget;
    }

    /**
     * @notice Gives a cookie to a specified address.
     * @dev This function calculates the sustainability fee, executes a trusted call to transfer the fee and the
     * remaining amount to the specified address.
     * If the cookie token is the zero address, it transfers native currency. Otherwise, it transfers the specified
     * ERC20 token.
     * @param cookieMonster The address to receive the cookie.
     * @param amount The amount of cookie to be given.
     * @param cookieToken The address of the ERC20 token to be transferred. If it is the zero address, native currency
     * is transferred.
     * @return cookieUid A unique identifier for the cookie.
     */
    function _giveCookie(
        address cookieMonster,
        uint256 amount,
        address cookieToken
    )
        internal
        override
        returns (bytes32 cookieUid)
    {
        uint256 fee = (amount / PERC_POINTS) * SUSTAINABILITY_FEE;

        // module exec

        if (cookieToken == address(0)) {
            if (!exec(SUSTAINABILITY_ADDR, fee, bytes(""), Enum.Operation.Call)) {
                revert CALL_FAILED("fund sustainability native");
            }
            if (!exec(cookieMonster, amount - fee, bytes(""), Enum.Operation.Call)) {
                revert CALL_FAILED("fund cookieMonster native");
            }
        } else {
            if (
                !exec(
                    cookieToken,
                    0,
                    abi.encodeWithSignature("transfer(address,uint256)", abi.encodePacked(SUSTAINABILITY_ADDR, fee)),
                    Enum.Operation.Call
                )
            ) {
                revert CALL_FAILED("fund sustainability erc20");
            }

            if (
                !exec(
                    cookieToken,
                    0,
                    abi.encodeWithSignature("transfer(address,uint256)", abi.encodePacked(cookieMonster, amount - fee)),
                    Enum.Operation.Call
                )
            ) {
                revert CALL_FAILED("fund cookieMonster erc20");
            }
        }

        cookieUid = CookieUtils.getCookieUid();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title CookieUtils
 * @dev This library provides utility functions for working with cookies.
 */
library CookieUtils {
    /**
     * @notice Generates a unique identifier for a cookie for reference purposes.
     * @dev This function is internal and view, and it returns a bytes32 value.
     * It generates the unique identifier by hashing the sender's address and the current block timestamp.
     * @return cookieUid The unique identifier for a cookie.
     */
    function getCookieUid() internal view returns (bytes32 cookieUid) {
        cookieUid = keccak256(abi.encodePacked(msg.sender, block.timestamp));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

/**
 * @title IAllowlist
 * @dev This is an interface for an allowlist used by the cookie jar
 */
interface IAllowlist {
    /**
     * @notice Sets up the allowlist with the provided initialization parameters.
     * @dev This function first inits the allow list and then the core contract.
     * @param _initializationParams The parameters to initialize the allowlist.
     */
    function __Allowlist_init(bytes memory _initializationParams) external;

    /**
     * @notice Checks if an address is in the allowlist.
     * @dev Checks against specified allowlist mechanism
     * @param user The address to check.
     * @return A boolean indicating whether the address is in the allowlist.
     */
    function isAllowList(address user) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface ICookieJar {
    /// @dev Emitted when the contract is set up.
    /// @param initializationParams The parameters used for initialization.
    event Setup(bytes initializationParams);

    /// @dev Emitted when a "cookie" is given to an address.
    /// @param cookieUid The unique identifier of the cookie given.
    /// @param cookieMonster The address receiving the cookie.
    /// @param amount The amount of cookie given.
    /// @param reason The reason for the cookie being given.
    event GiveCookie(bytes32 indexed cookieUid, address indexed cookieMonster, uint256 amount, string reason);

    /// @dev Emitted when a reason is assessed.
    /// @param cookieUid The unique identifier of the claim reason.
    /// @param message The message given by the assessor.
    /// @param isGood A boolean indicating whether the assessment is positive (true) or negative (false).
    event AssessReason(bytes32 indexed cookieUid, string message, bool isGood);

    //    /**
    //     * @notice Sets up the contract with the given initialization parameters.
    //     * @dev The initialization parameters are decoded from a bytes array into the Safe target, period length,
    // cookie
    //     * amount, and cookie token.
    //     * The Safe target is set as both the avatar and target for the module.  This means that the module cannot be
    //     * chained in a series of modules.
    //     * A check is done to ensure the cookie amount is greater than the percentage points constant.
    //     * The period length, cookie amount, and cookie token are then set as per the parameters.
    //     * An event is emitted with the initialization parameters.
    //     * @param _initializationParams The initialization parameters, encoded as a bytes array.
    //     *  // TODO: add initializer to this contract
    //     */
    //    function setUp(bytes memory _initializationParams) external;

    /**
     * @notice Allows owner to change congiguration.
     * @dev Checks if the caller is a member and if the claim period is valid. If the requirements are met,
     * @param _periodLength The length of the period between claims.
     * @param _cookieAmount The amount of "cookie" that can be claimed.
     * @param _cookieToken The address of the token that is being distributed, zero address for native.
     */
    function setConfig(uint256 _periodLength, uint256 _cookieAmount, address _cookieToken) external;

    /**
     * @notice Allows a member to make a claim and provides a reason for the claim.
     * @dev Checks if the caller is a member and if the claim period is valid. If the requirements are met,
     * it updates the last claim timestamp for the caller, gives a cookie to the caller, and posts the reason for the
     * claim.
     * This function can only be called by the member themselves, and not on behalf of others.
     * @param _reason The reason provided by the member for making the claim. This will be posted publicly.
     * @dev MUST emit a {GiveCookie} event.
     */
    function reachInJar(string calldata _reason) external;

    /**
     * @notice Allows a member to make a claim on behalf of another address and provides a reason for the claim.
     * @dev Checks if the caller is a member and if the claim period is valid. If the requirements are met,
     * it updates the last claim timestamp for the caller, gives a cookie to the specified address, and posts the reason
     * for the claim.
     * This function can be called by a member on behalf of another address, allowing for more flexible distribution.
     * @param cookieMonster The address to receive the cookie.
     * @param _reason The reason provided by the member for making the claim. This will be posted publicly.
     * @dev MUST emit a {GiveCookie} event.
     */
    function reachInJar(address cookieMonster, string calldata _reason) external;

    /**
     * @notice Allows a member to assess the reason for a claim.
     * @dev The member can give a thumbs up or thumbs down to a claim reason. The assessment is posted to the Poster
     * contract.
     * @param cookieUid The unique identifier of the claim reason to be assessed.
     * @param message The message given by the assessor.
     * @param isGood A boolean indicating whether the assessment is positive (true) or negative (false).
     * @dev MUST emit an {AssessReason} event.
     */
    function assessReason(bytes32 cookieUid, string calldata message, bool isGood) external;

    /**
     * @notice Checks if the caller is eligible to make a claim.
     * @dev Calls the isAllowList and isValidClaimPeriod functions to check if the caller is a member and within the
     * valid claim period.
     * @return A boolean indicating whether the caller is eligible to make a claim.
     */
    function canClaim(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { AccountERC6551 } from "src/ERC6551/erc6551/ERC6551Module.sol";
import { CookieUtils } from "src/lib/CookieUtils.sol";
import { CookieJarCore } from "../CookieJarCore.sol";
import { IGiver } from "../../interfaces/IGiver.sol";

/**
 * @title GiverBase
 * @dev This is an abstract contract that provides a mechanism for giving cookies.
 */
abstract contract GiverBase is IGiver {
    /// @notice The constant that represents percentage points for calculations.
    uint256 public constant PERC_POINTS = 1e6;

    /// @notice The fee charged on each transaction, set at 1% (10,000 out of a million).
    uint256 public constant SUSTAINABILITY_FEE = 10_000;

    /// @notice The address for the sustainability fee.
    address public constant SUSTAINABILITY_ADDR = 0x1cE42BA793BA1E9Bf36c8b3f0aDDEe6c89D9a9fc;

    function __Giver_init(bytes memory _initializationParams) public virtual;

    /**
     * @notice Gives a cookie to a specified address.
     * @dev This function is internal and virtual, and returns a unique identifier for the cookie.
     * @param cookieMonster The address to which the cookie will be given.
     * @param amount The amount of cookies to give.
     * @param cookieToken The address of the cookie token contract.
     * @return cookieUid A unique identifier for the given cookie.
     */
    function _giveCookie(
        address cookieMonster,
        uint256 amount,
        address cookieToken
    )
        internal
        virtual
        returns (bytes32 cookieUid);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

/// @notice This error is thrown when the lengths of two arrays do not match.
/// @param a The length of the first array.
/// @param b The length of the second array.
error ARRAY_LENGTH_MISMATCH(uint256 a, uint256 b);

/// @notice This error is thrown when a call to a function or contract fails.
/// @param message The error message.
error CALL_FAILED(string message);

/// @notice This error is thrown when an invalid token ID is used.
/// @param tokenId The invalid token ID.
error INVALID_TOKEN_ID(uint256 tokenId);

/// @notice This error is thrown when an action is not allowed.
/// @param message The error message.
error NOT_ALLOWED(string message);

/// @notice This error is thrown when the caller is not the approved address or the owner of a token.
error NOT_APPROVED_OR_OWNER();

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        address currentGuard = guard;
        if (currentGuard != address(0)) {
            IGuard(currentGuard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
            success = IAvatar(target).execTransactionFromModule(
                to,
                value,
                data,
                operation
            );
            IGuard(currentGuard).checkAfterExecution(bytes32("0x"), success);
        } else {
            success = IAvatar(target).execTransactionFromModule(
                to,
                value,
                data,
                operation
            );
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        address currentGuard = guard;
        if (currentGuard != address(0)) {
            IGuard(currentGuard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
            (success, returnData) = IAvatar(target)
                .execTransactionFromModuleReturnData(
                    to,
                    value,
                    data,
                    operation
                );
            IGuard(currentGuard).checkAfterExecution(bytes32("0x"), success);
        } else {
            (success, returnData) = IAvatar(target)
                .execTransactionFromModuleReturnData(
                    to,
                    value,
                    data,
                    operation
                );
        }
        return (success, returnData);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Enum - Collection of enums used in Safe contracts.
 * @author Richard Meissner - @rmeissner
 */
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "src/lib/MinimalReceiver.sol";
import { IAccount } from "src/interfaces/IERC6551.sol";
import { ERC6551AccountLib } from "src/lib/ERC6551AccountLib.sol";

/**
 * @title A smart contract wallet owned by a single ERC721 token
 * @author Jayden Windle (jaydenwindle)
 */
contract AccountERC6551 is IERC165, IERC1271, IAccount, MinimalReceiver, Initializable {
    error NotAuthorized();
    error AccountLocked();
    error ExceedsMaxLockTime();

    /**
     * @dev Timestamp at which Account will unlock
     */
    uint256 public unlockTimestamp;

    /**
     * @dev Mapping from owner address to executor address
     */
    mapping(address => address) public executor;

    /**
     * @dev Emitted whenever the lock status of a account is updated
     */
    event LockUpdated(uint256 timestamp);

    /**
     * @dev Emitted whenever the executor for a account is updated
     */
    event ExecutorUpdated(address owner, address executor);

    constructor() { }

    /**
     * @dev Ensures execution can only continue if the account is not locked
     */
    modifier onlyUnlocked() {
        if (unlockTimestamp > block.timestamp) revert AccountLocked();
        _;
    }

    /**
     * @dev If account is unlocked and an executor is set, pass call to executor
     */
    fallback(bytes calldata data) external payable onlyUnlocked returns (bytes memory result) {
        address _owner = owner();
        address _executor = executor[_owner];

        // accept funds if executor is undefined or cannot be called
        if (_executor.code.length == 0) return "";

        return _call(_executor, 0, data);
    }

    /**
     * @dev Executes a transaction from the Account. Must be called by an account owner.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    )
        external
        payable
        onlyUnlocked
        returns (bytes memory result)
    {
        address _owner = owner();
        if (msg.sender != _owner) revert NotAuthorized();

        return _call(to, value, data);
    }

    /**
     * @dev wrapper to align with zodiac.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata data
    )
        external
        payable
        onlyUnlocked
        returns (bytes memory result)
    {
        address _owner = owner();
        if (msg.sender != _owner) revert NotAuthorized();

        return _call(to, value, data);
    }

    /**
     * @dev Executes a transaction from the Account. Must be called by an authorized executor.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function executeTrustedCall(
        address to,
        uint256 value,
        bytes calldata data
    )
        external
        payable
        onlyUnlocked
        returns (bytes memory result)
    {
        address _executor = executor[owner()];
        if (msg.sender != _executor) revert NotAuthorized();

        return _call(to, value, data);
    }

    /**
     * @dev Sets executor address for Account, allowing owner to use a custom implementation if they choose to.
     * When the token controlling the account is transferred, the implementation address will reset
     *
     * @param _executionModule the address of the execution module
     */
    function setExecutor(address _executionModule) external onlyUnlocked {
        address _owner = owner();
        if (_owner != msg.sender) revert NotAuthorized();

        executor[_owner] = _executionModule;

        emit ExecutorUpdated(_owner, _executionModule);
    }

    function setExecutorInit(address _executionModule) external initializer {
        address _owner = owner();
        executor[_owner] = _executionModule;

        emit ExecutorUpdated(_owner, _executionModule);
    }

    /**
     * @dev Locks Account, preventing transactions from being executed until a certain time
     *
     * @param _unlockTimestamp timestamp when the account will become unlocked
     */
    function lock(uint256 _unlockTimestamp) external onlyUnlocked {
        if (_unlockTimestamp > block.timestamp + 365 days) {
            revert ExceedsMaxLockTime();
        }

        address _owner = owner();
        if (_owner != msg.sender) revert NotAuthorized();

        unlockTimestamp = _unlockTimestamp;

        emit LockUpdated(_unlockTimestamp);
    }

    // function lock(uint256 _lockedUntil) external onlyOwner onlyUnlocked {
    //     if (_lockedUntil > block.timestamp + 365 days)
    //         revert ExceedsMaxLockTime();

    //     lockedUntil = _lockedUntil;

    //     emit LockUpdated(_lockedUntil);

    //     _incrementNonce();
    // }

    /**
     * @dev Returns Account lock status
     *
     * @return true if Account is locked, false otherwise
     */
    function isLocked() external view returns (bool) {
        return unlockTimestamp > block.timestamp;
    }

    /**
     * @dev Returns true if caller is authorized to execute actions on this account
     *
     * @param caller the address to query authorization for
     * @return true if caller is authorized, false otherwise
     */
    function isAuthorized(address caller) external view returns (bool) {
        (, address tokenCollection, uint256 tokenId) = _context();

        address _owner = IERC721(tokenCollection).ownerOf(tokenId);
        if (caller == _owner) return true;

        address _executor = executor[_owner];
        if (caller == _executor) return true;

        return false;
    }

    /**
     * @dev Implements EIP-1271 signature validation
     *
     * @param hash      Hash of the signed data
     * @param signature Signature to validate
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue) {
        // If account is locked, disable signing
        if (unlockTimestamp > block.timestamp) return "";

        // If account has an executor, check if executor signature is valid
        address _owner = owner();
        address _executor = executor[_owner];

        if (_executor != address(0) && SignatureChecker.isValidSignatureNow(_executor, hash, signature)) {
            return IERC1271.isValidSignature.selector;
        }

        // Default - check if signature is valid for account owner
        if (SignatureChecker.isValidSignatureNow(_owner, hash, signature)) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    /**
     * @dev Implements EIP-165 standard interface detection
     *
     * @param interfaceId the interfaceId to check support for
     * @return true if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155Receiver)
        returns (bool)
    {
        // default interface support
        if (
            interfaceId == type(IAccount).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
                || interfaceId == type(IERC165).interfaceId
        ) {
            return true;
        }

        address _executor = executor[owner()];

        if (_executor == address(0) || _executor.code.length == 0) {
            return false;
        }

        // if interface is not supported by default, check executor
        try IERC165(_executor).supportsInterface(interfaceId) returns (bool _supportsInterface) {
            return _supportsInterface;
        } catch {
            return false;
        }
    }

    /**
     * @dev Returns the owner of the token that controls this Account (public for Ownable compatibility)
     *
     * @return the address of the Account owner
     */
    function owner() public view returns (address) {
        (uint256 chainId, address tokenCollection, uint256 tokenId) = _context();

        if (chainId != block.chainid) {
            return address(0);
        }

        return IERC721(tokenCollection).ownerOf(tokenId);
    }

    /**
     * @dev Returns information about the token that owns this account
     * @return chainId the chainId of the  ERC721 token which owns this account
     * @return tokenCollection the contract address of the  ERC721 token which owns this account
     * @return tokenId the tokenId of the  ERC721 token which owns this account
     */
    function token() public view returns (uint256 chainId, address tokenCollection, uint256 tokenId) {
        (chainId, tokenCollection, tokenId) = _context();
    }

    function _context() internal view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        (chainId, tokenContract, tokenId) = ERC6551AccountLib.token();
    }

    /**
     * @dev Executes a low-level call
     */
    function _call(address to, uint256 value, bytes calldata data) internal returns (bytes memory result) {
        bool success;
        (success, result) = to.call{ value: value }(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

/**
 * @title IGiver
 * @dev This is an interface for a giver  used by the cookie jar
 */
interface IGiver {
    /**
     * @notice Sets up the allowlist with the provided initialization parameters.
     * @dev This function first inits the allow list and then the core contract.
     * @param _initializationParams The parameters to initialize the allowlist.
     */
    function __Giver_init(bytes memory _initializationParams) external;
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    address public guard;

    event ChangedGuard(address guard);

    /// `guard_` does not implement IERC165.
    error NotIERC165Compliant(address guard_);

    /// @dev Set a guard that checks transactions before execution.
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard.
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            if (!BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId))
                revert NotIERC165Compliant(_guard);
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MinimalReceiver is ERC721Holder, ERC1155Holder {
    /**
     * @dev Allows all Ether transfers
     */
    receive() external payable virtual { }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IAccount {
    /// @dev Executes `call` on address `to`, with value `value` and calldata
    /// `data`.
    ///
    /// MUST revert and bubble up errors if call fails.
    ///
    /// By default, token bound accounts MUST allow the owner of the ERC-721 token
    /// which owns the account to execute arbitrary calls using `executeCall`.
    ///
    /// Token bound accounts MAY implement additional authorization mechanisms
    /// which limit the ability of the ERC-721 token holder to execute calls.
    ///
    /// Token bound accounts MAY implement additional execution functions which
    /// grant execution permissions to other non-owner accounts.
    ///
    /// @return The result of the call
    function executeCall(address to, uint256 value, bytes calldata data) external payable returns (bytes memory);

    /// @dev Returns identifier of the ERC-721 token which owns the
    /// account
    ///
    /// The return value of this function MUST be constant - it MUST NOT change
    /// over time.
    ///
    /// @return chainId The EIP-155 ID of the chain the ERC-721 token exists on
    /// @return tokenContract The contract address of the ERC-721 token
    /// @return tokenId The ID of the ERC-721 token
    function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);

    /// @dev Returns the owner of the ERC-721 token which controls the account
    /// if the token exists.
    ///
    /// This is value is obtained by calling `ownerOf` on the ERC-721 contract.
    ///
    /// @return Address of the owner of the ERC-721 token which owns the account
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ERC6551AccountLib {
    function token() internal view returns (uint256, address, uint256) {
        bytes memory footer = new bytes(0x60);

        assembly {
            // copy 0x60 bytes from end of footer
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0xad)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function salt() internal view returns (uint256) {
        bytes memory footer = new bytes(0x20);

        assembly {
            // copy 0x20 bytes from beginning of footer
            extcodecopy(address(), add(footer, 0x20), 0x2d, 0x4d)
        }

        return abi.decode(footer, (uint256));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// @dev Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}