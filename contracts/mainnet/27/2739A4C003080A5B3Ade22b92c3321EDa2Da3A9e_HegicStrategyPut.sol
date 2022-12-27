pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@hegic/utils/contracts/Math.sol";
import "@hegic/utils/contracts/ERC721WithURIBuilder.sol";
import "./ICoverPool.sol";

contract CoverPool is
    AccessControl,
    ERC721WithURIBuilder("Hegic Herge Stake & Cover", "HEGSC"),
    ICoverPool
{
    using SafeERC20 for IERC20;
    using HegicMath for uint256;
    IERC20 public immutable override coverToken;
    IERC20 public immutable override profitToken;

    uint256 _nextPositionId = 1;
    uint256 constant CHANGING_PRICE_DECIMALS = 1e30;
    uint256 constant ADDITIONAL_DECIMALS = 1e30;
    uint256 constant MINIMAL_EPOCH_DURATION = 7 days;
    bytes32 constant TEMPORARY_ADMIN_ROLE = keccak256("TEMPORARY_ADMIN_ROLE");
    bytes32 constant OPERATIONAL_TRESUARY_ROLE =
        keccak256("OPERATIONAL_TRESUARY_ROLE");

    uint32 public windowSize = 5 days;
    uint256 public cumulativeProfit;
    uint256 public profitTokenBalance;
    uint256 public totalShare;
    uint256 public unwithdrawnCoverTokens;
    address public payoffPool;

    mapping(uint256 => uint256) public shareOf;
    mapping(uint256 => uint256) public bufferredUnclaimedProfit;
    mapping(uint256 => uint256) public cumulativePoint;
    mapping(uint256 => Epoch) public override epoch;

    uint256 public nextEpochChangingPrice;
    uint256 public override currentEpoch;

    constructor(
        IERC20 _coverToken,
        IERC20 _profitToken,
        address _payoffPool,
        uint256 initialEpochChangingPrice
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEMPORARY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TEMPORARY_ADMIN_ROLE, TEMPORARY_ADMIN_ROLE);
        _setRoleAdmin(OPERATIONAL_TRESUARY_ROLE, TEMPORARY_ADMIN_ROLE);

        coverToken = _coverToken;
        profitToken = _profitToken;
        payoffPool = _payoffPool;

        nextEpochChangingPrice = initialEpochChangingPrice;
        _startNextEpoch();
    }

    // ╒═══════════════════════════════════════════╕
    //               user's functions
    // ╘═══════════════════════════════════════════╛

    /**
     * @notice user call this function to provide liquidity (in HEGIC)
     * into the Cover Pool
     * @param amount amount of the $HEGIC tokens to provide
     **/
    function provide(uint256 amount, uint256 positionId)
        external
        override
        returns (uint256)
    {
        require(
            _nextPositionId > 1 || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can create first position"
        );
        if (positionId == 0) {
            positionId = _nextPositionId++;
            _mint(msg.sender, positionId);
        }
        require(
            _isApprovedOrOwner(msg.sender, positionId),
            "Yuo are has no access to this position"
        );
        require(
            windowSize > block.timestamp - epoch[currentEpoch].start,
            "Enterence window is closed"
        );
        _bufferUnclaimedProfit(positionId);
        uint256 shareOfProvide = _provide(positionId, amount);
        coverToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Provided(
            positionId,
            amount,
            shareOfProvide,
            shareOf[positionId],
            totalShare
        );
        return positionId;
    }

    /**
     * @notice user call this function to withdraw liquidity (in HEGIC)
     * from the Cover Pool
     * @param amount amount of the $HEGIC tokens to withdraw
     **/
    function withdraw(uint256 positionId, uint256 amount) external override {
        require(
            _isApprovedOrOwner(msg.sender, positionId),
            "only owner of the position can withdraw it"
        );
        _bufferUnclaimedProfit(positionId);
        uint256 shareOfWithdraw = _withdraw(positionId, amount);
        emit Withdrawn(
            currentEpoch,
            positionId,
            amount,
            shareOfWithdraw,
            shareOf[positionId],
            totalShare
        );
    }

    /**
     * @notice used to claim 100% of users profits in $USDC (if any).
     * @param amount amount of the $USDC profits
     **/
    function claim(uint256 positionId)
        external
        override
        returns (uint256 amount)
    {
        amount = _bufferUnclaimedProfit(positionId);
        if (amount == 0) return 0;
        bufferredUnclaimedProfit[positionId] = 0;
        profitTokenBalance -= amount;
        profitToken.safeTransfer(ownerOf(positionId), amount);
        emit Claimed(positionId, amount);
    }

    /**
     * @notice allow a user to withdraw $HEGIC token when epoch is ended.
     * @param positionId TODO
     **/
    function withdrawEpoch(uint256 positionId, uint256[] calldata outFrom)
        external
    {
        uint256 profitAmount = _bufferUnclaimedProfit(positionId);
        bufferredUnclaimedProfit[positionId] = 0;
        uint256 tokenAmount;

        for (uint256 idx = 0; idx < outFrom.length; idx++) {
            (uint256 profit, uint256 token) = _withdrawFromEpoch(
                positionId,
                outFrom[idx]
            );
            profitAmount += profit;
            tokenAmount += token;
            emit WithdrawnFromEpoch(outFrom[idx], positionId, token, profit);
        }
        profitTokenBalance -= profitAmount;

        if (profitAmount > 0) emit Claimed(positionId, profitAmount);
        coverToken.safeTransfer(ownerOf(positionId), tokenAmount);
        profitToken.safeTransfer(ownerOf(positionId), profitAmount);
    }

    /**
     * @notice allows users to close previous epoch and start next epoch
     */
    function fallbackEpochClose() external {
        require(
            block.timestamp > epoch[currentEpoch].start + 90 days,
            "It's too early yet"
        );
        _startNextEpoch();
    }

    /**
     * @notice calculates all user's profits
     * @param positionId TODO
     * @return amount amount of profits in $USDC
     **/
    function availableToClaim(uint256 positionId)
        external
        view
        override
        returns (uint256 amount)
    {
        return
            bufferredUnclaimedProfit[positionId] +
            ((cumulativeProfit - cumulativePoint[positionId]) *
                shareOf[positionId]) /
            ADDITIONAL_DECIMALS;
    }

    /**
     * @notice calcualtes amount of $HEGIC token for each user
     * @param positionId TODO
     * @return amount amount of $HEGIC tokens
     **/
    function coverTokenBalance(uint256 positionId)
        external
        view
        override
        returns (uint256 amount)
    {
        return (coverTokenTotal() * shareOf[positionId]) / totalShare;
    }

    /**
     * @notice total amount of $HEGIC tokens on the Cover Pool
     * @return amount amount of $HEGIC tokens
     **/
    function coverTokenTotal() public view override returns (uint256 amount) {
        return coverToken.balanceOf(address(this)) - unwithdrawnCoverTokens;
    }

    /**
     * @notice maximum amount of $USDC the Cover Pool
     * can send to the option traders.
     * @return amount amount in $USDC
     **/
    function availableForPayment()
        external
        view
        override
        returns (uint256 amount)
    {
        uint256 changingPrice = epoch[currentEpoch].changingPrice;
        uint256 coverBalance = (coverTokenTotal() * changingPrice) /
            CHANGING_PRICE_DECIMALS;
        uint256 payoffPoolBalance = profitToken.balanceOf(payoffPool);

        {
            uint256 payoffPoolAllowance = profitToken.allowance(
                payoffPool,
                address(this)
            );
            if (payoffPoolBalance > payoffPoolAllowance)
                payoffPoolBalance = payoffPoolAllowance;
        }

        return
            payoffPoolBalance < coverBalance ? payoffPoolBalance : coverBalance;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721WithURIBuilder, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICoverPool).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            ERC721WithURIBuilder.supportsInterface(interfaceId);
    }

    // ╒═══════════════════════════════════════════╕
    //                admin's functions
    // ╘═══════════════════════════════════════════╛

    /**
     * TODO
     **/
    function setWindowSize(uint32 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        windowSize = value;
        emit SetWindowSize(value);
    }

    /**
     * TODO
     **/
    function setPayoffPool(address value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payoffPool = value;
        emit SetPayoffPool(value);
    }

    /**
     * TODO
     **/
    function setNextEpochChangingPrice(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nextEpochChangingPrice = value;
        emit SetNextEpochChangingPrice(value);
    }

    /**
     * TODO
     **/
    function fixProfit() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 profitAmount = profitToken.balanceOf(address(this)) -
            profitTokenBalance;
        profitTokenBalance += profitAmount;
        cumulativeProfit += (profitAmount * ADDITIONAL_DECIMALS) / totalShare;
        _startNextEpoch();
        emit Profit(currentEpoch, profitAmount);
    }

    /**
     * @notice send $USDC from the Cover Pool
     * to the Operational Treasury if any losses on
     * the Operational Treasury
     * @param amount amount of USDC to the
     * Operational Treasury
     **/
    function payOut(uint256 amount)
        external
        override
        onlyRole(OPERATIONAL_TRESUARY_ROLE)
    {
        uint256 changingPrice = epoch[currentEpoch].changingPrice;
        uint256 outAmount = ((amount * CHANGING_PRICE_DECIMALS) /
            changingPrice);

        coverToken.safeTransfer(payoffPool, outAmount);
        profitToken.safeTransferFrom(payoffPool, msg.sender, amount);
    }

    // ╒═══════════════════════════════════════════╕
    //               internal functions
    // ╘═══════════════════════════════════════════╛

    function _provide(uint256 positionId, uint256 amount)
        internal
        returns (uint256 shareOfProvide)
    {
        uint256 totalCoverBalance = coverTokenTotal();
        shareOfProvide = totalCoverBalance > 0
            ? (amount * totalShare) / totalCoverBalance
            : amount;
        shareOf[positionId] += shareOfProvide;
        totalShare += shareOfProvide;
    }

    function _withdraw(uint256 positionId, uint256 amount)
        internal
        returns (uint256 shareOfWithdraw)
    {
        uint256 totalCoverBalance = coverTokenTotal();
        shareOfWithdraw = (amount * totalShare).ceilDiv(totalCoverBalance);
        shareOf[positionId] -= shareOfWithdraw;
        epoch[currentEpoch].outShare[positionId] += shareOfWithdraw;
        epoch[currentEpoch].totalShareOut += shareOfWithdraw;
    }

    function _bufferUnclaimedProfit(uint256 positionId)
        internal
        returns (uint256 amount)
    {
        if (totalShare == 0) return 0;

        bufferredUnclaimedProfit[positionId] +=
            ((cumulativeProfit - cumulativePoint[positionId]) *
                shareOf[positionId]) /
            ADDITIONAL_DECIMALS;
        cumulativePoint[positionId] = cumulativeProfit;

        return bufferredUnclaimedProfit[positionId];
    }

    function _startNextEpoch() internal {
        require(
            MINIMAL_EPOCH_DURATION <
                block.timestamp - epoch[currentEpoch].start,
            "The epoch is too short to be closed"
        );

        uint256 totalShareOut = epoch[currentEpoch].totalShareOut;
        uint256 coverTokenOut = totalShare == 0
            ? 0
            : (totalShareOut * coverTokenTotal()) / totalShare;
        uint256 profitOut = (totalShareOut *
            (cumulativeProfit - epoch[currentEpoch].cumulativePoint)) /
            ADDITIONAL_DECIMALS;
        unwithdrawnCoverTokens += coverTokenOut;
        epoch[currentEpoch].coverTokenOut = coverTokenOut;
        epoch[currentEpoch].profitTokenOut = profitOut;
        totalShare -= epoch[currentEpoch].totalShareOut;

        currentEpoch++;
        epoch[currentEpoch].cumulativePoint = cumulativeProfit;
        epoch[currentEpoch].start = block.timestamp;
        epoch[currentEpoch].changingPrice = nextEpochChangingPrice;
        emit EpochStarted(currentEpoch, nextEpochChangingPrice);
    }

    function _withdrawFromEpoch(uint256 positionId, uint256 epochID)
        internal
        returns (uint256 profit, uint256 token)
    {
        require(
            epochID < currentEpoch,
            "Withdraw from current and future epoch are anavailable"
        );
        Epoch storage e = epoch[epochID];
        profit = (e.outShare[positionId] * e.profitTokenOut) / e.totalShareOut;
        token = (e.outShare[positionId] * e.coverTokenOut) / e.totalShareOut;
        e.outShare[positionId] = 0;
        unwithdrawnCoverTokens -= token;
    }
}

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@hegic/utils/contracts/IERC721WithURIBuilder.sol";

