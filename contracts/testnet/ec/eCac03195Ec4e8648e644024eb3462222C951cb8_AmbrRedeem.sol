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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {
    function burn(address account, uint256 amount) external;
}

// contract takes in pcAMBR and converts to a split between AMBR and ESAMBR.
// All tokens are ERC20.
contract AmbrRedeem {
    bool public redeemEnabled;
    address public gov;
    mapping(address => bool) public admins;
    IMintableERC20 public pcAMBR;
    IMintableERC20 public AMBR;
    IMintableERC20 public esAMBR;

    constructor(
        address _pcAMBR,
        address _AMBR,
        address _ESAMBR,
        address _gov,
        address[] memory _admins
    ) {
        gov = _gov;
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
        pcAMBR = IMintableERC20(_pcAMBR);
        AMBR = IMintableERC20(_AMBR);
        esAMBR = IMintableERC20(_ESAMBR);
        // redeem disabled on deployment
        redeemEnabled = false;
    }

    // MODIFIERS:
    modifier onlyGov() {
        require(msg.sender == gov, "Caller is not gov");
        _;
    }
    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller is not an admin");
        _;
    }

    // PUBLIC FUNCTIONS:
    // redeem pcAMBR for AMBR and ESAMBR
    function redeem(uint256 _amount) public {
        // Check that redeem is enabled

        // Ensure the caller has enough pcAMBR
        require(
            pcAMBR.balanceOf(msg.sender) >= _amount,
            "Insufficient pcAMBR balance"
        );

        // Calculate the amounts of AMBR and esAMBR to give out
        uint256 ambrAmount = (_amount * 60) / 100;
        uint256 esambrAmount = (_amount * 40) / 100;

        // Ensure the contract has enough AMBR and esAMBR
        require(
            AMBR.balanceOf(address(this)) >= ambrAmount,
            "Insufficient AMBR balance, please contact the contract admin"
        );

        require(
            esAMBR.balanceOf(address(this)) >= esambrAmount,
            "Insufficient esAMBR balance, please contact the contract admin"
        );

        // Burn pcAMBR from the sender
        // Requires pcAMBR burner role
        pcAMBR.burn(msg.sender, _amount);

        // Transfer AMBR and esAMBR from the contract to the sender
        AMBR.transfer(msg.sender, ambrAmount);
        esAMBR.transfer(msg.sender, esambrAmount);
    }

    // ADMIN FUNCTIONS:
    function toggleRedeem(bool _redeemEnabled) public onlyAdmin {
        // toggle redeem on/off
        redeemEnabled = _redeemEnabled;
    }

    // function to refill AMBR and ESAMBR balances
    function refill(
        uint256 _ambrAmount,
        uint256 _esambrAmount
    ) public onlyAdmin {
        // ensure the sender has enough AMBR and esAMBR
        require(
            AMBR.balanceOf(msg.sender) >= _ambrAmount,
            "Insufficient AMBR balance"
        );

        require(
            esAMBR.balanceOf(msg.sender) >= _esambrAmount,
            "Insufficient esAMBR balance"
        );

        // transfer AMBR and esAMBR from the sender to the contract
        AMBR.transferFrom(msg.sender, address(this), _ambrAmount);
        esAMBR.transferFrom(msg.sender, address(this), _esambrAmount);
    }

    // function to withdraw AMBR and ESAMBR balances
    function withdraw(
        uint256 _ambrAmount,
        uint256 _esambrAmount
    ) public onlyGov {
        // ensure the contract has enough AMBR and esAMBR
        require(
            AMBR.balanceOf(address(this)) >= _ambrAmount,
            "Insufficient AMBR balance, please contact the contract admin"
        );

        require(
            esAMBR.balanceOf(address(this)) >= _esambrAmount,
            "Insufficient esAMBR balance, please contact the contract admin"
        );

        // transfer AMBR and esAMBR from the contract to the sender
        AMBR.transfer(msg.sender, _ambrAmount);
        esAMBR.transfer(msg.sender, _esambrAmount);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setAdmin(address _admin, bool _isAdmin) external onlyGov {
        admins[_admin] = _isAdmin;
    }
}