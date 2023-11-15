// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusDAOReserves} from "./interfaces/ICygnusDAOReserves.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";
import {IHangar18} from "./interfaces/core/IHangar18.sol";

// Interfaces
import {ICygnusTerminal} from "./interfaces/core/ICygnusTerminal.sol";

/**
 *  @notice This contract receives all reserves and fees (if applicable) from Core contracts.
 *
 *          From the borrowable, this contract receives the reserve rate from borrows in the form of CygUSD. Note
 *          that the reserves are actually kept in CygUSD. The reserve rate is manually updatable at core contracts
 *          by admin, it is by default set to 10% with the option to set between 0% to 20%.
 *
 *          From the collateral, this contract receives liquidation fees in the form of CygLP. The liquidation fee
 *          is also an updatable parameter by admins, and can be set anywhere between 0% and 10%. It is by default
 *          set to 1%. This means that when CygLP is seized from the borrower, an extra 1% of CygLP is taken also.
 *
 *  @title  CygnusDAOReserves
 *  @author CygnusDAO
 *
 *                                              3.A. Harvest LP rewards
 *                   +------------------------------------------------------------------------------+
 *                   |                                                                              |
 *                   |                                                                              ▼
 *            +------------+                         +----------------------+            +--------------------+
 *            |            |  3.B. Mint USD reserves |                      |            |                    |
 *            |    CORE    |>----------------------► |     DAO RESERVES     |>---------► |      X1 VAULT      |
 *            |            |                         |   (this contract)    |            |                    |
 *            +------------+                         +----------------------+            +--------------------+
 *               ▲      |                                                                      ▲         |
 *               |      |    2. Track borrow/lend    +----------------------+                  |         |
 *               |      +--------------------------► |     CYG REWARDER     |                  |         |  6. Claim LP rewards + USDC
 *               |                                   +----------------------+                  |         |
 *               |                                            ▲    |                           |         |
 *               |                                            |    | 4. Claim CYG              |         |
 *               |                                            |    |                           |         |
 *               |                                            |    ▼                           |         |
 *               |                                   +------------------------+                |         |
 *               |    1. Deposit USDC / Liquidity    |                        |  5. Stake CYG  |         |
 *               +-----------------------------------|    LENDERS/BORROWERS   |>---------------+         |
 *                                                   |         ʕ•ᴥ•ʔ          |                          |
 *                                                   +------------------------+                          |
 *                                                              ▲                                        |
 *                                                              |                                        |
 *                                                              +----------------------------------------+
 *                                                                        LP Rewards + USDC
 *
 *       Important: Main functionality of this contract is to split the reserves received to two main addresses:
 *                  `daoReserves` and `cygnusX1Vault`
 *
 *                  This contract receives only CygUSD and CygLP (vault tokens of the Core contracts). The amount of
 *                  assets received by the X1 Vault depends on the `x1VaultWeight` variable. Basically this contract
 *                  redeems an amount of CygUSD shares for USDC and sends it to the vault so users can claim USD from
 *                  reserves. The DAO receives the leftover shares which are NOT to be redeemed. These shares sit in
 *                  the DAO reserves accruing interest (in the case of CygUSD) or earning from trading fees (in the
 *                  case of CygLP).
 */
