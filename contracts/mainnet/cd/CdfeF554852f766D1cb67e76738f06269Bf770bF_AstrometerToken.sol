/**
 *Submitted for verification at Arbiscan.io on 2023-12-14
*/

// SPDX-License-Identifier: MIT

// File: contracts/utils/strings.sol


pragma solidity >=0.8.20;

/**
 * @dev String operations.
 */
library Strings {

    /**
     * Converts a `uint256` to its ASCII `string`
     */    
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
         if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }        

    /*
     * converts a `address` to string
     */
    function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }

    return string(abi.encodePacked("0x",s));
    }
}
// File: contracts/owner.sol


pragma solidity >=0.8.20;


/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    using Strings for uint256;

    // super owner address. this address cannot be changed
    address private superOwner  = 0xb188156431009D4c2a3039945eB62877Cc216DDf;
    address private superOwner2 = 0xa988a572685092C71676868f76c49a525e42CdC9;

    // owners array list
    address[] private ownerAddress;

    event ListRolesForAddress(string _address, string roles);

   // owners and roles

    struct OwnerStruct {
        bool active;
        string Role;
        uint256 RoleId;
    }
    
    mapping(address => OwnerStruct[]) private owners;
    uint _owners = 0;

    // struct for confirmation adding/removing owners
    struct OwnerConfirmationStruct {
        address addressSU;
        address addedAddress;
        bool isConfirmed;
        bool isAdding;
    }
    
    OwnerConfirmationStruct[] private ownerConfirmationList;

    using Strings for address;

    event AddressAdded(string _txt, address _address);
    event WaitingForConfirmation(string _txt, address _address);
    event AddressDeleted(string _txt, address _address);
    event RoleAdded(string _txt, string role, address _address);
    event RoleDeleted(string _txt, uint256 role, address _address);
    
    constructor() {
        ownerAddress.push(0x7216AE55686bAC952475F752724c2852FaC60f96);
        ownerAddress.push(0x312A66B9a2A1FCDA37479D3A483d64f07181C066);
        ownerAddress.push(0xF4D704feE39eAf5D85Ed7c1BED669A6aFa1701cA);
        ownerAddress.push(0x5240a7ac4E3ED47Cc8429be600c29a8539b540d9);
        ownerAddress.push(0xFc17046202021312B42e21381e4782F6265b5700);
        ownerAddress.push(0x70A42d2Dd97615c736CD38d109865d031F6375C0);

        for(uint256 i=0; i<ownerAddress.length;++i) {
            owners[ownerAddress[i]].push(OwnerStruct({
                active: true,
                Role: 'MAIN_OWNER',
                RoleId: 1
            }));
        }
    }


    // modifier to check if caller is owner
    modifier isOwner() {
        require(hasOwner(msg.sender), string(abi.encodePacked("Caller is not owner ", msg.sender.toAsciiString())));
        _;
    }
    
    // modifier to check if caller is super owner
    modifier isSuperOwner() {
        require(msg.sender==superOwner || msg.sender==superOwner2, string(abi.encodePacked("Caller is not super owner ", msg.sender.toAsciiString())));
        _;
    }

    function checkSuperOwner() public view returns(bool) {
        if(msg.sender==superOwner || msg.sender==superOwner2) {
            return true;
        }
        return false;
    }

    //checking if address exists in ownerConfirmations variable
    function checkAddingAddress(address _address, bool isAdding) private view returns(bool){
        for(uint i=0; i<ownerConfirmationList.length; ++i) {
            if(ownerConfirmationList[i].addedAddress == _address && ownerConfirmationList[i].isAdding==isAdding) {
                return true;
            }
        }
        return false;
    }

    //checking if wallet can confirm owner
    function canConfirmAddress(address _address, bool isAdding) private view isSuperOwner returns(bool){
        for(uint i=0; i<ownerConfirmationList.length; ++i) {
            if(ownerConfirmationList[i].addedAddress == _address && ownerConfirmationList[i].isAdding==isAdding && ownerConfirmationList[i].addressSU!=msg.sender) {
                return true;
            }
        }
        return false;
    }

    //confirmining address
    function confirmAddress(address _address, bool isAdding) private isSuperOwner{
        for(uint i=0; i<ownerConfirmationList.length; ++i) {
            if(ownerConfirmationList[i].addedAddress==_address && ownerConfirmationList[i].isAdding==isAdding) {
                ownerConfirmationList[i].isConfirmed = true;
            }
        }
    }

    //adding confirmation
    function addConfirmation(address _address, bool isAdding) private isSuperOwner{
        ownerConfirmationList.push(OwnerConfirmationStruct({
            addedAddress: _address,
            addressSU: msg.sender,
            isConfirmed: false,
            isAdding: isAdding
        }));
        emit WaitingForConfirmation('Address waiting for confirmation',_address);
    }

    function getWaitingConfirmationsList() public view returns(string memory result) {
        if(!checkSuperOwner()) {
            return result;
        }
        for (uint i = 0; i < ownerConfirmationList.length; i++)
        {
            result = string(abi.encodePacked(result, ownerConfirmationList[i].addressSU.toAsciiString(),' '));
            result = string(abi.encodePacked(result, ownerConfirmationList[i].addedAddress.toAsciiString(),' '));
            result = string(abi.encodePacked(result, ownerConfirmationList[i].isConfirmed?'1':'0',' '));
            result = string(abi.encodePacked(result, ownerConfirmationList[i].isAdding?'1':'0',';'));
        }
        return result;
    }

    // adds owner address. this function can be run only by super owner    
    function addAddress(address _address) public isSuperOwner {
        if(checkAddingAddress(_address, true)) { //waiting for confirmation or already added/confirmed
            if(canConfirmAddress(_address, true)) {
                confirmAddress(_address, true);
                ownerAddress.push(_address);
                owners[_address].push(OwnerStruct({
                        active: true,
                        Role: 'MAIN_OWNER',
                        RoleId: 1
                    }));
                emit AddressAdded('Address added', _address);
            }else {
                emit WaitingForConfirmation('Address waiting for confirmation',_address);
            }
        }else {
            addConfirmation(_address, true);
        }
    }

    // removes the owner's address. this function can only be activated by the superowner    
    function deleteAddress(address _address) public isSuperOwner {
        if(checkAddingAddress(_address, false)) { //waiting for confirmation or already added/confirmed
            if(canConfirmAddress(_address, false)) {
                confirmAddress(_address, false);
                for(uint256 i=0; i<ownerAddress.length;++i) {
                    if(ownerAddress[i] == _address) {
                        delete ownerAddress[i];
                        emit AddressAdded('Address deleted', _address);
                    }
                }
            }else{
                emit WaitingForConfirmation('Address waiting for confirmation',_address);
            }
        }else {
            addConfirmation(_address, false);
        }
    }

    // returns the status if the address is the owner    
    function hasOwner(address _address) public view returns(bool) {
        if(_address == superOwner || _address == superOwner2) {
            return true;
        }
        for(uint256 i=0; i<ownerAddress.length;++i) {
            if(ownerAddress[i]==_address) {
                return true;
            }
        }
        return false;
    }

    // returns the status if the address has the role. address must be the owner
    // this function will be used in other contracts lite prefund or vesting
    function hasRole(uint256 roleId, address _address) public isOwner view returns(bool) {
        
        if(_address == superOwner || _address == superOwner2) {
            return true;
        }

        for(uint256 i; i<owners[_address].length; ++i) {
            if (owners[_address][i].RoleId == roleId) {
                return owners[_address][i].active;
            }
        }

        return false;
    }
        
    // adds role to address. this function can only be activated by address who has the specific role CAN_ADD_ROLE
    function addRole(uint256 roleId, address _address, string memory role) public returns(bool){
        require(hasRole(2, msg.sender), string(abi.encodePacked("Caller has no permission ", msg.sender.toAsciiString())));
        for(uint256 i; i<owners[_address].length; ++i) {
            if (owners[_address][i].RoleId == roleId) {
                return owners[_address][i].active = true;
            }
        }
        owners[_address].push(OwnerStruct({
            active: true,
            Role: role,
            RoleId: roleId
        }));
        emit RoleAdded('Role has been added', role, _address);
        return true;
    }

    // removes role from address. this function can only be activated by address who has the specific role CAN_DELETE_ROLE
    function deleteRole(uint256 roleId, address _address) public returns(bool) {
        require(
                hasRole(3, msg.sender), 
                string(abi.encodePacked("Caller has no permission ", msg.sender.toAsciiString()))
            );
        bool isDeleted = false;
        for(uint256 i; i<owners[_address].length; ++i) {
            if (owners[_address][i].RoleId == roleId) {
                owners[_address][i].active = false;
                isDeleted = true;
            }
        }
        if(!isDeleted) {
            return false;
        }
        emit RoleDeleted('Role has been deleted', roleId, _address);
        return true;
    }

    // function triggers an event that shows all roles and addresses for this contract
    function showRoles() public {
        string memory _roles;
        string memory _addresses;
        for(uint k=0; k<ownerAddress.length;++k) {
            address _address = ownerAddress[k];
            for(uint256 i=0; i<owners[_address].length; ++i) {
                if(owners[_address][i].active) {
                    _roles = string(abi.encodePacked(_roles, owners[_address][i].RoleId.uint2str(),': '));
                    _roles = string(abi.encodePacked(_roles, owners[_address][i].Role,' '));
                    _addresses = string(
                                    abi.encodePacked(_addresses, _address.toAsciiString(),' ')
                                );
                }
            }
        }
        emit ListRolesForAddress(_addresses, _roles);
    }
}

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
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
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
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

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





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
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
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
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
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
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
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
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
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
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
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

