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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IStakingBank.sol";


interface IStakingBankStatic is IStakingBank {
    /// @param _validators array of validators addresses to verify
    /// @return TRUE when all validators are valid, FALSE otherwise
    function verifyValidators(address[] calldata _validators) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUmbrellaFeeds {
    struct PriceData {
        /// @dev this is placeholder, that can be used for some additional data
        /// atm of creating this smart contract, it is only used as marker for removed data (when == type(uint8).max)
        uint8 data;
        /// @dev heartbeat: how often price data will be refreshed in case price stay flat
        uint24 heartbeat;
        /// @dev timestamp: price time, at this time validators run consensus
        uint32 timestamp;
        /// @dev price
        uint128 price;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev method for submitting consensus data
    /// @param _priceKeys array of keys for `_priceDatas`
    /// @param _priceDatas PriceData signed by validators
    /// @param _signatures validators signatures
    function update(
        bytes32[] calldata _priceKeys,
        PriceData[] calldata _priceDatas,
        Signature[] calldata _signatures
    ) external;

    /// @dev method for resetting data
    /// @param _priceKeys array of keys for `_priceDatas`
    /// @param _signatures validators signatures
    function reset(bytes32[] calldata _priceKeys, Signature[] calldata _signatures) external;

    /// @dev it will return array of price datas for provided `_keys`
    /// In case ony of feed does not exist, fallback call will be executed for that feed.
    /// @notice If data for any key not exists, function will revert. Use `getManyPriceDataRaw` method if you don't
    /// want revert.
    /// @param _keys array of feed keys
    /// @return data PriceData array
    function getManyPriceData(bytes32[] calldata _keys) external view returns (PriceData[] memory data);

    /// @dev same as getManyPriceData() but does not revert on empty data.
    /// @notice This method does no revert if some data does not exists.
    /// Check `data.timestamp` to see if price exist, if it is 0, then it does not exist.
    function getManyPriceDataRaw(bytes32[] calldata _keys) external view returns (PriceData[] memory data);

    /// @dev this is main endpoint for reading feeds.
    /// In case timestamp is empty (that means there is no data), contract will execute fallback call.
    /// Check main contract description for fallback details.
    /// If you do not need whole data from `PriceData` struct, you can save some gas by using other view methods that
    /// returns just what you need.
    /// @notice method will revert if data for `_key` not exists.
    /// @param _key hash of feed name
    /// @return data full PriceData struct
    function getPriceData(bytes32 _key) external view returns (PriceData memory data);

    /// @notice same as `getPriceData` but does not revert when no data
    /// @param _key hash of feed name
    /// @return data full PriceData struct
    function getPriceDataRaw(bytes32 _key) external view returns (PriceData memory data);

    /// @notice reader for mapping
    /// @param _key hash of feed name
    /// @return data full PriceData struct
    function prices(bytes32 _key) external view returns (PriceData memory data);

    /// @notice method will revert if data for `_key` not exists.
    /// @param _key hash of feed name
    /// @return price
    function getPrice(bytes32 _key) external view returns (uint128 price);

    /// @notice method will revert if data for `_key` not exists.
    /// @param _key hash of feed name
    /// @return price
    /// @return timestamp
    function getPriceTimestamp(bytes32 _key) external view returns (uint128 price, uint32 timestamp);

    /// @notice method will revert if data for `_key` not exists.
    /// @param _key hash of feed name
    /// @return price
    /// @return timestamp
    /// @return heartbeat
    function getPriceTimestampHeartbeat(bytes32 _key)
        external
        view
        returns (uint128 price, uint32 timestamp, uint24 heartbeat);

    /// @dev This method should be used only for Layer2 as it is more gas consuming than others views.
    /// @notice It does not revert on empty data.
    /// @param _name string feed name
    /// @return data PriceData
    function getPriceDataByName(string calldata _name) external view returns (PriceData memory data);

    /// @dev decimals for prices stored in this contract
    function DECIMALS() external view returns (uint8); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IUmbrellaFeeds.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IStakingBankStatic.sol";

/// @notice Main contract for all on-chain data.
/// This contract has build in fallback feature in case, it will be replaced by newer contract.
/// Fallback is transparent for the user, no additional setup is needed.
///
/// How fallback feature works? If data for provided key is empty, contract will execute following procedure:
/// 1. When new contract is deployed, data from ols one are erased
/// 2. if data is empty, contract will check if there is new contract with requested data
/// 3. if data is found in new contract it will be returned
/// 4. if there is no data or there is no new contract tx will revert.
///
/// After new deployment, it is recommended to update address to avoid fallback and reduce gas cost to minimum.
/// In long run this is most efficient solution, better than any proxy.
contract UmbrellaFeeds is IUmbrellaFeeds {
    bytes constant public ETH_PREFIX = "\x19Ethereum Signed Message:\n32";
    string constant public NAME = "UmbrellaFeeds";

    /// @dev marker that will tell us, that price data was reset
    uint8 constant public DATA_RESET = type(uint8).max;

    /// @dev Registry contract where list of all addresses is stored. Fallback feature uses this registry to
    /// resolve newest `UmbrellaFeeds` address
    IRegistry public immutable REGISTRY;  // solhint-disable-line var-name-mixedcase

    /// @dev StakingBank contract where list of validators is stored
    IStakingBankStatic public immutable STAKING_BANK;  // solhint-disable-line var-name-mixedcase

    /// @dev minimal number of signatures required for accepting price submission (PoA)
    uint16 public immutable REQUIRED_SIGNATURES; // solhint-disable-line var-name-mixedcase

    /// @dev decimals for prices stored in this contract
    uint8 public immutable DECIMALS;  // solhint-disable-line var-name-mixedcase

    /// @notice map of all prices stored in this contract, key for map is hash of feed name
    /// eg for "ETH-USD" feed, key will be hash("ETH-USD")
    mapping (bytes32 => PriceData) private _prices;

    error ArraysDataDoNotMatch();
    error FeedNotExist();
    error NotEnoughSignatures();
    error InvalidSigner();
    error InvalidRequiredSignatures();
    error SignaturesOutOfOrder();
    error OldData();
    error DataReset();

    /// @param _contractRegistry Registry address
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    /// @param _decimals decimals for prices stored in this contract
    constructor(
        IRegistry _contractRegistry,
        uint16 _requiredSignatures,
        uint8 _decimals
    ) {
        if (_requiredSignatures == 0) revert InvalidRequiredSignatures();

        REGISTRY = _contractRegistry;
        REQUIRED_SIGNATURES = _requiredSignatures;
        STAKING_BANK = IStakingBankStatic(_contractRegistry.requireAndGetAddress("StakingBank"));
        DECIMALS = _decimals;
    }

    /// @inheritdoc IUmbrellaFeeds
    function update(
        bytes32[] calldata _priceKeys,
        PriceData[] calldata _priceDatas,
        Signature[] calldata _signatures
    ) external {
        // below check is only for pretty errors, so we can safe gas and allow for raw revert
        // if (_priceKeys.length != _priceDatas.length) revert ArraysDataDoNotMatch();

        bytes32 priceDataHash = keccak256(abi.encode(getChainId(), address(this), _priceKeys, _priceDatas));
        verifySignatures(priceDataHash, _signatures);

        uint256 i;

        while (i < _priceDatas.length) {
            // we do not allow for older prices
            // at the same time it prevents from reusing signatures
            if (_prices[_priceKeys[i]].timestamp >= _priceDatas[i].timestamp) revert OldData();
            if (_prices[_priceKeys[i]].data == DATA_RESET) revert DataReset();

            _prices[_priceKeys[i]] = _priceDatas[i];

            // atm there is no need for events, so in order to save gas, we do not emit any
            unchecked { i++; }
        }
    }

    /// @inheritdoc IUmbrellaFeeds
    function reset(bytes32[] calldata _priceKeys, Signature[] calldata _signatures) external {
        bytes32 resetHash = keccak256(abi.encodePacked(getChainId(), address(this), _priceKeys, "RESET"));
        verifySignatures(resetHash, _signatures);

        for (uint256 i; i < _priceKeys.length;) {
            _prices[_priceKeys[i]] = PriceData(DATA_RESET, 0, 0, 0);
            // atm there is no need for events, so in order to save gas, we do not emit any
            unchecked { i++; }
        }
    }

    /// @inheritdoc IUmbrellaFeeds
    function getManyPriceData(bytes32[] calldata _keys) external view returns (PriceData[] memory data) {
        data = new PriceData[](_keys.length);

        for (uint256 i; i < _keys.length;) {
            data[i] = _prices[_keys[i]];

            if (data[i].timestamp == 0) {
                data[i] = _fallbackCall(_keys[i]);
            }

            unchecked { i++; }
        }
    }

    /// @inheritdoc IUmbrellaFeeds
    function getManyPriceDataRaw(bytes32[] calldata _keys) external view returns (PriceData[] memory data) {
        data = new PriceData[](_keys.length);

        for (uint256 i; i < _keys.length;) {
            data[i] = _prices[_keys[i]];

            if (data[i].timestamp == 0) {
                data[i] = _fallbackCallRaw(_keys[i]);
            }

            unchecked { i++; }
        }
    }

    /// @inheritdoc IUmbrellaFeeds
    function prices(bytes32 _key) external view returns (PriceData memory data) {
        return _prices[_key];
    }

    /// @inheritdoc IUmbrellaFeeds
    function getPriceData(bytes32 _key) external view returns (PriceData memory data) {
        data = _prices[_key];

        if (data.timestamp == 0) {
            data = _fallbackCall(_key);
        }
    }

    /// @inheritdoc IUmbrellaFeeds
    function getPriceDataRaw(bytes32 _key) external view returns (PriceData memory data) {
        data = _prices[_key];

        if (data.timestamp == 0) {
            data = _fallbackCallRaw(_key);
        }
    }

    /// @inheritdoc IUmbrellaFeeds
    function getPrice(bytes32 _key) external view returns (uint128 price) {
        PriceData memory data = _prices[_key];

        if (data.timestamp == 0) {
            data = _fallbackCall(_key);
        }

        return data.price;
    }

    function getPriceTimestamp(bytes32 _key) external view returns (uint128 price, uint32 timestamp) {
        PriceData memory data = _prices[_key];

        if (data.timestamp == 0) {
            data = _fallbackCall(_key);
        }

        return (data.price, data.timestamp);
    }

    function getPriceTimestampHeartbeat(bytes32 _key)
        external
        view
        returns (uint128 price, uint32 timestamp, uint24 heartbeat)
    {
        PriceData memory data = _prices[_key];

        if (data.timestamp == 0) {
            data = _fallbackCall(_key);
        }

        return (data.price, data.timestamp, data.heartbeat);
    }

    /// @dev this is helper method for UI
    function priceData(string memory _key) external view returns (PriceData memory) {
        return _prices[keccak256(abi.encodePacked(_key))];
    }

    /// @inheritdoc IUmbrellaFeeds
    function getPriceDataByName(string calldata _name) external view returns (PriceData memory data) {
        bytes32 key = keccak256(abi.encodePacked(_name));
        data = _prices[key];

        if (data.timestamp == 0) {
            data = _fallbackCallRaw(key);
        }
    }

    /// @dev helper method for QA purposes
    /// @return hash of data that are signed by validators (keys and priced data)
    function hashData(bytes32[] calldata _priceKeys, PriceData[] calldata _priceDatas)
        external
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(getChainId(), address(this), _priceKeys, _priceDatas));
    }

    /// @param _hash hash of signed data
    /// @param _signatures array of validators signatures
    function verifySignatures(bytes32 _hash, Signature[] calldata _signatures) public view {
        address prevSigner = address(0x0);

        if (_signatures.length < REQUIRED_SIGNATURES) revert NotEnoughSignatures();

        address[] memory validators = new address[](REQUIRED_SIGNATURES);

        // to save gas we check only required number of signatures
        // case, where you can have part of signatures invalid but still enough valid in total is not supported
        for (uint256 i; i < REQUIRED_SIGNATURES;) {
            address signer = recoverSigner(_hash, _signatures[i].v, _signatures[i].r, _signatures[i].s);
            if (prevSigner >= signer) revert SignaturesOutOfOrder();

            // because we check only required number of signatures, any invalid one will cause revert
            prevSigner = signer;
            validators[i] = signer;

            unchecked { i++; }
        }

        // bulk verification can optimise gas when we have 5 or more validators
        if (!STAKING_BANK.verifyValidators(validators)) revert InvalidSigner();
    }

    function getChainId() public view returns (uint256 id) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
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

    /// @dev to follow Registrable interface
    function getName() public pure returns (bytes32) {
        return "UmbrellaFeeds";
    }

    function _fallbackCall(bytes32 _key) internal view returns (PriceData memory data) {
        address umbrellaFeeds = REGISTRY.getAddressByString(NAME);

        // if contract was NOT updated, fallback is not needed, data does not exist - revert
        if (umbrellaFeeds == address(this)) revert FeedNotExist();

        data = IUmbrellaFeeds(umbrellaFeeds).prices(_key);
        // if contract WAS updated but there is no data - revert
        if (data.timestamp == 0) revert FeedNotExist();
    }

    function _fallbackCallRaw(bytes32 _key) internal view returns (PriceData memory data) {
        address umbrellaFeeds = REGISTRY.getAddress(getName());

        // if contract was updated, we do a fallback call
        if (umbrellaFeeds != address(this) && umbrellaFeeds != address(0)) {
            data = IUmbrellaFeeds(umbrellaFeeds).prices(_key);
        }

        // else - we return empty data
    }
}