interface ICoverPool is IERC721WithURIBuilder {
    struct Epoch {
        uint256 start;
        uint256 cumulativePoint;
        uint256 changingPrice;
        uint256 profitTokenOut;
        uint256 coverTokenOut;
        uint256 totalShareOut;
        mapping(uint256 => uint256) outShare;
        mapping(uint256 => uint256) Share;
    }

    event SetWindowSize(uint32 value);
    event SetPayoffPool(address value);
    event SetNextEpochChangingPrice(uint256 value);
    event EpochStarted(uint256 epochId, uint256 changingPrice);
    event PaidOut(uint256 epochId, uint256 amount, uint256 coverTokenAmount);
    event Profit(uint256 indexed epoch, uint256 amount);
    event Claimed(uint256 indexed positionId, uint256 amount);

    event Provided(
        uint256 indexed positionId,
        uint256 amount,
        uint256 shareOfProvide,
        uint256 shareOfPosition,
        uint256 totalShare
    );

    event Withdrawn(
        uint256 indexed epochId,
        uint256 indexed positionId,
        uint256 amount,
        uint256 shareOfProvide,
        uint256 shareOfPosition,
        uint256 totalShare
    );

    event WithdrawnFromEpoch(
        uint256 indexed epochId,
        uint256 indexed positionId,
        uint256 amount,
        uint256 profit
    );

    function coverToken() external view returns (IERC20);

    function profitToken() external view returns (IERC20);

    function provide(uint256 amount, uint256 positionId)
        external
        returns (uint256);

    function withdraw(uint256 positionId, uint256 amount) external;

    function claim(uint256 psoitionId) external returns (uint256 amount);

    function currentEpoch() external view returns (uint256 epochID);

    function coverTokenTotal() external view returns (uint256 amount);

    function epoch(uint256 id)
        external
        view
        returns (
            uint256 start,
            uint256 cumulativePoint,
            uint256 changingPrice,
            uint256 profitTokenOut,
            uint256 coverTokenOut,
            uint256 totalShareOut
        );

    function payOut(uint256 amount) external;

    function availableForPayment() external view returns (uint256 amount);

    function availableToClaim(uint256 positionId)
        external
        view
        returns (uint256 amount);

    function coverTokenBalance(uint256 positionId)
        external
        view
        returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

library HegicMath {
    /**
     * @dev Calculates a square root of the number.
     * Responds with an "invalid opcode" at uint(-1).
     **/
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        result = x;
        uint256 k = (x >> 1) + 1;
        while (k < result) (result, k) = (k, (x / k + k) >> 1);
    }

