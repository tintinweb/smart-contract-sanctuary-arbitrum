/**
 *Submitted for verification at Arbiscan.io on 2023-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * this solidity file is provided as-is; no guarantee, representation or warranty is being made, express or implied,
 * as to the safety or correctness of the code or any smart contracts or other software deployed from these files.
 **/

/// @notice read oracle-fed data via a view function on a proxy contract that handles oracle updates (if necessary/applicable) or interfacing
/// see: https://dapi-docs.api3.org/reference/dapis/understand/read-dapis.html
interface IProxy {
    function read() external view returns (int224 value, uint256 timestamp);
}

/**
 * @title      o=o=o=o=o Receipt o=o=o=o=o
 **/
/**
 * @author     o=o=o=o=o ChainLocker LLC o=o=o=o=o
 **/
/// @notice calculate USD price and total value of certain supported tokens via oracle data feed, providing an immutable 'receipt' of a transaction's value in USD;
/// @dev users may check their receipt amount at any time by submitting the 'paymentId' corresponding to their transaction to the public getter for the 'paymentIdToUsdValue' mapping
/// 'admin' is able to update proxy addresses, in order to add new token prices, replace broken or obsolete proxies, etc., but neither this contract nor its 'admin' can access any user assets
contract Receipt {
    // 60 seconds * 60 minutes * 24 hours
    uint256 internal constant ONE_DAY = 86400;

    address public admin;
    address private _pendingAdmin;
    // since 'paymentId' acts as an index/counter that is returned and emitted with each call of 'printReceipt()', no need for public visibility
    uint256 internal paymentId;

    /// @dev map token contract address to the contract address of the data feed proxy that returns the token's price
    mapping(address => address) public tokenToProxy;

    /// @notice allows a user to view their receipt (value in USD) based on their transaction's 'paymentId'
    /// @dev this mapping's public getter maps each 'paymentId' to its total USD value for external view; no need for separate function
    mapping(uint256 => uint256) public paymentIdToUsdValue;

    ///
    /// ERRORS
    ///

    error Receipt_ImproperAmount();
    error Receipt_OnlyAdmin();
    error Receipt_StalePrice();
    error Receipt_TokenNotSupported();

    ///
    /// EVENTS
    ///

    event Receipt_AdminUpdated(address newAdmin);
    event Receipt_ProxyUpdated(address token, address proxy);
    event Receipt_ReceiptPrinted(
        uint256 indexed paymentId,
        uint256 usdPrice,
        address token
    );

    ///
    /// FUNCTIONS
    ///

    constructor() payable {
        admin = msg.sender;
    }

    /// @notice stamp the receipt with the USD value of the supported '_token';
    /// returns the total USD value and a 'paymentId' which can be used to view the total USD value via public getter for the 'paymentIdToUsdValue' mapping
    /// @dev 'receipt' is stamped in the calling contract or address, but a caller may also save their transaction hash or 'paymentId' to access USD value
    /// @param _token: contract address of token with dAPI/data feed proxy
    /// @param _tokenAmount: amount of '_token'
    /// @param _decimals: decimals of '_token' for USD value calculation (18 for wei)
    function printReceipt(
        address _token,
        uint256 _tokenAmount,
        uint256 _decimals
    ) external returns (uint256, uint256) {
        if (_tokenAmount == 0) revert Receipt_ImproperAmount();
        if (tokenToProxy[_token] == address(0))
            revert Receipt_TokenNotSupported();

        // will not overflow on human timelines
        unchecked {
            ++paymentId;
        }

        /** @dev read value from data feed and get timestamp of its latest update;
         *** this function ensures '_value' is not negative,
         *** as this contract is only designed for token price/value receipts for payments (as opposed to valueConditions in ChainLockers) */
        (int224 _value, uint256 _timestamp) = IProxy(tokenToProxy[_token])
            .read();

        // revert if '_timestamp' is older than 'ONE_DAY' or greater than block.timestamp
        // this will also revert if _timestamp returns 0, suggesting the applicable proxy is not funded or otherwise inoperable, or if the value returned is negative
        if (
            _timestamp > block.timestamp ||
            _timestamp + ONE_DAY < block.timestamp ||
            _value < int224(0)
        ) revert Receipt_StalePrice();

        // USD value is equal to the USD price of one token * the amount of tokens, divided by 10^decimals
        uint256 _usdValue = (uint224(_value) * _tokenAmount) /
            (10 ** _decimals);

        paymentIdToUsdValue[paymentId] = _usdValue;

        emit Receipt_ReceiptPrinted(paymentId, _usdValue, _token);
        return (paymentId, _usdValue);
    }

    /// @notice add, update, or remove a token's dAPI/data feed proxy
    /// @dev enables admin to update a token's proxy address or remove it by passing 'address(0)'; see: https://market.api3.org/dapis for self-funding new proxies
    /// @param _token: contract address of token (or address(0) for native gas token) with dAPI/data feed proxy
    /// @param _proxy: contract address of the dAPI/data feed proxy for '_token' if supported; if not supported/no proxy, pass address(0)
    function updateProxy(address _token, address _proxy) external {
        if (msg.sender != admin) revert Receipt_OnlyAdmin();
        tokenToProxy[_token] = _proxy;

        emit Receipt_ProxyUpdated(_token, _proxy);
    }

    /// @notice for the current 'admin' to update their address. First step in two-step address change.
    /// @dev 'admin' can pass address(0) to fully relinquish control, though it is likely preferable to retain an admin to add new tokens and proxies or update broken proxies
    /// @param _newAdmin: new address for pending 'admin', who must accept the role by calling 'acceptAdminRole'
    function updateAdmin(address _newAdmin) external {
        if (msg.sender != admin) revert Receipt_OnlyAdmin();
        _pendingAdmin = _newAdmin;
    }

    /// @notice for the '_pendingAdmin' to accept the role transfer and become 'admin'.
    /// @dev access restricted to the address stored as '_pendingAdmin' to accept the two-step change. Transfers 'admin' role to the caller and deletes '_pendingAdmin' to reset the variable.
    function acceptAdminRole() external {
        // only '_pendingAdmin' can accept the role
        if (msg.sender != _pendingAdmin) revert Receipt_OnlyAdmin();
        delete _pendingAdmin;
        admin = msg.sender;
        emit Receipt_AdminUpdated(msg.sender);
    }
}