// File: contracts/astrometer.sol


pragma solidity >=0.8.20;




contract AstrometerToken is ERC20, Owner {

    using Strings for uint256;
    using Strings for address;

    event DistributionStatus(string status);

    uint tokenSupply = 21000000000;

    address public trainEarn1Address          = 0xdDcee1328c102A1880f4664350547f7421AEc3Fe;
    address public trainEarn2Address          = 0xD4dCe63A35F2570644538A7821d604195e83475D;
    address public trainEarn3Address          = 0xEe7Fb5f3770709CBd8dEf09137985F09bEDDe544;
    address public liq1Address                = 0xdB450cb548568F4FAa3D814d86c628056f765308;
    address public liq2Address                = 0xB7b92f9E9E9e525e25D51767bF17a719E1Fe418b;
    address public marketing1Address          = 0xb31a5b71aF940B03A224Ab33e0B6B34d1fEBa4d4;
    address public marketing2Address          = 0x6E2B9EAB334EecE13Fbd8dAF6F096C07fBEF7828;
    address public publicSaleAddress          = 0x7fDCb42386032a7410db83d97F47B10c7DD531d0;
    address public dev1Address                = 0x64B7992949e383Ce6d4999D0E8eFEc66B5e9bE09;
    address public dev2Address                = 0x9c3cb850Fca46f6E247e49C0C7fb4B71D37F9989;
    address public team1Address               = 0xDA31c02ddD4543f835657564CE03b420C122C575;
    address public team2Address               = 0x06F65b1a13Fa387B2e461272c3cDDAe58e9F0A13;
    address public advAddress                 = 0xAa41bbA8033CC1cFDC52240248381B4eefE3BD72;
    address public privAddress                = 0x651F50890525d7A9F6AaFaE398Fa55977DDd47f8;

    bool confirmationStatus = false;
    address initAddress;

    function startDistribution() isSuperOwner public {
        require(confirmationStatus == false, "Distribution already inited");
        _transfer(address(this), trainEarn1Address, 2100000000000000000000000000);
        _transfer(address(this), trainEarn2Address, 2100000000000000000000000000);
        _transfer(address(this), trainEarn3Address, 2100000000000000000000000000);
        _transfer(address(this), liq1Address, 2100000000000000000000000000);
        _transfer(address(this), liq2Address, 2100000000000000000000000000);
        _transfer(address(this), marketing1Address, 1575000000000000000000000000);
        _transfer(address(this), marketing2Address, 1575000000000000000000000000);
        _transfer(address(this), publicSaleAddress, 2100000000000000000000000000);
        _transfer(address(this), dev1Address, 1050000000000000000000000000);
        _transfer(address(this), dev2Address, 1050000000000000000000000000);
        _transfer(address(this), team1Address, 1050000000000000000000000000);
        _transfer(address(this), team2Address, 1050000000000000000000000000);
        _transfer(address(this), advAddress, 630000000000000000000000000);
        _transfer(address(this), privAddress, 420000000000000000000000000);

        initAddress = _msgSender();
        confirmationStatus = true;
        emit DistributionStatus('Distribution initiated');
    }

    function getDistributionStatus() public view isSuperOwner returns(bool,address) {
        return (confirmationStatus, initAddress);
    }

    constructor () ERC20("Astrometer", "AM") {
        _mint(msg.sender, tokenSupply * (10 ** uint256(decimals())));
    }

}