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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IRegistry.sol";
import "../interfaces/IStakingBank.sol";

/// @dev Main contract for all deviation triggered fees.
/// This contract has build in fallback feature in case it will be replaced by newer version.
/// Fallback is transparent for the user, no additional setup is needed.
///
/// How fallback feature works? If data for provided key is empty, contract will execute following procedure:
/// 1. triggered feeds, that needs to be updated will be updated in new contract and erased from this one
/// 2. if data is empty, check, if new deployment of UmbrellaFeeds is done, if not stop.
/// 3. forward the call to that new contract.
///
/// After new deployment done it is recommended to update address to avoid fallback and reduce gas cost.
/// In long run this is most efficient solution, better than any proxy.
contract UmbrellaFeeds {
    bytes constant public ETH_PREFIX = "\x19Ethereum Signed Message:\n32";
    string constant public NAME = "UmbrellaFeeds";

    IStakingBank public immutable STAKING_BANK;  // solhint-disable-line var-name-mixedcase
    IRegistry public immutable REGISTRY;  // solhint-disable-line var-name-mixedcase

    /// @dev minimal number of signatures required for accepting submission (PoA)
    uint16 public immutable REQUIRED_SIGNATURES; // solhint-disable-line var-name-mixedcase

    uint8 public immutable DECIMALS;  // solhint-disable-line var-name-mixedcase

    struct PriceData {
        uint8 data;
        uint24 heartbeat;
        uint32 timestamp;
        uint128 price;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping (bytes32 => PriceData) public prices;

    error ArraysDataDoNotMatch();
    error FeedNotExist();
    error FallbackFeedNotExist();
    error NotEnoughSignatures();
    error InvalidRequiredSignatures();
    error SignaturesOutOfOrder();
    error OldData();

    /// @param _contractRegistry Registry address
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    constructor(
        IRegistry _contractRegistry,
        uint16 _requiredSignatures,
        uint8 _decimals
    ) {
        if (_requiredSignatures == 0) revert InvalidRequiredSignatures();

        REGISTRY = _contractRegistry;
        REQUIRED_SIGNATURES = _requiredSignatures;
        STAKING_BANK = IStakingBank(_contractRegistry.requireAndGetAddress("StakingBank"));
        DECIMALS = _decimals;
    }

    /// @dev method for submitting consensus data
    /// @param _priceKeys array of keys for `_priceDatas`
    /// @param _priceDatas PriceData signed by validators
    /// @param _signatures validators signatures
    // solhint-disable-next-line function-max-lines, code-complexity
    function update(
        bytes32[] calldata _priceKeys,
        PriceData[] calldata _priceDatas,
        Signature[] calldata _signatures
    ) external {
        // below two checks are only for pretty errors, so we can safe gas and allow for raw revert
        // if (_priceKeys.length != _priceDatas.length) revert ArraysDataDoNotMatch();

        bytes32 priceDataHash = keccak256(abi.encode(_priceKeys, _priceDatas));
        verifySignatures(priceDataHash, _signatures);

        uint256 i;

        while (i < _priceDatas.length) {
            // we do not allow for older prices
            // at the same time it prevents from reusing signatures
            if (prices[_priceKeys[i]].timestamp >= _priceDatas[i].timestamp) revert OldData();

            prices[_priceKeys[i]] = _priceDatas[i];

            // atm there is no need for events, so in order to save gas, we do not emit any
            unchecked { i++; }
        }
    }

    /// @dev method for resetting data
    /// @param _priceKeys array of keys for `_priceDatas`
    /// @param _signatures validators signatures
    // solhint-disable-next-line function-max-lines, code-complexity
    function reset(bytes32[] calldata _priceKeys, Signature[] calldata _signatures) external {
        bytes32 resetHash = keccak256(abi.encodePacked(_priceKeys, "RESET"));
        verifySignatures(resetHash, _signatures);

        for (uint256 i; i < _priceKeys.length;) {
            delete prices[_priceKeys[i]];
            // atm there is no need for events, so in order to save gas, we do not emit any
            unchecked { i++; }
        }
    }

    /// @dev method for submitting consensus data
    /// @param _hash hash of signed data
    /// @param _signatures array of validators signatures
    // solhint-disable-next-line function-max-lines, code-complexity
    function verifySignatures(bytes32 _hash, Signature[] calldata _signatures) public view {
        address prevSigner = address(0x0);

        if (_signatures.length < REQUIRED_SIGNATURES) revert NotEnoughSignatures();

        // to save gas we check only required number of signatures
        // case, where you can have part of signatures invalid but still enough valid in total is not supported
        for (uint256 i; i < REQUIRED_SIGNATURES;) {
            address signer = recoverSigner(_hash, _signatures[i].v, _signatures[i].r, _signatures[i].s);
            if (prevSigner >= signer) revert SignaturesOutOfOrder();

            // because we check only required number of signatures, any invalid one will cause revert
            if (STAKING_BANK.balanceOf(signer) == 0) revert NotEnoughSignatures();

            prevSigner = signer;

            unchecked { i++; }
        }
    }

    /// @param _hash hashed of data
    /// @param _v part of signature
    /// @param _r part of signature
    /// @param _s part of signature
    /// @return signer address
    function recoverSigner(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(ETH_PREFIX, _hash));
        return ecrecover(hash, _v, _r, _s);
    }

    /// @dev helper method for QA purposes
    /// @return hash of data that are signed by validators (keys and priced data)
    function hashSubmitData(bytes32[] calldata _priceKeys, PriceData[] calldata _priceDatas)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_priceKeys, _priceDatas));
    }

    /// @dev it will return array of price datas for provided `_keys`
    /// In case ony of feeds timestamp is empty, fallback call will be executed for that feed.
    /// If any of feeds fallback calls fail, function will revert.
    /// @param _keys array of feed keys
    /// @return data PriceData array
    function getPricesData(bytes32[] calldata _keys) external view returns (PriceData[] memory data) {
        data = new PriceData[](_keys.length);

        for (uint256 i; i < _keys.length;) {
            data[i] = prices[_keys[i]];

            if (data[i].timestamp == 0) {
                data[i] = _fallbackCall(_keys[i]);
            }
        }
    }

    /// @dev same as getPricesData() but does not revert on empty data.
    function getPricesDataRaw(bytes32[] calldata _keys) external view returns (PriceData[] memory data) {
        data = new PriceData[](_keys.length);

        for (uint256 i; i < _keys.length;) {
            data[i] = prices[_keys[i]];

            if (data[i].timestamp == 0) {
                data[i] = _fallbackCallRaw(_keys[i]);
            }
        }
    }

    /// @dev this is main endpoint for reading feeds.
    /// In case timestamp is empty (that means there is no data), contract will execute fallback call.
    /// Check contract description for fallback details.
    function getPriceData(bytes32 _key) external view returns (PriceData memory data) {
        data = prices[_key];

        if (data.timestamp == 0) {
            data = _fallbackCall(_key);
        }
    }

    /// @dev same as `getPriceData` but does not revert when no data
    function getPriceDataRaw(bytes32 _key) external view returns (PriceData memory data) {
        data = prices[_key];

        if (data.timestamp == 0) {
            data = _fallbackCallRaw(_key);
        }
    }

    /// @dev to follow Registrable interface
    function getName() external pure returns (bytes32) {
        return "UmbrellaFeeds";
    }

    /// @dev to follow Registrable interface
    function register() external pure {
        // there are no requirements atm
    }

    /// @dev to follow Registrable interface
    function unregister() external pure {
        // there are no requirements atm
    }

    function _fallbackCall(bytes32 _key) internal view returns (PriceData memory) {
        address umbrellaFeeds = REGISTRY.getAddressByString(NAME);

        // if contract was NOT updated - revert
        if (umbrellaFeeds == address(this)) revert FeedNotExist();

        return UmbrellaFeeds(umbrellaFeeds).getPriceDataRaw(_key);
    }

    function _fallbackCallRaw(bytes32 _key) internal view returns (PriceData memory data) {
        address umbrellaFeeds = REGISTRY.getAddressByString(NAME);

        // if contract was updated, we do a fallback call
        if (umbrellaFeeds != address(this)) {
            return UmbrellaFeeds(umbrellaFeeds).getPriceDataRaw(_key);
        }

        // else - we return empty data
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IRegistry {
    event LogRegistered(address indexed destination, bytes32 name);

    /// @dev imports new contract addresses and override old addresses, if they exist under provided name
    /// This method can be used for contracts that for some reason do not have `getName` method
    /// @param  _names array of contract names that we want to register
    /// @param  _destinations array of contract addresses
    function importAddresses(bytes32[] calldata _names, address[] calldata _destinations) external;

    /// @dev imports new contracts and override old addresses, if they exist.
    /// Names of contracts are fetched directly from each contract by calling `getName`
    /// @param  _destinations array of contract addresses
    function importContracts(address[] calldata _destinations) external;

    /// @dev this method ensure, that old and new contract is aware of it state in registry
    /// Note: BSC registry does not have this method. This method was introduced in later stage.
    /// @param _newContract address of contract that will replace old one
    function atomicUpdate(address _newContract) external;

    /// @dev similar to `getAddress` but throws when contract name not exists
    /// @param name contract name
    /// @return contract address registered under provided name or throws, if does not exists
    function requireAndGetAddress(bytes32 name) external view returns (address);

    /// @param name contract name in a form of bytes32
    /// @return contract address registered under provided name
    function getAddress(bytes32 name) external view returns (address);

    /// @param _name contract name
    /// @return contract address assigned to the name or address(0) if not exists
    function getAddressByString(string memory _name) external view returns (address);

    /// @dev helper method that converts string to bytes32,
    /// you can use to to generate contract name
    function stringToBytes32(string memory _string) external pure returns (bytes32 result);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingBank is IERC20 {
    /// @param id address of validator wallet
    /// @param location URL of the validator API
    struct Validator {
        address id;
        string location;
    }

    event LogValidatorRegistered(address indexed id);
    event LogValidatorUpdated(address indexed id);
    event LogValidatorRemoved(address indexed id);
    event LogMinAmountForStake(uint256 minAmountForStake);

    /// @dev setter for `minAmountForStake`
    function setMinAmountForStake(uint256 _minAmountForStake) external;

    /// @dev allows to stake `token` by validators
    /// Validator needs to approve StakingBank beforehand
    /// @param _value amount of tokens to stake
    function stake(uint256 _value) external;

    /// @dev notification about approval from `_from` address on UMB token
    /// Staking bank will stake max approved amount from `_from` address
    /// @param _from address which approved token spend for IStakingBank
    function receiveApproval(address _from) external returns (bool success);

    /// @dev withdraws stake tokens
    /// it throws, when balance will be less than required minimum for stake
    /// to withdraw all use `exit`
    function withdraw(uint256 _value) external returns (bool success);

    /// @dev unstake and withdraw all tokens
    function exit() external returns (bool success);

    /// @dev creates (register) new validator
    /// @param _id validator address
    /// @param _location location URL of the validator API
    function create(address _id, string calldata _location) external;

    /// @dev removes validator
    /// @param _id validator wallet
    function remove(address _id) external;

    /// @dev updates validator location
    /// @param _id validator wallet
    /// @param _location new validator URL
    function update(address _id, string calldata _location) external;

    /// @return total number of registered validators (with and without balance)
    function getNumberOfValidators() external view returns (uint256);

    /// @dev gets validator address for provided index
    /// @param _ix index in array of list of all validators wallets
    function addresses(uint256 _ix) external view returns (address);

    /// @param _id address of validator
    /// @return id address of validator
    /// @return location URL of validator
    function validators(address _id) external view returns (address id, string memory location);
}