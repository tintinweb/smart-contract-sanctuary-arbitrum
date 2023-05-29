// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;
import "./IERC20.sol";

contract BirdFundsHolder {
    event FundHeld(string FundName, uint256 FundNo, address Token, address Receiver, uint256 Amount, uint256 ReleaseTime);
    event FundReleased(uint256 FundNo, address Token, address Receiver, uint256 Amount);
    struct Fund {
        string FundName;
        IERC20 Token;
        address Receiver;
        uint256 TokenAmount;
        uint256 ReleaseTime;
        bool Released;
    }
    string public Name;
    string public Twitter;
    uint256 public NoOfFundsHeld;
    mapping(uint256 => Fund) public FundsHeld;

    constructor() {
        Name = "Bird Funds Holder";
        Twitter = "https://twitter.com/BirdArbitrum";
    }

    function holdFunds(string memory _FundName, address _Token, address _Receiver, uint256 _TokenAmount, uint256 _ReleaseTime) external {
        require(_Token != address(0) && _Receiver != address(0) && _TokenAmount > 0 && _ReleaseTime > block.timestamp,"Fund Initiation Variables Error");
        NoOfFundsHeld++;
        IERC20(_Token).transferFrom(msg.sender, address(this), _TokenAmount);
        FundsHeld[NoOfFundsHeld] = Fund(_FundName, IERC20(_Token), _Receiver, _TokenAmount, _ReleaseTime, false);
        emit FundHeld(_FundName, NoOfFundsHeld, _Token, _Receiver, _TokenAmount, _ReleaseTime);
    }

    function releaseFunds(uint256 fundNo) external {
        Fund memory thisFund = FundsHeld[fundNo];
        require(block.timestamp >= thisFund.ReleaseTime,"Funds not released yet.");
        require(!thisFund.Released,"Funds already released.");
        FundsHeld[fundNo].Released = true;
        thisFund.Token.transfer(thisFund.Receiver, thisFund.TokenAmount);
        emit FundReleased(fundNo, address(thisFund.Token), thisFund.Receiver, thisFund.TokenAmount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}