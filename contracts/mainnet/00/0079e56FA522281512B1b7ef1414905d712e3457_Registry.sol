// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "../interfaces/ILiquidityProvider.sol";
import "../interfaces/IOperatorOwned.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IToken.sol";
import "../interfaces/ITokenOperatorOwned.sol";
import "../interfaces/ITotalRewardPool.sol";
import "../interfaces/ITrfVariables.sol";

import { UtilityVars } from "../interfaces/IFluidClient.sol";

struct FluidityClientChange {
    string name;
    bool overwrite;
    address token;
    IFluidClient client;
}

/// @dev return type from getUtilityVars
struct ScannedUtilityVars {
    UtilityVars vars;
    string name;
}

contract Registry is IRegistry, ITotalRewardPool, IOperatorOwned {

    /// @notice emitted when a fluidity client is updated
    event FluidityClientChanged(
        address indexed token,
        string indexed name,
        address oldClient,
        address newClient
    );

    /// @dev TrfVariablesUpdated in the code
    event TrfVariablesUpdated(TrfVariables old, TrfVariables new_);

    uint8 private version_;

    /**
    * @dev operator_ able to access the permissioned functions on this
    * Registry (note: not Operator)
    */
    address private operator_;

    ITokenOperatorOwned[] private tokens_;

    ILiquidityProvider[] private liquidityProviders_;

    /// @dev token => utility name => fluid client
    mapping(address => mapping(string => IFluidClient)) private fluidityClients_;

    mapping(address => TrfVariables) private trfVariables_;

    function init(address _operator) public {
        require(version_ == 0, "already deployed");

        operator_ = _operator;

        version_ = 1;
    }

    function _registerToken(ITokenOperatorOwned _token) internal {
        tokens_.push(_token);
    }

    function registerToken(ITokenOperatorOwned _token) public {
        require(operator_ == address(0) || msg.sender == operator_, "not allowed");
        _registerToken(_token);
    }

    function registerManyTokens(ITokenOperatorOwned[] calldata _tokens) public {
        require(operator_ == address(0) || msg.sender == operator_, "not allowed");

        for (uint i = 0; i < _tokens.length; ++i)
          _registerToken(_tokens[i]);
    }

    function _registerLiquidityProvider(ILiquidityProvider _lp) internal {
        liquidityProviders_.push(_lp);
    }

    function registerLiquidityProvider(ILiquidityProvider _lp) public {
        require(operator_ == address(0) || msg.sender == operator_, "not allowed");
        _registerLiquidityProvider(_lp);
    }

    function registerManyLiquidityProviders(ILiquidityProvider[] calldata _lps) public {
        require(operator_ == address(0) || msg.sender == operator_, "not allowed");

        for (uint i = 0; i < _lps.length; ++i)
          _registerLiquidityProvider(_lps[i]);
    }

    function tokens() public view returns (ITokenOperatorOwned[] memory) {
        return tokens_;
    }

    /// @inheritdoc ITotalRewardPool
    function getTVL() public returns (uint256 cumulative) {
        for (uint i = 0; i < tokens_.length; i++) {
            IToken token = tokens_[i];

            uint256 amount = token.underlyingLp().totalPoolAmount();

            uint8 decimals = token.decimals();

            require(18 >= decimals, "decimals too high");

            cumulative += amount * (10 ** (18 - decimals));
        }

        return cumulative;
    }

    /// @inheritdoc ITotalRewardPool
    function getTotalRewardPool() public returns (uint256 cumulative) {
        for (uint i = 0; i < tokens_.length; i++) {
            IToken token = tokens_[i];

            uint256 amount = token.rewardPoolAmount();

            uint8 decimals = token.decimals();

            require(18 >= decimals, "decimals too high");

            cumulative += amount * (10 ** (18 - decimals));
        }

        return cumulative;
    }

    function operator() public view returns (address) {
        return operator_;
    }

    function updateOperator(address _newOperator) public {
        require(msg.sender == operator_, "only operator");
        require(_newOperator != address(0), "zero operator");

        emit NewOperator(operator_, _newOperator);

        operator_ = _newOperator;
    }

    function getFluidityClient(
        address _token,
        string memory _clientName
    ) public view returns (IFluidClient) {
        return fluidityClients_[_token][_clientName];
    }

    function updateUtilityClients(FluidityClientChange[] memory _clients) public {
        require(msg.sender == operator_, "only operator");

        for (uint i = 0; i < _clients.length; ++i) {
            FluidityClientChange memory change = _clients[i];

            address oldClient = address(getFluidityClient(change.token, change.name));

            // either the old client must be unset (setting a completely new client)
            // or the overwrite option must be set

            require(oldClient == address(0) || change.overwrite, "no override");

            fluidityClients_[change.token][change.name] = change.client;

            emit FluidityClientChanged(
                change.token,
                change.name,
                oldClient,
                address(change.client)
            );
        }
    }

    /// @notice update the trf variables for a specific token
    function updateTrfVariables(address _token, TrfVariables calldata _trf) public {
        require(msg.sender == operator_, "only operator");

        emit TrfVariablesUpdated(trfVariables_[_token], _trf);

        trfVariables_[_token] = _trf;
    }

    function getTrfVariables(address _token) public view returns (TrfVariables memory) {
        return trfVariables_[_token];
    }

    /**
     * @notice fetches utility vars for several contracts by name
     * @param _token the token for which to fetch utilities
     * @param _names the list of names of utilities to fetch for
     *
     * @return an array of utility vars
     */
    function getUtilityVars(
        address _token,
        string[] memory _names
    ) public returns (ScannedUtilityVars[] memory) {
        ScannedUtilityVars[] memory vars = new ScannedUtilityVars[](_names.length);

        for (uint i = 0; i < _names.length; ++i) {
            string memory name = _names[i];

            vars[i].name = name;

            IFluidClient utility = fluidityClients_[_token][name];

            // reverts if utility == 0 !
            vars[i].vars = utility.getUtilityVars();
        }

        return vars;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.16;

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
     * @dev Returns the number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

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

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

/// @dev parameter for the batchReward function
struct Winner {
    address winner;
    uint256 amount;
}

/// @dev returned from the getUtilityVars function to calculate distribution amounts
struct UtilityVars {
    uint256 poolSizeNative;
    uint256 tokenDecimalScale;
    uint256 exchangeRateNum;
    uint256 exchangeRateDenom;
    uint256 deltaWeightNum;
    uint256 deltaWeightDenom;
    string customCalculationType;
}

// DEFAULT_CALCULATION_TYPE to use as the value for customCalculationType if
// your utility doesn't have a worker override
string constant DEFAULT_CALCULATION_TYPE = "";

interface IFluidClient {

    /// @notice MUST be emitted when any reward is paid out
    event Reward(
        address indexed winner,
        uint amount,
        uint startBlock,
        uint endBlock
    );

    /**
     * @notice pays out several rewards
     * @notice only usable by the trusted oracle account
     *
     * @param rewards the array of rewards to pay out
     */
    function batchReward(Winner[] memory rewards, uint firstBlock, uint lastBlock) external;

    /**
     * @notice gets stats on the token being distributed
     * @return the variables for the trf
     */
    function getUtilityVars() external returns (UtilityVars memory);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";

/// @title generic interface around an interest source
interface ILiquidityProvider {
    /**
     * @notice getter for the owner of the pool (account that can deposit and remove from it)
     * @return address of the owning account
     */
    function owner_() external view returns (address);
    /**
     * @notice gets the underlying token (ie, USDt)
     * @return address of the underlying token
     */
    function underlying_() external view returns (IERC20);

    /**
     * @notice adds `amount` of tokens to the pool from the amount in the LiquidityProvider
     * @notice requires that the user approve them first
     * @param amount number of tokens to add, in the units of the underlying token
     */
    function addToPool(uint amount) external;
    /**
     * @notice removes `amount` of tokens from the pool
     * @notice sends the tokens to the owner
     * @param amount number of tokens to remove, in the units of the underlying token
     */
    function takeFromPool(uint amount) external;
    /**
     * @notice returns the total amount in the pool, counting the invested amount and the interest earned
     * @return the amount of tokens in the pool, in the units of the underlying token
     */
    function totalPoolAmount() external returns (uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

interface IOperatorOwned {
    event NewOperator(address old, address new_);

    function operator() external view returns (address);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IFluidClient.sol";
import "./ITrfVariables.sol";
import "./ITokenOperatorOwned.sol";

interface IRegistry {
    function registerToken(ITokenOperatorOwned) external;
    function registerManyTokens(ITokenOperatorOwned[] calldata) external;

    function registerLiquidityProvider(ILiquidityProvider) external;
    function registerManyLiquidityProviders(ILiquidityProvider[] calldata) external;

    function tokens() external view returns (ITokenOperatorOwned[] memory);

    function getFluidityClient(
        address,
        string memory
    ) external view returns (IFluidClient);

    function updateTrfVariables(address, TrfVariables calldata) external;

    function getTrfVariables(address) external returns (TrfVariables memory);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IFluidClient.sol";
import "./ILiquidityProvider.sol";

import "./IERC20.sol";

interface IToken is IERC20 {
    /// @notice emitted when a reward is quarantined for being too large
    event BlockedReward(
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when a blocked reward is released
    event UnblockReward(
        bytes32 indexed originalRewardTx,
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when an underlying token is wrapped into a fluid asset
    event MintFluid(address indexed addr, uint256 amount);

    /// @notice emitted when a fluid token is unwrapped to its underlying asset
    event BurnFluid(address indexed addr, uint256 amount);

    /// @notice emitted when restrictions
    event MaxUncheckedRewardLimitChanged(uint256 amount);

    /// @notice updating the reward quarantine before manual signoff
    /// @notice by the multisig (with updateRewardQuarantineThreshold)
    event RewardQuarantineThresholdUpdated(uint256 amount);

    /// @notice emitted when a user is permitted to mint on behalf of another user
    event MintApproval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice getter for the RNG oracle provided by `workerConfig_`
     * @return the address of the trusted oracle
     *
     * @dev individual oracles are now recorded in the operator, this
     *      now should return the registry contract
     */
    function oracle() external view returns (address);

    /**
     * @notice underlyingToken that this IToken wraps
     */
    function underlyingToken() external view returns (IERC20);

    /**
     * @notice underlyingLp that's in use for the liquidity provider
     */
    function underlyingLp() external view returns (ILiquidityProvider);

    /// @notice updates the reward quarantine threshold if called by the operator
    function updateRewardQuarantineThreshold(uint256) external;

    /**
     * @notice wraps `amount` of underlying tokens into fluid tokens
     * @notice requires you to have called the ERC20 `approve` method
     * @notice targeting this contract first on the underlying asset
     *
     * @param _amount the number of tokens to wrap
     * @return the number of tokens wrapped
     */
    function erc20In(uint256 _amount) external returns (uint256);

    /**
     * @notice erc20InTo wraps the `amount` given and transfers the tokens to `receiver`
     *
     * @param _recipient of the wrapped assets
     * @param _amount to wrap and send to the recipient
     */
    function erc20InTo(address _recipient, uint256 _amount) external returns (uint256);

    /**
     * @notice unwraps `amount` of fluid tokens back to underlying
     *
     * @param _amount the number of fluid tokens to unwrap
     */
    function erc20Out(uint256 _amount) external;

   /**
     * @notice unwraps `amount` of fluid tokens with the address as recipient
     *
     * @param _recipient to receive the underlying tokens to
     * @param _amount the number of fluid tokens to unwrap
     */
    function erc20OutTo(address _recipient, uint256 _amount) external;

    /**
     * @notice calculates the size of the reward pool (the interest we've earned)
     *
     * @return the number of tokens in the reward pool
     */
    function rewardPoolAmount() external returns (uint256);

    /**
     * @notice admin function, unblocks a reward that was quarantined for being too large
     * @notice allows for paying out or removing the reward, in case of abuse
     *
     * @param _user the address of the user who's reward was quarantined
     *
     * @param _amount the amount of tokens to release (in case
     *        multiple rewards were quarantined)
     *
     * @param _payout should the reward be paid out or removed?
     *
     * @param _firstBlock the first block the rewards include (should
     *        be from the BlockedReward event)
     *
     * @param _lastBlock the last block the rewards include
     */
    function unblockReward(
        bytes32 _rewardTx,
        address _user,
        uint256 _amount,
        bool _payout,
        uint256 _firstBlock,
        uint256 _lastBlock
    )
        external;

    /**
     * @notice return the max unchecked reward that's currently set
     */
    function maxUncheckedReward() external view returns (uint256);

    /// @notice upgrade the underlying ILiquidityProvider to a new source
    function upgradeLiquidityProvider(ILiquidityProvider newPool) external;

    /**
     * @notice drain the reward pool of the amount given without
     *         touching any principal amounts
     *
     * @dev this is intended to only be used to retrieve initial
     *       liquidity provided by the team OR by the DAO to allocate funds
     */
    function drainRewardPool(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IToken.sol";
import "./IOperatorOwned.sol";

interface ITokenOperatorOwned is IToken, IOperatorOwned {
    // solhint-disable-empty-line
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

interface ITotalRewardPool {
    /**
     * @notice getTVL by summing the total supply and reward for each token
     *
     * @return the total TVL as 1e18
    */
    function getTVL() external returns (uint256);

    /**
     * @notice getTotalRewardPool for each token that's known by the
     *         contract, normalising to 1e18
     *
     * @return the total prize pool as 1e18
    */
    function getTotalRewardPool() external returns (uint256);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

/// @dev TrfVariables that the worker uses in it's configuration
///      (previously in the database)
struct TrfVariables {
    uint256 currentAtxTransactionMargin;
    uint256 defaultTransfersInBlock;
    uint256 spoolerInstantRewardThreshold;
    uint256 spoolerBatchedRewardThreshold;

    uint8 defaultSecondsSinceLastBlock;
    uint8 atxBufferSize;
}