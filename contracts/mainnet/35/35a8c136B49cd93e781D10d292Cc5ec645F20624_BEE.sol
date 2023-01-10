/**
 *Submitted for verification at Arbiscan on 2023-01-10
*/

/**
 *Submitted for verification at Arbiscan on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract BEE is IERC20 {
    string public name = "BEE";
    string public symbol = "BEE";
    uint8 public decimals = 6;
    uint256 public override totalSupply = 100000000000000;
    uint256 public marketingFee = 4;
    address public marketingWallet = address(0xb8E002A612ca1ff0106329EDb041058360f56A4a);
    address public owner;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    modifier onlyowner {
    require(msg.sender == owner);
    _;
}

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;

        // Check if sender or recipient is the owner
        if (msg.sender == owner || _to == owner || msg.sender == marketingWallet || _to == marketingWallet) {
            balanceOf[_to] = balanceOf[_to] + _value;
        } else {
            // Calculate the amount of tokens to be sent to the marketing wallet
            uint256 valueToMarketingWallet = (_value * marketingFee) / 100;
            // Calculate the amount of tokens to be sent to the recipient
            uint256 valueToRecipient = _value - valueToMarketingWallet;
            balanceOf[_to] = balanceOf[_to] + valueToRecipient;
            balanceOf[marketingWallet] = balanceOf[marketingWallet] + valueToMarketingWallet;
        }

        return true;
    }


    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_value <= balanceOf[_from] && _value <= allowance[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from] - _value;

        // Check if sender or recipient is the owner
        if (_from == owner || _to == owner || _from == marketingWallet || _to == marketingWallet) {
            balanceOf[_to] = balanceOf[_to] + _value;
        } else {
            // Calculate the amount of tokens to be sent to the marketing wallet
            uint256 valueToMarketingWallet = (_value * marketingFee) / 100;
            // Calculate the amount of tokens to be sent to the recipient
            uint256 valueToRecipient = _value - valueToMarketingWallet;
            balanceOf[_to] = balanceOf[_to] + valueToRecipient;
            balanceOf[marketingWallet] = balanceOf[marketingWallet] + valueToMarketingWallet;
        }

        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        return true;
    }


    function increaseAllowance(address _spender, uint _addedValue) public returns (bool success) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender] + _addedValue;
        return true;
    }

    function decreaseAllowance(address _spender, uint _subtractedValue) public returns (bool success) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender] - _subtractedValue;
        return true;
    }
    function transferOwnership(address newOwner) public onlyowner {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function setMarketingWallet(address newMarketingWallet) public onlyowner {
        require(msg.sender == owner);
        marketingWallet = newMarketingWallet;
    }

    function setMarketingFee(uint256 newMarketingFee) public onlyowner {
        require(msg.sender == owner);
        require(newMarketingFee < 30);
        marketingFee = newMarketingFee;
    }
}