    function round(uint256 value, uint8 decimals)
        internal
        pure
        returns (uint256 roundedValue)
    {
        if (decimals == 0) return value;
        uint256 a = value / 10**(decimals - 1);
        if (a % 10 < 5) return (a / 10) * 10**decimals;
        return (a / 10 + 1) * 10**decimals;
    }

    function ceilDiv(uint256 enumerator, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        if (enumerator % denominator == 0) return enumerator / denominator;
        return enumerator / denominator + 1;
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IERC721WithURIBuilder.sol";

contract ERC721WithURIBuilder is ERC721, AccessControl, IERC721WithURIBuilder {
    IERC721Metadata public override uriBuilder;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        if (address(uriBuilder) == address(0)) return ERC721.tokenURI(tokenId);
        return uriBuilder.tokenURI(tokenId);
    }

    function setURIBuilder(IERC721Metadata _uriBuilder)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uriBuilder = _uriBuilder;
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC721WithURIBuilder is IERC721 {
    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);

    function setURIBuilder(IERC721Metadata _uriBuilder) external;

    function uriBuilder() external view returns (IERC721Metadata uriBuilder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

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

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "../Interfaces/IPremiumCalculator.sol";
import "@hegic/utils/contracts/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Price Calculator Contract
 * @notice The contract that calculates the options prices (the premiums)
 **/

abstract contract BasePriceCalculator is IPremiumCalculator, AccessControl {
    using HegicMath for uint256;

    uint256 public minPeriod = 7 days;
    uint256 public maxPeriod = 45 days;
    AggregatorV3Interface public override priceProvider;

    constructor(AggregatorV3Interface _priceProvider) {
        priceProvider = _priceProvider;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setPeriodLimits(uint256 min, uint256 max)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            min >= 1 days && max <= 90 days,
            "PriceCalculator: Period limits are wrong"
        );
        maxPeriod = max;
        minPeriod = min;
        emit SetPeriodLimits(min, max);
    }

    function calculatePremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) public view override returns (uint256 premium) {
        (period, amount, strike) = _checkParams(period, amount, strike);
        return _calculatePeriodFee(period, amount, strike);
    }

    function _checkParams(
        uint256 period,
        uint256 amount,
        uint256 strike
    )
        internal
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(
            period >= minPeriod,
            "PriceCalculator: The period is too short"
        );
        require(period <= maxPeriod, "PriceCalculator: The period is too long");
        if (strike == 0) strike = _currentPrice();
        return (period, amount, strike);
    }

