// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IController {

    /**
        @notice General function that evaluates whether the target contract can
        be interacted with using the specified calldata
        @param target Address of external protocol/interaction
        @param useEth Specifies if Eth is being sent to the target
        @param data Calldata of the call made to target
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canCall(
        address target,
        bool useEth,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "./IController.sol";

interface IControllerFacade {
    function isTokenAllowed(address token) external view returns (bool);
    function controllerFor(address target) external view returns (IController);

    /**
        @notice General function that evaluates whether the target contract can
        be interacted with using the specified calldata
        @param target Address of external protocol/interaction
        @param useEth Specifies if Eth is being sent to the target
        @param data Calldata of the call made to target
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canCall(
        address target,
        bool useEth,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {Pausable} from "../utils/Pausable.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {IRiskEngine} from "../interface/core/IRiskEngine.sol";
import {IAccountFactory} from "../interface/core/IAccountFactory.sol";
import {IAccountManager} from "../interface/core/IAccountManager.sol";
import {IControllerFacade} from "controller/core/IControllerFacade.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";

/**
    @title Account Manager
    @notice Sentiment Account Manager,
        All account interactions go via the account manager
*/
contract AccountManager is ReentrancyGuard, Pausable, IAccountManager {
    using Helpers for address;

    /* -------------------------------------------------------------------------- */
    /*                               STATE_VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Utility variable to indicate if contract is initialized
    bool private initialized;

    /// @notice Registry
    IRegistry public registry;

    /// @notice Risk Engine
    IRiskEngine public riskEngine;

    /// @notice Controller Facade
    IControllerFacade public controller;

    /// @notice Account Factory
    IAccountFactory public accountFactory;

    /// @notice List of inactive accounts per user
    mapping(address => address[]) public inactiveAccountsOf;

    /// @notice Mapping of collateral enabled tokens
    mapping(address => bool) public isCollateralAllowed;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier onlyOwner(address account) {
        if (registry.ownerFor(account) != msg.sender)
            revert Errors.AccountOwnerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Initializes contract
        @dev Can only be invoked once
        @param _registry Address of Registry
    */
    function init(IRegistry _registry) external {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        locked = 1;
        initialized = true;
        initPausable(msg.sender);
        registry = _registry;
    }

    /// @notice Initializes external dependencies
    function initDep() external adminOnly {
        riskEngine = IRiskEngine(registry.getAddress('RISK_ENGINE'));
        controller = IControllerFacade(registry.getAddress('CONTROLLER'));
        accountFactory =
            IAccountFactory(registry.getAddress('ACCOUNT_FACTORY'));
    }

    /**
        @notice Opens a new account for a user
        @dev Creates a new account if there are no inactive accounts otherwise
            reuses an already inactive account
            Emits AccountAssigned(account, owner) event
        @param owner Owner of the newly opened account
    */
    function openAccount(address owner) external nonReentrant whenNotPaused {
        if (owner == address(0)) revert Errors.ZeroAddress();
        address account;
        uint length = inactiveAccountsOf[owner].length;
        if (length == 0) {
            account = accountFactory.create(address(this));
            IAccount(account).init(address(this));
            registry.addAccount(account, owner);
        } else {
            account = inactiveAccountsOf[owner][length - 1];
            inactiveAccountsOf[owner].pop();
            registry.updateAccount(account, owner);
        }
        IAccount(account).activate();
        emit AccountAssigned(account, owner);
    }

    /**
        @notice Closes a specified account for a user
        @dev Account can only be closed when the account has no debt
            Emits AccountClosed(account, owner) event
        @param _account Address of account to be closed
    */
    function closeAccount(address _account) public nonReentrant onlyOwner(_account) {
        IAccount account = IAccount(_account);
        if (account.activationBlock() == block.number)
            revert Errors.AccountDeactivationFailure();
        if (!account.hasNoDebt()) revert Errors.OutstandingDebt();
        account.deactivate();
        registry.closeAccount(_account);
        inactiveAccountsOf[msg.sender].push(_account);
        account.sweepTo(msg.sender);
        emit AccountClosed(_account, msg.sender);
    }

    /**
        @notice Transfers Eth from owner to account
        @param account Address of account
    */
    function depositEth(address account)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyOwner(account)
    {
        account.safeTransferEth(msg.value);
    }

    /**
        @notice Transfers Eth from the account to owner
        @dev Eth can only be withdrawn if the account remains healthy
            after withdrawal
        @param account Address of account
        @param amt Amount of Eth to withdraw
    */
    function withdrawEth(address account, uint amt)
        external
        nonReentrant
        onlyOwner(account)
    {
        if(!riskEngine.isWithdrawAllowed(account, address(0), amt))
            revert Errors.RiskThresholdBreached();
        account.withdrawEth(msg.sender, amt);
    }

    /**
        @notice Transfers a specified amount of token from the owner
            to the account
        @dev Token must be accepted as collateral by the protocol
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to deposit
    */
    function deposit(address account, address token, uint amt)
        external
        nonReentrant
        whenNotPaused
        onlyOwner(account)
    {
        if (!isCollateralAllowed[token])
            revert Errors.CollateralTypeRestricted();
        if (IAccount(account).hasAsset(token) == false)
            IAccount(account).addAsset(token);
        token.safeTransferFrom(msg.sender, account, amt);
    }

    /**
        @notice Transfers a specified amount of token from the account
            to the owner of the account
        @dev Amount of token can only be withdrawn if the account remains healthy
            after withdrawal
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to withdraw
    */
    function withdraw(address account, address token, uint amt)
        external
        nonReentrant
        onlyOwner(account)
    {
        if (!riskEngine.isWithdrawAllowed(account, token, amt))
            revert Errors.RiskThresholdBreached();
        account.withdraw(msg.sender, token, amt);
        if (token.balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
    }

    /**
        @notice Transfers a specified amount of token from the LP to the account
        @dev Specified token must have a LP
            Account must remain healthy after the borrow, otherwise tx is reverted
            Emits Borrow(account, msg.sender, token, amount) event
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to borrow
    */
    function borrow(address account, address token, uint amt)
        external
        nonReentrant
        whenNotPaused
        onlyOwner(account)
    {
        if (registry.LTokenFor(token) == address(0))
            revert Errors.LTokenUnavailable();
        if (IAccount(account).hasAsset(token) == false)
            IAccount(account).addAsset(token);
        if (ILToken(registry.LTokenFor(token)).lendTo(account, amt))
            IAccount(account).addBorrow(token);
        if (!riskEngine.isAccountHealthy(account))
            revert Errors.RiskThresholdBreached();
        emit Borrow(account, msg.sender, token, amt);
    }

    /**
        @notice Transfers a specified amount of token from the account to the LP
        @dev Specified token must have a LP
            Emits Repay(account, msg.sender, token, amount) event
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to borrow
    */
    function repay(address account, address token, uint amt)
        public
        nonReentrant
        onlyOwner(account)
    {
        _repay(account, token, amt);
    }

    /**
        @notice Liquidates an account
        @dev Account can only be liquidated when it's unhealthy
            Emits AccountLiquidated(account, owner) event
        @param account Address of account
    */
    function liquidate(address account) external nonReentrant {
        if (riskEngine.isAccountHealthy(account))
            revert Errors.AccountNotLiquidatable();
        _liquidate(account);
        emit AccountLiquidated(account, registry.ownerFor(account));
    }

    /**
        @notice Gives a spender approval to spend a given amount of token from
            the account
        @dev Spender must have a controller in controller facade
        @param account Address of account
        @param token Address of token
        @param spender Address of spender
        @param amt Amount of token
    */
    function approve(
        address account,
        address token,
        address spender,
        uint amt
    )
        external
        nonReentrant
        onlyOwner(account)
    {
        if(address(controller.controllerFor(spender)) == address(0))
            revert Errors.FunctionCallRestricted();
        account.safeApprove(token, spender, amt);
    }

    /**
        @notice A general function that allows the owner to perform specific interactions
            with external protocols for their account
        @dev Target must have a controller in controller facade
        @param account Address of account
        @param target Address of contract to transact with
        @param amt Amount of Eth to send to the target contract
        @param data Encoded sig + params of the function to transact with in the
            target contract
    */
    function exec(
        address account,
        address target,
        uint amt,
        bytes calldata data
    )
        external
        nonReentrant
        onlyOwner(account)
    {
        bool isAllowed;
        address[] memory tokensIn;
        address[] memory tokensOut;
        (isAllowed, tokensIn, tokensOut) =
            controller.canCall(target, (amt > 0), data);
        if (!isAllowed) revert Errors.FunctionCallRestricted();
        _updateTokensIn(account, tokensIn);
        (bool success,) = IAccount(account).exec(target, amt, data);
        if (!success)
            revert Errors.AccountInteractionFailure(account, target, amt, data);
        _updateTokensOut(account, tokensOut);
        if (!riskEngine.isAccountHealthy(account))
            revert Errors.RiskThresholdBreached();
    }

    /**
        @notice Settles an account by repaying all the loans
        @param account Address of account
    */
    function settle(address account) external nonReentrant onlyOwner(account) {
        address[] memory borrows = IAccount(account).getBorrows();
        for (uint i; i < borrows.length; i++) {
            _repay(account, borrows[i], type(uint).max);
        }
    }

    /**
        @notice Fetches inactive accounts of a user
        @param user Address of user
        @return address[] List of inactive accounts
    */
    function getInactiveAccountsOf(
        address user
    )
        external
        view
        returns (address[] memory)
    {
        return inactiveAccountsOf[user];
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    function _updateTokensIn(address account, address[] memory tokensIn)
        internal
    {
        uint tokensInLen = tokensIn.length;
        for(uint i; i < tokensInLen; ++i) {
            if (IAccount(account).hasAsset(tokensIn[i]) == false)
                IAccount(account).addAsset(tokensIn[i]);
        }
    }

    function _updateTokensOut(address account, address[] memory tokensOut)
        internal
    {
        uint tokensOutLen = tokensOut.length;
        for(uint i; i < tokensOutLen; ++i) {
            if (tokensOut[i].balanceOf(account) == 0)
                IAccount(account).removeAsset(tokensOut[i]);
        }
    }

    function _liquidate(address _account) internal {
        IAccount account = IAccount(_account);
        address[] memory accountBorrows = account.getBorrows();
        uint borrowLen = accountBorrows.length;

        ILToken LToken;
        uint amt;

        for(uint i; i < borrowLen; ++i) {
            address token = accountBorrows[i];
            LToken = ILToken(registry.LTokenFor(token));
            LToken.updateState();
            amt = LToken.getBorrowBalance(_account);
            token.safeTransferFrom(msg.sender, address(LToken), amt);
            LToken.collectFrom(_account, amt);
            account.removeBorrow(token);
        }
        account.sweepTo(msg.sender);
    }

    function _repay(address account, address token, uint amt)
        internal
    {
        ILToken LToken = ILToken(registry.LTokenFor(token));
        if (address(LToken) == address(0))
            revert Errors.LTokenUnavailable();
        LToken.updateState();
        if (amt == type(uint256).max) amt = LToken.getBorrowBalance(account);
        account.withdraw(address(LToken), token, amt);
        if (LToken.collectFrom(account, amt))
            IAccount(account).removeBorrow(token);
        if (IERC20(token).balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
        emit Repay(account, msg.sender, token, amt);
    }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Toggle collateral status of a token
        @param token Address of token
    */
    function toggleCollateralStatus(address token) external adminOnly {
        isCollateralAllowed[token] = !isCollateralAllowed[token];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccount {
    function activate() external;
    function deactivate() external;
    function addAsset(address token) external;
    function addBorrow(address token) external;
    function removeAsset(address token) external;
    function sweepTo(address toAddress) external;
    function removeBorrow(address token) external;
    function init(address accountManager) external;
    function hasAsset(address) external returns (bool);
    function assets(uint) external returns (address);
    function hasNoDebt() external view returns (bool);
    function activationBlock() external view returns (uint);
    function accountManager() external view returns (address);
    function getAssets() external view returns (address[] memory);
    function getBorrows() external view returns (address[] memory);
    function exec(
        address target,
        uint amt,
        bytes calldata data
    ) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccountFactory {

    event AccountCreated(
        address indexed account,
        address indexed accountManager
    );

    function create(address accountManager) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRegistry} from "./IRegistry.sol";
import {IRiskEngine} from "./IRiskEngine.sol";
import {IAccountFactory} from "../core/IAccountFactory.sol";
import {IControllerFacade} from "controller/core/IControllerFacade.sol";

interface IAccountManager {
    event AccountAssigned(address indexed account, address indexed owner);
    event AccountClosed(address indexed account, address indexed owner);
    event AccountLiquidated(address indexed account, address indexed owner);
    event Repay(
        address indexed account,
        address indexed owner,
        address indexed token,
        uint amt
    );
    event Borrow(
        address indexed account,
        address indexed owner,
        address indexed token,
        uint amt
    );

    function registry() external returns (IRegistry);
    function riskEngine() external returns (IRiskEngine);
    function accountFactory() external returns (IAccountFactory);
    function controller() external returns (IControllerFacade);
    function init(IRegistry) external;
    function initDep() external;
    function openAccount(address owner) external;
    function closeAccount(address account) external;
    function repay(address account, address token, uint amt) external;
    function borrow(address account, address token, uint amt) external;
    function deposit(address account, address token, uint amt) external;
    function withdraw(address account, address token, uint amt) external;
    function depositEth(address account) payable external;
    function withdrawEth(address, uint) external;
    function liquidate(address) external;
    function settle(address) external;
    function exec(
        address account,
        address target,
        uint amt,
        bytes calldata data
    ) external;
    function approve(
        address account,
        address token,
        address spender,
        uint amt
    ) external;
    function toggleCollateralStatus(address token) external;
    function getInactiveAccountsOf(
        address owner
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRateModel {
    function getBorrowRatePerSecond(
        uint liquidity,
        uint borrows
    ) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRegistry {
    event AccountCreated(address indexed account, address indexed owner);

    function init() external;

    function addressFor(string calldata id) external view returns (address);
    function ownerFor(address account) external view returns (address);

    function getAllLTokens() external view returns (address[] memory);
    function LTokenFor(address underlying) external view returns (address);

    function setAddress(string calldata id, address _address) external;
    function setLToken(address underlying, address lToken) external;

    function addAccount(address account, address owner) external;
    function updateAccount(address account, address owner) external;
    function closeAccount(address account) external;

    function getAllAccounts() external view returns(address[] memory);
    function accountsOwnedBy(address user)
        external view returns (address[] memory);
    function getAddress(string calldata) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRiskEngine {
    function initDep() external;
    function getBorrows(address account) external view returns (uint);
    function getBalance(address account) external view returns (uint);
    function isAccountHealthy(address account) external view returns (bool);
    function isBorrowAllowed(address account, address token, uint amt)
        external view returns (bool);
    function isWithdrawAllowed(address account, address token, uint amt)
        external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)
        external returns (bool success);
    function approve(address _spender, uint256 _value)
        external returns (bool success);
    function allowance(address _owner, address _spender)
        external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value)
        external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC4626 {
    function convertToAssets(uint256 shares) external view returns (uint256);
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";
import {IERC4626} from "./IERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IOwnable} from "../utils/IOwnable.sol";
import {IRegistry} from "../core/IRegistry.sol";
import {IRateModel} from "../core/IRateModel.sol";

interface ILToken {
    function init(
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _originationFee,
        address treasury,
        uint _min_mint,
        uint _maxSupply
    ) external;

    function initDep(string calldata) external;

    function registry() external returns (IRegistry);
    function rateModel() external returns (IRateModel);
    function accountManager() external returns (address);

    function updateState() external;
    function lendTo(address account, uint amt) external returns (bool);
    function collectFrom(address account, uint amt) external returns (bool);

    function getBorrows() external view returns (uint);
    function getBorrowBalance(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOwnable {
    function admin() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error AdminOnly();
    error MaxSupply();
    error ZeroShares();
    error ZeroAssets();
    error ZeroAddress();
    error MinimumShares();
    error ContractPaused();
    error OutstandingDebt();
    error AccountOwnerOnly();
    error TokenNotContract();
    error AddressNotContract();
    error ContractNotPaused();
    error LTokenUnavailable();
    error LiquidationFailed();
    error EthTransferFailure();
    error AccountManagerOnly();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error IncorrectConstructorArgs();
    error ContractAlreadyInitialized();
    error AccountDeactivationFailure();
    error AccountInteractionFailure(address, address, uint, bytes);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {IAccount} from "../interface/core/IAccount.sol";

/// @author Modified from Rari-Capital/Solmate
library Helpers {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeTransferEth(address to, uint256 amt) internal {
        (bool success, ) = to.call{value: amt}(new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function balanceOf(address token, address owner) internal view returns (uint) {
        return IERC20(token).balanceOf(owner);
    }

    function withdrawEth(address account, address to, uint amt) internal {
        (bool success, ) = IAccount(account).exec(to, amt, new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function withdraw(address account, address to, address token, uint amt) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
                abi.encodeWithSelector(IERC20.transfer.selector, to, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(address account, address token, address spender, uint amt) internal {
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
            abi.encodeWithSelector(IERC20.approve.selector, spender, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function isContract(address token) internal view returns (bool) {
        return token.code.length > 0;
    }

    function functionDelegateCall(
        address target,
        bytes calldata data
    ) internal {
        if (!isContract(target)) revert Errors.AddressNotContract();
        (bool success, ) = target.delegatecall(data);
        require(success, "CALL_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";

abstract contract Ownable {

    address public admin;

    event OwnershipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    function initOwnable(address _admin) internal {
        if (_admin == address(0)) revert Errors.ZeroAddress();
        admin = _admin;
    }

    modifier adminOnly() {
        if (admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function transferOwnership(address newAdmin) external virtual adminOnly {
        if (newAdmin == address(0)) revert Errors.ZeroAddress();
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";
import {Ownable} from  "./Ownable.sol";

abstract contract Pausable is Ownable {
    bool public paused;

    event PauseToggled(address indexed admin, bool pause);

    function initPausable(address _admin) internal {
        initOwnable(_admin);
    }

    modifier whenNotPaused() {
        if (paused) revert Errors.ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert  Errors.ContractNotPaused();
        _;
    }

    function togglePause() external adminOnly {
        paused = !paused;
        emit PauseToggled(msg.sender, paused);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
contract ReentrancyGuard {
    uint256 internal locked;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}