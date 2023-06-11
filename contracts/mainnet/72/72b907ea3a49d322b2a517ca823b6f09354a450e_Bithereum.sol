/**
 *Submitted for verification at Arbiscan on 2023-06-11
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: bithereum/bithereum_gpt.sol


pragma solidity ^0.8.0;



// developer: Zhouxingxing

contract BTHErc20 is ERC20 {
    bool private _initialized;
    uint256 private _LimitperBTH;
    uint256 private _cap;
    address public BTHcontract;
    string private _name;
    string private _symbol;

    uint256[] public allOrdinal;
    uint256 public creationOrdinal;

    constructor() ERC20("", "") {
        _initialized = false;
    }

    function initialize(
        string memory tokeName,
        string memory tokenSymbol,
        uint256 decimals,
        uint256 cap,
        uint256 LimitperBTH,
        uint256 Ordinal
    ) public {
        require(!_initialized, "Already initialized");
        require(cap % LimitperBTH == 0, "LimitperBTH must be divisible by cap");

        _initialized = true;
        _cap = cap * (10**decimals);
        _LimitperBTH = LimitperBTH * (10**decimals);
        BTHcontract = msg.sender;
        _name = tokeName;
        _symbol = tokenSymbol;
        creationOrdinal = Ordinal;
    }

    modifier onlyBTH {
        require(msg.sender == BTHcontract, "Only BTH CA");
        _;
    }

    function getCap() public view returns (uint256) {
        return _cap;
    }

    function inscribeOrdinal(uint256 Ordinal, address user) public onlyBTH {
        require(totalSupply() + _LimitperBTH <= _cap, "Exceeds cap");
        _mint(user, _LimitperBTH);
        allOrdinal.push(Ordinal);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
}




// Create Bithereum contract which is a subtype of ERC20 and Ownable contract.
contract Bithereum is ERC20, Ownable {
    uint256 public halvingInterval = 345600;  // Interval at which block reward is halved.
    uint256 public lastHalvingBlock;  // Last block at which reward was halved.
    uint256 public currentReward = 8 * 10 ** decimals();  // Current block reward.
    uint256 public accumulatedReward;  // Reward accumulated since the last block.
    uint256 public lastBlock;  // Last block for which the reward was calculated.
    uint256 public transactionCount;  // Number of transactions in the current block.

    bool public RecordOrdinal = true;

    // A struct to store the range of tokens.
    struct Range {
        uint256 start;  // Start of the range.
        uint256 end;  // End of the range.
    }

    // A struct to store the linked list node.
    struct Node {
        Range tokenRange;  // Token range associated with the node.
        uint256 next;  // Index of the next node in the linked list.
        uint256 prev;  // Index of the previous node in the linked list.
    }

    // A struct to store the linked list.
    struct LinkedList {
        uint256 head;  // Head of the linked list.
        uint256 tail;  // Tail of the linked list.
        uint256 nodeCounter;  // Counter to generate unique node ids.
        mapping(uint256 => Node) nodes;  // Mapping from node id to Node.
    }

    mapping(address => LinkedList) public linkedLists;  // Mapping from address to its LinkedList.
    mapping(uint256 => address) public allInscription;
    mapping(uint256 => address) public OrdinalOwner;
    mapping(bytes32 => address) private _createdContracts;

    // Constructor of the Bithereum contract.
    constructor() ERC20("Bithereum", "BTH") {
        lastHalvingBlock = block.number;
        lastBlock = block.number;
    }

    // Override the decimals function to return 3.
    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function setRecordOrdinal(bool isRecord) public onlyOwner {
        RecordOrdinal = isRecord;
    }

    function _setallInscription(uint256 Oridnal, address _addr) internal {
        require(allInscription[Oridnal] == address(0), "Already Inscription!");
        allInscription[Oridnal] = _addr;
    }

    function CreateInscription(
        string memory tokenname,
        string memory tokensymbol,
        uint256 tokendecimals,
        uint256 tokencap,
        uint256 tokenLimitperBTH,
        uint256 Ordinal
    ) public {
        _PickOrdinal(Ordinal);
        bytes32 salt = keccak256(abi.encodePacked(tokensymbol));
        bytes memory bytecode = type(BTHErc20).creationCode;
        bytes32 contractHash = keccak256(abi.encodePacked(bytecode, salt));

        require(_createdContracts[contractHash] == address(0), "Contract already created");

        address erc20Address;
        assembly {
            erc20Address := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(erc20Address)) {
                revert(0, 0)
            }
        }

        _createdContracts[contractHash] = erc20Address;

        BTHErc20(erc20Address).initialize(tokenname, tokensymbol, tokendecimals, tokencap, tokenLimitperBTH, Ordinal);
        _transfer(msg.sender, erc20Address, 1);
        _ReceiveOrdinal(erc20Address, Ordinal);
        _setallInscription(Ordinal, erc20Address);
    }

    function _inscription(uint256 Ordinal, string memory symbol) internal {
        bytes32 salt = keccak256(abi.encodePacked(symbol));
        bytes memory bytecode = type(BTHErc20).creationCode;
        bytes32 contractHash = keccak256(abi.encodePacked(bytecode, salt));
        address erc20Address = _createdContracts[contractHash];
        require(erc20Address != address(0), "Contract not initialized");
        BTHErc20(erc20Address).inscribeOrdinal(Ordinal, msg.sender);
        _transfer(msg.sender, erc20Address, 1);
        _ReceiveOrdinal(erc20Address, Ordinal);
        _setallInscription(Ordinal, erc20Address);
    }

    // inscripton specified vik
    function Inscrible(uint256 Ordinal, string memory symbol) public {
        _PickOrdinal(Ordinal);
        _inscription(Ordinal, symbol);

    }
    // inscripton the last vik
    function InscriptionSimple(string memory symbol) public {
        address user = msg.sender;
        require(balanceOf(user) > 0, "Not own enough vik!");
        uint256 tail;
        uint256 Ordinal;
        LinkedList storage linkedList = linkedLists[user];
        tail = linkedList.tail;
        Range memory range = linkedList.nodes[tail].tokenRange;
        Ordinal = range.end;
        if (range.start == range.end) {
            uint256 tailNew = linkedList.nodes[tail].prev;
            linkedList.nodes[tailNew].next = 0;
            _deleteNode(linkedList, tail);
        } else {
            linkedList.nodes[tail].tokenRange.end -= 1;
        }
        _inscription(Ordinal, symbol);
    }

    // Update the token range of the recipient.
    function _updateRecipientTokenRange(address recipient, Range memory range) internal {
        LinkedList storage linkedList = linkedLists[recipient];
        linkedList.nodeCounter += 1;

        uint256 previous = linkedList.tail;
        linkedList.nodes[linkedList.nodeCounter] = Node({tokenRange: range, next: 0, prev: previous});

        if (previous != 0) {
            linkedList.nodes[previous].next = linkedList.nodeCounter;
        }

        linkedList.tail = linkedList.nodeCounter;
        
        if (linkedList.head == 0) {
            linkedList.head = linkedList.nodeCounter;
        }
    }

    // Update the token range after a transfer.
    function _updateTokenRange(address sender, address recipient, uint256 amount) internal {
        LinkedList storage senderList = linkedLists[sender];
        uint256 index = senderList.tail;

        while (amount > 0 && index != 0) {
            Node storage node = senderList.nodes[index];
            uint256 rangeSize = node.tokenRange.end - node.tokenRange.start + 1;

            if (rangeSize > amount) {
                Range memory range = Range(node.tokenRange.end - amount + 1, node.tokenRange.end);
                node.tokenRange.end -= amount;
                amount = 0;

                _updateRecipientTokenRange(recipient, range);
            } else {
                Range memory range = node.tokenRange;
                amount -= rangeSize;

                _updateRecipientTokenRange(recipient, range);

                uint256 prevIndex = node.prev;
                _deleteNode(senderList, index);
                index = prevIndex;
            }
        }
    }

    // Delete a node from the linked list.
    function _deleteNode(LinkedList storage list, uint256 index) internal {
        Node storage node = list.nodes[index];
        if (node.prev != 0) {
            list.nodes[node.prev].next = node.next;
        }
        if (node.next != 0) {
            list.nodes[node.next].prev = node.prev;
        }
        if (list.head == index) {
            list.head = node.next;
        }
        if (list.tail == index) {
            list.tail = node.prev;
        }
        delete list.nodes[index];
    }

    // Sort and merge the linked list.
    function _sortAndMergeLinkedList() internal {
        address owner = tx.origin;
        _sortLinkedList(owner);
        _mergeLinkedList(owner);
    }

    // Sort the linked list.
    function _sortLinkedList(address owner) internal {
        LinkedList storage linkedList = linkedLists[owner];
        if (linkedList.head == 0 || linkedList.head == linkedList.tail) {
            // The list is empty or has only one node, no need to sort.
            return;
        }

        // Create a new head for the sorted part.
        uint256 sortedHead = linkedList.head;
        uint256 unsortedHead = linkedList.nodes[linkedList.head].next;
        linkedList.nodes[sortedHead].next = 0;
        linkedList.nodes[sortedHead].prev = 0;

        while (unsortedHead != 0) {
            uint256 nodeToInsert = unsortedHead;
            unsortedHead = linkedList.nodes[unsortedHead].next;

            // Reset the pointers of the node to insert.
            linkedList.nodes[nodeToInsert].next = 0;
            linkedList.nodes[nodeToInsert].prev = 0;

            // Insert the node in the sorted part.
            uint256 current = sortedHead;
            uint256 previous = 0;
            while (current != 0 && linkedList.nodes[current].tokenRange.start < linkedList.nodes[nodeToInsert].tokenRange.start) {
                previous = current;
                current = linkedList.nodes[current].next;
            }

            // Connect the node to insert with the current node.
            linkedList.nodes[nodeToInsert].next = current;
            if (current != 0) {
                linkedList.nodes[nodeToInsert].prev = linkedList.nodes[current].prev;
                linkedList.nodes[current].prev = nodeToInsert;
            }

            // Connect the node to insert with the previous node.
            if (previous != 0) {
                linkedList.nodes[previous].next = nodeToInsert;
                linkedList.nodes[nodeToInsert].prev = previous;
            } else {
                // The node to insert becomes the new head.
                sortedHead = nodeToInsert;
            }
        }

        // Update the head of the linked list.
        linkedList.head = sortedHead;
    }


    // Merge the linked list nodes if the end of the previous node is one less than the start of the next node.
    function _mergeLinkedList(address owner) internal {
        LinkedList storage linkedList = linkedLists[owner];

        uint256 i = linkedList.head;
        while (i != 0 && linkedList.nodes[i].next != 0) {
            uint256 next = linkedList.nodes[i].next;
            if (linkedList.nodes[i].tokenRange.end + 1 == linkedList.nodes[next].tokenRange.start) {
                // Merge the two nodes.
                linkedList.nodes[i].tokenRange.end = linkedList.nodes[next].tokenRange.end;

                // Delete the next node.
                if (next == linkedList.tail) {
                    linkedList.tail = i;
                }
                linkedList.nodes[i].next = linkedList.nodes[next].next;
                if (linkedList.nodes[next].next != 0) {
                    linkedList.nodes[linkedList.nodes[next].next].prev = i;
                }
                delete linkedList.nodes[next];
            } else {
                i = next;
            }
        }
    }


    // Get the linked list node associated with the given address and key.
    function getNode(address _addr, uint256 key) external view returns (Node memory) {
        return linkedLists[_addr].nodes[key];
    }

    // Get the token ranges associated with the given address.
    function getTokenRanges(address owner) public view returns (Range[] memory) {
        LinkedList storage linkedList = linkedLists[owner];
        if (linkedList.head == 0) {
            return new Range[](0);
        } else {
            uint256 index = linkedList.head;
            uint256 length = 0;
            while (index != 0) {
                length++;
                index = linkedList.nodes[index].next;
            }

            Range[] memory ranges = new Range[](length);

            index = linkedList.head;
            for (uint256 i = 0; i < length; i++) {
                ranges[i] = linkedList.nodes[index].tokenRange;
                index = linkedList.nodes[index].next;
            }

            return ranges;
        }
    }

    // Mint a reward based on the halving interval.
    function _mintReward() internal {
        if (block.number >= lastHalvingBlock + halvingInterval) {
            currentReward /= 2;
            lastHalvingBlock = block.number;
        }

        if (block.number > lastBlock) {
            accumulatedReward += (block.number - lastBlock - 1) * currentReward;
            accumulatedReward += currentReward;
            lastBlock = block.number;
            transactionCount = 0;
        } else {
            accumulatedReward = currentReward / 2 ** transactionCount;
        }

        transactionCount += 1;
        _mint(tx.origin, accumulatedReward);
        _updateRecipientTokenRange(tx.origin, Range(totalSupply() - accumulatedReward, totalSupply() - 1));
        accumulatedReward = 0;
        _sortAndMergeLinkedList();
    }

    // Determine whether the ordinal belongs to addr
    function isOrdinalOwner(address _addr, uint256 Ordinal) public view returns (bool, uint256) {
        LinkedList storage linkedList = linkedLists[_addr];
        uint256 index = linkedList.head;

        while (index != 0) {
            Range memory range = linkedList.nodes[index].tokenRange;

            if (range.start <= Ordinal && Ordinal <= range.end) {
                return (true, index);
            }

            index = linkedList.nodes[index].next;
        }
        return (false, index);
    }

    function _PickOrdinal(uint256 Ordinal) internal {
        address user = msg.sender;
        bool ownOrdinal;
        uint256 index;
        uint256 newId;
        (ownOrdinal, index) = isOrdinalOwner(user, Ordinal);
        require(ownOrdinal, "You don't have this ordinal");
        LinkedList storage linkedList = linkedLists[user];
        Range memory range = linkedList.nodes[index].tokenRange;
        if (range.start == Ordinal) {
            linkedList.nodes[index].tokenRange.start += 1;
        } else if (range.end == Ordinal) {
            linkedList.nodes[index].tokenRange.end -= 1;
        } else {
            linkedList.nodeCounter += 1;
            newId = linkedList.nodeCounter;
            uint256 rightPrevId = linkedList.nodes[index].prev;
            linkedList.nodes[index].prev = newId;
            linkedList.nodes[rightPrevId].next = newId;
            Range memory Newrange = Range(range.start, Ordinal - 1);
            linkedList.nodes[newId] = Node({tokenRange: Newrange, next: index, prev: rightPrevId});
            linkedList.nodes[index].tokenRange.start = Ordinal + 1;

            if (index == linkedList.head){
                linkedList.head = newId;
            }
        }
    }

    function _ReceiveOrdinal(address recipient, uint256 Ordinal) internal {
        LinkedList storage linkedList = linkedLists[recipient];
        linkedList.nodeCounter += 1;

        uint256 previous = linkedList.tail;
        Range memory range = Range(Ordinal, Ordinal);
        linkedList.nodes[linkedList.nodeCounter] = Node({tokenRange: range, next: 0, prev: previous});

        if (previous != 0) {
            linkedList.nodes[previous].next = linkedList.nodeCounter;
        }

        linkedList.tail = linkedList.nodeCounter;
        
        if (linkedList.head == 0) {
            linkedList.head = linkedList.nodeCounter;
        }
    }

    function sendOrdinal(address recipient, uint256 Ordinal) public {
        _PickOrdinal(Ordinal);
        _transfer(msg.sender, recipient, 1);
        Range memory range = Range(Ordinal, Ordinal);
        _updateRecipientTokenRange(recipient, range);
    }

    // Override the transfer function to include additional logic.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        bool success = super.transfer(recipient, amount);
        if (success && RecordOrdinal) {
            _updateTokenRange(msg.sender, recipient, amount);
        }
        return success;
    }

    // Override the transferFrom function to include additional logic.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        bool success = super.transferFrom(sender, recipient, amount);
        if (success && RecordOrdinal) {
            _updateTokenRange(sender, recipient, amount);
        }
        return success;
    }

    // Receives any incoming Ether and mints a reward.
    receive() external payable {
        require(RecordOrdinal, "Terminate recording ordinal!");
        _mintReward();
        _sortAndMergeLinkedList();
    }

    // Function for manually triggering reward minting.
    function getBlockreward() external {
        require(RecordOrdinal, "Terminate recording ordinal!");
        _mintReward();
        _sortAndMergeLinkedList();
    }

    // Function for manually triggering reward minting, sort others
    function sortAndmerge(address _addr) external {
        require(RecordOrdinal, "Terminate recording ordinal!");
        require(balanceOf(_addr) > 0, "The sort address needs to vik!");
        _mintReward();
        _sortLinkedList(_addr);
        _mergeLinkedList(_addr);        
    }

    function withdrawETH(uint256 amount) public onlyOwner{
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function withdrawERC20(IERC20 token, uint256 amount) public onlyOwner{
        bool success = token.transfer(msg.sender, amount);
        require(success, "Token transfer failed");
    }
}