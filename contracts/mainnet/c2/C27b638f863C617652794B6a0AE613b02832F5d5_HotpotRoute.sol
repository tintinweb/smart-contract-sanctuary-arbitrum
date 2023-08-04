// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
pragma solidity ^0.8.0;

import "./interfaces/IHotpotRoute.sol";
import "./interfaces/IHotpotToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HotpotRoute is IHotpotRoute {
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "expired");
        _;
    }

    function swap(
        address fromTokenAddr,
        address toTokenAddr,
        uint256 amount,
        uint256 minReturn,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        IHotpotToken fromToken = IHotpotToken(fromTokenAddr);
        IHotpotToken toToken = IHotpotToken(toTokenAddr);
        (uint tokenReceived, uint raisingTokenAmount) = getAmountOut(fromTokenAddr, toTokenAddr, amount);
        require(tokenReceived >= minReturn, "can not reach minReturn");
        IERC20(fromTokenAddr).transferFrom(msg.sender, address(this), amount);
        fromToken.burn(address(this), amount, raisingTokenAmount);
        address raisingToken = fromToken.getRaisingToken();
        if (raisingToken != address(0)) {
            IERC20(raisingToken).approve(toTokenAddr, raisingTokenAmount);
        }
        toToken.mint{value: raisingToken == address(0) ? raisingTokenAmount : 0}(
            address(to),
            raisingTokenAmount,
            tokenReceived
        );
    }

    function getAmountOut(
        address fromTokenAddr,
        address toTokenAddr,
        uint256 amount
    ) public view returns (uint256 returnAmount, uint256 raisingTokenAmount) {
        require(
            IHotpotToken(fromTokenAddr).getRaisingToken() == IHotpotToken(toTokenAddr).getRaisingToken(),
            "not the same raising token"
        );
        (, raisingTokenAmount, , ) = IHotpotToken(fromTokenAddr).estimateBurn(amount);
        (returnAmount, , , ) = IHotpotToken(toTokenAddr).estimateMint(raisingTokenAmount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHotpotRoute {
    /**
     * swap `fromToken` to `toToken`, both token must be HotpotToken
     * @param fromTokenAddr the address of `fromToken`
     * @param toTokenAddr the address of `toToken`
     * @param amount  the amount of `fromToken` that want to swap
     * @param minReturn the mininum amount of `toToken` that expect
     * @param to swap to who
     * @param deadline the deadline of transaction
     */
    function swap(
        address fromTokenAddr,
        address toTokenAddr,
        uint256 amount,
        uint256 minReturn,
        address to,
        uint256 deadline
    ) external;

    /**
     * get the amount of `toToken` after swap
     * @param fromTokenAddr the address of `fromToken`
     * @param toTokenAddr the address of `toToken`
     * @param amount  the amount of `fromToken` that want to swap
     * @return returnAmount the amount of `toToken` that will receive
     * @return raisingTokenAmount the amount of `raisingToken` that will use in swap
     */
    function getAmountOut(
        address fromTokenAddr,
        address toTokenAddr,
        uint256 amount
    ) external view returns (uint256 returnAmount, uint256 raisingTokenAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/**
 * @dev Interface of the hotpot swap
 */
interface IHotpotToken is IAccessControlUpgradeable {
    /**
     * @dev Initializes the hotpot token contract.
     * @param bondingCurveAddress Address of the bonding curve contract.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param metadata Metadata URL for the token.
     * @param projectAdmin Address of the project administrator.
     * @param projectTreasury Address of the project treasury.
     * @param projectMintTax Tax rate for project token minting.
     * @param projectBurnTax Tax rate for project token burning.
     * @param raisingTokenAddr Address of the raising token.
     * @param parameters Parameters for the bonding curve contract.
     * @param factory Address of the factory contract.
     */
    function initialize(
        address bondingCurveAddress,
        string memory name,
        string memory symbol,
        string memory metadata,
        address projectAdmin,
        address projectTreasury,
        uint256 projectMintTax,
        uint256 projectBurnTax,
        address raisingTokenAddr,
        bytes memory parameters,
        address factory
    ) external;

    /**
     * @dev Sets the address of the governance contract.
     * @param gov Address of the governance contract.
     */
    function setGov(address gov) external;

    /**
     * @dev Returns the role identifier for the project administrator.
     * @return role identifier for the project administrator.
     */
    function getProjectAdminRole() external pure returns (bytes32 role);

    /**
     * @dev Sets the metadata URL for the token.
     * @param url Metadata URL for the token.
     */
    function setMetadata(string memory url) external;

    /**
     * @dev Returns the metadata URL for the token.
     * @return Metadata URL for the token.
     */
    function getMetadata() external view returns (string memory);

    /**
     * @dev Returns the tax rates for project token minting and burning.
     * @return projectMintRate Tax rate for project token minting
     * @return projectBurnRate Tax rate for project token burning.
     */
    function getTaxRateOfProject() external view returns (uint256 projectMintRate, uint256 projectBurnRate);

    /**
     * @dev Returns the tax rates for platform token minting and burning.
     * @return platformMintTax Tax rate for platform when token minting
     * @return platformBurnTax Tax rate for platform when token burning.
     */
    function getTaxRateOfPlatform() external view returns (uint256 platformMintTax, uint256 platformBurnTax);

    /**
     * @dev Sets the tax rates for project token minting and burning.
     * @param projectMintTax Tax rate for project when token minting.
     * @param projectBurnTax Tax rate for project when token burning.
     */
    function setProjectTaxRate(uint256 projectMintTax, uint256 projectBurnTax) external;

    /**
     * @dev Gets the factory contract address
     * @return Address of the factory contract
     */
    function getFactory() external view returns (address);

    /**
     * @dev Gets the raising token address
     * @return Address of the raising token
     */
    function getRaisingToken() external view returns (address);

    /**
     * @dev Get the current project admin address
     * @return projectAdmin address
     */
    function getProjectAdmin() external view returns (address);

    /**
     * @dev Set a new address as project admin
     * @param newProjectAdmin new address to be set as project admin
     */
    function setProjectAdmin(address newProjectAdmin) external;

    /**
     * @dev Get the current project treasury address
     * @return projectTreasury address
     */
    function getProjectTreasury() external view returns (address);

    /**
     * @dev Set a new address as project treasury
     * @param newProjectTreasury new address to be set as project treasury
     */
    function setProjectTreasury(address newProjectTreasury) external;

    /**
     * @dev Get the current token price
     * @return token price
     */
    function price() external view returns (uint256);

    /**
     * @dev Mint new tokens
     * @param to the address where the new tokens will be sent to
     * @param payAmount the amount of raising token to pay
     * @param minReceive the minimum amount of tokens the buyer wants to receive
     */
    function mint(address to, uint payAmount, uint minReceive) external payable;

    /**
     * @dev Estimate the amount of tokens that will be received from minting, the amount of raising token that will be paid, and the platform and project fees
     * @param payAmount the amount of raising token to pay
     * @return receivedAmount the estimated amount of tokens received
     * @return paidAmount the estimated amount of raising token paid
     * @return platformFee the estimated platform fee
     * @return projectFee the estimated project fee
     */
    function estimateMint(
        uint payAmount
    ) external view returns (uint receivedAmount, uint paidAmount, uint platformFee, uint projectFee);

    /**
     * @dev Estimate the amount of raising token that needs to be paid to receive a specific amount of tokens, and the platform and project fees
     * @param tokenAmountWant the desired amount of tokens
     * @return receivedAmount the estimated amount of tokens received
     * @return paidAmount the estimated amount of raising token paid
     * @return platformFee the estimated platform fee
     * @return projectFee the estimated project fee
     */
    function estimateMintNeed(
        uint tokenAmountWant
    ) external view returns (uint receivedAmount, uint paidAmount, uint platformFee, uint projectFee);

    /**
     * @dev Burn tokens to receive raising token
     * @param to the address where the raising token will be sent to
     * @param payAmount the amount of tokens to burn
     * @param minReceive the minimum amount of raising token the seller wants to receive
     */
    function burn(address to, uint payAmount, uint minReceive) external payable;

    /**
     * @dev Estimate the amount of raising token that will be received from burning tokens, the amount of tokens that need to be burned, and the platform and project fees
     * @param tokenAmount the amount of tokens to burn
     * @return amountNeed the estimated amount of tokens needed to be burned
     * @return amountReturn the estimated amount of raising token received
     * @return platformFee the estimated platform fee
     * @return projectFee the estimated project fee
     */
    function estimateBurn(
        uint tokenAmount
    ) external view returns (uint amountNeed, uint amountReturn, uint platformFee, uint projectFee);

    /**
     *   @dev Pauses the hotpot token contract
     */
    function pause() external;

    /**
     *   @dev Unpauses the hotpot token contract
     */
    function unpause() external;

    /**
     *  @dev Destroys the hotpot token contract for doomsday scenario
     */
    function destroyForDoomsday() external;

    /**
     *   @dev Declares doomsday scenario for the hotpot token contract
     */
    function declareDoomsday() external;
}