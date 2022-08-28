/**
 *Submitted for verification at Arbiscan on 2022-08-27
*/

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/token/ERC20/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File contracts/ERC20/Token.sol
pragma solidity ^0.8.0;
contract Token is ERC20{

    constructor() ERC20("Token", "TK"){

    }

    function mint(uint256 amount, address recipient) external{
        _mint( recipient, amount);
    }
}


// File contracts/LibOrder.sol
pragma solidity ^0.8.0;

library LibOrder{
   
   
    bytes32 constant internal eip712DomainHash = 0xfc93c018bfb4eebf549119e02ea2ca9b4382693560b70ab3e293d5dc2df75291;
    /*
    keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId)"
            ),
            keccak256(bytes("ZigZag")),
            keccak256(bytes("5")),
            uint256(42161)
        )
    ); 
    */

    bytes32 constant internal _EIP712_ORDER_SCHEMA_HASH = 0x0b86e5560a722da94769313c9690e24ca4925d085b3cdbd5a1240ba1bcc92a95;
    //keccak256("Order(address user,address sellToken,address buyToken,address feeRecipientAddress,address relayerAddress,uint256 sellAmount,uint256 buyAmount,uint256 makerVolumeFee,uint256 takerVolumeFee,uint256 gasFee,uint256 expirationTimeSeconds,uint256 salt)")

    enum OrderStatus {
        INVALID,                     // Default value
        INVALID_MAKER_ASSET_AMOUNT,  // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT,  // Order does not have a valid taker asset amount
        FILLABLE,                    // Order is fillable
        EXPIRED,                     // Order has already expired
        FULLY_FILLED,                // Order is fully filled
        CANCELLED                    // Order has been cancelled
    }

   struct Order{
        address user; //address of the Order Creator making the sale
        address sellToken; // address of the Token the Order Creator wants to sell
        address buyToken; // address of the Token the Order Creator wants to receive in return
        address feeRecipientAddress; // address of the protocol owner that recives the fees
        address relayerAddress; // if specified, only the specified address can relay the order. setting it to the zero address will allow anyone to relay
        uint256 sellAmount; // amount of Token that the Order Creator wants to sell
        uint256 buyAmount; // amount of Token that the Order Creator wants to receive in return
        uint256 makerVolumeFee; // Fee taken from an order if it is filled in the maker position
        uint256 takerVolumeFee;// Fee taken from an order if it is filled in the taker position
        uint256 gasFee;// Fee paid by taker Order to cover gas fees each time a transaction is made with this order, taken in the form of the sellToken
        uint256 expirationTimeSeconds; //time after which the order is no longer valid
        uint256 salt; //to further ensure the order hash is unique, could represent the order created time
   }

    struct OrderInfo {
        OrderStatus orderStatus;                    // Status that describes order's validity and fillability.
        bytes32 orderHash;                    // EIP712 typed data hash of the order (see LibOrder.getTypedDataHash).
        uint256 orderBuyFilledAmount;  // Amount of order that has already been filled.
    }

   function getOrderHash(Order memory order) internal pure returns (bytes32){

      
      // Why does this clusterfuck of bad code have to exist?
      // Trying to encode the entire order struct at once leads to a "stack too deep" error,
      // so it has to be split into two pieces to be encoded, then recombined
      bytes memory encodedOrderAbi = bytes.concat(encodeFirstHalfOrderAbi(order), encodeSecondHalfOrderAbi(order));
      bytes32 orderHash = keccak256(encodedOrderAbi);

       
      //return hashEIP712Message(orderHash);
      return keccak256(abi.encodePacked("\x19\x01",eip712DomainHash,orderHash));
   }

   function encodeFirstHalfOrderAbi(Order memory order) internal pure returns (bytes memory){
       return abi.encode(
          _EIP712_ORDER_SCHEMA_HASH,
          order.user,
          order.sellToken,
          order.buyToken,
          order.feeRecipientAddress,
          order.relayerAddress
       );
   }

   function encodeSecondHalfOrderAbi(Order memory order) internal pure returns (bytes memory){
       return abi.encode(
          order.sellAmount,
          order.buyAmount,
          order.makerVolumeFee,
          order.takerVolumeFee,
          order.gasFee,
          order.expirationTimeSeconds,
          order.salt
       );
   }

    function hashEIP712Message( bytes32 hashStruct)
        internal
        pure
        returns (bytes32 result)
    {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}


// File contracts/LibMath.sol
pragma solidity ^0.8.0;


library LibMath{

    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        
        require(!isRoundingErrorFloor(numerator, denominator,target),"floor rounding error >= 0.1%");
        partialAmount = numerator * target/  denominator;
        return partialAmount;
    }

        function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        require(!isRoundingErrorCeil(
                numerator,
                denominator,
                target
        ),"ceil rounding error >= 0.1%") ;

        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator* (target+(denominator-1)) /denominator;

        return partialAmount;
    }

    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {   
        require(denominator != 0,"error denominator is zero");
           if(target == 0 || numerator == 0){
            return false;
        }
        uint256 remainder = mulmod(target,numerator,denominator);
     
        isError = remainder * 1000 >= numerator * target;
        return isError;
    }

     function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
       require(denominator != 0,"error denominator is zero");

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = (denominator - remainder )% denominator;
        isError = remainder * 1000 >= numerator * target;
        return isError;
    }
}


