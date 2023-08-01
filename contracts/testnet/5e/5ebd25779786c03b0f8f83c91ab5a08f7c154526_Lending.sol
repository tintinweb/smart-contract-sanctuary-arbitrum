// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IPyth} from "pyth/IPyth.sol";
import {PythErrors} from "pyth/PythErrors.sol";
import {PythStructs} from "pyth/PythStructs.sol";

import {iToken} from "./iToken.sol";
import {iTokenManager} from "./iTokenManager.sol";

contract Lending {
    uint256 public managerCount;
    mapping(uint256 => address) public tokenManagers;
    mapping(address => bool) public isTokenManager;

    IPyth pyth;

    error PriceNotAvailable();

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount, address token, uint256 price, uint256 expoedPrice, PythStructs.Price response);

    constructor(address pythContract) {
        pyth = IPyth(pythContract);
    }

    function createTokenManager(
        address _underlyingToken,
        bytes32 _priceId
    ) public returns (address) {
        ERC20 underlyingERC20 = ERC20(_underlyingToken);

        iTokenManager manager = new iTokenManager(underlyingERC20, _priceId);

        isTokenManager[address(manager)] = true;

        tokenManagers[managerCount] = address(manager);

        ++managerCount;

        return address(manager);
    }

    function deposit(address _tokenManager, uint256 _amount) public {
        require(isTokenManager[_tokenManager], "Not a valid token manager");

        iTokenManager manager = iTokenManager(_tokenManager);

        manager.deposit(msg.sender, _amount);
    }

    function withdraw(
        address _tokenManager,
        uint256 _amount,
        bytes[] calldata priceUpdateData
    ) public payable {
        require(isTokenManager[_tokenManager], "Not a valid token manager");

        iTokenManager manager = iTokenManager(_tokenManager);

        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        PythStructs.Price memory response = pyth.getPrice(
            manager.priceId()
        );

        // uint256 price = uint64(response.price) * 10 ** 18 - (4294967295 + 1 - uint32(response.expo));

        emit Withdraw(msg.sender, _amount, address(manager.underlying()), uint64(response.price) * (10 ** 10), 10 ** (18 - (4294967295 + 1 - uint32(response.expo))), response);

        manager.withdraw(msg.sender, _amount);
        // require(gethf() <= 90, "Health factor too high");
    }

    function gethf() public view returns (uint256) {
        uint256 collateral = 0;
        uint256 debt = 0;

        for (uint256 i = 0; i < managerCount; i++) {
            iTokenManager manager = iTokenManager(tokenManagers[i]);

            PythStructs.Price memory response = pyth.getPrice(
                manager.priceId()
            );

            (uint256 _collateral, uint256 _debt) = manager.userBalanceInUnderlying(msg.sender);

            uint256 price = uint64(response.price);

            uint256 factor = (10 ** (4294967295 + 1 - uint32(response.expo)));

            collateral += _collateral * price / factor;
            debt += _debt * price / factor;
        }

        return (debt * 100) / collateral; // returns the utilization ex: 1% utilised
    }

    function borrow(
        address _tokenManager,
        uint256 _amount,
        bytes[] calldata priceUpdateData
    ) public {
        require(isTokenManager[_tokenManager], "Not a valid token manager");

        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        iTokenManager manager = iTokenManager(_tokenManager);

        manager.borrow(msg.sender, _amount);
        require(gethf() <= 90, "Health factor too high"); // vulnerable to reentrancy ?
    }

    function repay(address _tokenManager, uint256 _amount) public {
        require(isTokenManager[_tokenManager], "Not a valid token manager");

        iTokenManager manager = iTokenManager(_tokenManager);

        manager.repay(msg.sender, _amount);
    }

    function liquidate(
        address _tokenManager,
        address _user,
        uint256 _amount,
        bytes[] calldata priceUpdateData
    ) public {
        require(isTokenManager[_tokenManager], "Not a valid token manager");

        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        require(gethf() >= 95, "User cannot be liquidated yet");

        iTokenManager manager = iTokenManager(_tokenManager);
        manager.liquidate(msg.sender, _user, _amount);
    }

    function getAllManagers() public view returns (address[] memory) {
        address[] memory managers = new address[](managerCount);

        for (uint256 i = 0; i < managerCount; i++) {
            managers[i] = tokenManagers[i];
        }

        return managers;
    }

    function getAllTokens() public view returns (address[] memory) {
        address[] memory tokens = new address[](managerCount);

        for (uint256 i = 0; i < managerCount; i++) {
            tokens[i] = address(iTokenManager(tokenManagers[i]).underlying());
        }

        return tokens;
    }

    function getPythPrice(
        address _tokenManager,
        bytes[] calldata _priceUpdateData
    ) public payable returns (uint256) {
        uint256 fee = pyth.getUpdateFee(_priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(_priceUpdateData);
        iTokenManager manager = iTokenManager(_tokenManager);
        int64 pythPrice = pyth.getPrice(manager.priceId()).price;
        if (pythPrice == 0) revert PriceNotAvailable();
        return uint256(uint64(pythPrice));
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract iToken is ERC20 {
    bool transferrable = false;

    address public manager;

    uint256 lastUpdated;

    constructor(
        address _manager,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, 18) {
        manager = _manager;
    }

    modifier noTransfer() {
        require(transferrable);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override noTransfer returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override noTransfer returns (bool) {}

    function mint(address to, uint256 amt) public onlyManager {
        _mint(to, amt);
    }

    function burn(address from, uint256 amt) public onlyManager {
        _burn(from, amt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {iToken} from "./iToken.sol";

contract iTokenManager {
    iToken public cToken;
    iToken public dToken;

    ERC20 public underlying;

    uint256 public emFactor = 5; // 5%
    uint256 public emFactorWhenMoreThan80 = 70; // 70%

    uint256 public spread = 20; // 20%

    uint256 public lastUpdated;

    uint256 public totalCAssets;
    uint256 public totalDAssets;

    address public pool;

    uint256 public ltv;
    uint256 public liqThreshold;

    bytes32 public priceId;

    constructor(ERC20 _underlying, bytes32 _priceId) {
        cToken = new iToken(
            address(this),
            string.concat("c", _underlying.name()),
            string.concat("c", _underlying.symbol())
        );
        dToken = new iToken(
            address(this),
            string.concat("d", _underlying.name()),
            string.concat("d", _underlying.symbol())
        );
        priceId = _priceId;
        pool = msg.sender;
        underlying = _underlying;
        lastUpdated = block.timestamp;
    }

    modifier onlyPool() {
        require(msg.sender == pool);
        _;
    }

    function utilization() public view returns (uint256) {
        uint256 cSupply = cToken.totalSupply();
        uint256 dSupply = dToken.totalSupply();

        if (cSupply == 0 || dSupply == 0) return 0;
        return ((dSupply * 1e18) / cSupply);
    }

    function borrowAPR() public view returns (uint256) {
        uint256 util = utilization();
        if (util != 0) {
            return
                util < 80
                    ? (util * emFactor) / 100
                    : (util * emFactorWhenMoreThan80) / 100;
        } else return 0;
    }

    function supplyAPR() public view returns (uint256) {
        return ((100 - spread) * borrowAPR()) / 100;
    }

    function updateTotalAssets() public {
        uint256 bAPR = borrowAPR();
        uint256 timeElapsed = block.timestamp - lastUpdated;

        if (bAPR != 0 && timeElapsed != 0) {
            totalDAssets +=
                (totalDAssets * bAPR * timeElapsed) /
                (100 * 365 * 24 * 3600 * 1e18);

            totalCAssets +=
                (totalCAssets * (100 - spread) * bAPR * timeElapsed) /
                (100 * 100 * 365 * 24 * 3600 * 1e18);
        }

        lastUpdated = block.timestamp;
    }

    function underlyingToInterestToken(
        uint256 amount,
        bool debt
    ) public view returns (uint256) {
        if (debt == true) {
            uint256 dSupply = dToken.totalSupply();
            if (dSupply == 0 || totalDAssets == 0) return amount;
            return (amount * dSupply) / totalDAssets;
        } else {
            uint256 cSupply = cToken.totalSupply();
            if (cSupply == 0 || totalCAssets == 0) return amount;
            return (amount * cSupply) / totalCAssets;
        }
    }

    function interestToUnderlyingToken(
        uint256 amount,
        bool debt
    ) public view returns (uint256) {
        if (debt == true) {
            uint256 dSupply = dToken.totalSupply();
            if (dSupply == 0 || totalDAssets == 0) return amount;
            return (amount * totalDAssets) / dToken.totalSupply();
        } else {
            uint256 cSupply = cToken.totalSupply();
            if (cSupply == 0 || totalCAssets == 0) return amount;
            return (amount * totalCAssets) / cToken.totalSupply();
        }
    }

    function deposit(address user, uint256 _amount) public onlyPool {
        underlying.transferFrom(user, address(this), _amount);
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, false);
        totalCAssets += _amount;
        cToken.mint(user, shares);
    }

    function withdraw(address user, uint256 _amount) public onlyPool {
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, false);
        totalCAssets -= _amount;
        cToken.burn(user, shares);
        underlying.transfer(user, _amount);
    }

    function borrow(address user, uint256 _amount) public onlyPool {
        require(
            _amount <= underlying.balanceOf(address(this)),
            "not enough liquidity to borrow"
        );
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, true);
        totalDAssets += _amount;
        dToken.mint(user, shares);
        underlying.transfer(user, _amount);
    }

    function repay(address user, uint256 _amount) public onlyPool {
        underlying.transferFrom(user, address(this), _amount);
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, true);
        totalDAssets -= _amount;
        dToken.burn(user, shares);
    }

    function userBalanceInUnderlying(
        address user
    ) public view returns (uint256, uint256) {
        uint256 cSupply = cToken.totalSupply();
        uint256 cBalance = cToken.balanceOf(user);

        uint256 collateral = cSupply == 0 || cBalance == 0
            ? 0
            : (cBalance * totalCAssets) / cSupply;

        uint256 dSupply = dToken.totalSupply();
        uint256 dBalance = dToken.balanceOf(user);

        uint256 debt = dSupply == 0 || dBalance == 0
            ? 0
            : (dBalance * totalDAssets) / dSupply;
        return (collateral, debt);
    }

    function liquidate(
        address liquidator,
        address user,
        uint256 _amount
    ) public onlyPool {
        underlying.transferFrom(liquidator, address(this), _amount);
        updateTotalAssets();
        uint256 dShares = underlyingToInterestToken(_amount, true);
        totalDAssets -= _amount;
        dToken.burn(user, dShares);
        uint256 cShares = underlyingToInterestToken(_amount, false);
        totalCAssets -= _amount;
        cToken.burn(user, cShares);
        underlying.transfer(user, ((_amount * 100) / 95));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}