contract CygnusDAOReserves is ICygnusDAOReserves, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @custom:library SafeTransferLib ERC20 transfer library that gracefully handles missing return values.
    using SafeTransferLib for address;

    /// @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @inheritdoc ICygnusDAOReserves
    Shuttle[] public override allShuttles;

    /// @inheritdoc ICygnusDAOReserves
    string public override name = "Cygnus: DAO Reserves";

    /// @inheritdoc ICygnusDAOReserves
    address public override cygnusDAOSafe;
    /// @inheritdoc ICygnusDAOReserves
    address public override cygnusX1Vault;
    /// @inheritdoc ICygnusDAOReserves
    uint256 public override daoWeight;
    /// @inheritdoc ICygnusDAOReserves
    uint256 public override x1VaultWeight;

    /// @inheritdoc ICygnusDAOReserves
    address public override cygToken;
    /// @inheritdoc ICygnusDAOReserves
    uint256 public override daoLock;

    /// @inheritdoc ICygnusDAOReserves
    address public immutable override usd;

    /// @inheritdoc ICygnusDAOReserves
    IHangar18 public immutable override hangar18;

    /// @inheritdoc ICygnusDAOReserves
    bool public override privateBanker = true; // If true only admin can move

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice Constructs the DAO Reserves contract
    constructor(IHangar18 _hangar18) {
        // Set the Hangar18 contract address
        hangar18 = _hangar18;

        // Set the USD contract
        usd = _hangar18.usd(); // This is underlying for all borrowables

        // Set the weight of the shares that are redeemed and sent to the vault
        x1VaultWeight = 1e18;

        // Set the weight of the shares that this contract receives that are sent to the dao positions address
        daoWeight = 1e18 - x1VaultWeight;

        // CYG tokens for the DAO are locked from moving for the first 3 months
        daoLock = block.timestamp + 90 days;
    }

    /**
     *  @dev This function is called for plain Ether transfers
     */
    receive() external payable {}

    /**
     *  @dev Fallback function is executed if none of the other functions match the function identifier or no data was provided
     */
    fallback() external payable {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @custom:modifier cygnusAdmin Controls important parameters in both Collateral and Borrow contracts 👽
    modifier cygnusAdmin() {
        _checkAdmin();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /// @notice Internal check for msg.sender admin, checks factory's current admin 👽
    function _checkAdmin() private view {
        // Current admin from the factory
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin Avoid unless caller is Cygnus Admin
        if (msg.sender != admin) {
            revert CygnusDAOReserves__MsgSenderNotAdmin({admin: admin, sender: msg.sender});
        }
    }

    /// @notice Checks the `token` balance of this contract
    /// @param token The token to view balance of
    /// @return amount This contract's `token` balance
    function _checkBalance(address token) private view returns (uint256) {
        // Our balance of `token` (uses solady lib)
        return token.balanceOf(address(this));
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /// @inheritdoc ICygnusDAOReserves
    function allShuttlesLength() public view returns (uint256) {
        return allShuttles.length;
    }

    /// @inheritdoc ICygnusDAOReserves
    function cygTokenBalance() public view returns (uint256) {
        // Return CYG balance
        return _checkBalance(cygToken);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /// @notice Redeems vault token (CygUSD)
    /// @param borrowable The address of the CygUSD vault token
    /// @return shares The amount of shares sent to the safe
    /// @return assets The amount of assets sent to the vault
    function _redeemAndFundUSD(address borrowable) private returns (uint256 shares, uint256 assets) {
        /// @custom:error CantRedeemAddressZero Avoid if shuttle does not exist
        if (borrowable == address(0)) revert CygnusDAOReserves__CantRedeemAddressZero();

        // Sync and mint new reserves if needed
        ICygnusTerminal(borrowable).sync();

        // Get balance of vault shares we own
        uint256 totalShares = _checkBalance(borrowable);

        // Shares for the X1 Vault
        uint256 x1Shares = totalShares.mulWad(x1VaultWeight);

        // Shares for the DAO
        shares = totalShares - x1Shares;

        // Redeem USDC to the X1 vault
        if (x1Shares > 0) assets = ICygnusTerminal(borrowable).redeem(x1Shares, cygnusX1Vault, address(this));

        // Send CygUSD to the DAO safe
        if (shares > 0) borrowable.safeTransfer(cygnusDAOSafe, shares);
    }

    /// @notice Redeems vault token (CygLP)
    /// @param collateral The address of the CygLP vault token
    /// @return shares The amount of shares sent to the safe
    function _redeemAndFundCygLP(address collateral) private returns (uint256 shares) {
        // Get balance of this CygLP we own
        shares = _checkBalance(collateral);

        // Transfer CygLP to the safe
        if (shares > 0) collateral.safeTransfer(cygnusDAOSafe, shares);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    // USDC: Have 100 CygUSD. We redeem 50 CygUSD for USDC and send the USDC to the X1 Vault.
    //       The 50 leftover CygUSD we send to the DAO to not be redeemed, kept as reserves.

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security non-reentrant
    function fundX1VaultUSD(uint256 shuttleId) external override nonReentrant returns (uint256 daoShares, uint256 x1Assets) {
        // If the private banker is set to "TRUE" then we revert if msg.sender is not admin
        if (privateBanker) _checkAdmin();

        // Address of borrowable at index `i`
        address borrowable = allShuttles[shuttleId].borrowable;

        // Redeem CygUSD for USD
        (daoShares, x1Assets) = _redeemAndFundUSD(borrowable);

        /// @custom:event FundX1Vault
        emit FundX1Vault(borrowable, cygnusDAOSafe, cygnusX1Vault, daoShares, x1Assets);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security non-reentrant
    function fundX1VaultUSDAll() external override nonReentrant returns (uint256 daoShares, uint256 x1Assets) {
        // If the private banker is set to "TRUE" then we revert if msg.sender is not admin
        if (privateBanker) _checkAdmin();

        // Get shuttles length
        uint256 shuttlesLength = allShuttles.length;

        // Gas savings
        Shuttle[] memory _shuttles = allShuttles;

        // Loop over each lending borrowable and redeem CygUSD for USD
        for (uint256 i = 0; i < shuttlesLength; ) {
            // Address of borrowable at index `i`
            address borrowable = _shuttles[i].borrowable;

            // Redeem CygUSD for USD
            (uint256 _shares, uint256 _assets) = _redeemAndFundUSD(borrowable);

            unchecked {
                // Increase shares redeemed
                daoShares += _shares;

                // Increase assets received
                x1Assets += _assets;

                i++;
            }
        }

        /// @custom:event FundX1VaultAll
        emit FundX1VaultAll(shuttlesLength, cygnusX1Vault, daoShares, x1Assets);
    }

    // LP Tokens: Function only used if `liquidationFee` is active, meaning we receive from each Liquidation.

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security non-reentrant
    function fundDAOPositionsCygLP(uint256 shuttleId) external override nonReentrant returns (uint256 daoShares) {
        // If the private banker is set to "TRUE" then we revert if msg.sender is not admin
        if (privateBanker) _checkAdmin();

        // Get this shuttle's collateral address
        address collateral = allShuttles[shuttleId].collateral;

        // Send CygLP to the safe if we have any
        daoShares = _redeemAndFundCygLP(collateral);

        /// @custom:event FundDAOCygLP
        emit FundDAOReserves(collateral, cygnusDAOSafe, daoShares);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security non-reentrant
    function fundDAOPositionsCygLPAll() external override nonReentrant returns (uint256 daoShares) {
        // If the private banker is set to "TRUE" then we revert if msg.sender is not admin
        if (privateBanker) _checkAdmin();

        // Get shuttles length
        uint256 shuttlesLength = allShuttles.length;

        // Gas savings
        Shuttle[] memory _shuttles = allShuttles;

        // Loop over each collateral and check for our CygLP balance
        for (uint256 i = 0; i < shuttlesLength; ) {
            // Get collateral for shuttle at index `i`
            address collateral = _shuttles[i].collateral;

            unchecked {
                // Send CygLP to the safe if we have any
                daoShares += _redeemAndFundCygLP(collateral);

                // Next iteration
                i++;
            }
        }

        /// @custom:event FundDAOPositions
        emit FundDAOReservesAll(shuttlesLength, cygnusDAOSafe, daoShares);
    }

    // Hangar18 only

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security non-reentrant only-hangar
    function addShuttle(uint256 shuttleId, address borrowable, address collateral) external override {
        /// @custom:error MsgSenderNotHangar Can only be added after deployment
        if (msg.sender != address(hangar18)) revert CygnusDAOReserves__MsgSenderNotHangar();

        // Create Lending pool with borrowable and collateral
        Shuttle memory shuttle = Shuttle({initialized: true, shuttleId: shuttleId, borrowable: borrowable, collateral: collateral});

        // Push to array
        allShuttles.push(shuttle);

        /// @custom:event NewShuttleAdded
        emit NewShuttleAdded(shuttle);
    }

    // Admin only

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security non-reentrant only-admin
    function setX1VaultWeight(uint256 weight) external override cygnusAdmin {
        /// @custom:error WeightNotAllowed Avoid setting new weight above 100%
        if (weight > 1e18) revert CygnusDAOReserves__WeightNotAllowed({weight: weight});

        // Old weight
        uint256 oldWeight = x1VaultWeight;

        // New weight
        x1VaultWeight = weight;

        // Adjust DAO Positions
        daoWeight = 1e18 - weight;

        /// @custom:event NewX1VaultWeight
        emit NewX1VaultWeight(oldWeight, x1VaultWeight);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security only-admin
    function setCYGToken(address _token) external override cygnusAdmin {
        // Important: Can only be set once!
        if (cygToken != address(0)) return;

        // Assign the CYG token
        cygToken = _token;

        /// @custom:event CygTokenAdded
        emit CygTokenAdded(_token);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security only-admin
    function sweepToken(address token) external override cygnusAdmin {
        // Escape if the token is CygToken OR if cygToken has not been set yet, cannot sweep
        if (token == cygToken || cygToken == address(0)) return;

        // Balance this contract has of the erc20 token we are recovering
        uint256 balance = token.balanceOf(address(this));

        // Transfer token
        if (balance > 0) token.safeTransfer(msg.sender, balance);

        /// @custom:event SweepToken
        emit SweepToken(token, balance);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security only-admin
    function sweepNative() external override cygnusAdmin {
        // Get native balance
        uint256 balance = address(this).balance;

        // Get native out
        if (balance > 0) SafeTransferLib.safeTransferETH(msg.sender, balance);

        /// @custom:event SweepToken
        emit SweepToken(address(0), balance);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security only-admin
    function claimCygTokenDAO(uint256 amount, address to) external override cygnusAdmin {
        // Current timestamp of withdrawal
        uint256 currentTime = block.timestamp;

        /// @custom:error CantClaimCygYet
        if (currentTime < daoLock) revert CygnusDAOReserves__CantClaimCygYet({time: currentTime, claimAt: daoLock});

        // Balance of CYG
        uint256 balance = cygTokenBalance();

        /// @custom:error NotEnoughCyg
        if (amount > balance) revert CygnusDAOReserves__NotEnoughCyg({amount: amount, balance: balance});

        // Transfer to `to`
        cygToken.safeTransfer(to, amount);

        /// @custom:event ClaimCygToken
        emit ClaimCygToken(amount, to);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security only-admin
    function switchPrivateBanker() external override cygnusAdmin {
        /// @custom:event SwitchPrivateBanker
        emit SwitchPrivateBanker(privateBanker = !privateBanker);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security only-admin
    function setCygnusDAOSafe(address _newSafe) external override cygnusAdmin {
        /// @custom:error SafeCantBeZero
        if (_newSafe == address(0)) revert CygnusDAOReserves__SafeCantBeZero();

        // Safe up to now
        address oldSafe = cygnusDAOSafe;

        /// @custom;event NewDAOSafe
        emit NewDAOSafe(oldSafe, cygnusDAOSafe = _newSafe);
    }

    /// @inheritdoc ICygnusDAOReserves
    /// @custom:security only-admin
    function setCygnusX1Vault(address _x1Vault) external override cygnusAdmin {
        /// @custom:error X1VaultCantBeZero
        if (_x1Vault == address(0)) revert CygnusDAOReserves__X1VaultCantBeZero();

        // Old vault up to now
        address oldVault = cygnusX1Vault;

        /// @custom:event NewX1Vault
        emit NewX1Vault(oldVault, cygnusX1Vault = _x1Vault);
    }
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusTerminal.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {IERC20Permit} from "./IERC20Permit.sol";

/**
 *  @title ICygnusTerminal
 *  @notice The interface to mint/redeem pool tokens (CygLP and CygUSD)
 */
interface ICygnusTerminal is IERC20Permit {

    /**
     *  @notice Redeems the specified amount of `shares` for the underlying asset and transfers it to `recipient`.
     *
     *  @dev shares must be greater than 0.
     *  @dev If the function is called by someone other than `owner`, then the function will reduce the allowance
     *       granted to the caller by `shares`.
     *
     *  @param shares The number of shares to redeem for the underlying asset.
     *  @param recipient The address that will receive the underlying asset.
     *  @param owner The address that owns the shares.
     *
     *  @return assets The amount of underlying assets received by the `recipient`.
     */
    function redeem(uint256 shares, address recipient, address owner) external returns (uint256 assets);

    /**
     *  @notice Exchange Rate between the pool token and the asset
     */
    function exchangeRate() external view returns (uint256);

    /**
     *  @notice The lending pool ID (shared by borrowable/collateral)
     */
    function shuttleId() external view returns (uint256);

    /**
     *  @notice Get the collateral address from the borrowable
     */
    function collateral() external view returns (address);

    /**
     *  @notice Get the borrowable address from the collateral
     */
    function borrowable() external view returns (address);

    /**
     *  @notice Syncs the totalBalance in terms of its underlying (accrues interest in borrowable)
     */
    function sync() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
pragma solidity >=0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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

    // Mint
    function mint(address, uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
pragma solidity >=0.8.17;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IHangar18.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Oracles

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface IHangar18 {

    /**
     *  @notice Array of LP Token pairs deployed
     *  @param _shuttleId The ID of the shuttle deployed
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @return usd The address of the borrowable token (stablecoin)
     */
    function usd() external view returns (address);

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @return daoReserves The address that handles Cygnus reserves from all pools
     */
    function daoReserves() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import {IHangar18} from "./core/IHangar18.sol";

interface ICygnusDAOReserves {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @dev Reverts when attempting to call Admin-only functions
    /// @param admin The address of the admin of hangar18
    /// @param sender Address of msg.sender
    /// @custom:error MsgSenderNotAdmin
    error CygnusDAOReserves__MsgSenderNotAdmin(address admin, address sender);

    /// @dev Reverts when adding new shuttle to the reserves
    /// @param shuttleId The ID for the lending pool we are initializing
    /// @custom:error ShuttleNotInitialized
    error CygnusDAOReserves__ShuttleDoesntExist(uint256 shuttleId);

    /// @dev Reverts when adding new shuttle to the reserves
    /// @param shuttleId The ID for the lending pool we are initializing
    /// @custom:error ShuttleAlreadyInitialized
    error CygnusDAOReserves__ShuttleAlreadyInitialized(uint256 shuttleId);

    /// @dev Reverts when setting a new weight outside range allowed
    /// @param weight The weight of the X1 Vault
    /// @custom:error WeightNotAllowed
    error CygnusDAOReserves__WeightNotAllowed(uint256 weight);

    /// @dev Reverts when trying to claim cyg before lock period ends
    /// @custom:error CantClaimCygYet
    error CygnusDAOReserves__CantClaimCygYet(uint256 time, uint256 claimAt);

    /// @dev Reverts when theres not enough cyg to claim
    /// @custom:error NotEnoughCyg
    error CygnusDAOReserves__NotEnoughCyg(uint256 amount, uint256 balance);

    /// @dev Reverts if borrowable is not set
    /// @custom:error CantRedeemAddressZero
    error CygnusDAOReserves__CantRedeemAddressZero();

    /// @dev Reverts if Safe is 0
    /// @custom:error SafeCantBeZero
    error CygnusDAOReserves__SafeCantBeZero();

    /// @dev Reverts if X1 vault is 0
    /// @custom:error X1VaultCantBeZero
    error CygnusDAOReserves__X1VaultCantBeZero();

    /// @dev Reverts if sender is not Hangar18
    /// @custom:error MsgSenderNotHangar
    error CygnusDAOReserves__MsgSenderNotHangar();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @dev Logs when the X1 Vault is funded with assets
    /// @param vaultToken The address of the vault token
    /// @param positions The address receiving the left over shares
    /// @param vault The address receiving the assets
    /// @param shares The amount of shares being redeemed
    /// @param assets The amount of assets funded to
    /// @custom:event FundX1Vault
    event FundX1Vault(address indexed vaultToken, address indexed positions, address indexed vault, uint256 shares, uint256 assets);

    /// @dev Logs when the DAO Positions receives CygLP
    /// @param vaultToken The address of the vault token
    /// @param positions The address of the DAO Positions
    /// @param shares The amount of shares transfered to DAO Positions
    /// @custom:event FundDAOPositions
    event FundDAOReserves(address indexed vaultToken, address indexed positions, uint256 shares);

    /// @dev Logs when admin sets a new weight for the vault
    /// @param oldWeight The old X1 Vault weight
    /// @param newWeight The new X1 Vault weight
    /// @custom:event NewX1VaultWeight
    event NewX1VaultWeight(uint256 oldWeight, uint256 newWeight);

    /// @dev Logs when a new shuttle is added
    /// @param shuttle The Shuttle struct record
    /// @custom:event NewShuttleAdded
    event NewShuttleAdded(Shuttle shuttle);

    /// @dev Logs When the Cygnus X1 Vault is funded by all shuttles
    /// @param totalShuttles The amount of lending pools we harvested
    /// @param vault The address of the X1 Vault
    /// @param shares The amount of CygUSD redeemed
    /// @param assets The amount of assets received
    /// @custom:event FundX1VaultAll
    event FundX1VaultAll(uint256 totalShuttles, address vault, uint256 shares, uint256 assets);

    /// @dev Logs When the Cygnus X1 Vault is funded by all shuttles
    /// @param totalShuttles The amount of lending pools we harvested
    /// @param positions The address of the DAO Positions
    /// @param shares The amount of shares transfered to DAO Positions
    /// @custom:event FundDAOReservesAll
    event FundDAOReservesAll(uint256 totalShuttles, address positions, uint256 shares);

    /// @dev Logs when permissions for splitting shares and assets are switched
    /// @param _privateBanker Whether only admin can split or anyone can (true = only admin)
    /// @custom:event SwitchPrivateBanker
    event SwitchPrivateBanker(bool _privateBanker);

    /// @dev Logs when the DAO claims their shares of CYG token
    /// @param amount Amount claimed of CYG token
    /// @param to Address who received the CYG tokens
    /// @custom:event ClaimCygToken
    event ClaimCygToken(uint256 amount, address to);

    /// @dev Logs when admin sweeps a token (throws is the token is CYG)
    /// @param token The address of the token
    /// @param balance The balance of the token claimed
    /// @custom:event SweepToken
    event SweepToken(address token, uint256 balance);

    /// @dev Logs when admin adds the CYG token
    /// @param token The address of the CYG token
    /// @custom:event CygTokenAdded
    event CygTokenAdded(address token);

    /// @dev Logs when admin replaces the dao safe
    /// @param oldSafe the address of the safe up to now
    /// @param newSafe the address of the new safe
    /// @custom:event NewDAOSafe
    event NewDAOSafe(address oldSafe, address newSafe);

    /// @dev Logs when admin replaces the X1 Vault
    /// @param oldVault the address of the X1 Vault up to now
    /// @param newVault the address of the new X1 Vault
    /// @custom:event NewX1Vault
    event NewX1Vault(address oldVault, address newVault);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice The shuttle struct for each lending pool
    /// @custom:struct Shuttle Information of each lending pool
    /// @custom:member initialized Whether the shuttle is initialized or not
    /// @custom:member shuttleId The unique identifier of the shuttle
    /// @custom:member borrowable The address of the borrowable asset
    /// @custom:member collateral The address of the collateral asset
    struct Shuttle {
        bool initialized;
        uint256 shuttleId;
        address borrowable;
        address collateral;
    }

    /// @dev Retrieves information about a specific shuttle.
    /// @param _shuttleId The ID of the shuttle to retrieve information about.
    /// @return initialized Whether the shuttle is initialized or not.
    /// @return shuttleId The unique identifier of the shuttle.
    /// @return borrowable The address of the borrowable asset.
    /// @return collateral The address of the collateral asset.
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool initialized, uint256 shuttleId, address borrowable, address collateral);

    /// @dev Name of the contract
    function name() external view returns (string memory);

    /// @dev Retrieves the address of the Hangar18 contract.
    /// @return The address of the Hangar18 contract.
    function hangar18() external view returns (IHangar18);

    /// @dev Retrieves the address of the Cygnus DAO positions.
    /// @return The address of the CygnusDAO positions.
    function cygnusDAOSafe() external view returns (address);

    /// @dev Retrieves the address of the CygnusX1Vault contract.
    /// @return The address of the CygnusX1Vault contract.
    function cygnusX1Vault() external view returns (address);

    /// @dev Retrieves the address of the USD contract.
    /// @return The address of the USD contract.
    function usd() external view returns (address);

    /// @dev Retrieves the weight of the X1 vault.
    /// @return The weight of the X1 vault.
    function x1VaultWeight() external view returns (uint256);

    /// @dev Retrieves the weight of the DAO positions
    /// @return The weight of the DAO positions.
    function daoWeight() external view returns (uint256);

    /// @dev Retrieves the length of the allShuttles array.
    /// @return The length of the allShuttles array.
    function allShuttlesLength() external view returns (uint256);

    /// @dev Address of the CYG token
    function cygToken() external view returns (address);

    /// @dev current balance of CYg
    function cygTokenBalance() external view returns (uint256);

    /// @dev The unlock cyg DAO time
    function daoLock() external view returns (uint256);

    /// @dev Whether anyone can split shares and assets
    function privateBanker() external view returns (bool);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @dev Funds the CygnusX1Vault with all the available USD tokens from `shuttleId`
    /// @param shuttleId The ID of the lending pool
    /// @return shares The total amount of shares transferred to CygnusDAOPositions.
    /// @return assets The total amount of assets transferred to CygnusX1Vault.
    function fundX1VaultUSD(uint256 shuttleId) external returns (uint256 shares, uint256 assets);

    /// @dev Funds the CygnusX1Vault with all the available LP tokens from `shuttleId`
    /// @param shuttleId The ID of the lending pool
    /// @return shares The total amount of shares transfered to CygnusDAOPositions
    function fundDAOPositionsCygLP(uint256 shuttleId) external returns (uint256 shares);

    /// @dev Funds the CygnusX1Vault with all the available tokens from all shuttles.
    /// @return shares The total amount of shares transferred to CygnusDAOPositions.
    /// @return assets The total amount of assets transferred to CygnusX1Vault.
    function fundX1VaultUSDAll() external returns (uint256 shares, uint256 assets);

    /// @dev Funds the DAO Positions with all the available tokens from all shuttles.
    /// @return shares The total amount of shares transferred to CygnusDAOPositions.
    function fundDAOPositionsCygLPAll() external returns (uint256 shares);

    /// @dev Sets the weight of the X1 vault.
    /// @param weight The new weight to be set for the X1 vault.
    function setX1VaultWeight(uint256 weight) external;

    /// @notice Adds a shuttle to the record
    /// @param shuttleId The ID for the shuttle we are adding
    /// @custom:security non-reentrant only-admin
    function addShuttle(uint256 shuttleId, address borrowable, address collateral) external;

    /// @notice Sweeps any token sent to this contract except the CYG token
    /// @param token The address of the token being swept
    function sweepToken(address token) external;

    /// @notice Sends an amount of `cygToken` to `to`
    function claimCygTokenDAO(uint256 amount, address to) external;

    /// @notice Sets the CYG token
    function setCYGToken(address _token) external;

    /// @notice Admin allows anyone to split the shares/assets between the DAO Reserves and X1 Vault
    /// @custom:security only-admin
    function switchPrivateBanker() external;

    /// @notice Admin assigns new safe address
    /// @custom:security only-admin
    function setCygnusDAOSafe(address _safe) external;

    /// @notice Admin assigns new X1 vault address
    /// @custom:security only-admin
    function setCygnusX1Vault(address _vault) external;

    /// @notice Sweep ETH
    function sweepNative() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(
                    or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)),
                    96
                )
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {

            } 1 {

            } {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } 1 {

            } {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001), 0x3fffff)
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for {
                        let w := not(0)
                    } 1 {

                    } {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) {
                            break
                        }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue) internal pure returns (uint256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {
                z := x
            } y {

            } {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Store the `from` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x60, amount) // Store the `amount` argument.

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, from) // Store the `from` argument.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x40, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x6a.
            amount := mload(0x60)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x3a, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x1a, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x3a.
            amount := mload(0x3a)
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0x095ea7b3000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, account) // Store the `account` argument.
            amount := mul(
                mload(0x20),
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x20, 0x20)
                )
            )
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied
/// to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not
/// call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when there is a reentrancy call.
    error ReentrantCall();

    /// PRIVATE STORAGE ///

    bool private notEntered;

    /// CONSTRUCTOR ///

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percetange of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /// MODIFIERS ///

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true.
        if (!notEntered) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}