// File contracts/LibFillResults.sol
pragma solidity ^0.8.0;
library LibFillResults {

    struct FillResults {
        uint256 sellFilledAmount;      // The amount sold by the user in the sell token
        uint256 buyFilledAmount;       // The amount received by the user in the buy token
        uint256 feePaid;               // Total amount of fees paid in sell token to feeRecipient(s).
    }

    struct MatchedFillResults {
        FillResults maker;                // Amounts filled and fees paid of maker order.
        FillResults taker;               // Amounts filled and fees paid of taker order.
    }

    function calculateMatchedFillResults(
        LibOrder.Order memory makerOrder,
        LibOrder.Order memory takerOrder,
        uint256 makerOrderBuyFilledAmount,
        uint256 takerOrderBuyFilledAmount
     ) internal pure returns(MatchedFillResults memory matchedFillResults){


        uint256 makerBuyAmountRemaining = makerOrder.buyAmount - makerOrderBuyFilledAmount;
        uint256 makerSellAmountRemaining = LibMath.safeGetPartialAmountFloor(
            makerOrder.sellAmount,
            makerOrder.buyAmount,
            makerBuyAmountRemaining
        );

        uint256 takerBuyAmountRemaining = takerOrder.buyAmount - takerOrderBuyFilledAmount;
        uint256 takerSellAmountRemaining = LibMath.safeGetPartialAmountFloor(
            takerOrder.sellAmount,
            takerOrder.buyAmount,
            takerBuyAmountRemaining
        ) ;

        matchedFillResults = _calculateMatchedFillResultsWithMaximalFill(makerOrder,
            takerOrder,
            makerSellAmountRemaining,
            makerBuyAmountRemaining,
            takerSellAmountRemaining
        );
        

        // Compute fees for maker order
        matchedFillResults.maker.feePaid = LibMath.safeGetPartialAmountFloor(
            matchedFillResults.maker.sellFilledAmount,
            makerOrder.sellAmount,
            makerOrder.makerVolumeFee
        );
        matchedFillResults.taker.feePaid = LibMath.safeGetPartialAmountFloor(
            matchedFillResults.taker.sellFilledAmount,
            takerOrder.sellAmount,
            takerOrder.takerVolumeFee
        );

    }

    function _calculateMatchedFillResultsWithMaximalFill(
        LibOrder.Order memory makerOrder,
        LibOrder.Order memory takerOrder,
        uint256 makerSellAmountRemaining,
        uint256 makerBuyAmountRemaining,
        uint256 takerSellAmountRemaining
    )
        private
        pure
        returns (MatchedFillResults memory matchedFillResults)
    {
        
        // Calculate the maximum fill results for the maker and taker assets. At least one of the orders will be fully filled.
        //
        // The maximum that the maker maker can possibly buy is the amount that the taker order can sell.
        // The maximum that the taker maker can possibly buy is the amount that the maker order can sell.
        //
        // If the maker order is fully filled, profit will be paid out in the maker maker asset. If the taker order is fully filled,
        // the profit will be out in the taker maker asset.
        //
        // There are three cases to consider:
        // Case 1.
        //   If the maker can buy more or the same as the taker can sell, then the taker order is fully filled, but at the price of the maker order.
        // Case 2.
        //   If the taker can buy more or the same as the maker can sell, then the maker order is fully filled, at the price of the maker order.
        // Case 3.
        //   Both orders can be filled fully so we can default to case 2

        if (makerBuyAmountRemaining >= takerSellAmountRemaining) {
            matchedFillResults.maker.buyFilledAmount = takerSellAmountRemaining;
            matchedFillResults.maker.sellFilledAmount = LibMath.safeGetPartialAmountFloor(
                makerOrder.sellAmount,
                makerOrder.buyAmount,
                takerSellAmountRemaining
            );
            matchedFillResults.taker.sellFilledAmount = takerSellAmountRemaining;
            matchedFillResults.taker.buyFilledAmount = matchedFillResults.maker.sellFilledAmount;
        }
        else {
            matchedFillResults.maker.sellFilledAmount = makerSellAmountRemaining;
            matchedFillResults.maker.buyFilledAmount = makerBuyAmountRemaining;
            matchedFillResults.taker.sellFilledAmount = LibMath.safeGetPartialAmountCeil(
                takerOrder.sellAmount,
                takerOrder.buyAmount,
                makerSellAmountRemaining
            );
            matchedFillResults.taker.buyFilledAmount = makerSellAmountRemaining;
        }

        return matchedFillResults;
    }

}