    /**
     * @notice Calculates and prices in the time value of the option
     * @param amount Option size
     * @param period The option period in seconds (1 days <= period <= 90 days)
     * @return fee The premium size to be paid
     **/
    function _calculatePeriodFee(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal view virtual returns (uint256 fee);

    /**
     * @notice Used for requesting the current price of the asset
     * using the ChainLink data feeds contracts.
     * See https://feeds.chain.link/
     * @return price Price
     **/
    function _currentPrice() internal view returns (uint256 price) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        price = uint256(latestPrice);
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @notice The interface fot the contract that calculates
 *   the options prices (the premiums) that are adjusted
 *   through balancing the `ImpliedVolRate` parameter.
 **/
interface IIVLPriceCalculator {
    event SetImpliedVolRate(uint256 value);
    event SetSettlementFeeShare(uint256 value);
}

interface IPremiumCalculator is IIVLPriceCalculator {
    event SetBorders(uint256[3] values);
    event SetImpliedVolRates(uint256[4] values);
    event SetDiscountCall(int256[5] values);
    event SetDiscountPut(int256[5] values);
    event SetDiscountSpread(uint8 values);
    event SetStrikePercentage(uint256 value);
    event SetPeriodLimits(uint256 min, uint256 max);

    /**
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     **/
    function calculatePremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external view returns (uint256 premium);

    function priceProvider() external view returns (AggregatorV3Interface);
}

interface IPriceCalculator is IIVLPriceCalculator {
    /**
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     **/
    function calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external view returns (uint256 settlementFee, uint256 premium);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./BasePriceCalculator.sol";
import "../Interfaces/IPremiumCalculator.sol";
import "@hegic/utils/contracts/Math.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Price Calculator Contract
 * @notice The contract that calculates the options prices (the premiums)
 * that are adjusted through the `ImpliedVolRate` parameter.
 **/

contract PolynomialPriceCalculator is BasePriceCalculator {
    using HegicMath for uint256;

    int256[5] public coefficients;
    uint256 internal immutable tokenDecimals;

    event SetCoefficients(int256[5] values);

    constructor(
        int256[5] memory initialCoefficients,
        AggregatorV3Interface _priceProvider,
        uint256 _tokenDecimals
    ) BasePriceCalculator(_priceProvider) {
        coefficients = initialCoefficients;
        tokenDecimals = _tokenDecimals;
    }

    /**
     * @notice Used for adjusting the options prices (the premiums)
     * @param values [i] New setCoefficients value
     **/
    function setCoefficients(int256[5] calldata values)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        coefficients = values;
        emit SetCoefficients(values);
    }

    /**
     * @notice Calculates and prices in the time value of the option
     * @param amount Option size
     * @param period The option period in seconds (1 days <= period <= 90 days)
     * @return fee The premium size to be paid
     **/
    function _calculatePeriodFee(
        uint256 period,
        uint256 amount,
        uint256 /*strike*/
    ) internal view virtual override returns (uint256 fee) {
        uint256 premium = uint256(
            coefficients[0] +
                coefficients[1] *
                int256(period) +
                coefficients[2] *
                int256(period)**2 +
                coefficients[3] *
                int256(period)**3 +
                coefficients[4] *
                int256(period)**4
        );
        return ((premium / 1e24) * amount) / 10**tokenDecimals;
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./HegicInverseStrategy.sol";
import "@hegic/utils/contracts/Math.sol";

contract HegicStrategyInverseLongCondor is HegicInverseStrategy {
    uint256 public immutable strikePercentage;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint256 percentage,
        uint48[2] memory periodLimits,
        LimitController _limitController
    )
        HegicInverseStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _limitController
        )
    {
        strikePercentage = percentage;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        uint256 currentPrice = _currentPrice();
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = uint256(data.strike);
        require(currentPrice != data.strike, "Invalid strike = Current price");
        uint256 SELL_OTM_CALLStrike = ((ATMStrike * 110) / 100);
        uint256 SELL_OTM_PUTStrike = ((ATMStrike * 90) / 100);
        uint256 BUY_OTM_CALLStrike = ((ATMStrike * (100 + strikePercentage)) /
            100);
        uint256 BUY_OTM_PUTStrike = ((ATMStrike * (100 - strikePercentage)) /
            100);
        if (currentPrice >= SELL_OTM_CALLStrike) {
            if (currentPrice <= BUY_OTM_CALLStrike) {
                return
                    ((currentPrice - SELL_OTM_CALLStrike) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            } else if (currentPrice >= BUY_OTM_CALLStrike) {
                return
                    ((BUY_OTM_CALLStrike - SELL_OTM_CALLStrike) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            }
        } else if (
            currentPrice <= SELL_OTM_CALLStrike &&
            currentPrice >= SELL_OTM_PUTStrike
        ) {
            return 0;
        } else if (currentPrice <= SELL_OTM_PUTStrike) {
            if (currentPrice >= BUY_OTM_PUTStrike) {
                return
                    ((SELL_OTM_PUTStrike - currentPrice) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            } else if (currentPrice <= BUY_OTM_PUTStrike) {
                return
                    ((SELL_OTM_PUTStrike - BUY_OTM_PUTStrike) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            }
        }
    }

    function _calculateCollateral(
        uint256 amount,
        uint256 /*period*/
    ) internal view override returns (uint128 collateral) {
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = _currentPrice();
        uint256 SELL_OTM_CALLStrike = ((ATMStrike * 110) / 100);
        uint256 SELL_OTM_PUTStrike = ((ATMStrike * 90) / 100);
        uint256 BUY_OTM_CALLStrike = ((ATMStrike * (100 + strikePercentage)) /
            100);
        uint256 BUY_OTM_PUTStrike = ((ATMStrike * (100 - strikePercentage)) /
            100);
        uint256 CALLProfit = ((BUY_OTM_CALLStrike - SELL_OTM_CALLStrike) *
            amount *
            TOKEN_DECIMALS) /
            spotDecimals /
            priceDecimals;
        uint256 PUTProfit = ((SELL_OTM_PUTStrike - BUY_OTM_PUTStrike) *
            amount *
            TOKEN_DECIMALS) /
            spotDecimals /
            priceDecimals;
        if (CALLProfit > PUTProfit) {
            return uint128(CALLProfit);
        } else {
            return uint128(PUTProfit);
        }
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../IOperationalTreasury.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./HegicStrategy.sol";

abstract contract HegicInverseStrategy is HegicStrategy {
    using SafeERC20 for IERC20;
    bytes32 public constant EXERCISER_ROLE = keccak256("EXERCISER_ROLE");

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint48[2] memory periodLimits,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            0,
            _limitController
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EXERCISER_ROLE, msg.sender);
    }

    function calculateNegativepnlAndPositivepnl(
        uint256 amount,
        uint256 period,
        bytes[] calldata /*additional*/
    )
        public
        view
        override(HegicStrategy)
        returns (uint128 negativepnl, uint128 positivepnl)
    {
        negativepnl = _calculateStrategyPremium(amount, period);
        uint128 collateral = _calculateCollateral(amount, period);
        positivepnl = collateral - uint128(negativepnl);
    }

    function isPayoffAvailable(
        uint256 positionID,
        address caller,
        address recipient
    ) external view override(HegicStrategy) returns (bool) {
        if (pool.manager().ownerOf(positionID) != recipient) return false;
        if (block.timestamp < positionExpiration[positionID]) {
            return
                hasRole(EXERCISER_ROLE, caller) &&
                _calculateStrategyPayOff(positionID) > 0;
        }
        return true;
    }

    function _create(
        uint256 id,
        address, /*holder*/
        uint256 amount,
        uint256 period,
        bytes[] calldata additional
    )
        internal
        virtual
        override
        returns (
            uint32 expiration,
            uint256 negativePNL,
            uint256 positivePNL
        )
    {
        (negativePNL, positivePNL) = calculateNegativepnlAndPositivepnl(
            amount,
            period,
            additional
        );
        positionExpiration[id] = uint32(block.timestamp + period);
        uint256 strike = _currentPrice();
        strategyData[id] = StrategyData(uint128(amount), uint128(strike));
        expiration = uint32(block.timestamp + 90 days);
    }

    function payOffAmount(uint256 optionID)
        external
        view
        override(HegicStrategy)
        returns (uint256 amount)
    {
        (, , uint128 negativepnl, uint128 positivepnl, ) = pool.lockedLiquidity(
            optionID
        );
        if (block.timestamp > positionExpiration[optionID])
            return uint256(positivepnl + negativepnl);
        return
            uint256(positivepnl + negativepnl) -
            _calculateStrategyPayOff(optionID);
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICoverPool.sol";
import "./PositionsManager/IPositionsManager.sol";
import "./Strategies/IHegicStrategy.sol";

interface IOperationalTreasury {
    enum LockedLiquidityState {
        Unlocked,
        Locked
    }

    event Expired(uint256 indexed id);
    event Paid(uint256 indexed id, address indexed account, uint256 amount);
    event Replenished(uint256 amount);

    struct LockedLiquidity {
        LockedLiquidityState state;
        IHegicStrategy strategy;
        uint128 negativepnl;
        uint128 positivepnl;
        uint32 expiration;
    }

    function coverPool() external view returns (ICoverPool);

    function manager() external view returns (IPositionsManager);

    function token() external view returns (IERC20);

    function payOff(uint256 positionID, address account) external;

    function lockedByStrategy(IHegicStrategy strategy)
        external
        view
        returns (uint256 lockedAmount);

    function buy(
        IHegicStrategy strategy,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] calldata additional
    ) external;

    function totalBalance() external view returns (uint256);

    function lockedPremium() external view returns (uint256);

    function benchmark() external view returns (uint256);

    function totalLocked() external view returns (uint256);

    function lockedLiquidity(uint256 id)
        external
        view
        returns (
            LockedLiquidityState state,
            IHegicStrategy strategy,
            uint128 negativepnl,
            uint128 positivepnl,
            uint32 expiration
        );

    /**
     * @notice  Used for unlocking
     * liquidity after an expiration
     * @param lockedLiquidityID The option contract ID
     **/
    function unlock(uint256 lockedLiquidityID) external;
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../IOperationalTreasury.sol";
import "./IHegicStrategy.sol";
import "./LimitController.sol";

import "@hegic/v8888/contracts/Interfaces/IPremiumCalculator.sol";

abstract contract HegicStrategy is
    AccessControl,
    IHegicStrategy,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    IOperationalTreasury public pool;
    AggregatorV3Interface public immutable priceProvider;
    LimitController public limitController;
    uint256 public override lockedLimit;
    IPremiumCalculator public pricer;
    uint256 internal immutable spotDecimals; // 1e18 for ETH | 1e8 for BTC

    uint32 internal constant TOKEN_DECIMALS = 1e6;
    uint32 private constant K_DECIMALS = 100;
    uint48 public k = 100;
    uint48 public minPeriod;
    uint48 public maxPeriod;
    uint48 public immutable exerciseWindowDuration;

    mapping(uint256 => StrategyData) public override strategyData;
    mapping(uint256 => uint32) public override positionExpiration;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 limit,
        uint8 _spotDecimals,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        pricer = _pricer;
        priceProvider = _priceProvider;
        lockedLimit = limit;
        spotDecimals = 10**_spotDecimals;
        minPeriod = periodLimits[0];
        maxPeriod = periodLimits[1];
        exerciseWindowDuration = _exerciseWindowDuration == 0
            ? type(uint48).max
            : _exerciseWindowDuration;
        limitController = _limitController;
    }

    function create(
        uint256 id,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] calldata additional
    )
        external
        override
        returns (
            uint32 expiration,
            uint256 negativePNL,
            uint256 positivePNL
        )
    {
        require(
            msg.sender == address(pool),
            "Only OperationalTresuary pool can execute this function"
        );

        (expiration, negativePNL, positivePNL) = _create(
            id,
            holder,
            amount,
            period,
            additional
        );

        require(
            pool.lockedByStrategy(this) + negativePNL <= lockedLimit &&
                pool.totalLocked() + negativePNL <= limitController.limit(),
            "HegicStrategy: The limit is exceeded"
        );

        emit Acquired(
            id,
            strategyData[id],
            negativePNL,
            positivePNL,
            period,
            additional
        );
    }

    function _create(
        uint256 id,
        address, /*holder*/
        uint256 amount,
        uint256 period,
        bytes[] calldata additional
    )
        internal
        virtual
        returns (
            uint32 lockDuration,
            uint256 negativePNL,
            uint256 positivePNL
        )
    {
        require(minPeriod <= period && period <= maxPeriod, "Period is wrong");
        (negativePNL, positivePNL) = calculateNegativepnlAndPositivepnl(
            amount,
            period,
            additional
        );
        lockDuration = uint32(block.timestamp + period);
        positionExpiration[id] = lockDuration;
        uint256 strike = _currentPrice();
        strategyData[id] = StrategyData(uint128(amount), uint128(strike));
    }

    function connect() external override {
        IOperationalTreasury _pool = IOperationalTreasury(msg.sender);
        address limitPool = address(limitController.operationalTreasury());
        require(
            limitPool == address(0) || limitPool == msg.sender,
            "OperationalTreasury only"
        );
        require(address(pool) == address(0), "The strategy was inited");
        pool = _pool;
    }

    /**
     * @notice Used for viewing the total liquidity
     * locked up for a specific options strategy
     **/
    function getLockedByStrategy()
        external
        view
        override
        returns (uint256 amount)
    {
        return pool.lockedByStrategy(this);
    }

    function setPricer(IPremiumCalculator value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pricer = value;
    }

    /**
     * @notice Used for setting a limit
     * on the total locked liquidity
     * @param value The maximum locked liquidity
     **/
    function setLimit(uint256 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockedLimit = value;
        emit SetLimit(value);
    }

    /**
     * @notice Used for setting the collateralization coefficient
     * @param value The collateralization coefficient
     **/
    function setK(uint48 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        k = value;
    }

    function setLimitController(LimitController value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        limitController = value;
    }

    /**
     * TODO
     **/
    function getAvailableContracts(uint32 period, bytes[] calldata additional)
        external
        view
        override
        returns (uint256 available)
    {
        uint256 limit;
        uint256 operationalLocked = pool.totalLocked();

        {
            uint256 coverBalance = pool.coverPool().availableForPayment();
            uint256 operationalTotal = pool.totalBalance();
            uint256 operationalPremium = pool.lockedPremium();
            if (
                coverBalance + operationalTotal <
                operationalLocked + operationalPremium
            ) {
                return 0;
            }
            limit =
                coverBalance +
                operationalTotal -
                operationalLocked -
                operationalPremium;
        }
        {
            uint256 lockedByStrategy = pool.lockedByStrategy(this);
            if (lockedLimit < lockedByStrategy) return 0;
            if (limit > lockedLimit - lockedByStrategy)
                limit = lockedLimit - lockedByStrategy;
        }
        {
            uint256 totalLimitation = limitController.limit();
            if (totalLimitation < operationalLocked) return 0;
            if (limit > totalLimitation - operationalLocked)
                limit = totalLimitation - operationalLocked;
        }
        (uint256 lockedAmount, ) = calculateNegativepnlAndPositivepnl(
            spotDecimals,
            period,
            additional
        );

        return (limit * spotDecimals) / lockedAmount;
    }

    /**
     * TODO
     **/

    function isPayoffAvailable(
        uint256 positionID,
        address caller,
        address /*recipient*/
    ) external view virtual override returns (bool) {
        return
            pool.manager().isApprovedOrOwner(caller, positionID) &&
            _calculateStrategyPayOff(positionID) > 0 &&
            positionExpiration[positionID] <
            block.timestamp + exerciseWindowDuration;
    }

    function setPeriodLimits(uint48[2] calldata periodLimits)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minPeriod = periodLimits[0];
        maxPeriod = periodLimits[1];
    }

    function _calculateCollateral(uint256 amount, uint256 period)
        internal
        view
        virtual
        returns (uint128 lockedAmount)
    {
        return
            uint128(
                (pricer.calculatePremium(uint32(period), uint128(amount), 0) *
                    k) / K_DECIMALS
            );
    }

    function _calculateStrategyPremium(uint256 amount, uint256 period)
        internal
        view
        returns (uint128 premium)
    {
        premium = uint128(pricer.calculatePremium(period, amount, 0));
    }

    function calculateNegativepnlAndPositivepnl(
        uint256 amount,
        uint256 period,
        bytes[] calldata /*additional*/
    )
        public
        view
        virtual
        override
        returns (uint128 negativepnl, uint128 positivepnl)
    {
        negativepnl = _calculateCollateral(amount, period);
        positivepnl = _calculateStrategyPremium(amount, period);
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Used for calculating the holder's
     * option/strategy unrealized profits
     * @param optionID The option/strategy ID
     * @param profit The unrealized profits amount
     **/
    function payOffAmount(uint256 optionID)
        external
        view
        virtual
        override
        returns (uint256 profit)
    {
        return _calculateStrategyPayOff(optionID);
    }

    function _currentPrice() internal view returns (uint256 price) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        price = uint256(latestPrice);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@hegic/utils/contracts/IERC721WithURIBuilder.sol";

/**
 * @notice The interface for the contract
 *   that tokenizes options as ERC721.
 **/
interface IPositionsManager is IERC721WithURIBuilder {
    /**
     * @param holder The option buyer address
     **/
    function createOptionFor(address holder) external returns (uint256);

    /**
     * @param tokenId The ERC721 token ID linked to the option
     **/
    function tokenPool(uint256 tokenId) external returns (address pool);
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

interface IHegicStrategy {
    event SetLimit(uint256 limit);

    event Acquired(
        uint256 indexed id,
        StrategyData data,
        uint256 negativepnl,
        uint256 positivepnl,
        uint256 period,
        bytes[] additional
    );

    struct StrategyData {
        uint128 amount;
        uint128 strike;
    }

    function strategyData(uint256 strategyID)
        external
        view
        returns (uint128 amount, uint128 strike);

    function getLockedByStrategy() external view returns (uint256 amount);

    function lockedLimit() external view returns (uint256 value);

    function isPayoffAvailable(
        uint256 optID,
        address caller,
        address recipient
    ) external view returns (bool);

    function getAvailableContracts(uint32 period, bytes[] calldata additional)
        external
        view
        returns (uint256 available);

    function payOffAmount(uint256 optionID)
        external
        view
        returns (uint256 profit);

    function calculateNegativepnlAndPositivepnl(
        uint256 amount,
        uint256 period,
        bytes[] calldata
    ) external view returns (uint128 negativepnl, uint128 positivepnl);

    function create(
        uint256 id,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] calldata
    )
        external
        returns (
            uint32 expiration,
            uint256 positivePNL,
            uint256 negativePNL
        );

    function connect() external;

    function positionExpiration(uint256)
        external
        view
        returns (uint32 timestamp);
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../IOperationalTreasury.sol";

contract LimitController is AccessControl {
    uint256 internal _limit = type(uint256).max;
    IOperationalTreasury public operationalTreasury;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setLimit(uint256 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _limit = value;
    }

    function setOperationalTreasury(IOperationalTreasury value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        operationalTreasury = value;
    }

    function limit() external view returns (uint256) {
        if (operationalTreasury == IOperationalTreasury(address(0))) {
            return _limit;
        }
        uint256 operationalTreasuryLimit = operationalTreasury.totalBalance() -
            operationalTreasury.totalLocked() -
            operationalTreasury.lockedPremium();
        return
            _limit < operationalTreasuryLimit
                ? _limit
                : operationalTreasuryLimit;
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./HegicInverseStrategy.sol";

import "@hegic/utils/contracts/Math.sol";

contract HegicStrategyInverseLongButterfly is HegicInverseStrategy {
    uint256 public immutable strikePercentage;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint256 percentage,
        uint48[2] memory periodLimits,
        LimitController _limitController
    )
        HegicInverseStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _limitController
        )
    {
        strikePercentage = percentage;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        uint256 currentPrice = _currentPrice();
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = uint256(data.strike);
        require(currentPrice != data.strike, "Invalid strike = Current price");
        uint256 OTM_CALLStrike = ((ATMStrike * (100 + strikePercentage)) / 100);
        uint256 OTM_PUTStrike = ((ATMStrike * (100 - strikePercentage)) / 100);
        if (currentPrice > ATMStrike) {
            if (currentPrice <= OTM_CALLStrike) {
                return
                    ((currentPrice - ATMStrike) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            } else if (currentPrice > OTM_CALLStrike) {
                return
                    ((OTM_CALLStrike - ATMStrike) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            }
        } else if (currentPrice < ATMStrike) {
            if (currentPrice > OTM_PUTStrike) {
                return
                    ((ATMStrike - currentPrice) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            } else if (currentPrice <= OTM_PUTStrike) {
                return
                    ((ATMStrike - OTM_PUTStrike) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            }
        }
    }

    function _calculateCollateral(
        uint256 amount,
        uint256 /*period*/
    ) internal view override returns (uint128 collateral) {
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = _currentPrice();
        uint256 OTM_CALLStrike = ((ATMStrike * (100 + strikePercentage)) / 100);
        uint256 OTM_PUTStrike = ((ATMStrike * (100 - strikePercentage)) / 100);
        uint256 CALLProfit = ((OTM_CALLStrike - ATMStrike) *
            amount *
            TOKEN_DECIMALS) /
            spotDecimals /
            priceDecimals;
        uint256 PUTProfit = ((ATMStrike - OTM_PUTStrike) *
            amount *
            TOKEN_DECIMALS) /
            spotDecimals /
            priceDecimals;
        if (CALLProfit > PUTProfit) {
            return uint128(CALLProfit);
        } else {
            return uint128(PUTProfit);
        }
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./HegicInverseStrategy.sol";

import "@hegic/utils/contracts/Math.sol";

contract HegicStrategyInverseBullPutSpread is HegicInverseStrategy {
    uint256 public immutable strikePercentage;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint256 percentage,
        uint48[2] memory periodLimits,
        LimitController _limitController
    )
        HegicInverseStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _limitController
        )
    {
        strikePercentage = percentage;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        uint256 currentPrice = _currentPrice();
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = uint256(data.strike);
        require(currentPrice != data.strike, "Invalid strike = Current price");
        uint256 OTMStrike = ((ATMStrike * strikePercentage) / 100);
        if (currentPrice < ATMStrike) {
            if (currentPrice > OTMStrike) {
                return
                    ((ATMStrike - currentPrice) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            } else if (currentPrice <= OTMStrike) {
                return
                    ((ATMStrike - OTMStrike) * data.amount * TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            }
        } else {
            return 0;
        }
    }

    function _calculateCollateral(
        uint256 amount,
        uint256 /*period*/
    ) internal view override returns (uint128 collateral) {
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = _currentPrice();
        uint256 OTMStrike = ((ATMStrike * strikePercentage) / 100);
        return
            uint128(
                ((ATMStrike - OTMStrike) * amount * TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals
            );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./HegicInverseStrategy.sol";
import "@hegic/utils/contracts/Math.sol";

contract HegicStrategyInverseBearCallSpread is HegicInverseStrategy {
    uint256 public immutable strikePercentage;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint256 percentage,
        uint48[2] memory periodLimits,
        LimitController _limitController
    )
        HegicInverseStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _limitController
        )
    {
        strikePercentage = percentage;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        uint256 currentPrice = _currentPrice();
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = uint256(data.strike);
        require(currentPrice != data.strike, "Invalid strike = Current price");
        uint256 OTMStrike = ((ATMStrike * strikePercentage) / 100);
        if (currentPrice > ATMStrike) {
            if (currentPrice < OTMStrike) {
                return
                    ((currentPrice - ATMStrike) *
                        data.amount *
                        TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            } else if (currentPrice >= OTMStrike) {
                return
                    ((OTMStrike - ATMStrike) * data.amount * TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals;
            }
        } else {
            return 0;
        }
    }

    function _calculateCollateral(
        uint256 amount,
        uint256 /*period*/
    ) internal view override returns (uint128 collateral) {
        uint256 priceDecimals = 10**priceProvider.decimals();
        uint256 ATMStrike = _currentPrice();
        uint256 OTMStrike = ((ATMStrike * strikePercentage) / 100);
        return
            uint128(
                ((OTMStrike - ATMStrike) * amount * TOKEN_DECIMALS) /
                    spotDecimals /
                    priceDecimals
            );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceProviderMock is AggregatorV3Interface {
    uint256 public price;
    uint8 public immutable override decimals;
    string public override description = "Test implementatiln";
    uint256 public override version = 0;

    constructor(uint256 _price, uint8 _decimals) {
        price = _price;
        decimals = _decimals;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function getRoundData(uint80)
        external
        pure
        override
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        revert("Test implementation");
    }

    function latestAnswer() external view returns (int256 result) {
        (, result, , , ) = latestRoundData();
    }

    function latestRoundData()
        public
        view
        override
        returns (
            uint80,
            int256 answer,
            uint256,
            uint256,
            uint80
        )
    {
        answer = int256(price);
        return (0, answer, 0, 0, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@hegic/utils/contracts/Mocks/PriceProviderMock.sol';

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ProfitCalculator.sol";
import "./HegicStrategy.sol";

contract HegicStrategyStrip is HegicStrategy {
    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {}

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];

        uint256 currentPrice = _currentPrice();

        return
            currentPrice < data.strike
                ? ProfitCalculator.calculatePutProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                ) * 2
                : ProfitCalculator.calculateCallProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

library ProfitCalculator {
    function calculatePutProfit(
        uint256 strike,
        uint256 currentPrice,
        uint256 amount,
        uint256 tokenDen,
        uint256 spotDen,
        uint256 priceDen
    ) public pure returns (uint256) {
        if (currentPrice > strike) return 0;
        return
            ((strike - currentPrice) * amount * tokenDen) / spotDen / priceDen;
    }

    function calculateCallProfit(
        uint256 strike,
        uint256 currentPrice,
        uint256 amount,
        uint256 tokenDen,
        uint256 spotDen,
        uint256 priceDen
    ) public pure returns (uint256) {
        if (currentPrice < strike) return 0;
        return
            ((currentPrice - strike) * amount * tokenDen) / spotDen / priceDen;
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ProfitCalculator.sol";
import "./HegicStrategy.sol";

contract HegicStrategyStrap is HegicStrategy {
    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {}

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];

        uint256 currentPrice = _currentPrice();

        return
            currentPrice < data.strike
                ? ProfitCalculator.calculatePutProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                )
                : ProfitCalculator.calculateCallProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                ) * 2;
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ProfitCalculator.sol";
import "./HegicStrategy.sol";

contract HegicStrategyStrangle is HegicStrategy {
    uint16 private constant PRICE_SCALE_DENOMINATOR = 1e4;
    uint16 private immutable PRICE_SCALE_NUMERATOR;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint16 _priceScale,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {
        PRICE_SCALE_NUMERATOR = _priceScale;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        uint256 currentPrice = _currentPrice();

        uint256 callStrike = (data.strike *
            (PRICE_SCALE_DENOMINATOR + PRICE_SCALE_NUMERATOR)) /
            PRICE_SCALE_DENOMINATOR;
        uint256 putStrike = (data.strike *
            (PRICE_SCALE_DENOMINATOR - PRICE_SCALE_NUMERATOR)) /
            PRICE_SCALE_DENOMINATOR;

        return
            currentPrice < data.strike
                ? ProfitCalculator.calculatePutProfit(
                    putStrike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                )
                : ProfitCalculator.calculateCallProfit(
                    callStrike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ProfitCalculator.sol";
import "./HegicStrategy.sol";

contract HegicStrategyStraddle is HegicStrategy {
    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {}

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];

        uint256 currentPrice = _currentPrice();

        return
            currentPrice < data.strike
                ? ProfitCalculator.calculatePutProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                )
                : ProfitCalculator.calculateCallProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ProfitCalculator.sol";
import "./HegicStrategy.sol";

contract HegicStrategySpreadPut is HegicStrategy {
    uint16 private constant PRICE_SCALE_DENOMINATOR = 1e4;
    uint16 private immutable PRICE_SCALE_NUMERATOR;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint16 _priceScale,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {
        PRICE_SCALE_NUMERATOR = _priceScale;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];

        uint256 otmStrike = (data.strike *
            (PRICE_SCALE_DENOMINATOR - PRICE_SCALE_NUMERATOR)) /
            PRICE_SCALE_DENOMINATOR;

        uint256 currentPrice = _currentPrice();

        return
            currentPrice < otmStrike
                ? ProfitCalculator.calculatePutProfit(
                    data.strike,
                    otmStrike,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                )
                : ProfitCalculator.calculatePutProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ProfitCalculator.sol";
import "./HegicStrategy.sol";

contract HegicStrategySpreadCall is HegicStrategy {
    uint16 private constant PRICE_SCALE_DENOMINATOR = 1e4;
    uint16 private immutable PRICE_SCALE_NUMERATOR;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint16 _priceScale,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {
        PRICE_SCALE_NUMERATOR = _priceScale;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];

        uint256 otmStrike = (data.strike *
            (PRICE_SCALE_DENOMINATOR + PRICE_SCALE_NUMERATOR)) /
            PRICE_SCALE_DENOMINATOR;

        uint256 currentPrice = _currentPrice();

        return
            currentPrice > otmStrike
                ? ProfitCalculator.calculateCallProfit(
                    data.strike,
                    otmStrike,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                )
                : ProfitCalculator.calculateCallProfit(
                    data.strike,
                    currentPrice,
                    data.amount,
                    TOKEN_DECIMALS,
                    spotDecimals,
                    10**priceProvider.decimals()
                );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./HegicStrategy.sol";
import "./ProfitCalculator.sol";

contract HegicStrategyPut is HegicStrategy {
    uint16 private constant PRICE_SCALE_DENOMINATOR = 1e4;
    uint16 private immutable PRICE_SCALE_NUMERATOR;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint16 _priceScale,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {
        PRICE_SCALE_NUMERATOR = _priceScale;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        return
            ProfitCalculator.calculatePutProfit(
                (data.strike * PRICE_SCALE_NUMERATOR) / PRICE_SCALE_DENOMINATOR,
                _currentPrice(),
                data.amount,
                TOKEN_DECIMALS,
                spotDecimals,
                10**priceProvider.decimals()
            );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ProfitCalculator.sol";
import "./HegicStrategy.sol";

contract HegicStrategyCall is HegicStrategy {
    uint16 private constant PRICE_SCALE_DENOMINATOR = 1e4;
    uint16 private immutable PRICE_SCALE_NUMERATOR;

    constructor(
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint256 _limit,
        uint8 _spotDecimals,
        uint16 _priceScale,
        uint48[2] memory periodLimits,
        uint48 _exerciseWindowDuration,
        LimitController _limitController
    )
        HegicStrategy(
            _priceProvider,
            _pricer,
            _limit,
            _spotDecimals,
            periodLimits,
            _exerciseWindowDuration,
            _limitController
        )
    {
        PRICE_SCALE_NUMERATOR = _priceScale;
    }

    function _calculateStrategyPayOff(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        return
            ProfitCalculator.calculateCallProfit(
                (data.strike * PRICE_SCALE_NUMERATOR) / PRICE_SCALE_DENOMINATOR,
                _currentPrice(),
                data.amount,
                TOKEN_DECIMALS,
                spotDecimals,
                10**priceProvider.decimals()
            );
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PositionsManager/IPositionsManager.sol";
import "./IOperationalTreasury.sol";
import "./ICoverPool.sol";

contract OperationalTreasury is
    IOperationalTreasury,
    AccessControl,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    IERC20 public immutable override token;
    IPositionsManager public immutable override manager;
    ICoverPool public immutable override coverPool;
    mapping(uint256 => LockedLiquidity) public override lockedLiquidity;
    mapping(IHegicStrategy => uint256) public override lockedByStrategy;
    mapping(IHegicStrategy => bool) public acceptedStrategy;
    mapping(IHegicStrategy => uint256) public mayBeAcceptedAtEpoch;

    uint256 public override benchmark;

    uint256 public override lockedPremium;
    uint256 public override totalLocked;
    uint256 public immutable maxLockupPeriod;

    constructor(
        IERC20 _token,
        IPositionsManager _manager,
        uint256 _maxLockupPeriod,
        ICoverPool _coverPool,
        uint256 _benchmark,
        IHegicStrategy[] memory initialStrategies
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = _token;
        manager = _manager;
        maxLockupPeriod = _maxLockupPeriod;
        coverPool = _coverPool;
        benchmark = _benchmark;
        for (uint256 i = 0; i < initialStrategies.length; i++)
            _connect(initialStrategies[i]);
    }

    /**
     * @notice Used for buying options/strategies
     * @param holder The holder address
     * @param period The option/strategy period
     * @param amount The option/strategy amount
     * @param additional TODO
     **/
    function buy(
        IHegicStrategy strategy,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] calldata additional
    ) external override nonReentrant {
        uint256 optionID = manager.createOptionFor(holder);
        (uint32 expiration, uint256 negativePNL, uint256 positivePNL) = strategy
            .create(optionID, holder, amount, period, additional);
        _lockLiquidity(
            strategy,
            optionID,
            uint128(negativePNL),
            uint128(positivePNL),
            expiration
        );
    }

    /**
     * @notice Used for locking liquidity in an active options strategy
     * @param optionID TODO
     * @param negativepnl The amount of options strategy contract
     * @param expiration The options strategy expiration time
     **/
    function _lockLiquidity(
        IHegicStrategy strategy,
        uint256 optionID,
        uint128 negativepnl,
        uint128 positivepnl,
        uint32 expiration
    ) internal {
        require(acceptedStrategy[strategy], "Wrong strategy");

        totalLocked += negativepnl;
        lockedPremium += positivepnl;

        require(
            totalLocked + lockedPremium <=
                totalBalance() + coverPool.availableForPayment(),
            "The negative pnl amount is too large"
        );
        require(
            block.timestamp + maxLockupPeriod >= expiration,
            "The period is too long"
        );

        lockedByStrategy[strategy] += negativepnl;
        lockedLiquidity[optionID] = LockedLiquidity(
            LockedLiquidityState.Locked,
            strategy,
            negativepnl,
            positivepnl,
            expiration
        );

        token.safeTransferFrom(msg.sender, address(this), positivepnl);
    }

    /**
     * @notice Used for unlocking liquidity after an expiration
     * @param lockedLiquidityID The option contract ID
     **/
    function unlock(uint256 lockedLiquidityID) public virtual override {
        LockedLiquidity storage ll = lockedLiquidity[lockedLiquidityID];
        require(
            block.timestamp > ll.expiration,
            "The expiration time has not yet come"
        );
        _unlock(ll);
        emit Expired(lockedLiquidityID);
    }

    /**
     * @notice Used for paying off the profits
     * if an option is exercised in-the-money
     * @param positionID The option contract ID
     **/
    function payOff(uint256 positionID, address account)
        external
        override
        nonReentrant
    {
        LockedLiquidity storage ll = lockedLiquidity[positionID];
        uint256 amount = ll.strategy.payOffAmount(positionID);
        require(
            ll.expiration > block.timestamp,
            "The option has already expired"
        );
        require(
            ll.strategy.isPayoffAvailable(positionID, msg.sender, account),
            "You can not execute this option strat"
        );

        _unlock(ll);
        if (totalBalance() < amount) {
            _replenish(amount);
        }
        _withdraw(account, amount);
        emit Paid(positionID, account, amount);
    }

    /**
     * @notice Used for setting the initial
     * contract benchmark for calculating
     * future profits or losses
     * @param value The benchmark value
     **/
    function setBenchmark(uint256 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        benchmark = value;
    }

    /**
     * @notice Used for withdrawing deposited
     * tokens from the contract
     * @param to The recipient address
     * @param amount The amount to withdraw
     **/
    function withdraw(address to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _withdraw(to, amount);
    }

    /**replenish
     * @notice Used for replenishing of
     * the Hegic Operational Treasury contract
     **/
    function replenish() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _replenish(0);
    }

    function addStrategy(IHegicStrategy s)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            mayBeAcceptedAtEpoch[s] == 0,
            "Strategy has already been added"
        );
        uint256 currentEpoch = coverPool.currentEpoch();
        (uint256 epochStart, , , , , ) = coverPool.epoch(currentEpoch);
        uint8 delay = block.timestamp - epochStart > 7 days ? 2 : 1;
        mayBeAcceptedAtEpoch[s] = coverPool.currentEpoch() + delay;
    }

    function connectStrategy(IHegicStrategy s)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 currentEpoch = coverPool.currentEpoch();
        require(
            mayBeAcceptedAtEpoch[s] > 0,
            "You should add the strategy before"
        );
        require(mayBeAcceptedAtEpoch[s] <= currentEpoch, "Wait for next epoch");
        _connect(s);
    }

    function totalBalance() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function _unlock(LockedLiquidity storage ll) internal {
        require(
            ll.state == LockedLiquidityState.Locked,
            "The liquidity has already been unlocked"
        );
        ll.state = LockedLiquidityState.Unlocked;
        totalLocked -= ll.negativepnl;
        lockedPremium -= ll.positivepnl;
        lockedByStrategy[ll.strategy] -= ll.negativepnl;
    }

    function _replenish(uint256 additionalAmount) internal {
        uint256 transferAmount = benchmark +
            additionalAmount +
            lockedPremium -
            totalBalance();
        coverPool.payOut(transferAmount);
        emit Replenished(transferAmount);
    }

    function _withdraw(address to, uint256 amount) internal {
        require(
            amount + totalLocked + lockedPremium <=
                totalBalance() + coverPool.availableForPayment(),
            "The amount to withdraw is too large"
        );
        if (amount > 0) token.safeTransfer(to, amount);
    }

    function _connect(IHegicStrategy s) internal {
        s.connect();
        acceptedStrategy[s] = true;
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 __decimals
    ) ERC20(name, symbol) {
        _decimals = __decimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@hegic/utils/contracts/Mocks/ERC20Mock.sol';

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProfitDistributor is AccessControl {
    using SafeERC20 for IERC20;

    struct ProfitRecipient {
        address account;
        uint32 share;
    }

    IERC20 immutable USDC;
    ProfitRecipient[] public recipients;

    uint256 constant TOTAL_SHARE_SUM = 1e9;
    uint8 constant MAX_RECIPIENTS_COUNT = 20;

    constructor(IERC20 _USDC) {
        USDC = _USDC;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function distributeProfit() external {
        require(_checkRecipientsArray(recipients), "Wrong recipients list");

        uint256 amount = USDC.balanceOf(address(this));
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 transferAmount = (amount * recipients[i].share) /
                TOTAL_SHARE_SUM;
            if (transferAmount > 0)
                USDC.safeTransfer(recipients[i].account, transferAmount);
        }
    }

    function setProfitRecipients(ProfitRecipient[] calldata _recipients)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_checkRecipientsArray(_recipients), "Wrong recipients list");
        delete recipients;

        for (uint256 i = 0; i < _recipients.length; i++) {
            recipients.push(_recipients[i]);
        }
    }

    function _checkRecipientsArray(ProfitRecipient[] memory _recipients)
        internal
        pure
        returns (bool)
    {
        uint256 summary = 0;

        if (_recipients.length > MAX_RECIPIENTS_COUNT) return false;
        for (uint256 i = 0; i < _recipients.length; i++) {
            summary += _recipients[i].share;
        }
        return summary == TOTAL_SHARE_SUM;
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MainPool is AccessControl {
    IERC20 immutable USDC;

    constructor(IERC20 _USDC) {
        USDC = _USDC;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/
import "./IHegicStrategy.sol";

interface IHegicInverseStrategy is IHegicStrategy {
    function positionExpiration(uint256)
        external
        view
        returns (uint32 timestamp);
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./IPositionsManager.sol";
import "@hegic/utils/contracts/ERC721WithURIBuilder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Positions Manager Contract
 * @notice The contract that buys the options contracts for the options holders
 * as well as checks whether the contract that is used for buying/exercising
 * options has been been granted with the permission to do it on the user's behalf.
 **/

contract PositionsManager is
    AccessControl,
    ERC721WithURIBuilder("Hegic Herge Options & Strategies", "HEGOPS"),
    IPositionsManager
{
    bytes32 public constant HEGIC_POOL_ROLE = keccak256("HEGIC_POOL_ROLE");
    uint256 public nextTokenId = 0;
    mapping(uint256 => address) public override tokenPool;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createOptionFor(address holder)
        public
        override
        onlyRole(HEGIC_POOL_ROLE)
        returns (uint256 id)
    {
        id = nextTokenId++;
        tokenPool[id] = msg.sender;
        _safeMint(holder, id);
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721WithURIBuilder, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IPositionsManager).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@hegic/v8888/contracts/PriceCalculators/PolynomialPriceCalculator.sol';

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "../Interfaces/IPremiumCalculator.sol";
import "./BasePriceCalculator.sol";

contract CombinePriceCalculator is BasePriceCalculator {
    using HegicMath for uint256;

    IPremiumCalculator[2] public basePricers;
    int256[2] public coeficients;
    uint256 internal constant COEFICIENTS_DECIMALS = 1e5;

    constructor(
        IPremiumCalculator[2] memory _basePricers,
        int256[2] memory _coeficients
    ) BasePriceCalculator(_basePricers[0].priceProvider()) {
        basePricers = _basePricers;
        coeficients = _coeficients;
    }

    function setCoefficients(int256[2] memory c)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        coeficients = c;
    }

    function _calculatePeriodFee(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal view virtual override returns (uint256 fee) {
        return
            uint256(
                int256(
                    basePricers[0].calculatePremium(period, amount, strike)
                ) *
                    coeficients[0] +
                    int256(
                        basePricers[1].calculatePremium(period, amount, strike)
                    ) *
                    coeficients[1]
            ) / COEFICIENTS_DECIMALS;
    }

    function _checkParams(
        uint256 period,
        uint256 amount,
        uint256 strike
    )
        internal
        view
        virtual
        override
        returns (
            uint256 _period,
            uint256 _amount,
            uint256 _strike
        )
    {
        if (strike == 0) strike = _currentPrice();
        require(
            strike == _currentPrice(),
            "PriceCalculator: The strike is invalid"
        );
        (_period, _amount, ) = super._checkParams(period, amount, strike);
        _strike = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@hegic/v8888/contracts/PriceCalculators/CombinedPriceCalculator.sol';

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

contract ReinvestmentPool {

}