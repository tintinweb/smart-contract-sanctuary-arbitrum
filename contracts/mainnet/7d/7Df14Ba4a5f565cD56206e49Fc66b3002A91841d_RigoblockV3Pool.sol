// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

import "../immutable/MixinStorage.sol";
import "../../interfaces/IKyc.sol";

abstract contract MixinActions is MixinStorage {
    /*
     * MODIFIERS
     */
    /// @notice Functions with this modifer cannot be reentered. The mutex will be locked before function execution and unlocked after.
    modifier nonReentrant() {
        // Ensure mutex is unlocked
        Pool storage pool = pool();
        require(pool.unlocked, "REENTRANCY_ILLEGAL");

        // Lock mutex before function call
        pool.unlocked = false;

        // Perform function call
        _;

        // Unlock mutex after function call
        pool.unlocked = true;
    }

    /*
     * EXTERNAL METHODS
     */
    /// @inheritdoc IRigoblockV3PoolActions
    function mint(
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) public payable override nonReentrant returns (uint256 recipientAmount) {
        address kycProvider = poolParams().kycProvider;

        // require whitelisted user if kyc is enforced
        if (kycProvider != address(0)) {
            require(IKyc(kycProvider).isWhitelistedUser(recipient), "POOL_CALLER_NOT_WHITELISTED_ERROR");
        }

        _assertBiggerThanMinimum(amountIn);

        if (pool().baseToken == address(0)) {
            require(msg.value == amountIn, "POOL_MINT_AMOUNTIN_ERROR,");
        } else {
            _safeTransferFrom(msg.sender, address(this), amountIn);
        }

        uint256 markup = (amountIn * _getSpread()) / _SPREAD_BASE;
        amountIn -= markup;
        uint256 mintedAmount = (amountIn * 10**decimals()) / _getUnitaryValue();
        require(mintedAmount > amountOutMin, "POOL_MINT_OUTPUT_AMOUNT_ERROR");
        poolTokens().totalSupply += mintedAmount;

        /// @notice allocate pool token transfers and log events.
        recipientAmount = _allocateMintTokens(recipient, mintedAmount);
    }

    /// @inheritdoc IRigoblockV3PoolActions
    function burn(uint256 amountIn, uint256 amountOutMin) external override nonReentrant returns (uint256 netRevenue) {
        require(amountIn > 0, "POOL_BURN_NULL_AMOUNT_ERROR");
        UserAccount memory userAccount = accounts().userAccounts[msg.sender];
        require(userAccount.userBalance >= amountIn, "POOL_BURN_NOT_ENOUGH_ERROR");
        require(block.timestamp >= userAccount.activation, "POOL_MINIMUM_PERIOD_NOT_ENOUGH_ERROR");

        /// @notice allocate pool token transfers and log events.
        uint256 burntAmount = _allocateBurnTokens(amountIn);
        poolTokens().totalSupply -= burntAmount;

        uint256 markup = (burntAmount * _getSpread()) / _SPREAD_BASE;
        burntAmount -= markup;
        netRevenue = (burntAmount * _getUnitaryValue()) / 10**decimals();
        require(netRevenue >= amountOutMin, "POOL_BURN_OUTPUT_AMOUNT_ERROR");

        if (pool().baseToken == address(0)) {
            payable(msg.sender).transfer(netRevenue);
        } else {
            _safeTransfer(msg.sender, netRevenue);
        }
    }

    /*
     * PUBLIC METHODS
     */
    function decimals() public view virtual override returns (uint8);

    /*
     * INTERNAL METHODS
     */
    function _getFeeCollector() internal view virtual returns (address);

    function _getMinPeriod() internal view virtual returns (uint48);

    function _getSpread() internal view virtual returns (uint16);

    function _getUnitaryValue() internal view virtual returns (uint256);

    /*
     * PRIVATE METHODS
     */
    /// @notice Allocates tokens to recipient. Fee tokens are locked too.
    /// @dev Each new mint on same recipient sets new activation on all owned tokens.
    /// @param recipient Address of the recipient.
    /// @param mintedAmount Value of issued tokens.
    /// @return recipientAmount Number of new tokens issued to recipient.
    function _allocateMintTokens(address recipient, uint256 mintedAmount) private returns (uint256 recipientAmount) {
        recipientAmount = mintedAmount;
        Accounts storage accounts = accounts();
        uint208 recipientBalance = accounts.userAccounts[recipient].userBalance;
        uint48 activation;
        // it is safe to use unckecked as max min period is 30 days
        unchecked {
            activation = uint48(block.timestamp) + _getMinPeriod();
        }
        uint16 transactionFee = poolParams().transactionFee;

        if (transactionFee != 0) {
            address feeCollector = _getFeeCollector();

            if (feeCollector == recipient) {
                // it is safe to use unckecked as recipientAmount requires user holding enough base tokens.
                unchecked {
                    recipientBalance += uint208(recipientAmount);
                }
            } else {
                uint208 feeCollectorBalance = accounts.userAccounts[feeCollector].userBalance;
                uint256 feePool = (mintedAmount * transactionFee) / _FEE_BASE;
                recipientAmount -= feePool;
                unchecked {
                    feeCollectorBalance += uint208(feePool);
                    recipientBalance += uint208(recipientAmount);
                }
                //fee tokens are locked as well
                accounts.userAccounts[feeCollector] = UserAccount({
                    userBalance: feeCollectorBalance,
                    activation: activation
                });
                emit Transfer(address(0), feeCollector, feePool);
            }
        } else {
            unchecked {
                recipientBalance += uint208(recipientAmount);
            }
        }

        accounts.userAccounts[recipient] = UserAccount({userBalance: recipientBalance, activation: activation});
        emit Transfer(address(0), recipient, recipientAmount);
    }

    /// @notice Destroys tokens of holder.
    /// @dev Fee is paid in pool tokens.
    /// @param amountIn Value of tokens to be burnt.
    /// @return burntAmount Number of net burnt tokens.
    function _allocateBurnTokens(uint256 amountIn) private returns (uint256 burntAmount) {
        burntAmount = amountIn;
        Accounts storage accounts = accounts();
        uint208 holderBalance = accounts.userAccounts[msg.sender].userBalance;

        if (poolParams().transactionFee != uint256(0)) {
            address feeCollector = _getFeeCollector();

            if (msg.sender == feeCollector) {
                holderBalance -= uint208(burntAmount);
            } else {
                uint256 feePool = (amountIn * poolParams().transactionFee) / _FEE_BASE;
                burntAmount -= feePool;
                holderBalance -= uint208(burntAmount);

                // allocate fee tokens to fee collector
                uint208 feeCollectorBalance = accounts.userAccounts[feeCollector].userBalance;
                uint48 activation;
                unchecked {
                    feeCollectorBalance += uint208(feePool);
                    activation = uint48(block.timestamp + 1);
                }
                accounts.userAccounts[feeCollector] = UserAccount({
                    userBalance: feeCollectorBalance,
                    activation: uint48(block.timestamp + 1)
                });
                emit Transfer(msg.sender, feeCollector, feePool);
            }
        } else {
            holderBalance -= uint208(burntAmount);
        }

        // clear storage is user account has sold all held tokens
        if (holderBalance == 0) {
            delete accounts.userAccounts[msg.sender];
        } else {
            accounts.userAccounts[msg.sender].userBalance = holderBalance;
        }

        emit Transfer(msg.sender, address(0), burntAmount);
    }

    function _assertBiggerThanMinimum(uint256 amount) private view {
        require(amount >= 10**decimals() / _MINIMUM_ORDER_DIVISOR, "POOL_AMOUNT_SMALLER_THAN_MINIMUM_ERROR");
    }

    function _safeTransfer(address to, uint256 amount) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = pool().baseToken.call(
            abi.encodeWithSelector(_TRANSFER_SELECTOR, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "POOL_TRANSFER_FAILED_ERROR");
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = pool().baseToken.call(
            abi.encodeWithSelector(_TRANSFER_FROM_SELECTOR, from, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "POOL_TRANSFER_FROM_FAILED_ERROR");
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

import "./MixinActions.sol";

abstract contract MixinOwnerActions is MixinActions {
    /// @dev We keep this check to prevent accidental failure in Nav calculations.
    modifier notPriceError(uint256 newUnitaryValue) {
        /// @notice most typical error is adding/removing one 0, we check by a factory of 5 for safety.
        require(
            newUnitaryValue < _getUnitaryValue() * 5 && newUnitaryValue > _getUnitaryValue() / 5,
            "POOL_INPUT_VALUE_ERROR"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == pool().owner, "POOL_CALLER_IS_NOT_OWNER_ERROR");
        _;
    }

    /// @inheritdoc IRigoblockV3PoolOwnerActions
    function changeFeeCollector(address feeCollector) external override onlyOwner {
        poolParams().feeCollector = feeCollector;
        emit NewCollector(msg.sender, address(this), feeCollector);
    }

    /// @inheritdoc IRigoblockV3PoolOwnerActions
    function changeMinPeriod(uint48 minPeriod) external override onlyOwner {
        /// @notice minimum period is always at least 1 to prevent flash txs.
        require(minPeriod >= _MIN_LOCKUP && minPeriod <= _MAX_LOCKUP, "POOL_CHANGE_MIN_LOCKUP_PERIOD_ERROR");
        poolParams().minPeriod = minPeriod;
        emit MinimumPeriodChanged(address(this), minPeriod);
    }

    /// @inheritdoc IRigoblockV3PoolOwnerActions
    function changeSpread(uint16 newSpread) external override onlyOwner {
        // new spread must always be != 0, otherwise default spread from immutable storage will be returned
        require(newSpread > 0, "POOL_SPREAD_NULL_ERROR");
        require(newSpread <= _MAX_SPREAD, "POOL_SPREAD_TOO_HIGH_ERROR");
        poolParams().spread = newSpread;
        emit SpreadChanged(address(this), newSpread);
    }

    /// @inheritdoc IRigoblockV3PoolOwnerActions
    function setKycProvider(address kycProvider) external override onlyOwner {
        require(_isContract(kycProvider), "POOL_INPUT_NOT_CONTRACT_ERROR");
        poolParams().kycProvider = kycProvider;
        emit KycProviderSet(address(this), kycProvider);
    }

    /// @inheritdoc IRigoblockV3PoolOwnerActions
    function setTransactionFee(uint16 transactionFee) external override onlyOwner {
        require(transactionFee <= _MAX_TRANSACTION_FEE, "POOL_FEE_HIGHER_THAN_ONE_PERCENT_ERROR"); //fee cannot be higher than 1%
        poolParams().transactionFee = transactionFee;
        emit NewFee(msg.sender, address(this), transactionFee);
    }

    /// @inheritdoc IRigoblockV3PoolOwnerActions
    function setUnitaryValue(uint256 unitaryValue) external override onlyOwner notPriceError(unitaryValue) {
        // unitary value can be updated only after first mint. we require positive value as would
        //  return to default value if storage cleared
        require(poolTokens().totalSupply > 0, "POOL_SUPPLY_NULL_ERROR");

        // This will underflow with small decimals tokens at some point, which is ok
        uint256 minimumLiquidity = ((unitaryValue * totalSupply()) / 10**decimals() / 100) * 3;

        if (pool().baseToken == address(0)) {
            require(address(this).balance >= minimumLiquidity, "POOL_CURRENCY_BALANCE_TOO_LOW_ERROR");
        } else {
            require(
                IERC20(pool().baseToken).balanceOf(address(this)) >= minimumLiquidity,
                "POOL_TOKEN_BALANCE_TOO_LOW_ERROR"
            );
        }

        poolTokens().unitaryValue = unitaryValue;
        emit NewNav(msg.sender, address(this), unitaryValue);
    }

    /// @inheritdoc IRigoblockV3PoolOwnerActions
    function setOwner(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "POOL_NULL_OWNER_INPUT_ERROR");
        address oldOwner = pool().owner;
        pool().owner = newOwner;
        emit NewOwner(oldOwner, newOwner);
    }

    function totalSupply() public view virtual override returns (uint256);

    function decimals() public view virtual override returns (uint8);

    function _getUnitaryValue() internal view virtual override returns (uint256);

    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "../../IRigoblockV3Pool.sol";

/// @notice Constants are copied in the bytecode and not assigned a storage slot, can safely be added to this contract.
/// @dev Inheriting from interface is required as we override public variables.
abstract contract MixinConstants is IRigoblockV3Pool {
    /// @inheritdoc IRigoblockV3PoolImmutable
    string public constant override VERSION = "HF 3.1.2";

    bytes32 internal constant _POOL_INIT_SLOT = 0xe48b9bb119adfc3bccddcc581484cc6725fe8d292ebfcec7d67b1f93138d8bd8;

    bytes32 internal constant _POOL_VARIABLES_SLOT = 0xe3ed9e7d534645c345f2d15f0c405f8de0227b60eb37bbeb25b26db462415dec;

    bytes32 internal constant _POOL_TOKENS_SLOT = 0xf46fb7ff9ff9a406787c810524417c818e45ab2f1997f38c2555c845d23bb9f6;

    bytes32 internal constant _POOL_ACCOUNTS_SLOT = 0xfd7547127f88410746fb7969b9adb4f9e9d8d2436aa2d2277b1103542deb7b8e;

    uint16 internal constant _FEE_BASE = 10000;

    uint16 internal constant _INITIAL_SPREAD = 500; // +-5%, in basis points

    uint16 internal constant _MAX_SPREAD = 1000; // +-10%, in basis points

    uint16 internal constant _MAX_TRANSACTION_FEE = 100; // maximum 1%

    // minimum order size 1/1000th of base to avoid dust clogging things up
    uint16 internal constant _MINIMUM_ORDER_DIVISOR = 1e3;

    uint16 internal constant _SPREAD_BASE = 10000;

    uint48 internal constant _MAX_LOCKUP = 30 days;

    uint48 internal constant _MIN_LOCKUP = 2;

    bytes4 internal constant _TRANSFER_FROM_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    bytes4 internal constant _TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "./MixinConstants.sol";

/// @notice Immutables are not assigned a storage slot, can be safely added to this contract.
abstract contract MixinImmutables is MixinConstants {
    /// @inheritdoc IRigoblockV3PoolImmutable
    address public immutable override authority;

    // EIP1967 standard, must be immutable to be compile-time constant.
    address internal immutable _implementation;

    constructor(address newAuthority) {
        authority = newAuthority;
        _implementation = address(this);
    }
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

import "./MixinImmutables.sol";

pragma solidity >=0.8.0 <0.9.0;

/// @notice Storage slots must be preserved to prevent storage clashing.
/// @dev Pool storage is not sequential: each variable is wrapped into a struct which is assigned a storage slot.
abstract contract MixinStorage is MixinImmutables {
    constructor() {
        // governance must always check that pool extensions are not using these storage slots (reserved for proxy storage)
        assert(_POOL_INIT_SLOT == bytes32(uint256(keccak256("pool.proxy.initialization")) - 1));
        assert(_POOL_VARIABLES_SLOT == bytes32(uint256(keccak256("pool.proxy.variables")) - 1));
        assert(_POOL_TOKENS_SLOT == bytes32(uint256(keccak256("pool.proxy.token")) - 1));
        assert(_POOL_ACCOUNTS_SLOT == bytes32(uint256(keccak256("pool.proxy.user.accounts")) - 1));
    }

    // mappings slot kept empty and i.e. userBalance stored at location keccak256(address(msg.sender) . uint256(_POOL_USER_ACCOUNTS_SLOT))
    // activation stored at locantion keccak256(address(msg.sender) . uint256(_POOL_USER_ACCOUNTS_SLOT)) + 1
    struct Accounts {
        mapping(address => UserAccount) userAccounts;
    }

    function accounts() internal pure returns (Accounts storage s) {
        assembly {
            s.slot := _POOL_ACCOUNTS_SLOT
        }
    }

    /// @notice Pool initialization parameters.
    /// @dev This struct is not visible externally and used to store/read pool init params.
    /// @param name String of the pool name (max 32 characters).
    /// @param symbol Bytes8 of the pool symbol (from 3 to 5 characters).
    /// @param decimals Uint8 decimals.
    /// @param owner Address of the pool operator.
    /// @param unlocked Boolean the pool is locked for reentrancy check.
    /// @param baseToken Address of the base token of the pool (0 for base currency).
    struct Pool {
        string name;
        bytes8 symbol;
        uint8 decimals;
        address owner;
        bool unlocked;
        address baseToken;
    }

    function pool() internal pure returns (Pool storage s) {
        assembly {
            s.slot := _POOL_INIT_SLOT
        }
    }

    /// @notice Pool initialization struct wrapper.
    /// @dev Allows initializing pool as struct for better readability.
    /// @param pool The pool struct.
    struct PoolWrapper {
        Pool pool;
    }

    function poolWrapper() internal pure returns (PoolWrapper storage s) {
        assembly {
            s.slot := _POOL_INIT_SLOT
        }
    }

    function poolParams() internal pure returns (PoolParams storage s) {
        assembly {
            s.slot := _POOL_VARIABLES_SLOT
        }
    }

    function poolTokens() internal pure returns (PoolTokens storage s) {
        assembly {
            s.slot := _POOL_TOKENS_SLOT
        }
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

import "../actions/MixinOwnerActions.sol";

abstract contract MixinPoolState is MixinOwnerActions {
    /*
     * EXTERNAL VIEW METHODS
     */
    /// @dev Returns how many pool tokens a user holds.
    /// @param who Address of the target account.
    /// @return Number of pool.
    function balanceOf(address who) external view override returns (uint256) {
        return accounts().userAccounts[who].userBalance;
    }

    /// @inheritdoc IRigoblockV3PoolState
    function getPoolStorage()
        external
        view
        override
        returns (
            ReturnedPool memory poolInitParams,
            PoolParams memory poolVariables,
            PoolTokens memory poolTokensInfo
        )
    {
        return (getPool(), getPoolParams(), getPoolTokens());
    }

    function getUserAccount(address who) external view override returns (UserAccount memory) {
        return accounts().userAccounts[who];
    }

    /// @inheritdoc IRigoblockV3PoolState
    function owner() external view override returns (address) {
        return pool().owner;
    }

    /*
     * PUBLIC VIEW METHODS
     */
    /// @notice Decimals are initialized at proxy creation.
    /// @return Number of decimals.
    function decimals() public view override returns (uint8) {
        return pool().decimals;
    }

    /// @inheritdoc IRigoblockV3PoolState
    function getPool() public view override returns (ReturnedPool memory) {
        Pool memory pool = pool();
        // we return symbol as string, omit unlocked as always true
        return
            ReturnedPool({
                name: pool.name,
                symbol: symbol(),
                decimals: pool.decimals,
                owner: pool.owner,
                baseToken: pool.baseToken
            });
    }

    /// @inheritdoc IRigoblockV3PoolState
    function getPoolParams() public view override returns (PoolParams memory) {
        return
            PoolParams({
                minPeriod: _getMinPeriod(),
                spread: _getSpread(),
                transactionFee: poolParams().transactionFee,
                feeCollector: _getFeeCollector(),
                kycProvider: poolParams().kycProvider
            });
    }

    /// @inheritdoc IRigoblockV3PoolState
    function getPoolTokens() public view override returns (PoolTokens memory) {
        return PoolTokens({unitaryValue: _getUnitaryValue(), totalSupply: poolTokens().totalSupply});
    }

    /// @inheritdoc IRigoblockV3PoolState
    function name() public view override returns (string memory) {
        return pool().name;
    }

    /// @inheritdoc IRigoblockV3PoolState
    function symbol() public view override returns (string memory) {
        bytes8 _symbol = pool().symbol;
        uint8 i = 0;
        while (i < 8 && _symbol[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 8 && _symbol[i] != 0; i++) {
            bytesArray[i] = _symbol[i];
        }
        return string(bytesArray);
    }

    /// @inheritdoc IRigoblockV3PoolState
    function totalSupply() public view override returns (uint256) {
        return poolTokens().totalSupply;
    }

    /*
     * INTERNAL VIEW METHODS
     */
    function _getFeeCollector() internal view override returns (address) {
        address feeCollector = poolParams().feeCollector;
        return feeCollector != address(0) ? feeCollector : pool().owner;
    }

    function _getMinPeriod() internal view override returns (uint48) {
        uint48 minPeriod = poolParams().minPeriod;
        return minPeriod != 0 ? minPeriod : _MIN_LOCKUP;
    }

    function _getSpread() internal view override returns (uint16) {
        uint16 spread = poolParams().spread;
        return spread != 0 ? spread : _INITIAL_SPREAD;
    }

    function _getUnitaryValue() internal view override returns (uint256) {
        uint256 unitaryValue = poolTokens().unitaryValue;
        return unitaryValue != 0 ? unitaryValue : 10**pool().decimals;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../../interfaces/pool/IStorageAccessible.sol";

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
abstract contract MixinStorageAccessible is IStorageAccessible {
    /// @inheritdoc IStorageAccessible
    function getStorageAt(uint256 offset, uint256 length) public view override returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /// @inheritdoc IStorageAccessible
    function getStorageSlotsAt(uint256[] memory slots) public view override returns (bytes memory) {
        bytes memory result = new bytes(slots.length * 32);
        for (uint256 index = 0; index < slots.length; index++) {
            uint256 slot = slots[index];
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(slot)
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

import "../../interfaces/IERC20.sol";

/// @notice This contract makes it easy for clients to track ERC20.
abstract contract MixinAbstract is IERC20 {
    /// @dev Non-implemented ERC20 method.
    function transfer(address to, uint256 value) external override returns (bool success) {}

    /// @dev Non-implemented ERC20 method.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool success) {}

    /// @dev Non-implemented ERC20 method.
    function approve(address spender, uint256 value) external override returns (bool success) {}

    /// @dev Non-implemented ERC20 method.
    function allowance(address owner, address spender) external view override returns (uint256) {}
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

//import "../actions/MixinActions.sol";
import "../immutable/MixinImmutables.sol";
import "../immutable/MixinStorage.sol";
import "../../interfaces/IAuthority.sol";

abstract contract MixinFallback is MixinImmutables, MixinStorage {
    // reading immutable through internal method more gas efficient
    modifier onlyDelegateCall() {
        _checkDelegateCall();
        _;
    }

    /* solhint-disable no-complex-fallback */
    /// @inheritdoc IRigoblockV3PoolFallback
    fallback() external payable {
        address adapter = _getApplicationAdapter(msg.sig);
        // we check that the method is approved by governance
        require(adapter != address(0), "POOL_METHOD_NOT_ALLOWED_ERROR");

        // direct fallback to implementation will result in staticcall to extension as implementation owner is address(1)
        address poolOwner = pool().owner;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success
            // pool owner can execute a delegatecall to extension, any other caller will perform a staticcall
            if eq(caller(), poolOwner) {
                success := delegatecall(gas(), adapter, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                if eq(success, 0) {
                    revert(0, returndatasize())
                }
                return(0, returndatasize())
            }
            success := staticcall(gas(), adapter, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            // we allow the staticcall to revert with rich error, should we want to add errors to extensions view methods
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /* solhint-enable no-complex-fallback */

    /// @inheritdoc IRigoblockV3PoolFallback
    receive() external payable onlyDelegateCall {}

    function _checkDelegateCall() private view {
        require(address(this) != _implementation, "POOL_IMPLEMENTATION_DIRECT_CALL_NOT_ALLOWED_ERROR");
    }

    /// @dev Returns the address of the application adapter.
    /// @param selector Hash of the method signature.
    /// @return Address of the application adapter.
    function _getApplicationAdapter(bytes4 selector) private view returns (address) {
        return IAuthority(authority).getApplicationAdapter(selector);
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

import "../immutable/MixinImmutables.sol";
import "../immutable/MixinStorage.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IRigoblockPoolProxyFactory.sol";

abstract contract MixinInitializer is MixinImmutables, MixinStorage {
    error BaseTokenDecimals();

    modifier onlyUninitialized() {
        // pool proxy is always initialized in the constructor, therefore
        // empty code means the pool has not been initialized
        require(address(this).code.length == 0, "POOL_ALREADY_INITIALIZED_ERROR");
        _;
    }

    /// @inheritdoc IRigoblockV3PoolInitializer
    function initializePool() external override onlyUninitialized {
        IRigoblockPoolProxyFactory.Parameters memory initParams = IRigoblockPoolProxyFactory(msg.sender).parameters();
        uint8 tokenDecimals;

        if (initParams.baseToken != address(0)) {
            assert(initParams.baseToken.code.length > 0);
            // revert in case the ERC20 read call fails silently
            try IERC20(initParams.baseToken).decimals() returns (uint8 decimals) {
                tokenDecimals = decimals;
            } catch {
                revert BaseTokenDecimals();
            }
            // a pool with small decimals could easily underflow.
            assert(tokenDecimals >= 6);
        } else {
            tokenDecimals = 18;
        }

        poolWrapper().pool = Pool({
            name: initParams.name,
            symbol: initParams.symbol,
            decimals: tokenDecimals,
            owner: initParams.owner,
            unlocked: true,
            baseToken: initParams.baseToken
        });

        emit PoolInitialized(msg.sender, initParams.owner, initParams.baseToken, initParams.name, initParams.symbol);
    }
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.7.0 <0.9.0;

/// @title Authority Interface - Allows interaction with the Authority contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IAuthority {
    /// @notice Adds a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionAdded(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the  method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionRemoved(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes an approved method.
    /// @dev Removes a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event RemovedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    /// @notice Approves a new method.
    /// @dev Adds a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter  Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event WhitelistedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    enum Role {
        ADAPTER,
        FACTORY,
        WHITELISTER
    }

    /// @notice Mapping of permission type to bool.
    /// @param Mapping of type of permission to bool is authorized.
    struct Permission {
        mapping(Role => bool) authorized;
    }

    /// @notice Allows a whitelister to whitelist a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    /// @notice We do not save list of approved as better queried by events.
    function addMethod(bytes4 selector, address adapter) external;

    /// @notice Allows a whitelister to remove a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    function removeMethod(bytes4 selector, address adapter) external;

    /// @notice Allows owner to set extension adapter address.
    /// @param adapter Address of the target adapter.
    /// @param isWhitelisted Bool whitelisted.
    function setAdapter(address adapter, bool isWhitelisted) external;

    /// @notice Allows an admin to set factory permission.
    /// @param factory Address of the target factory.
    /// @param isWhitelisted Bool whitelisted.
    function setFactory(address factory, bool isWhitelisted) external;

    /// @notice Allows the owner to set whitelister permission.
    /// @param whitelister Address of the whitelister.
    /// @param isWhitelisted Bool whitelisted.
    /// @notice Whitelister permission is required to approve methods in extensions adapter.
    function setWhitelister(address whitelister, bool isWhitelisted) external;

    /// @notice Returns the address of the adapter associated to the signature.
    /// @param selector Hex of the method signature.
    /// @return Address of the adapter.
    function getApplicationAdapter(bytes4 selector) external view returns (address);

    /// @notice Provides whether a factory is whitelisted.
    /// @param target Address of the target factory.
    /// @return Bool is whitelisted.
    function isWhitelistedFactory(address target) external view returns (bool);

    /// @notice Provides whether an address is whitelister.
    /// @param target Address of the target whitelister.
    /// @return Bool is whitelisted.
    function isWhitelister(address target) external view returns (bool);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    /// @notice Emitted when a token is transferred.
    /// @param from Address transferring the tokens.
    /// @param to Address receiving the tokens.
    /// @param value Number of token units.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when a token holder sets and approval.
    /// @param owner Address of the account setting the approval.
    /// @param spender Address of the allowed account.
    /// @param value Number of approved units.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Transfers token from holder to another address.
    /// @param to Address to send tokens to.
    /// @param value Number of token units to send.
    /// @return success Bool the transaction was successful.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice Allows spender to transfer tokens from the holder.
    /// @param from Address of the token holder.
    /// @param to Address to send tokens to.
    /// @param value Number of units to transfer.
    /// @return success Bool the transaction was successful.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice Allows a holder to approve a spender.
    /// @param spender Address of the token spender.
    /// @param value Number of units to be approved.
    /// @return success Bool the transaction was successful.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice Returns token balance for an address.
    /// @param who Address to query balance for.
    /// @return Number of units held.
    function balanceOf(address who) external view returns (uint256);

    /// @notice Returns token allowance of an address to another address.
    /// @param owner Address of token hodler.
    /// @param spender Address of the token spender.
    /// @return Number of allowed units.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns token decimals.
    /// @return Uint8 number of decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title KycFace - allows interaction with a Kyc provider.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IKyc {
    /// @notice Returns whether an address has been whitelisted.
    /// @param user The address to verify.
    /// @return Bool the user is whitelisted.
    function isWhitelistedUser(address user) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2017-2022 RigoBlock, Rigo Investment Sagl, Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Pool Proxy Factory Interface - Allows external interaction with Pool Proxy Factory.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockPoolProxyFactory {
    /// @notice Emitted when a new pool is created.
    /// @param poolAddress Address of the new pool.
    event PoolCreated(address poolAddress);

    /// @notice Emitted when a new implementation is set by the Rigoblock Dao.
    /// @param implementation Address of the new implementation.
    event Upgraded(address indexed implementation);

    /// @notice Emitted when registry address is upgraded by the Rigoblock Dao.
    /// @param registry Address of the new registry.
    event RegistryUpgraded(address indexed registry);

    /// @notice Returns the implementation address for the pool proxies.
    /// @return Address of the implementation.
    function implementation() external view returns (address);

    /// @notice Creates a new Rigoblock pool.
    /// @param name String of the name.
    /// @param symbol String of the symbol.
    /// @param baseToken Address of the base token.
    /// @return newPoolAddress Address of the new pool.
    /// @return poolId Id of the new pool.
    function createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) external returns (address newPoolAddress, bytes32 poolId);

    /// @notice Allows Rigoblock Dao to update factory pool implementation.
    /// @param newImplementation Address of the new implementation contract.
    function setImplementation(address newImplementation) external;

    /// @notice Allows owner to update the registry.
    /// @param newRegistry Address of the new registry.
    function setRegistry(address newRegistry) external;

    /// @notice Returns the address of the pool registry.
    /// @return Address of the registry.
    function getRegistry() external view returns (address);

    /// @notice Pool initialization parameters.
    /// @params name String of the name (max 31 characters).
    /// @params symbol bytes8 symbol.
    /// @params owner Address of the owner.
    /// @params baseToken Address of the base token.
    struct Parameters {
        string name;
        bytes8 symbol;
        address owner;
        address baseToken;
    }

    /// @notice Returns the pool initialization parameters at proxy deploy.
    /// @return Tuple of the pool parameters.
    function parameters() external view returns (Parameters memory);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Actions Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3PoolActions {
    /// @notice Allows a user to mint pool tokens on behalf of an address.
    /// @param recipient Address receiving the tokens.
    /// @param amountIn Amount of base tokens.
    /// @param amountOutMin Minimum amount to be received, prevents pool operator frontrunning.
    /// @return recipientAmount Number of tokens minted to recipient.
    function mint(
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) external payable returns (uint256 recipientAmount);

    /// @notice Allows a pool holder to burn pool tokens.
    /// @param amountIn Number of tokens to burn.
    /// @param amountOutMin Minimum amount to be received, prevents pool operator frontrunning.
    /// @return netRevenue Net amount of burnt pool tokens.
    function burn(uint256 amountIn, uint256 amountOutMin) external returns (uint256 netRevenue);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Events - Declares events of the pool contract.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolEvents {
    /// @notice Emitted when a new pool is initialized.
    /// @dev Pool is initialized at new pool creation.
    /// @param group Address of the factory.
    /// @param owner Address of the owner.
    /// @param baseToken Address of the base token.
    /// @param name String name of the pool.
    /// @param symbol String symbol of the pool.
    event PoolInitialized(
        address indexed group,
        address indexed owner,
        address indexed baseToken,
        string name,
        bytes8 symbol
    );

    /// @notice Emitted when new owner is set.
    /// @param old Address of the previous owner.
    /// @param current Address of the new owner.
    event NewOwner(address indexed old, address indexed current);

    /// @notice Emitted when pool operator updates NAV.
    /// @param poolOperator Address of the pool owner.
    /// @param pool Address of the pool.
    /// @param unitaryValue Value of 1 token in wei units.
    event NewNav(address indexed poolOperator, address indexed pool, uint256 unitaryValue);

    /// @notice Emitted when pool operator sets new mint fee.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param transactionFee Number of the new fee in wei.
    event NewFee(address indexed pool, address indexed who, uint16 transactionFee);

    /// @notice Emitted when pool operator updates fee collector address.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param feeCollector Address of the new fee collector.
    event NewCollector(address indexed pool, address indexed who, address feeCollector);

    /// @notice Emitted when pool operator updates minimum holding period.
    /// @param pool Address of the pool.
    /// @param minimumPeriod Number of seconds.
    event MinimumPeriodChanged(address indexed pool, uint48 minimumPeriod);

    /// @notice Emitted when pool operator updates the mint/burn spread.
    /// @param pool Address of the pool.
    /// @param spread Number of the spread in basis points.
    event SpreadChanged(address indexed pool, uint16 spread);

    /// @notice Emitted when pool operator sets a kyc provider.
    /// @param pool Address of the pool.
    /// @param kycProvider Address of the kyc provider.
    event KycProviderSet(address indexed pool, address indexed kycProvider);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Fallback Interface - Interface of the fallback method.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolFallback {
    /// @notice Delegate calls to pool extension.
    /// @dev Delegatecall restricted to owner, staticcall accessible by everyone.
    /// @dev Restricting delegatecall to owner effectively locks direct calls.
    fallback() external payable;

    /// @notice Allows transfers to pool.
    /// @dev Prevents accidental transfer to implementation contract.
    receive() external payable;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Immutable - Interface of the pool storage.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolImmutable {
    /// @notice Returns a string of the pool version.
    /// @return String of the pool implementation version.
    function VERSION() external view returns (string memory);

    /// @notice Returns the address of the authority contract.
    /// @return Address of the authority contract.
    function authority() external view returns (address);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Initializer Interface - Allows initializing a pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3PoolInitializer {
    /// @notice Initializes to pool storage.
    /// @dev Pool can only be initialized at creation, meaning this method cannot be called directly to implementation.
    function initializePool() external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Owner Actions Interface - Interface of the owner methods.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolOwnerActions {
    /// @notice Allows owner to decide where to receive the fee.
    /// @param feeCollector Address of the fee receiver.
    function changeFeeCollector(address feeCollector) external;

    /// @notice Allows pool owner to change the minimum holding period.
    /// @param minPeriod Time in seconds.
    function changeMinPeriod(uint48 minPeriod) external;

    /// @notice Allows pool owner to change the mint/burn spread.
    /// @param newSpread Number between 0 and 1000, in basis points.
    function changeSpread(uint16 newSpread) external;

    /// @notice Allows pool owner to set/update the user whitelist contract.
    /// @dev Kyc provider can be set to null, removing user whitelist requirement.
    /// @param kycProvider Address if the kyc provider.
    function setKycProvider(address kycProvider) external;

    /// @notice Allows pool owner to set a new owner address.
    /// @dev Method restricted to owner.
    /// @param newOwner Address of the new owner.
    function setOwner(address newOwner) external;

    /// @notice Allows pool owner to set the transaction fee.
    /// @param transactionFee Value of the transaction fee in basis points.
    function setTransactionFee(uint16 transactionFee) external;

    /// @notice Allows pool owner to set the pool price.
    /// @param unitaryValue Value of 1 token in wei units.
    function setUnitaryValue(uint256 unitaryValue) external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool State - Returns the pool view methods.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolState {
    /// @notice Returned pool initialization parameters.
    /// @dev Symbol is stored as bytes8 but returned as string to facilitating client view.
    /// @param name String of the pool name (max 32 characters).
    /// @param symbol String of the pool symbol (from 3 to 5 characters).
    /// @param decimals Uint8 decimals.
    /// @param owner Address of the pool operator.
    /// @param baseToken Address of the base token of the pool (0 for base currency).
    struct ReturnedPool {
        string name;
        string symbol;
        uint8 decimals;
        address owner;
        address baseToken;
    }

    /// @notice Returns the struct containing pool initialization parameters.
    /// @dev Symbol is stored as bytes8 but returned as string in the returned struct, unlocked is omitted as alwasy true.
    /// @return ReturnedPool struct.
    function getPool() external view returns (ReturnedPool memory);

    /// @notice Pool variables.
    /// @param minPeriod Minimum holding period in seconds.
    /// @param spread Value of spread in basis points (from 0 to +-10%).
    /// @param transactionFee Value of transaction fee in basis points (from 0 to 1%).
    /// @param feeCollector Address of the fee receiver.
    /// @param kycProvider Address of the kyc provider.
    struct PoolParams {
        uint48 minPeriod;
        uint16 spread;
        uint16 transactionFee;
        address feeCollector;
        address kycProvider;
    }

    /// @notice Returns the struct compaining pool parameters.
    /// @return PoolParams struct.
    function getPoolParams() external view returns (PoolParams memory);

    /// @notice Pool tokens.
    /// @param unitaryValue A token's unitary value in base token.
    /// @param totalSupply Number of total issued pool tokens.
    struct PoolTokens {
        uint256 unitaryValue;
        uint256 totalSupply;
    }

    /// @notice Returns the struct containing pool tokens info.
    /// @return PoolTokens struct.
    function getPoolTokens() external view returns (PoolTokens memory);

    /// @notice Returns the aggregate pool generic storage.
    /// @return poolInitParams The pool's initialization parameters.
    /// @return poolVariables The pool's variables.
    /// @return poolTokensInfo The pool's tokens info.
    function getPoolStorage()
        external
        view
        returns (
            ReturnedPool memory poolInitParams,
            PoolParams memory poolVariables,
            PoolTokens memory poolTokensInfo
        );

    /// @notice Pool holder account.
    /// @param userBalance Number of tokens held by user.
    /// @param activation Time when tokens become active.
    struct UserAccount {
        uint208 userBalance;
        uint48 activation;
    }

    /// @notice Returns a pool holder's account struct.
    /// @return UserAccount struct.
    function getUserAccount(address _who) external view returns (UserAccount memory);

    /// @notice Returns a string of the pool name.
    /// @dev Name maximum length 31 bytes.
    /// @return String of the name.
    function name() external view returns (string memory);

    /// @notice Returns the address of the owner.
    /// @return Address of the owner.
    function owner() external view returns (address);

    /// @notice Returns a string of the pool symbol.
    /// @return String of the symbol.
    function symbol() external view returns (string memory);

    /// @notice Returns the total amount of issued tokens for this pool.
    /// @return Number of total issued tokens.
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.7.0 <0.9.0;

/// @title IStorageAccessible - generic base interface that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
interface IStorageAccessible {
    /// @notice Reads `length` bytes of storage in the currents contract.
    /// @param offset - the offset in the current contract's storage in words to start reading from.
    /// @param length - the number of words (32 bytes) of data to read.
    /// @return Bytes string of the bytes that were read.
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    /// @notice Reads bytes of storage at different storage locations.
    /// @dev Returns a string with values regarless of where they are stored, i.e. variable, mapping or struct.
    /// @param slots The array of storage slots to query into.
    /// @return Bytes string composite of different storage locations' value.
    function getStorageSlotsAt(uint256[] memory slots) external view returns (bytes memory);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IERC20.sol";
import "./interfaces/pool/IRigoblockV3PoolActions.sol";
import "./interfaces/pool/IRigoblockV3PoolEvents.sol";
import "./interfaces/pool/IRigoblockV3PoolFallback.sol";
import "./interfaces/pool/IRigoblockV3PoolImmutable.sol";
import "./interfaces/pool/IRigoblockV3PoolInitializer.sol";
import "./interfaces/pool/IRigoblockV3PoolOwnerActions.sol";
import "./interfaces/pool/IRigoblockV3PoolState.sol";
import "./interfaces/pool/IStorageAccessible.sol";

/// @title Rigoblock V3 Pool Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3Pool is
    IERC20,
    IRigoblockV3PoolImmutable,
    IRigoblockV3PoolEvents,
    IRigoblockV3PoolFallback,
    IRigoblockV3PoolInitializer,
    IRigoblockV3PoolActions,
    IRigoblockV3PoolOwnerActions,
    IRigoblockV3PoolState,
    IStorageAccessible
{

}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity 0.8.17;

import "./IRigoblockV3Pool.sol";
import "./core/immutable/MixinStorage.sol";
import "./core/state/MixinPoolState.sol";
import "./core/state/MixinStorageAccessible.sol";
import "./core/sys/MixinAbstract.sol";
import "./core/sys/MixinInitializer.sol";
import "./core/sys/MixinFallback.sol";

/// @title RigoblockV3Pool - A set of rules for Rigoblock pools.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract RigoblockV3Pool is
    IRigoblockV3Pool,
    MixinStorage,
    MixinFallback,
    MixinInitializer,
    MixinAbstract,
    MixinPoolState,
    MixinStorageAccessible
{
    /// @notice Owner is initialized to 0 to lock owner actions in this implementation.
    /// @notice Kyc provider set as will effectively lock direct mint/burn actions.
    constructor(address authority) MixinImmutables(authority) {
        // we lock implementation at deploy
        pool().owner = address(0);
        poolParams().kycProvider == address(1);
    }
}