// File contracts/LibBytes.sol
pragma solidity ^0.8.0;

library LibBytes {

    using LibBytes for bytes;

    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(b.length >= index, "BytesLib: length");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }


}


// File contracts/SignatureValidator.sol
pragma solidity ^0.8.0;
contract SignatureValidator{

    using LibOrder for LibOrder.Order;
    using LibBytes for bytes;

    function isValidSignature(LibOrder.Order memory order, bytes memory signature) public pure returns (bool isValid){
        bytes32 orderHash = order.getOrderHash();

        address signerAddress = order.user;

           uint8 v = uint8(signature[0]);
           bytes32 r = signature.readBytes32(1);
           bytes32 s = signature.readBytes32(33);
           address recovered = ecrecover(
                orderHash,
                v,
                r,
                s
            );
           isValid = recovered == signerAddress;
            return isValid;
    }
    
    function _isValidOrderWithHashSignature(bytes32 orderHash, bytes memory signature, address signerAddress) internal pure returns( bool isValid){
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            address recovered = ecrecover(
                    orderHash,
                    v,
                    r,
                    s
                );
            isValid = recovered == signerAddress;
            return isValid;
    }

    // function helper() public pure returns(bytes32 orderhash){
    //     orderhash = keccak256("Order(address makerAddress,address makerToken,address takerToken,address feeRecipientAddress,uint256 makerAssetAmount,uint256 takerAssetAmount,uint256 makerVolumeFee,uint256 takerVolumeFee,uint256 gasFee,uint256 expirationTimeSeconds,uint256 salt)");
    //     return orderhash;
    // }
    
}


// File contracts/Exchange.sol

pragma solidity ^0.8.0;
//import "hardhat/console.sol";

contract Exchange is SignatureValidator{

    using LibOrder for LibOrder.Order;

    mapping (bytes32 => uint256) public filled;

    mapping (bytes32 => bool) public cancelled;

    function cancelOrder(
        LibOrder.Order memory order
    ) public{   

        require(msg.sender == order.user, "only user may cancel order");

        LibOrder.OrderInfo memory orderInfo = getOrderInfo(order);

        cancelled[orderInfo.orderHash] = true;
    }
    
   function matchOrders(
       LibOrder.Order memory makerOrder, 
       LibOrder.Order memory takerOrder,
       bytes memory makerSignature,
       bytes memory takerSignature
   )
   public returns(LibFillResults.MatchedFillResults memory matchedFillResults){

        // check that tokens address match
        require(takerOrder.sellToken == makerOrder.buyToken, "mismatched tokens");
        require(takerOrder.buyToken == makerOrder.sellToken, "mismatched tokens");
  
        // check the relayer field
        require(makerOrder.relayerAddress == address(0) || makerOrder.relayerAddress == msg.sender, "maker relayer mismatch");
        require(takerOrder.relayerAddress == address(0) || takerOrder.relayerAddress == msg.sender, "taker relayer mismatch");

        LibOrder.OrderInfo memory makerOrderInfo = getOrderInfo(makerOrder);
        LibOrder.OrderInfo memory takerOrderInfo = getOrderInfo(takerOrder);
       
     
        require(takerOrderInfo.orderStatus == LibOrder.OrderStatus.FILLABLE, "taker order status not Fillable");
        require(makerOrderInfo.orderStatus == LibOrder.OrderStatus.FILLABLE, "maker order status not Fillable");

        //validate signature
        require(msg.sender == takerOrder.user || _isValidOrderWithHashSignature(takerOrderInfo.orderHash, takerSignature, takerOrder.user), "invalid taker signature");
        require(msg.sender == makerOrder.user || _isValidOrderWithHashSignature(makerOrderInfo.orderHash, makerSignature, makerOrder.user),"invalid maker signature");
        
        // Make sure there is a profitable spread.
        // There is a profitable spread iff the cost per unit bought (OrderA.SellAmount/OrderA.BuyAmount) for each order is greater
        // than the profit per unit sold of the matched order (OrderB.BuyAmount/OrderB.SellAmount).
        // This is satisfied by the equations below:
        // <makerOrder.sellAmount> / <makerOrder.buyAmount> >= <takerOrder.buyAmount> / <takerOrder.sellAmount>
        // AND
        // <takerOrder.sellAmount> / <takerOrder.buyAmount> >= <makerOrder.buyAmount> / <makerOrder.sellAmount>
        // These equations can be combined to get the following:
        require(
            makerOrder.sellAmount * takerOrder.sellAmount >= makerOrder.buyAmount * takerOrder.buyAmount, 
            "not profitable spread"
        );

        matchedFillResults = LibFillResults.calculateMatchedFillResults(
            makerOrder,
            takerOrder,
            makerOrderInfo.orderBuyFilledAmount,
            takerOrderInfo.orderBuyFilledAmount
        );
        
        
        _updateFilledState(
            makerOrderInfo.orderHash,
            matchedFillResults.maker.buyFilledAmount
        );

        _updateFilledState(
            takerOrderInfo.orderHash,
            matchedFillResults.taker.buyFilledAmount
        );

        _settleMatchedOrders(
            makerOrder,
            takerOrder,
            matchedFillResults
        );

        return matchedFillResults;
   }



    function _settleMatchedOrders(
        LibOrder.Order memory makerOrder,
        LibOrder.Order memory takerOrder,
        LibFillResults.MatchedFillResults memory matchedFillResults
    )
    internal{
        require(
            IERC20(takerOrder.sellToken).balanceOf(takerOrder.user) >= matchedFillResults.maker.buyFilledAmount,
            "taker order not enough balance"
        );
        require(
            IERC20(makerOrder.sellToken).balanceOf(makerOrder.user) >= matchedFillResults.taker.buyFilledAmount,
            "maker order not enough balance"
        );
        
        // Right maker asset -> maker maker
        IERC20(takerOrder.sellToken).transferFrom(takerOrder.user, makerOrder.user, matchedFillResults.maker.buyFilledAmount);
       
        // Left maker asset -> taker maker
        IERC20(makerOrder.sellToken).transferFrom(makerOrder.user, takerOrder.user, matchedFillResults.taker.buyFilledAmount);


        /*
            Fees Paid 
        */
        // Taker fee + gas fee -> fee recipient
        uint takerOrderFees = matchedFillResults.taker.feePaid + takerOrder.gasFee;
        if (takerOrderFees > 0) {
            require(
                IERC20(takerOrder.sellToken).balanceOf(takerOrder.user) >= takerOrderFees,
                "taker order not enough balance for fee"
            );
            IERC20(takerOrder.sellToken).transferFrom(takerOrder.user, takerOrder.feeRecipientAddress, takerOrderFees);
        }
       
        // Maker fee -> fee recipient
        if (matchedFillResults.maker.feePaid > 0) {
            require(
                IERC20(makerOrder.sellToken).balanceOf(makerOrder.user) >= matchedFillResults.maker.feePaid,
                "maker order not enough balance for fee"
            );
            IERC20(makerOrder.sellToken).transferFrom(makerOrder.user, makerOrder.feeRecipientAddress, matchedFillResults.maker.feePaid);
        }

    }


    function _updateFilledState(bytes32 orderHash, uint256 orderBuyFilledAmount) internal{
       
        filled[orderHash] += orderBuyFilledAmount;
    }

    function getOrderInfo(LibOrder.Order memory order) public view returns(LibOrder.OrderInfo memory orderInfo){
        (orderInfo.orderHash, orderInfo.orderBuyFilledAmount) = _getOrderHashAndFilledAmount(order);
        
        if (order.sellAmount == 0) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_MAKER_ASSET_AMOUNT;
            return orderInfo;
        }

        if (order.buyAmount == 0) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_TAKER_ASSET_AMOUNT;
            return orderInfo;
        }

        if (orderInfo.orderBuyFilledAmount >= order.buyAmount) {
            orderInfo.orderStatus = LibOrder.OrderStatus.FULLY_FILLED;
            return orderInfo;
        }

       
        if (block.timestamp >= order.expirationTimeSeconds) {
            orderInfo.orderStatus = LibOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        if (cancelled[orderInfo.orderHash]) {
            orderInfo.orderStatus = LibOrder.OrderStatus.CANCELLED;
            return orderInfo;
        }

        orderInfo.orderStatus = LibOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    function _getOrderHashAndFilledAmount(LibOrder.Order memory order)
        internal
        view
        returns (bytes32 orderHash, uint256 orderBuyFilledAmount)
    {
        orderHash = order.getOrderHash();
        orderBuyFilledAmount = filled[orderHash];
        return (orderHash, orderBuyFilledAmount);
    }

}