// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    error BatchError(bytes innerError);

    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure{
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert BatchError(_returnData);

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                _getRevertMsg(result);
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IMasterContract.sol";

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Mapping from clone contracts to their masterContract.
    mapping(address => address) public masterContractOf;

    /// @notice Mapping from masterContract to an array of all clones
    /// On mainnet events can be used to get this list, but events aren't always easy to retrieve and
    /// barely work on sidechains. While this adds gas, it makes enumerating all clones much easier.
    mapping(address => address[]) public clonesOf;

    /// @notice Returns the count of clones that exists for a specific masterContract
    /// @param masterContract The address of the master contract.
    /// @return cloneCount total number of clones for the masterContract.
    function clonesOfCount(address masterContract) public view returns (uint256 cloneCount) {
        cloneCount = clonesOf[masterContract].length;
    }

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;
        clonesOf[masterContract].push(cloneAddress);

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC165.sol";

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

library BoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendNative(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}("");
        require(success, "BoringAddress: transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "./IPenrose.sol";
import "../swappers/ISwapper.sol";

interface IFee {
    function depositFeesToYieldBox(
        ISwapper,
        IPenrose.SwapData calldata
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IOracle.sol";

interface IMarket {
    function asset() external view returns (address);

    function assetId() external view returns (uint256);

    function collateral() external view returns (address);

    function collateralId() external view returns (uint256);

    function totalBorrowCap() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function totalBorrow()
        external
        view
        returns (uint128 elastic, uint128 base);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function exchangeRate() external view returns (uint256);

    function yieldBox() external view returns (address payable);

    function liquidationMultiplier() external view returns (uint256);

    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external;

    function removeCollateral(address from, address to, uint256 share) external;

    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function withdrawTo(
        address from,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        bytes calldata adapterParams,
        address payable refundAddress
    ) external payable;

    function borrow(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 part, uint256 share);

    function execute(
        bytes[] calldata calls,
        bool revertOnFail
    ) external returns (bool[] memory successes, string[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(
        bytes calldata data
    ) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(
        bytes calldata data
    ) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "../usd0/IUSDO.sol";
import "../swappers/ISwapper.sol";

interface IPenrose {
    /// @notice swap extra data
    struct SwapData {
        uint256 minAssetAmount;
    }

    /// @notice Used to define the MasterContract's type
    enum ContractType {
        lowRisk,
        mediumRisk,
        highRisk
    }

    /// @notice MasterContract address and type
    struct MasterContract {
        address location;
        ContractType risk;
    }

    function bigBangEthMarket() external view returns (address);

    function bigBangEthDebtRate() external view returns (uint256);

    function swappers(ISwapper swapper) external view returns (bool);

    function yieldBox() external view returns (address payable);

    function tapToken() external view returns (address);

    function tapAssetId() external view returns (uint256);

    function usdoToken() external view returns (address);

    function usdoAssetId() external view returns (uint256);

    function feeTo() external view returns (address);

    function wethToken() external view returns (address);

    function wethAssetId() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

/**
 * @dev Interface of the IOFT core standard
 */
interface ISendFrom {
    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        LzCallParams calldata _callParams
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface ITapiocaOFT {
    function sendToYB(
        uint256 amount,
        uint256 assetId,
        uint16 lzDstChainId,
        uint256 extraGasLimit,
        address zroPaymentAddress,
        bool strategyDeposit
    ) external payable;

    function retrieveFromYB(
        uint256 amount,
        uint256 assetId,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        bytes memory airdropAdapterParam,
        bool strategyWithdrawal
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";

// solhint-disable max-line-length

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB, pairCodeHash)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                pairCodeHash
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                pairCodeHash
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

import "../../interfaces/IPenrose.sol";
import "../ILiquidationQueue.sol";
import "../../libraries/ICurvePool.sol";
import "../../swappers/CurveSwapper.sol";
import "../../singularity/interfaces/ISingularity.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title Swaps Stable to USDO through Curve
/// @dev Performs a swap operation between stable and USDO through 3CRV+USDO pool
contract CurveStableToUsdoBidder is BoringOwnable {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice 3Crv+USDO swapper
    ISwapper public curveSwapper;
    /// @notice Curve pool assets number
    uint256 curveAssetsLength;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event CurveSwapperUpdated(address indexed _old, address indexed _new);

    /// @notice creates a new CurveStableToUsdoBidder
    /// @param curveSwapper_ CurveSwapper address
    /// @param curvePoolAssetCount_ Curve pool assets number
    constructor(ISwapper curveSwapper_, uint256 curvePoolAssetCount_) {
        curveSwapper = curveSwapper_;
        curveAssetsLength = curvePoolAssetCount_;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns the unique name
    function name() external pure returns (string memory) {
        return "stable -> USDO (3Crv+USDO)";
    }

    /// @notice returns the amount of collateral
    /// @param amountIn Stablecoin amount
    function getOutputAmount(
        ISingularity singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata
    ) external view returns (uint256) {
        require(
            IPenrose(singularity.penrose()).usdoToken() != address(0),
            "USDO not set"
        );

        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        if (tokenInId == usdoAssetId) {
            return amountIn;
        }

        return
            _getOutput(
                IYieldBox(singularity.yieldBox()),
                tokenInId,
                usdoAssetId,
                amountIn
            );
    }

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param tokenInId Token in asset id
    /// @param amountOut Token out amount
    function getInputAmount(
        ISingularity singularity,
        uint256 tokenInId,
        uint256 amountOut,
        bytes calldata
    ) external view returns (uint256) {
        require(
            IPenrose(singularity.penrose()).usdoToken() != address(0),
            "USDO not set"
        );

        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        if (tokenInId == usdoAssetId) {
            return amountOut;
        }

        return
            _getOutput(
                IYieldBox(singularity.yieldBox()),
                usdoAssetId,
                tokenInId,
                amountOut
            );
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice swaps stable to collateral
    /// @param tokenInId Stablecoin asset id
    /// @param amountIn Stablecoin amount
    /// @param data extra data used for the swap operation
    function swap(
        ISingularity singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external returns (uint256) {
        require(
            IPenrose(singularity.penrose()).usdoToken() != address(0),
            "USDO not set"
        );
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());
        ILiquidationQueue liquidationQueue = ILiquidationQueue(
            singularity.liquidationQueue()
        );

        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        require(msg.sender == address(liquidationQueue), "only LQ");
        if (tokenInId == usdoAssetId) {
            yieldBox.transfer(
                address(this),
                address(liquidationQueue),
                tokenInId,
                yieldBox.toShare(tokenInId, amountIn, false)
            );
            return amountIn;
        }

        uint256 _usdoMin = 0;
        if (data.length > 0) {
            //should always be sent
            _usdoMin = abi.decode(data, (uint256));
        }
        yieldBox.transfer(
            address(this),
            address(curveSwapper),
            tokenInId,
            yieldBox.toShare(tokenInId, amountIn, false)
        );
        return
            _swap(
                yieldBox,
                tokenInId,
                usdoAssetId,
                amountIn,
                _usdoMin,
                address(liquidationQueue)
            );
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice sets the Curve swapper
    /// @dev used for USDO to WETH swap
    /// @param _swapper The curve pool swapper address
    function setCurveSwapper(ISwapper _swapper) external onlyOwner {
        emit CurveSwapperUpdated(address(curveSwapper), address(_swapper));
        curveSwapper = _swapper;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _getCurveIndex(address token) private view returns (uint256) {
        ICurvePool pool = ICurvePool(
            CurveSwapper(address(curveSwapper)).curvePool()
        );
        int256 index = -1;
        for (uint256 i = 0; i < curveAssetsLength; i++) {
            address tokenAtIndex = pool.coins(i);
            if (tokenAtIndex == token) {
                index = int256(i);
            }
        }
        require(index > -1, "asset not found");
        return uint256(index);
    }

    function _getOutput(
        IYieldBox yieldBox,
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountIn
    ) private view returns (uint256) {
        (, address tokenInAddress, , ) = yieldBox.assets(tokenInId);
        (, address tokenOutAddress, , ) = yieldBox.assets(tokenOutId);

        uint256 tokenInCurveIndex = _getCurveIndex(tokenInAddress);
        uint256 tokenOutCurveIndex = _getCurveIndex(tokenOutAddress);
        uint256[] memory indexes = new uint256[](2);
        indexes[0] = tokenInCurveIndex;
        indexes[1] = tokenOutCurveIndex;

        uint256 share = yieldBox.toShare(tokenInId, amountIn, false);
        return
            curveSwapper.getOutputAmount(tokenInId, share, abi.encode(indexes));
    }

    function _swap(
        IYieldBox yieldBox,
        uint256 stableAssetId,
        uint256 usdoAssetId,
        uint256 amountIn,
        uint256 minAmount,
        address to
    ) private returns (uint256) {
        (, address tokenInAddress, , ) = yieldBox.assets(stableAssetId);
        (, address tokenOutAddress, , ) = yieldBox.assets(usdoAssetId);

        uint256 tokenInCurveIndex = _getCurveIndex(tokenInAddress);
        uint256 tokenOutCurveIndex = _getCurveIndex(tokenOutAddress);

        uint256[] memory indexes = new uint256[](2);
        indexes[0] = tokenInCurveIndex;
        indexes[1] = tokenOutCurveIndex;
        uint256 tokenInShare = yieldBox.toShare(stableAssetId, amountIn, false);

        (uint256 amountOut, ) = curveSwapper.swap(
            stableAssetId,
            usdoAssetId,
            tokenInShare,
            to,
            minAmount,
            abi.encode(indexes)
        );

        return amountOut;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/// @notice Used for performing swap operations when bidding on LiquidationQueue
interface IBidder {
    /// @notice returns the unique name
    function name() external view returns (string memory);

    /// @notice returns the amount of collateral
    /// @param singularity Market to query for
    /// @param tokenInId Token in YieldBox asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for retrieving the ouput
    function getOutputAmount(
        address singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external view returns (uint256);

    /// @notice swap USDO to collateral
    /// @param singularity Market to swap for
    /// @param tokenInId Token in asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for the swap operation
    function swap(
        address singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external returns (uint256);

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param singularity Market to query for
    /// @param tokenInId Token in asset id
    /// @param amountOut Token out amount
    /// @param data extra data used for retrieving the ouput
    function getInputAmount(
        address singularity,
        uint256 tokenInId,
        uint256 amountOut,
        bytes calldata data
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

import "../../interfaces/IPenrose.sol";
import "../ILiquidationQueue.sol";
import "../../swappers/ISwapper.sol";
import "../../singularity/interfaces/ISingularity.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title Swaps USDO to WETH UniswapV2
/// @dev Performs 1 swap operation:
///     - USDO to Weth through UniV2
contract UniUsdoToWethBidder is BoringOwnable {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice UniswapV2 swapper
    ISwapper public univ2Swapper;

    /// @notice YieldBox WETH asset id
    uint256 wethId;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event UniV2SwapperUpdated(address indexed _old, address indexed _new);

    /// @notice Creates a new UniUsdoToWethBidder contract
    /// @param uniV2Swapper_ UniswapV2 swapper address
    /// @param _wethAssetId YieldBox WETH asset id
    constructor(ISwapper uniV2Swapper_, uint256 _wethAssetId) {
        univ2Swapper = uniV2Swapper_;
        wethId = _wethAssetId;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns the unique name
    function name() external pure returns (string memory) {
        return "USDO -> WETH (Uniswap V2)";
    }

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param tokenInId Token in asset id
    /// @param amountOut Token out amount
    function getInputAmount(
        ISingularity singularity,
        uint256 tokenInId,
        uint256 amountOut,
        bytes calldata
    ) external view returns (uint256) {
        require(
            tokenInId == IPenrose(singularity.penrose()).usdoAssetId(),
            "token not valid"
        );
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());

        uint256 shareOut = yieldBox.toShare(wethId, amountOut, false);

        (, address tokenInAddress, , ) = yieldBox.assets(tokenInId);
        (, address tokenOutAddress, , ) = yieldBox.assets(wethId);

        address[] memory path = new address[](2);
        path[0] = tokenInAddress;
        path[1] = tokenOutAddress;

        return univ2Swapper.getInputAmount(wethId, shareOut, abi.encode(path));
    }

    /// @notice returns the amount of collateral
    /// @param amountIn Stablecoin amount
    function getOutputAmount(
        ISingularity singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata
    ) external view returns (uint256) {
        require(
            IPenrose(singularity.penrose()).usdoToken() != address(0),
            "USDO not set"
        );
        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        require(tokenInId == usdoAssetId, "token not valid");

        return
            _uniswapOutputAmount(
                IYieldBox(singularity.yieldBox()),
                usdoAssetId,
                wethId,
                amountIn
            );
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice swaps stable to collateral
    /// @param tokenInId Token in asset Id
    /// @param amountIn Stablecoin amount
    /// @param data extra data used for the swap operation
    function swap(
        ISingularity singularity,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external returns (uint256) {
        require(
            IPenrose(singularity.penrose()).usdoToken() != address(0),
            "USDO not set"
        );
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());
        ILiquidationQueue liquidationQueue = ILiquidationQueue(
            singularity.liquidationQueue()
        );

        uint256 usdoAssetId = IPenrose(singularity.penrose()).usdoAssetId();
        require(tokenInId == usdoAssetId, "token not valid");
        require(msg.sender == address(liquidationQueue), "only LQ");

        uint256 assetMin = 0;
        if (data.length > 0) {
            //should always be sent
            assetMin = abi.decode(data, (uint256));
        }

        yieldBox.transfer(
            address(this),
            address(univ2Swapper),
            tokenInId,
            yieldBox.toShare(tokenInId, amountIn, false)
        );

        return
            _uniswapSwap(
                yieldBox,
                usdoAssetId,
                wethId,
                amountIn,
                assetMin,
                address(liquidationQueue)
            );
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice sets the UniV2 swapper
    /// @dev used for WETH to USDC swap
    /// @param _swapper The UniV2 pool swapper address
    function setUniswapSwapper(ISwapper _swapper) external onlyOwner {
        emit UniV2SwapperUpdated(address(univ2Swapper), address(_swapper));
        univ2Swapper = _swapper;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _uniswapSwap(
        IYieldBox yieldBox,
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 tokenInAmount,
        uint256 minAmount,
        address to
    ) private returns (uint256) {
        (, address tokenInAddress, , ) = yieldBox.assets(tokenInId);
        (, address tokenOutAddress, , ) = yieldBox.assets(tokenOutId);
        address[] memory swapPath = new address[](2);
        swapPath[0] = tokenInAddress;
        swapPath[1] = tokenOutAddress;
        uint256 tokenInShare = yieldBox.toShare(
            tokenInId,
            tokenInAmount,
            false
        );
        (uint256 outAmount, ) = univ2Swapper.swap(
            tokenInId,
            tokenOutId,
            tokenInShare,
            to,
            minAmount,
            abi.encode(swapPath)
        );

        return outAmount;
    }

    function _uniswapOutputAmount(
        IYieldBox yieldBox,
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountIn
    ) private view returns (uint256) {
        (, address tokenInAddress, , ) = yieldBox.assets(tokenInId);
        (, address tokenOutAddress, , ) = yieldBox.assets(tokenOutId);
        address[] memory swapPath = new address[](2);
        swapPath[0] = tokenInAddress;
        swapPath[1] = tokenOutAddress;
        uint256 tokenInShare = yieldBox.toShare(tokenInId, amountIn, false);
        return
            univ2Swapper.getOutputAmount(
                tokenInId,
                tokenInShare,
                abi.encode(swapPath)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./bidders/IBidder.sol";

interface ILiquidationQueue {
    enum MODE {
        ADD,
        SUB
    }

    struct PoolInfo {
        uint256 totalAmount; //liquidated asset amount
        mapping(address => Bidder) users;
    }
    struct Bidder {
        bool isUsdo;
        bool swapOnExecute;
        uint256 usdoAmount;
        uint256 liquidatedAssetAmount;
        uint256 timestamp; // Timestamp in second of the last bid.
    }

    struct OrderBookPoolEntry {
        address bidder;
        Bidder bidInfo;
    }

    struct OrderBookPoolInfo {
        uint32 poolId;
        uint32 nextBidPull; // Next position in `entries` to start pulling bids from
        uint32 nextBidPush; // Next position in `entries` to start pushing bids to
    }

    struct LiquidationQueueMeta {
        uint256 activationTime; // Time needed before a bid can be activated for execution
        uint256 minBidAmount; // Minimum bid amount
        address feeCollector; // Address of the fee collector
        IBidder bidExecutionSwapper; //Allows swapping USDO to collateral when a bid is executed
        IBidder usdoSwapper; //Allows swapping any other stablecoin to USDO
    }

    struct BidExecutionData {
        uint256 curPoolId;
        bool isBidAvail;
        OrderBookPoolInfo poolInfo;
        OrderBookPoolEntry orderBookEntry;
        OrderBookPoolEntry orderBookEntryCopy;
        uint256 totalPoolAmountExecuted;
        uint256 totalPoolCollateralLiquidated;
        uint256 totalUsdoAmountUsed;
        uint256 exchangeRate;
        uint256 discountedBidderAmount;
    }

    function init(LiquidationQueueMeta calldata, address singularity) external;

    function onlyOnce() external view returns (bool);

    function setBidExecutionSwapper(address swapper) external;

    function setUsdoSwapper(address swapper) external;

    function getNextAvailBidPool()
        external
        view
        returns (uint256 i, bool available, uint256 totalAmount);

    function executeBids(
        uint256 collateralAmountToLiquidate,
        bytes calldata swapData
    ) external returns (uint256 amountExecuted, uint256 collateralLiquidated);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

import "../interfaces/IPenrose.sol";
import "./ILiquidationQueue.sol";
import "../singularity/interfaces/ISingularity.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IStrategy.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/strategies/ERC20WithoutStrategy.sol";

import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

/// @title LiquidationQueue
/// @author @0xRektora, TapiocaDAO
// TODO: Capital efficiency? (register assets to strategies) (farm strat for TAP)
// TODO: ERC20 impl?
contract LiquidationQueue is ILiquidationQueue {
    // ************ //
    // *** VARS *** //
    // ************ //

    /**
     * General information about the LiquidationQueue contract.
     */

    /// @notice returns metadata information
    LiquidationQueueMeta public liquidationQueueMeta;
    /// @notice targeted market
    ISingularity public singularity;
    /// @notice Penrose addres
    IPenrose public penrose;
    /// @notice YieldBox address
    YieldBox public yieldBox;

    /// @notice liquidation queue Penrose asset id
    uint256 public lqAssetId;
    /// @notice singularity asset id
    uint256 public marketAssetId;
    /// @notice asset that is being liquidated
    uint256 public liquidatedAssetId;

    /// @notice initialization status
    bool public onlyOnce;

    /**
     * Pools & order books information.
     */

    /// @notice Bid pools
    /// @dev x% premium => bid pool
    ///      0 ... 30 range
    ///      poolId => totalAmount
    ///      poolId => userAddress => userBidInfo.
    mapping(uint256 => PoolInfo) public bidPools;

    /// @notice The actual order book. Entries are stored only once a bid has been activated
    /// @dev poolId => bidIndex => bidEntry).
    mapping(uint256 => mapping(uint256 => OrderBookPoolEntry))
        public orderBookEntries;
    /// @notice Meta-data about the order book pool
    /// @dev poolId => poolInfo.
    mapping(uint256 => OrderBookPoolInfo) public orderBookInfos;

    /**
     * Ledger.
     */

    /// @notice User current bids
    /// @dev user => orderBookEntries[poolId][bidIndex]
    mapping(address => mapping(uint256 => uint256[])) public userBidIndexes;

    /// @notice Due balance of users
    /// @dev user => amountDue.
    mapping(address => uint256) public balancesDue;

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    uint256 constant MAX_BID_POOLS = 10; // Maximum amount of pools.
    // `amount` * ((`bidPool` * `PREMIUM_FACTOR`) / `PREMIUM_FACTOR_PRECISION`) = premium.
    uint256 constant PREMIUM_FACTOR = 100; // Premium factor.
    uint256 constant PREMIUM_FACTOR_PRECISION = 10_000; // Precision of the premium factor.

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 private constant WITHDRAWAL_FEE = 50; // 0.5%
    uint256 private constant WITHDRAWAL_FEE_PRECISION = 10_000;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    event Bid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 timestamp
    );

    event ActivateBid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 collateralValue,
        uint256 timestamp
    );

    event RemoveBid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 collateralValue,
        uint256 timestamp
    );

    event ExecuteBids(
        address indexed caller,
        uint256 indexed pool,
        uint256 usdoAmountExecuted,
        uint256 liquidatedAssetAmountExecuted,
        uint256 collateralLiquidated,
        uint256 timestamp
    );

    event Redeem(address indexed redeemer, address indexed to, uint256 amount);
    event BidSwapperUpdated(IBidder indexed _old, address indexed _new);
    event UsdoSwapperUpdated(IBidder indexed _old, address indexed _new);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    modifier Active() {
        require(onlyOnce, "LQ: Not initialized");
        _;
    }

    /// @notice Acts as a 'constructor', should be called by a Singularity market.
    /// @param  _liquidationQueueMeta Info about the liquidations.
    function init(
        LiquidationQueueMeta calldata _liquidationQueueMeta,
        address _mixologist
    ) external override {
        require(!onlyOnce, "LQ: Initialized");

        liquidationQueueMeta = _liquidationQueueMeta;

        singularity = ISingularity(_mixologist);
        liquidatedAssetId = singularity.collateralId();
        marketAssetId = singularity.assetId();
        penrose = IPenrose(singularity.penrose());
        yieldBox = YieldBox(singularity.yieldBox());

        lqAssetId = marketAssetId;

        IERC20(singularity.asset()).approve(
            address(yieldBox),
            type(uint256).max
        );
        yieldBox.setApprovalForAll(address(singularity), true);

        // We initialize the pools to save gas on conditionals later on.
        for (uint256 i = 0; i <= MAX_BID_POOLS; ) {
            _initOrderBookPoolInfo(i);
            ++i;
        }

        onlyOnce = true; // We set the init flag.
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //

    /// @notice returns targeted market
    function market() public view returns (string memory) {
        return singularity.name();
    }

    /// @notice returns order book size
    function getOrderBookSize(uint256 pool) public view returns (uint256 size) {
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        unchecked {
            size = poolInfo.nextBidPush - poolInfo.nextBidPull;
        }
    }

    /// @notice returns an array of 'OrderBookPoolEntry' for a pool
    function getOrderBookPoolEntries(
        uint256 pool
    ) external view returns (OrderBookPoolEntry[] memory x) {
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        uint256 orderBookSize = poolInfo.nextBidPush - poolInfo.nextBidPull;

        x = new OrderBookPoolEntry[](orderBookSize); // Initialize the return array.

        mapping(uint256 => OrderBookPoolEntry)
            storage entries = orderBookEntries[pool];
        for (
            (uint256 i, uint256 j) = (poolInfo.nextBidPull, 0);
            i < poolInfo.nextBidPush;

        ) {
            x[j] = entries[i]; // Copy the entry to the return array.

            unchecked {
                ++i;
                ++j;
            }
        }
    }

    /// @notice Get the next not empty bid pool in ASC order.
    /// @return i The bid pool id.
    /// @return available True if there is at least 1 bid available across all the order books.
    /// @return totalAmount Total available liquidated asset amount.
    function getNextAvailBidPool()
        public
        view
        override
        returns (uint256 i, bool available, uint256 totalAmount)
    {
        for (; i <= MAX_BID_POOLS; ) {
            if (getOrderBookSize(i) != 0) {
                available = true;
                totalAmount = bidPools[i].totalAmount;
                break;
            }
            ++i;
        }
    }

    /// @notice returns user data for an existing bid pool
    /// @param pool the pool identifier
    /// @param user the user identifier
    function getBidPoolUserInfo(
        uint256 pool,
        address user
    ) external view returns (Bidder memory) {
        return bidPools[pool].users[user];
    }

    /// @notice returns number of pool bids for user
    function userBidIndexLength(
        address user,
        uint256 pool
    ) external view returns (uint256 len) {
        uint256[] memory bidIndexes = userBidIndexes[user][pool];

        uint256 bidIndexesLen = bidIndexes.length;
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        for (uint256 i = 0; i < bidIndexesLen; ) {
            if (bidIndexes[i] >= poolInfo.nextBidPull) {
                bidIndexesLen--;
            }
            unchecked {
                ++i;
            }
        }

        return bidIndexes.length;
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Add a bid to a bid pool using stablecoins.
    /// @dev Works the same way as `bid` but performs a swap from the stablecoin to USDO
    ///      - if stableAssetId == usdoAssetId, no swap is performed
    /// @param user The bidder
    /// @param pool To which pool the bid should go
    /// @param stableAssetId Stablecoin YieldBox asset id
    /// @param amountIn Stablecoin amount
    /// @param data Extra data for swap operations
    function bidWithStable(
        address user,
        uint256 pool,
        uint256 stableAssetId,
        uint256 amountIn,
        bytes calldata data
    ) external Active {
        require(pool <= MAX_BID_POOLS, "LQ: premium too high");
        require(
            address(liquidationQueueMeta.usdoSwapper) != address(0),
            "LQ: USDO swapper not set"
        );

        uint256 usdoAssetId = penrose.usdoAssetId();
        yieldBox.transfer(
            msg.sender,
            address(liquidationQueueMeta.usdoSwapper),
            stableAssetId,
            yieldBox.toShare(stableAssetId, amountIn, false)
        );

        uint256 usdoAmount = liquidationQueueMeta.usdoSwapper.swap(
            address(singularity),
            stableAssetId,
            amountIn,
            data
        );

        Bidder memory bidder = _bid(user, pool, usdoAmount, true);

        uint256 usdoValueInLqAsset = bidder.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                address(singularity),
                usdoAssetId,
                usdoAmount,
                data
            )
            : bidder.usdoAmount;

        require(
            usdoValueInLqAsset >= liquidationQueueMeta.minBidAmount,
            "LQ: bid too low"
        );
    }

    /// @notice Add a bid to a bid pool.
    /// @dev Create an entry in `bidPools`.
    ///      Clean the userBidIndex here instead of the `executeBids()` function to save on gas.
    /// @param user The bidder.
    /// @param pool To which pool the bid should go.
    /// @param amount The amount in asset to bid.
    function bid(address user, uint256 pool, uint256 amount) external Active {
        require(pool <= MAX_BID_POOLS, "LQ: premium too high");
        require(amount >= liquidationQueueMeta.minBidAmount, "LQ: bid too low");

        // Transfer assets to the LQ contract.
        uint256 assetId = lqAssetId;
        yieldBox.transfer(
            msg.sender,
            address(this),
            assetId,
            yieldBox.toShare(assetId, amount, false)
        );
        _bid(user, pool, amount, false);
    }

    /// @notice Activate a bid by putting it in the order book.
    /// @dev Create an entry in `orderBook` and remove it from `bidPools`.
    /// @dev Spam vector attack is mitigated the min amount req., 10min CD + activation fees.
    /// @param user The user to activate the bid for.
    /// @param pool The target pool.
    function activateBid(address user, uint256 pool) external {
        Bidder memory bidder = bidPools[pool].users[user];

        require(bidder.timestamp > 0, "LQ: bid not available"); //fail early
        require(
            block.timestamp >=
                bidder.timestamp + liquidationQueueMeta.activationTime,
            "LQ: too soon"
        );

        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool]; // Info about the pool array indexes.

        // Create a new order book entry.
        OrderBookPoolEntry memory orderBookEntry;
        orderBookEntry.bidder = user;
        orderBookEntry.bidInfo = bidder;

        // Insert the order book entry and delete the bid entry from the given pool.
        orderBookEntries[pool][poolInfo.nextBidPush] = orderBookEntry;
        delete bidPools[pool].users[user];

        // Add the index to the user bid index.
        userBidIndexes[user][pool].push(poolInfo.nextBidPush);

        // Update the `orderBookInfos`.
        unchecked {
            ++poolInfo.nextBidPush;
        }
        orderBookInfos[pool] = poolInfo;

        uint256 bidAmount = orderBookEntry.bidInfo.isUsdo
            ? orderBookEntry.bidInfo.usdoAmount
            : orderBookEntry.bidInfo.liquidatedAssetAmount;
        uint256 assetValue = orderBookEntry.bidInfo.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                address(singularity),
                penrose.usdoAssetId(),
                orderBookEntry.bidInfo.usdoAmount,
                ""
            )
            : bidAmount;
        bidPools[pool].totalAmount += assetValue;
        emit ActivateBid(
            msg.sender,
            user,
            pool,
            orderBookEntry.bidInfo.usdoAmount,
            orderBookEntry.bidInfo.liquidatedAssetAmount,
            assetValue,
            block.timestamp
        );
    }

    /// @notice Remove a not yet activated bid from the bid pool.
    /// @dev Remove `msg.sender` funds.
    /// @param user The user to send the funds to.
    /// @param pool The pool to remove the bid from.
    /// @return amountRemoved The amount of the bid.
    function removeBid(
        address user,
        uint256 pool
    ) external returns (uint256 amountRemoved) {
        bool isUsdo = bidPools[pool].users[msg.sender].isUsdo;
        amountRemoved = isUsdo
            ? bidPools[pool].users[msg.sender].usdoAmount
            : bidPools[pool].users[msg.sender].liquidatedAssetAmount;
        require(amountRemoved > 0, "LQ: bid not available");
        delete bidPools[pool].users[msg.sender];

        uint256 lqAssetValue = amountRemoved;
        if (bidPools[pool].users[msg.sender].swapOnExecute) {
            lqAssetValue = liquidationQueueMeta
                .bidExecutionSwapper
                .getOutputAmount(
                    address(singularity),
                    penrose.usdoAssetId(),
                    amountRemoved,
                    ""
                );
        }
        require(
            lqAssetValue >= liquidationQueueMeta.minBidAmount,
            "LQ: bid does not exist"
        ); //save gas

        // Transfer assets
        uint256 assetId = isUsdo ? penrose.usdoAssetId() : lqAssetId;
        yieldBox.transfer(
            address(this),
            user,
            assetId,
            yieldBox.toShare(assetId, amountRemoved, false)
        );

        emit RemoveBid(
            msg.sender,
            user,
            pool,
            isUsdo ? amountRemoved : 0,
            isUsdo ? 0 : amountRemoved,
            lqAssetValue,
            block.timestamp
        );
    }

    /// @notice Redeem a balance.
    /// @dev `msg.sender` is used as the redeemer.
    /// @param to The address to redeem to.
    function redeem(address to) external {
        require(balancesDue[msg.sender] > 0, "LQ: No balance due");

        uint256 balance = balancesDue[msg.sender];
        uint256 fee = (balance * WITHDRAWAL_FEE) / WITHDRAWAL_FEE_PRECISION;
        uint256 redeemable = balance - fee;

        balancesDue[msg.sender] = 0;
        balancesDue[liquidationQueueMeta.feeCollector] += fee;

        uint256 assetId = liquidatedAssetId;
        yieldBox.transfer(
            address(this),
            to,
            assetId,
            yieldBox.toShare(assetId, redeemable, false)
        );

        emit Redeem(msg.sender, to, redeemable);
    }

    /// @notice Execute the liquidation call by executing the bids placed in the pools in ASC order.
    /// @dev Should only be called from Singularity.
    ///      Singularity should send the `collateralAmountToLiquidate` to this contract before calling this function.
    /// Tx will fail if it can't transfer allowed Penrose asset from Singularity.
    /// @param collateralAmountToLiquidate The amount of collateral to liquidate.
    /// @param swapData Swap data necessary for swapping USDO to market asset; necessary only if bidder added USDO
    /// @return totalAmountExecuted The amount of asset that was executed.
    /// @return totalCollateralLiquidated The amount of collateral that was liquidated.
    function executeBids(
        uint256 collateralAmountToLiquidate,
        bytes calldata swapData
    )
        external
        override
        returns (uint256 totalAmountExecuted, uint256 totalCollateralLiquidated)
    {
        require(msg.sender == address(singularity), "LQ: Only Singularity");
        BidExecutionData memory data;

        (data.curPoolId, data.isBidAvail, ) = getNextAvailBidPool();
        data.exchangeRate = singularity.exchangeRate();
        // We loop through all the bids for each pools until all the collateral is liquidated
        // or no more bid are available.
        while (collateralAmountToLiquidate > 0 && data.isBidAvail) {
            data.poolInfo = orderBookInfos[data.curPoolId];
            // Reset pool vars.
            data.totalPoolAmountExecuted = 0;
            data.totalPoolCollateralLiquidated = 0;
            // While bid pool is not empty and we haven't liquidated enough collateral.
            while (
                collateralAmountToLiquidate > 0 &&
                data.poolInfo.nextBidPull != data.poolInfo.nextBidPush
            ) {
                // Get the next bid.
                data.orderBookEntry = orderBookEntries[data.curPoolId][
                    data.poolInfo.nextBidPull
                ];
                data.orderBookEntryCopy = data.orderBookEntry;

                // Get the total amount of asset with the pool discount applied for the bidder.
                data
                    .discountedBidderAmount = _viewBidderDiscountedCollateralAmount(
                    data.orderBookEntryCopy.bidInfo,
                    data.exchangeRate,
                    data.curPoolId
                );

                // Check if the bidder can pay the remaining collateral to liquidate `collateralAmountToLiquidate`.
                if (data.discountedBidderAmount > collateralAmountToLiquidate) {
                    (
                        uint256 finalDiscountedCollateralAmount,
                        uint256 finalUsdoAmount
                    ) = _userPartiallyBidAmount(
                            data.orderBookEntryCopy.bidInfo,
                            collateralAmountToLiquidate,
                            data.exchangeRate,
                            data.curPoolId,
                            swapData
                        );

                    // Execute the bid.
                    balancesDue[
                        data.orderBookEntryCopy.bidder
                    ] += collateralAmountToLiquidate; // Write balance.

                    if (!data.orderBookEntry.bidInfo.isUsdo) {
                        data
                            .orderBookEntry
                            .bidInfo
                            .liquidatedAssetAmount -= finalDiscountedCollateralAmount; // Update bid entry amount.
                    } else {
                        data
                            .orderBookEntry
                            .bidInfo
                            .usdoAmount -= finalUsdoAmount;
                    }

                    // Update the total amount executed, the total collateral liquidated and collateral to liquidate.
                    data
                        .totalPoolAmountExecuted += finalDiscountedCollateralAmount;
                    data
                        .totalPoolCollateralLiquidated += collateralAmountToLiquidate;
                    collateralAmountToLiquidate = 0; // Since we have liquidated all the collateral.
                    data.totalUsdoAmountUsed += finalUsdoAmount;

                    orderBookEntries[data.curPoolId][data.poolInfo.nextBidPull]
                        .bidInfo = data.orderBookEntry.bidInfo;
                } else {
                    (
                        uint256 finalCollateralAmount,
                        uint256 finalDiscountedCollateralAmount,
                        uint256 finalUsdoAmount
                    ) = _useEntireBidAmount(
                            data.orderBookEntryCopy.bidInfo,
                            data.discountedBidderAmount,
                            data.exchangeRate,
                            data.curPoolId,
                            swapData
                        );
                    // Execute the bid.
                    balancesDue[
                        data.orderBookEntryCopy.bidder
                    ] += finalDiscountedCollateralAmount; // Write balance.
                    data.orderBookEntry.bidInfo.usdoAmount = 0; // Update bid entry amount.
                    data.orderBookEntry.bidInfo.liquidatedAssetAmount = 0; // Update bid entry amount.
                    // Update the total amount executed, the total collateral liquidated and collateral to liquidate.
                    data.totalUsdoAmountUsed += finalUsdoAmount;
                    data.totalPoolAmountExecuted += finalCollateralAmount;
                    data
                        .totalPoolCollateralLiquidated += finalDiscountedCollateralAmount;

                    collateralAmountToLiquidate -= finalDiscountedCollateralAmount;
                    orderBookEntries[data.curPoolId][data.poolInfo.nextBidPull]
                        .bidInfo = data.orderBookEntry.bidInfo;
                    // Since the current bid was fulfilled, get the next one.
                    unchecked {
                        ++data.poolInfo.nextBidPull;
                    }
                }
            }
            // Update the totals.
            totalAmountExecuted += data.totalPoolAmountExecuted;
            totalCollateralLiquidated += data.totalPoolCollateralLiquidated;
            orderBookInfos[data.curPoolId] = data.poolInfo; // Update the pool info for the current pool.
            // Look up for the next available bid pool.
            (data.curPoolId, data.isBidAvail, ) = getNextAvailBidPool();
            bidPools[data.curPoolId].totalAmount -= totalAmountExecuted;

            emit ExecuteBids(
                msg.sender,
                data.curPoolId,
                data.totalUsdoAmountUsed,
                data.totalPoolAmountExecuted,
                data.totalPoolCollateralLiquidated,
                block.timestamp
            );
        }
        // Stack too deep
        {
            uint256 toSend = totalAmountExecuted;

            // Transfer the assets to the Singularity.
            yieldBox.withdraw(
                lqAssetId,
                address(this),
                address(this),
                toSend,
                0
            );
            yieldBox.depositAsset(
                marketAssetId,
                address(this),
                address(singularity),
                toSend,
                0
            );
        }
    }

    /// @notice updates the bid swapper address
    /// @param _swapper thew new ICollateralSwaper contract address
    function setBidExecutionSwapper(address _swapper) external override {
        require(msg.sender == address(singularity), "unauthorized");
        emit BidSwapperUpdated(
            liquidationQueueMeta.bidExecutionSwapper,
            _swapper
        );
        liquidationQueueMeta.bidExecutionSwapper = IBidder(_swapper);
    }

    /// @notice updates the bid swapper address
    /// @param _swapper thew new ICollateralSwaper contract address
    function setUsdoSwapper(address _swapper) external override {
        require(msg.sender == address(singularity), "unauthorized");
        emit UsdoSwapperUpdated(liquidationQueueMeta.usdoSwapper, _swapper);
        liquidationQueueMeta.usdoSwapper = IBidder(_swapper);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _viewBidderDiscountedCollateralAmount(
        Bidder memory entry,
        uint256 exchangeRate,
        uint256 poolId
    ) private view returns (uint256) {
        uint256 bidAmount = entry.isUsdo
            ? entry.usdoAmount
            : entry.liquidatedAssetAmount;
        uint256 liquidatedAssetAmount = entry.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                address(singularity),
                penrose.usdoAssetId(),
                entry.usdoAmount,
                ""
            )
            : bidAmount;
        return
            _getPremiumAmount(
                _bidToCollateral(liquidatedAssetAmount, exchangeRate),
                poolId,
                MODE.ADD
            );
    }

    function _useEntireBidAmount(
        Bidder memory entry,
        uint256 discountedBidderAmount,
        uint256 exchangeRate,
        uint256 poolId,
        bytes memory swapData
    )
        private
        returns (
            uint256 finalCollateralAmount,
            uint256 finalDiscountedCollateralAmount,
            uint256 finalUsdoAmount
        )
    {
        finalCollateralAmount = entry.liquidatedAssetAmount;
        finalDiscountedCollateralAmount = discountedBidderAmount;
        finalUsdoAmount = entry.usdoAmount;
        //Execute the swap if USDO was provided and it's different from the liqudation asset id
        if (entry.swapOnExecute) {
            yieldBox.transfer(
                address(this),
                address(liquidationQueueMeta.bidExecutionSwapper),
                penrose.usdoAssetId(),
                yieldBox.toShare(penrose.usdoAssetId(), entry.usdoAmount, false)
            );

            finalCollateralAmount = liquidationQueueMeta
                .bidExecutionSwapper
                .swap(
                    address(singularity),
                    penrose.usdoAssetId(),
                    entry.usdoAmount,
                    swapData
                );
            finalDiscountedCollateralAmount = _getPremiumAmount(
                _bidToCollateral(finalCollateralAmount, exchangeRate),
                poolId,
                MODE.ADD
            );
        }
    }

    function _userPartiallyBidAmount(
        Bidder memory entry,
        uint256 collateralAmountToLiquidate,
        uint256 exchangeRate,
        uint256 poolId,
        bytes memory swapData
    )
        private
        returns (
            uint256 finalDiscountedCollateralAmount,
            uint256 finalUsdoAmount
        )
    {
        finalUsdoAmount = 0;
        finalDiscountedCollateralAmount = _getPremiumAmount(
            _collateralToBid(collateralAmountToLiquidate, exchangeRate),
            poolId,
            MODE.SUB
        );

        //Execute the swap if USDO was provided and it's different from the liqudation asset id
        uint256 usdoAssetId = penrose.usdoAssetId();
        if (entry.swapOnExecute) {
            finalUsdoAmount = liquidationQueueMeta
                .bidExecutionSwapper
                .getInputAmount(
                    address(singularity),
                    usdoAssetId,
                    finalDiscountedCollateralAmount,
                    ""
                );

            yieldBox.transfer(
                address(this),
                address(liquidationQueueMeta.bidExecutionSwapper),
                usdoAssetId,
                yieldBox.toShare(usdoAssetId, finalUsdoAmount, false)
            );
            uint256 returnedCollateral = liquidationQueueMeta
                .bidExecutionSwapper
                .swap(
                    address(singularity),
                    usdoAssetId,
                    finalUsdoAmount,
                    swapData
                );
            require(
                returnedCollateral >= finalDiscountedCollateralAmount,
                "need-more-collateral"
            );
        }
    }

    function _bid(
        address user,
        uint256 pool,
        uint256 amount,
        bool isUsdo
    ) private returns (Bidder memory bidder) {
        bidder.usdoAmount = isUsdo ? amount : 0;
        bidder.liquidatedAssetAmount = isUsdo ? 0 : amount;
        bidder.timestamp = block.timestamp;
        bidder.isUsdo = isUsdo;
        bidder.swapOnExecute = isUsdo && lqAssetId != penrose.usdoAssetId();

        bidPools[pool].users[user] = bidder;

        emit Bid(
            msg.sender,
            user,
            pool,
            isUsdo ? amount : 0, //USDO amount
            isUsdo ? 0 : amount, //liquidated asset amount
            block.timestamp
        );

        // Clean the userBidIndex.
        uint256[] storage bidIndexes = userBidIndexes[user][pool];
        uint256 bidIndexesLen = bidIndexes.length;
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        for (uint256 i = 0; i < bidIndexesLen; ) {
            if (bidIndexes[i] >= poolInfo.nextBidPull) {
                bidIndexesLen = bidIndexes.length;
                bidIndexes[i] = bidIndexes[bidIndexesLen - 1];
                bidIndexes.pop();
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Called with `init`, setup the initial pool info values.
    /// @param pool The targeted pool.
    function _initOrderBookPoolInfo(uint256 pool) internal {
        OrderBookPoolInfo memory poolInfo;
        poolInfo.poolId = uint32(pool);
        orderBookInfos[pool] = poolInfo;
    }

    /// @notice Get the discount gained from a bid in a `poolId` given a `amount`.
    /// @param amount The amount of collateral to get the discount from.
    /// @param poolId The targeted pool.
    /// @param mode 0 subtract - 1 add.
    function _getPremiumAmount(
        uint256 amount,
        uint256 poolId,
        MODE mode
    ) internal pure returns (uint256) {
        uint256 premium = (amount * poolId * PREMIUM_FACTOR) /
            PREMIUM_FACTOR_PRECISION;
        return mode == MODE.ADD ? amount + premium : amount - premium;
    }

    /// @notice Convert a bid amount to a collateral amount.
    /// @param amount The amount of bid to convert.
    /// @param exchangeRate The exchange rate to use.
    function _bidToCollateral(
        uint256 amount,
        uint256 exchangeRate
    ) internal pure returns (uint256) {
        return (amount * exchangeRate) / EXCHANGE_RATE_PRECISION;
    }

    /// @notice Convert a collateral amount to a bid amount.
    /// @param collateralAmount The amount of collateral to convert.
    /// @param exchangeRate The exchange rate to use.
    function _collateralToBid(
        uint256 collateralAmount,
        uint256 exchangeRate
    ) internal pure returns (uint256) {
        return (collateralAmount * EXCHANGE_RATE_PRECISION) / exchangeRate;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../ILiquidationQueue.sol";
import "../../interfaces/IPenrose.sol";

contract LQSingularityMock {
    IPenrose immutable penrose;

    uint256 immutable assetId;

    uint256 constant EXCHANGE_RATE_PRECISION = 1e18;

    constructor(IPenrose _penrose, uint256 _assetId) {
        penrose = _penrose;
        assetId = _assetId;
    }

    function initLq(
        ILiquidationQueue liquidationQueue,
        ILiquidationQueue.LiquidationQueueMeta calldata lqMeta
    ) external {
        liquidationQueue.init(lqMeta, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

import "./interfaces/IMarket.sol";
import "./interfaces/IOracle.sol";
import "./usd0/interfaces/IBigBang.sol";
import "./singularity/interfaces/ISingularity.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

/// @title Useful helper functions for `Singularity` and `BingBang`
contract MarketsHelper {
    using RebaseLibrary for Rebase;

    struct MarketInfo {
        address collateral;
        uint256 collateralId;
        address asset;
        uint256 assetId;
        IOracle oracle;
        bytes oracleData;
        uint256 totalCollateralShare;
        uint256 userCollateralShare;
        Rebase totalBorrow;
        uint256 userBorrowPart;
        uint256 currentExchangeRate;
        uint256 spotExchangeRate;
        uint256 oracleExchangeRate;
        uint256 totalBorrowCap;
    }
    struct SingularityInfo {
        MarketInfo market;
        Rebase totalAsset;
        uint256 userAssetFraction;
        ISingularity.AccrueInfo accrueInfo;
    }
    struct BigBangInfo {
        MarketInfo market;
        IBigBang.AccrueInfo accrueInfo;
    }

    function singularityMarketInfo(
        address who,
        ISingularity[] memory markets
    ) external view returns (SingularityInfo[] memory) {
        uint256 len = markets.length;
        SingularityInfo[] memory result = new SingularityInfo[](len);

        Rebase memory _totalAsset;
        ISingularity.AccrueInfo memory _accrueInfo;
        for (uint256 i = 0; i < len; i++) {
            ISingularity sgl = markets[i];

            result[i].market = _commonInfo(who, IMarket(address(sgl)));

            (uint128 totalAssetElastic, uint128 totalAssetBase) = sgl //
                .totalAsset(); //
            _totalAsset = Rebase(totalAssetElastic, totalAssetBase); //
            result[i].totalAsset = _totalAsset; //
            result[i].userAssetFraction = sgl.balanceOf(who); //

            (
                uint64 interestPerSecond,
                uint64 lastBlockAccrued,
                uint128 feesEarnedFraction
            ) = sgl.accrueInfo();
            _accrueInfo = ISingularity.AccrueInfo(
                interestPerSecond,
                lastBlockAccrued,
                feesEarnedFraction
            );
            result[i].accrueInfo = _accrueInfo;
        }

        return result;
    }

    function bigBangMarketInfo(
        address who,
        IBigBang[] memory markets
    ) external view returns (BigBangInfo[] memory) {
        uint256 len = markets.length;
        BigBangInfo[] memory result = new BigBangInfo[](len);

        IBigBang.AccrueInfo memory _accrueInfo;
        for (uint256 i = 0; i < len; i++) {
            IBigBang bigBang = markets[i];
            result[i].market = _commonInfo(who, IMarket(address(bigBang)));

            (uint64 debtRate, uint64 lastAccrued) = bigBang.accrueInfo();
            _accrueInfo = IBigBang.AccrueInfo(debtRate, lastAccrued);
            result[i].accrueInfo = _accrueInfo;
        }

        return result;
    }

    /// @notice Calculate the collateral amount off the shares.
    /// @param market the Singularity or BigBang address
    /// @param share The shares.
    /// @return amount The amount.
    function getCollateralAmountForShare(
        IMarket market,
        uint256 share
    ) public view returns (uint256 amount) {
        IYieldBox yieldBox = IYieldBox(market.yieldBox());
        return yieldBox.toAmount(market.collateralId(), share, false);
    }

    /// @notice Calculate the collateral shares that are needed for `borrowPart`,
    /// taking the current exchange rate into account.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The borrow part.
    /// @return collateralShares The collateral shares.
    function getCollateralSharesForBorrowPart(
        IMarket market,
        uint256 borrowPart,
        uint256 liquidationMultiplierPrecision,
        uint256 exchangeRatePrecision
    ) public view returns (uint256 collateralShares) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        IYieldBox yieldBox = IYieldBox(market.yieldBox());
        uint256 borrowAmount = _totalBorrowed.toElastic(borrowPart, false);
        return
            yieldBox.toShare(
                market.collateralId(),
                (borrowAmount *
                    market.liquidationMultiplier() *
                    market.exchangeRate()) /
                    (liquidationMultiplierPrecision * exchangeRatePrecision),
                false
            );
    }

    /// @notice Return the equivalent of borrow part in asset amount.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The amount of borrow part to convert.
    /// @return amount The equivalent of borrow part in asset amount.
    function getAmountForBorrowPart(
        IMarket market,
        uint256 borrowPart
    ) public view returns (uint256 amount) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toElastic(borrowPart, false);
    }

    /// @notice Compute the amount of `singularity.assetId` from `fraction`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param fraction The fraction.
    /// @return amount The amount.
    function getAmountForAssetFraction(
        ISingularity singularity,
        uint256 fraction
    ) public view returns (uint256 amount) {
        (uint128 totalAssetElastic, uint128 totalAssetBase) = singularity
            .totalAsset();

        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());
        return
            yieldBox.toAmount(
                singularity.assetId(),
                (fraction * totalAssetElastic) / totalAssetBase,
                false
            );
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice deposts collateral to YieldBox, adds collateral to Singularity, borrows and can withdraw to personal address
    /// @param market the Singularity or BigBang address
    /// @param _collateralAmount the collateral amount to add
    /// @param _borrowAmount the amount to borrow
    /// @param deposit_ if true, deposits to YieldBox from `msg.sender`
    /// @param withdraw_ if true, withdraws from YieldBox to `msg.sender`
    /// @param _withdrawData custom withdraw data; ignore if you need to withdraw on the same chain
    function depositAddCollateralAndBorrow(
        IMarket market,
        uint256 _collateralAmount,
        uint256 _borrowAmount,
        bool deposit_,
        bool withdraw_,
        bytes calldata _withdrawData
    ) external payable {
        YieldBox yieldBox = YieldBox(market.yieldBox());

        uint256 collateralId = market.collateralId();

        (, address collateralAddress, , ) = yieldBox.assets(collateralId);

        //deposit into the yieldbox
        uint256 _share = yieldBox.toShare(
            collateralId,
            _collateralAmount,
            false
        );
        if (deposit_) {
            _extractTokens(collateralAddress, _collateralAmount);
            IERC20(collateralAddress).approve(
                address(yieldBox),
                _collateralAmount
            );
            yieldBox.depositAsset(
                collateralId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        //add collateral
        _setApprovalForYieldBox(market, yieldBox);
        market.addCollateral(
            deposit_ ? address(this) : msg.sender,
            msg.sender,
            false,
            _share
        );

        //borrow
        address borrowReceiver = withdraw_ ? address(this) : msg.sender;
        market.borrow(msg.sender, borrowReceiver, _borrowAmount);

        if (withdraw_) {
            _withdraw(
                borrowReceiver,
                _withdrawData,
                market,
                yieldBox,
                _borrowAmount,
                0,
                false
            );
        }
    }

    /// @notice deposits to YieldBox and repays borrowed amount
    /// @param market the Singularity or BigBang address
    /// @param _depositAmount the amount to deposit
    /// @param _repayAmount the amount to be repayed
    function depositAndRepay(
        IMarket market,
        uint256 _depositAmount,
        uint256 _repayAmount,
        bool deposit_
    ) public {
        uint256 assetId = market.assetId();
        YieldBox yieldBox = YieldBox(market.yieldBox());

        (, address assetAddress, , ) = yieldBox.assets(assetId);

        //deposit into the yieldbox
        if (deposit_) {
            _extractTokens(assetAddress, _depositAmount);
            IERC20(assetAddress).approve(address(yieldBox), _depositAmount);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                _depositAmount,
                0
            );
        }

        //repay
        _setApprovalForYieldBox(market, yieldBox);
        market.repay(
            deposit_ ? address(this) : msg.sender,
            msg.sender,
            false,
            _repayAmount
        );
    }

    /// @notice deposits to YieldBox, repays borrowed amount and removes collateral
    /// @param market the Singularity or BigBang address
    /// @param _depositAmount the amount to deposit
    /// @param _repayAmount the amount to be repayed
    /// @param _collateralAmount collateral amount to be removed
    /// @param deposit_ if true deposits to YieldBox
    /// @param withdraw_ if true withdraws to sender address
    function depositRepayAndRemoveCollateral(
        IMarket market,
        uint256 _depositAmount,
        uint256 _repayAmount,
        uint256 _collateralAmount,
        bool deposit_,
        bool withdraw_
    ) external {
        YieldBox yieldBox = YieldBox(market.yieldBox());

        depositAndRepay(market, _depositAmount, _repayAmount, deposit_);

        //remove collateral
        address receiver = withdraw_ ? address(this) : msg.sender;
        uint256 collateralShare = yieldBox.toShare(
            market.collateralId(),
            _collateralAmount,
            false
        );
        market.removeCollateral(msg.sender, receiver, collateralShare);

        //withdraw
        if (withdraw_) {
            yieldBox.withdraw(
                market.collateralId(),
                address(this),
                msg.sender,
                _collateralAmount,
                0
            );
        }
    }

    /// @notice deposits asset to YieldBox and lends it to Singularity
    /// @param singularity the singularity address
    /// @param _amount the amount to lend
    function depositAndAddAsset(
        ISingularity singularity,
        uint256 _amount,
        bool deposit_
    ) external {
        uint256 assetId = singularity.assetId();
        YieldBox yieldBox = YieldBox(singularity.yieldBox());

        (, address assetAddress, , ) = yieldBox.assets(assetId);

        uint256 _share = yieldBox.toShare(assetId, _amount, false);
        if (deposit_) {
            //deposit into the yieldbox
            _extractTokens(assetAddress, _amount);
            IERC20(assetAddress).approve(address(yieldBox), _amount);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        //add asset
        _setApprovalForYieldBox(singularity, yieldBox);
        singularity.addAsset(address(this), msg.sender, false, _share);
    }

    /// @notice deposits asset to YieldBox, mints USDO and lends it to Singularity
    /// @param singularity the Singularity address
    /// @param bingBang the BingBang address
    /// @param _collateralAmount the amount added to BingBang as collateral
    /// @param _borrowAmount the borrowed amount from BingBang
    /// @param deposit_ if true deposits to YieldBox
    function mintAndLend(
        ISingularity singularity,
        IMarket bingBang,
        uint256 _collateralAmount,
        uint256 _borrowAmount,
        bool deposit_
    ) external {
        uint256 collateralId = bingBang.collateralId();
        YieldBox yieldBox = YieldBox(singularity.yieldBox());

        (, address collateralAddress, , ) = yieldBox.assets(collateralId);
        uint256 _share = yieldBox.toShare(
            collateralId,
            _collateralAmount,
            false
        );

        if (deposit_) {
            //deposit to YieldBox
            _extractTokens(collateralAddress, _collateralAmount);
            IERC20(collateralAddress).approve(
                address(yieldBox),
                _collateralAmount
            );
            yieldBox.depositAsset(
                collateralId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        if (_collateralAmount > 0) {
            //add collateral to BingBang
            _setApprovalForYieldBox(bingBang, yieldBox);
            bingBang.addCollateral(address(this), msg.sender, false, _share);
        }

        //borrow from BingBang
        bingBang.borrow(msg.sender, msg.sender, _borrowAmount);

        //lend to Singularity
        uint256 assetId = singularity.assetId();
        uint256 borrowShare = yieldBox.toShare(assetId, _borrowAmount, false);
        _setApprovalForYieldBox(singularity, yieldBox);
        singularity.addAsset(msg.sender, msg.sender, false, borrowShare);
    }

    function removeAssetAndRepay(
        ISingularity singularity,
        IMarket bingBang,
        uint256 _removeShare, //slightly greater than _repayAmount to cover the interest
        uint256 _repayAmount,
        uint256 _collateralShare,
        bool withdraw_,
        bytes calldata withdrawData_
    ) external {
        YieldBox yieldBox = YieldBox(singularity.yieldBox());

        //remove asset
        uint256 bbAssetId = bingBang.assetId();
        uint256 _removeAmount = yieldBox.toAmount(
            bbAssetId,
            _removeShare,
            false
        );
        singularity.removeAsset(msg.sender, address(this), _removeShare);

        //repay
        uint256 repayed = bingBang.repay(
            address(this),
            msg.sender,
            false,
            _repayAmount
        );
        if (repayed < _removeAmount) {
            yieldBox.transfer(
                address(this),
                msg.sender,
                bbAssetId,
                yieldBox.toShare(bbAssetId, _removeAmount - repayed, false)
            );
        }

        //remove collateral
        bingBang.removeCollateral(
            msg.sender,
            withdraw_ ? address(this) : msg.sender,
            _collateralShare
        );

        //withdraw
        if (withdraw_) {
            _withdraw(
                address(this),
                withdrawData_,
                singularity,
                yieldBox,
                0,
                _collateralShare,
                true
            );
        }
    }

    // ************************** //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _commonInfo(
        address who,
        IMarket market
    ) private view returns (MarketInfo memory) {
        Rebase memory _totalBorrowed;
        MarketInfo memory info;

        info.collateral = market.collateral();
        info.asset = market.asset();
        info.oracle = market.oracle();
        info.oracleData = market.oracleData();
        info.totalCollateralShare = market.totalCollateralShare();
        info.userCollateralShare = market.userCollateralShare(who);

        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);
        info.totalBorrow = _totalBorrowed;
        info.userBorrowPart = market.userBorrowPart(who);

        info.currentExchangeRate = market.exchangeRate();
        (, info.oracleExchangeRate) = market.oracle().peek(market.oracleData());
        info.spotExchangeRate = market.oracle().peekSpot(market.oracleData());
        info.totalBorrowCap = market.totalBorrowCap();
        info.assetId = market.assetId();
        info.collateralId = market.collateralId();
        return info;
    }

    function _withdraw(
        address _from,
        bytes calldata _withdrawData,
        IMarket market,
        YieldBox yieldBox,
        uint256 _amount,
        uint256 _share,
        bool _withdrawCollateral
    ) private {
        bool _otherChain;
        uint16 _destChain;
        bytes32 _receiver;
        bytes memory _adapterParams;
        if (_withdrawData.length > 0) {
            (_otherChain, _destChain, _receiver, _adapterParams) = abi.decode(
                _withdrawData,
                (bool, uint16, bytes32, bytes)
            );
        }
        if (!_otherChain) {
            yieldBox.withdraw(
                _withdrawCollateral ? market.collateralId() : market.assetId(),
                address(this),
                msg.sender,
                _amount,
                _share
            );
            return;
        }

        market.withdrawTo{value: msg.value}(
            _from,
            _destChain,
            _receiver,
            _amount,
            _adapterParams,
            payable(msg.sender)
        );
    }

    function _setApprovalForYieldBox(
        IMarket market,
        YieldBox yieldBox
    ) private {
        bool isApproved = yieldBox.isApprovedForAll(
            address(this),
            address(market)
        );
        if (!isApproved) {
            yieldBox.setApprovalForAll(address(market), true);
        }
        isApproved = yieldBox.isApprovedForAll(address(this), address(market));
    }

    function _extractTokens(address _token, uint256 _amount) private {
        require(
            ERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "transfer failed"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "tapioca-sdk/dist/contracts/lzApp/NonblockingLzApp.sol";

import "./interfaces/IMarket.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/
/// @title Omnichain proxy for Singularity
contract MarketsProxy is NonblockingLzApp {
    // ************ //
    // *** VARS *** //
    // ************ //
    bool public useCustomAdapterParams;

    // Address of the whitelisted Singularity contracts
    mapping(address => bool) public markets;

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    uint256 public constant NO_EXTRA_GAS = 0;
    uint256 public constant FUNCTION_TYPE_SEND = 1;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    event ReceiveFromChain(
        uint16 indexed _srcChainId,
        address indexed _dstSingularity,
        bytes _sglPayload
    );
    event SendToChain(
        uint16 indexed _srcChainId,
        address indexed _srcAddress,
        bytes _sglPayload
    );
    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
    event LogMarketStatus(address indexed singularity, bool status);

    /// @notice creates a new SGLProxy contract
    /// @param _lzEndpoint LayerZero endpoint address
    /// @param _owner contract's owner address
    constructor(
        address _lzEndpoint,
        address _owner
    ) NonblockingLzApp(_lzEndpoint) {
        _transferOwnership(_owner);
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice execute Singularity methods on another chain
    /// @param _dstChainId te LayerZero destination chain id
    /// @param _marketDstAddress destination Market address
    /// @param _marketCalls Market calls
    /// @param _adapterParams custom adapters
    function executeOnChain(
        uint16 _dstChainId,
        address _marketDstAddress,
        bytes[] memory _marketCalls,
        bytes memory _adapterParams
    ) external payable {
        uint256 chainId = lzEndpoint.getChainId();
        require(chainId != _dstChainId, "MarketsProxy: chain not valid");

        _send(
            msg.sender,
            _dstChainId,
            _marketDstAddress,
            _marketCalls,
            payable(msg.sender),
            address(0),
            _adapterParams
        );
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice set whitelist status for market
    /// @dev callable by owner
    /// @param _market the market address
    /// @param _status whitelisted/not
    function updateMarketStatus(
        address _market,
        bool _status
    ) external onlyOwner {
        markets[_market] = _status;
        emit LogMarketStatus(_market, _status);
    }

    /// @notice set custom adapter usage status
    /// @param _useCustomAdapterParams true/false
    function setUseCustomAdapterParams(
        bool _useCustomAdapterParams
    ) external onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    /// @notice override of the '_nonblockingLzReceive' method
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory /*_srcAddress*/,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        // decode and load the toAddress
        (, address toAddress, bytes[] memory marketCalls) = abi.decode(
            _payload,
            (bytes32, address, bytes[])
        );

        require(markets[toAddress], "MarketsProxy: market not valid");

        IMarket(toAddress).execute(marketCalls, true);

        emit ReceiveFromChain(_srcChainId, toAddress, _payload);
    }

    /// @notice override of the '_send' method
    function _send(
        address _from,
        uint16 _dstChainId,
        address _toAddress,
        bytes[] memory _marketCalls,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal {
        bytes memory payload = abi.encode(
            abi.encodePacked(address(this)),
            _toAddress,
            _marketCalls
        );
        if (useCustomAdapterParams) {
            _checkGasLimit(
                _dstChainId,
                uint16(FUNCTION_TYPE_SEND),
                _adapterParams,
                NO_EXTRA_GAS
            );
        } else {
            require(
                _adapterParams.length == 0,
                "LzApp: _adapterParams must be empty."
            );
        }
        _lzSend(
            _dstChainId,
            payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams,
            msg.value
        );

        emit SendToChain(_dstChainId, _from, payload);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../../singularity/legacy/mocks/ERC20Mock.sol";
import "../../usd0/IUSDO.sol";

contract CurvePoolMock {
    using BoringERC20 for IERC20;

    mapping(uint256 => address) public coins;

    uint256 public divider;

    constructor(address token0, address token1) {
        coins[0] = token0;
        coins[1] = token1;
        divider = 1;
    }

    function setDivider(uint256 div) external {
        divider = div;
    }

    function get_dy(
        int128,
        int128,
        uint256 dx
    ) external view returns (uint256) {
        if (divider == 0) return 0;
        return dx / divider;
    }

    function exchange(int128, int128 j, uint256 dx, uint256) external {
        if (divider == 0) return;
        address tokenOut = coins[uint256(uint128(j))];
        uint256 freeMintAmount = dx / divider;
        IUSDO(tokenOut).mint(address(this), freeMintAmount);
        IERC20(tokenOut).safeTransfer(msg.sender, freeMintAmount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "../swappers/ISwapper.sol";
import "../interfaces/IPenrose.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

/// @notice Always gives out the minimum requested amount, if it has it.
/// @notice Do not use the other functions.
contract MockSwapper is ISwapper {
    using BoringERC20 for IERC20;

    YieldBox private immutable yieldBox;

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    function getOutputAmount(
        uint256 /* tokenInId */,
        uint256 /* shareIn */,
        bytes calldata /* dexData */
    ) external pure returns (uint256) {
        return 0;
    }

    function getInputAmount(
        uint256 /* tokenOutId */,
        uint256 /* shareOut */,
        bytes calldata /* dexData */
    ) external pure returns (uint256) {
        return 0;
    }

    /// @notice swaps token in with token out
    /// @dev returns both amount and shares
    /// @param tokenOutId YieldBox asset id
    /// @param to Receiver address
    /// @param amountOutMin Minimum amount to be received
    function swap(
        uint256 /* tokenInId */,
        uint256 tokenOutId,
        uint256 /* shareIn */,
        address to,
        uint256 amountOutMin,
        bytes calldata /* dexData */
    ) external returns (uint256 amountOut, uint256 shareOut) {
        shareOut = yieldBox.toShare(tokenOutId, amountOutMin, true);
        amountOut = amountOutMin;
        yieldBox.transfer(address(this), to, tokenOutId, shareOut);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../../Penrose.sol";

contract VulnMultiSwapper {
    function counterfeitSwap(
        Penrose penrose,
        uint256 assetId,
        address target
    ) public {
        penrose.yieldBox().withdraw(
            assetId,
            target,
            msg.sender,
            penrose.yieldBox().amountOf(target, assetId),
            0
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/strategies/ERC20WithoutStrategy.sol";
import "./singularity/interfaces/ISingularity.sol";
import "./interfaces/IPenrose.sol";

// TODO: Permissionless market deployment
///     + asset registration? (toggle to renounce ownership so users can call)
/// @title Global market registry
/// @notice Singularity management
contract Penrose is BoringOwnable, BoringFactory {
    // ************ //
    // *** VARS *** //
    // ************ //
    /// @notice returns the Conservator address
    address public conservator;
    /// @notice returns the pause state of the contract
    bool public paused;

    /// @notice returns the YieldBox contract
    YieldBox public immutable yieldBox;

    /// @notice returns the TAP contract
    IERC20 public immutable tapToken;
    /// @notice returns TAP asset id registered in the YieldBox contract
    uint256 public immutable tapAssetId;

    /// @notice returns USDO contract
    IUSDO public usdoToken;

    /// @notice returns USDO asset id registered in the YieldBox contract
    uint256 public usdoAssetId;

    /// @notice returns the WETH contract
    IERC20 public immutable wethToken;

    /// @notice returns WETH asset id registered in the YieldBox contract
    uint256 public immutable wethAssetId;

    /// @notice master contracts registered
    IPenrose.MasterContract[] public singularityMasterContracts;
    IPenrose.MasterContract[] public bigbangMasterContracts;

    // Used to check if a master contract is registered
    mapping(address => bool) isSingularityMasterContractRegistered;
    mapping(address => bool) isBigBangMasterContractRegistered;

    /// @notice protocol fees
    address public feeTo;

    /// @notice whitelisted swappers
    mapping(ISwapper => bool) public swappers;

    address public bigBangEthMarket;
    uint256 public bigBangEthDebtRate;

    mapping(address => IStrategy) public emptyStrategies;

    /// @notice creates a Penrose contract
    /// @param _yieldBox YieldBox contract address
    /// @param tapToken_ TapOFT contract address
    /// @param wethToken_ WETH contract address
    /// @param _owner owner address
    constructor(
        YieldBox _yieldBox,
        IERC20 tapToken_,
        IERC20 wethToken_,
        address _owner
    ) {
        yieldBox = _yieldBox;
        tapToken = tapToken_;
        owner = _owner;

        emptyStrategies[address(tapToken_)] = IStrategy(
            address(
                new ERC20WithoutStrategy(
                    IYieldBox(address(_yieldBox)),
                    tapToken_
                )
            )
        );
        tapAssetId = uint96(
            _yieldBox.registerAsset(
                TokenType.ERC20,
                address(tapToken_),
                emptyStrategies[address(tapToken_)],
                0
            )
        );

        wethToken = wethToken_;
        emptyStrategies[address(wethToken_)] = IStrategy(
            address(
                new ERC20WithoutStrategy(
                    IYieldBox(address(_yieldBox)),
                    wethToken_
                )
            )
        );
        wethAssetId = uint96(
            _yieldBox.registerAsset(
                TokenType.ERC20,
                address(wethToken_),
                emptyStrategies[address(wethToken_)],
                0
            )
        );

        bigBangEthDebtRate = 5e15;
    }

    // **************//
    // *** EVENTS *** //
    // ************** //
    event ProtocolWithdrawal(IFee[] markets, uint256 timestamp);
    event RegisterSingularityMasterContract(
        address location,
        IPenrose.ContractType risk
    );
    event RegisterBigBangMasterContract(
        address location,
        IPenrose.ContractType risk
    );
    event RegisterSingularity(address location, address masterContract);
    event RegisterBigBang(address location, address masterContract);
    event FeeToUpdate(address newFeeTo);
    event FeeVeTapUpdate(address newFeeVeTap);
    event SwapperUpdate(address swapper, bool isRegistered);
    event UsdoTokenUpdated(address indexed usdoToken, uint256 assetId);
    event ConservatorUpdated(address indexed old, address indexed _new);
    event PausedUpdated(bool oldState, bool newState);
    event BigBangEthMarketSet(address indexed _newAddress);
    event BigBangEthMarketDebtRate(uint256 _rate);

    // ******************//
    // *** MODIFIERS *** //
    // ***************** //
    modifier registeredSingularityMasterContract(address mc) {
        require(
            isSingularityMasterContractRegistered[mc] == true,
            "Penrose: MC not registered"
        );
        _;
    }

    modifier registeredBigBangMasterContract(address mc) {
        require(
            isBigBangMasterContractRegistered[mc] == true,
            "Penrose: MC not registered"
        );
        _;
    }

    modifier notPaused() {
        require(!paused, "Penrose: paused");
        _;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //

    /// @notice Get all the Singularity contract addresses
    /// @return markets list of available markets
    function singularityMarkets()
        public
        view
        returns (address[] memory markets)
    {
        markets = _getMasterContractLength(singularityMasterContracts);
    }

    /// @notice Get all the BigBang contract addresses
    /// @return markets list of available markets
    function bigBangMarkets() public view returns (address[] memory markets) {
        markets = _getMasterContractLength(bigbangMasterContracts);
    }

    /// @notice Get the length of `singularityMasterContracts`
    function singularityMasterContractLength() public view returns (uint256) {
        return singularityMasterContracts.length;
    }

    /// @notice Get the length of `bigbangMasterContracts`
    function bigBangMasterContractLength() public view returns (uint256) {
        return bigbangMasterContracts.length;
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Loop through the master contracts and call `depositFeesToYieldBox()` to each one of their clones.
    /// @dev `swappers_` can have one element that'll be used for all clones. Or one swapper per MasterContract.
    /// @dev Fees are withdrawn in TAP and sent to the FeeDistributor contract
    /// @param swappers_ One or more swappers to convert the asset to TAP.
    function withdrawAllSingularityFees(
        IFee[] calldata markets_,
        ISwapper[] calldata swappers_,
        IPenrose.SwapData[] calldata swapData_
    ) public notPaused {
        require(
            markets_.length == swappers_.length &&
                swappers_.length == swapData_.length,
            "Penrose: length mismatch"
        );
        require(address(swappers_[0]) != address(0), "Penrose: zero address");
        require(address(markets_[0]) != address(0), "Penrose: zero address");

        _withdrawAllProtocolFees(swappers_, swapData_, markets_);
        emit ProtocolWithdrawal(markets_, block.timestamp);
    }

    /// @notice Loop through the master contracts and call `depositFeesToYieldBox()` to each one of their clones.
    /// @dev `swappers_` can have one element that'll be used for all clones. Or one swapper per MasterContract.
    /// @dev Fees are withdrawn in TAP and sent to the FeeDistributor contract
    /// @param swappers_ One or more swappers to convert the asset to TAP.
    function withdrawAllBigBangFees(
        IFee[] calldata markets_,
        ISwapper[] calldata swappers_,
        IPenrose.SwapData[] calldata swapData_
    ) public notPaused {
        require(
            markets_.length == swappers_.length &&
                swappers_.length == swapData_.length,
            "Penrose: length mismatch"
        );
        require(address(swappers_[0]) != address(0), "Penrose: zero address");

        _withdrawAllProtocolFees(swappers_, swapData_, markets_);
        emit ProtocolWithdrawal(markets_, block.timestamp);
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice sets the main BigBang market debt rate
    /// @param _rate the new rate
    function setBigBangEthMarketDebtRate(uint256 _rate) external onlyOwner {
        bigBangEthDebtRate = _rate;
        emit BigBangEthMarketDebtRate(_rate);
    }

    /// @notice sets the main BigBang market
    /// @dev needed for the variable debt computation
    function setBigBangEthMarket(address _market) external onlyOwner {
        bigBangEthMarket = _market;
        emit BigBangEthMarketSet(_market);
    }

    /// @notice updates the pause state of the contract
    /// @param val the new value
    function updatePause(bool val) external {
        require(msg.sender == conservator, "Penrose: unauthorized");
        require(val != paused, "Penrose: same state");
        emit PausedUpdated(paused, val);
        paused = val;
    }

    /// @notice Set the Conservator address
    /// @dev Conservator can pause the contract
    /// @param _conservator The new address
    function setConservator(address _conservator) external onlyOwner {
        require(_conservator != address(0), "Penrose: address not valid");
        emit ConservatorUpdated(conservator, _conservator);
        conservator = _conservator;
    }

    /// @notice Set the USDO token
    /// @dev sets usdoToken and usdoAssetId
    /// @param _usdoToken the USDO token address
    function setUsdoToken(address _usdoToken) external onlyOwner {
        usdoToken = IUSDO(_usdoToken);

        emptyStrategies[_usdoToken] = IStrategy(
            address(
                new ERC20WithoutStrategy(
                    IYieldBox(address(yieldBox)),
                    IERC20(_usdoToken)
                )
            )
        );
        usdoAssetId = uint96(
            yieldBox.registerAsset(
                TokenType.ERC20,
                _usdoToken,
                emptyStrategies[_usdoToken],
                0
            )
        );
        emit UsdoTokenUpdated(_usdoToken, usdoAssetId);
    }

    /// @notice Register a Singularity master contract
    /// @param mcAddress The address of the contract
    /// @param contractType_ The risk type of the contract
    function registerSingularityMasterContract(
        address mcAddress,
        IPenrose.ContractType contractType_
    ) external onlyOwner {
        require(
            isSingularityMasterContractRegistered[mcAddress] == false,
            "Penrose: MC registered"
        );

        IPenrose.MasterContract memory mc;
        mc.location = mcAddress;
        mc.risk = contractType_;
        singularityMasterContracts.push(mc);
        isSingularityMasterContractRegistered[mcAddress] = true;

        emit RegisterSingularityMasterContract(mcAddress, contractType_);
    }

    /// @notice Register a BigBang master contract
    /// @param mcAddress The address of the contract
    /// @param contractType_ The risk type of the contract
    function registerBigBangMasterContract(
        address mcAddress,
        IPenrose.ContractType contractType_
    ) external onlyOwner {
        require(
            isBigBangMasterContractRegistered[mcAddress] == false,
            "Penrose: MC registered"
        );

        IPenrose.MasterContract memory mc;
        mc.location = mcAddress;
        mc.risk = contractType_;
        bigbangMasterContracts.push(mc);
        isBigBangMasterContractRegistered[mcAddress] = true;

        emit RegisterBigBangMasterContract(mcAddress, contractType_);
    }

    /// @notice Registers a Singularity market
    /// @param mc The address of the master contract which must be already registered
    /// @param data The init data of the Singularity
    /// @param useCreate2 Whether to use create2 or not
    function registerSingularity(
        address mc,
        bytes calldata data,
        bool useCreate2
    )
        external
        payable
        onlyOwner
        registeredSingularityMasterContract(mc)
        returns (address _contract)
    {
        _contract = deploy(mc, data, useCreate2);
        emit RegisterSingularity(_contract, mc);
    }

    /// @notice Registers a BigBang market
    /// @param mc The address of the master contract which must be already registered
    /// @param data The init data of the BigBang contract
    /// @param useCreate2 Whether to use create2 or not
    function registerBigBang(
        address mc,
        bytes calldata data,
        bool useCreate2
    )
        external
        payable
        onlyOwner
        registeredBigBangMasterContract(mc)
        returns (address _contract)
    {
        _contract = deploy(mc, data, useCreate2);
        emit RegisterBigBang(_contract, mc);
    }

    /// @notice Execute an only owner function inside of a Singularity or a BigBang market
    function executeMarketFn(
        address[] calldata mc,
        bytes[] memory data,
        bool forceSuccess
    )
        external
        onlyOwner
        notPaused
        returns (bool[] memory success, bytes[] memory result)
    {
        uint256 len = mc.length;
        success = new bool[](len);
        result = new bytes[](len);
        for (uint256 i = 0; i < len; ) {
            require(
                isSingularityMasterContractRegistered[
                    masterContractOf[mc[i]]
                ] || isBigBangMasterContractRegistered[masterContractOf[mc[i]]],
                "Penrose: MC not registered"
            );
            (success[i], result[i]) = mc[i].call(data[i]);
            if (forceSuccess) {
                require(success[i], _getRevertMsg(result[i]));
            }
            ++i;
        }
    }

    /// @notice Set protocol fees address
    function setFeeTo(address feeTo_) external onlyOwner {
        feeTo = feeTo_;
        emit FeeToUpdate(feeTo_);
    }

    /// @notice Used to register and enable or disable swapper contracts used in closed liquidations.
    /// MasterContract Only Admin function.
    /// @param swapper The address of the swapper contract that conforms to `ISwapper`.
    /// @param enable True to enable the swapper. To disable use False.
    function setSwapper(ISwapper swapper, bool enable) external onlyOwner {
        swappers[swapper] = enable;
        emit SwapperUpdate(address(swapper), enable);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _getRevertMsg(
        bytes memory _returnData
    ) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "SGL: no return data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _withdrawAllProtocolFees(
        ISwapper[] calldata swappers_,
        IPenrose.SwapData[] calldata swapData_,
        IFee[] memory markets_
    ) private {
        uint256 length = markets_.length;
        unchecked {
            for (uint256 i = 0; i < length; ) {
                markets_[i].depositFeesToYieldBox(swappers_[i], swapData_[i]);
                ++i;
            }
        }
    }

    function _getMasterContractLength(
        IPenrose.MasterContract[] memory array
    ) public view returns (address[] memory markets) {
        uint256 _masterContractLength = array.length;
        uint256 marketsLength = 0;

        unchecked {
            // We first compute the length of the markets array
            for (uint256 i = 0; i < _masterContractLength; ) {
                marketsLength += clonesOfCount(array[i].location);

                ++i;
            }
        }

        markets = new address[](marketsLength);

        uint256 marketIndex;
        uint256 clonesOfLength;

        unchecked {
            // We populate the array
            for (uint256 i = 0; i < _masterContractLength; ) {
                address mcLocation = array[i].location;
                clonesOfLength = clonesOfCount(mcLocation);

                // Loop through clones of the current MC.
                for (uint256 j = 0; j < clonesOfLength; ) {
                    markets[marketIndex] = clonesOf[mcLocation][j];
                    ++marketIndex;
                    ++j;
                }
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./MarketsProxy.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title MarketsProxy factory
contract ProxyDeployer {
    // ************ //
    // *** VARS *** //
    // ************ //
    address public owner;
    address[] public proxies;

    // ************ //
    // *** EVENTS *** //
    // ************ //
    event LogDeploy(address indexed lzEndpoint, address indexed cloneAddress);

    // ************ //
    // *** METHODS *** //
    // ************ //
    /// @notice creates a new ProxyDeployer contract
    constructor() {
        owner = msg.sender;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns proxies count
    function proxiesCount() external view returns (uint256) {
        return proxies.length;
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice creates a new MarketsProxy contract using CREATE2 opcode
    /// @param _lzEndpoint the LayerZero endpoint MarketsProxy will be associated with
    /// @param _salt CREATE2 salt used to compute the new address
    function deployWithCreate2(
        address _lzEndpoint,
        bytes32 _salt
    ) public payable returns (address cloneAddress) {
        require(msg.sender == owner, "ProxyDeployer: unauthorized");
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        cloneAddress = address(
            new MarketsProxy{salt: _salt}(_lzEndpoint, owner)
        );
        proxies.push(cloneAddress);
        emit LogDeploy(_lzEndpoint, cloneAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "../../interfaces/IOracle.sol";
import "../../interfaces/IFee.sol";
import "../../interfaces/IMarket.sol";

interface ISingularity is IMarket, IFee {
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event LogAccrue(
        uint256 accruedAmount,
        uint256 feeFraction,
        uint64 rate,
        uint256 utilization
    );
    event LogAddAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount,
        uint256 part
    );
    event LogExchangeRate(uint256 rate);
    event LogFeeTo(address indexed newFeeTo);
    event LogRemoveAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogRemoveCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogRepay(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event LogFlashLoan(
        address indexed borrower,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );
    event LogYieldBoxFeesDeposit(uint256 feeShares, uint256 tapAmount);
    event LogApprovalForAll(
        address indexed _from,
        address indexed _operator,
        bool _approved
    );
    error NotApproved(address _from, address _operator);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function accrue() external;

    function accrueInfo()
        external
        view
        returns (
            uint64 interestPerSecond,
            uint64 lastBlockAccrued,
            uint128 feesEarnedFraction
        );

    function setApprovalForAll(address operator, bool approved) external;

    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function penrose() external view returns (address);

    function claimOwnership() external;

    /// @notice Allows batched call to Singularity.
    /// @param calls An array encoded call data.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    function execute(
        bytes[] calldata calls,
        bool revertOnFail
    ) external returns (bool[] memory successes, string[] memory results);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function getInitData(
        address collateral_,
        address asset_,
        IOracle oracle_,
        bytes calldata oracleData_
    ) external pure returns (bytes memory data);

    function init(bytes calldata data) external payable;

    function isSolvent(address user, bool open) external view returns (bool);

    function liquidate(
        address[] calldata users,
        uint256[] calldata borrowParts,
        address to,
        ISwapper swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(
        address from,
        address to,
        uint256 fraction
    ) external returns (uint256 share);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(ISwapper swapper, bool enable) external;

    function swappers(ISwapper) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function callerFee() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function borrowOpeningFee() external view returns (uint256);

    function orderBookLiquidationMultiplier() external view returns (uint256);

    function closedCollateralizationRate() external view returns (uint256);

    function lqCollateralizationRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function withdrawFees() external;

    function liquidationQueue() external view returns (address payable);

    function totalBorrowCap() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";

import "./ERC20Mock.sol";

contract ERC20FactoryMock {
    ERC20Mock public last;

    function deployToken(
        uint256 _supply,
        uint8 _decimals,
        uint256 _mintLimit
    ) external {
        ERC20Mock tkn = new ERC20Mock(_supply, _decimals, _mintLimit);
        last = tkn;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";

contract ERC20Mock is ERC20WithSupply {
    string public name = "Fantom";
    string public symbol = "FTM";
    uint8 public decimals;

    mapping(address => uint256) public mintedAt;
    uint256 public constant MINT_WINDOW = 24 hours;
    uint256 public mintLimit;

    constructor(uint256 _initialAmount, uint8 _decimals, uint256 _mintLimit) {
        totalSupply = _initialAmount;
        decimals = _decimals;
        mintLimit = _mintLimit;
    }

    function freeMint(uint256 _val) public {
        require(_val <= mintLimit, "ERC20Mock: amount too big");
        require(
            mintedAt[msg.sender] + MINT_WINDOW <= block.timestamp,
            "ERC20Mock: too early"
        );

        mintedAt[msg.sender] = block.timestamp;

        _mint(msg.sender, _val);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "../../../interfaces/IOracle.sol";

contract OracleMock is IOracle {
    uint256 public rate;
    bool public success;
    string public __name;
    string public __symbol;

    constructor(string memory _name, string memory _symbol, uint256 _rate) {
        success = true;
        rate = _rate;
        __name = _name;
        __symbol = _symbol;
    }

    function set(uint256 rate_) public {
        // The rate can be updated.
        rate = rate_;
    }

    function setSuccess(bool val) public {
        success = val;
    }

    function getDataParameter() public pure returns (bytes memory) {
        return abi.encode("0x0");
    }

    // Get the latest exchange rate
    function get(bytes calldata) public view override returns (bool, uint256) {
        return (success, rate);
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata) public view override returns (bool, uint256) {
        return (success, rate);
    }

    function peekSpot(bytes calldata) public view override returns (uint256) {
        return rate;
    }

    function name(bytes calldata) public view override returns (string memory) {
        return __name;
    }

    function symbol(
        bytes calldata
    ) public view override returns (string memory) {
        return __symbol;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./SGLStorage.sol";

contract SGLCommon is SGLStorage {
    using RebaseLibrary for Rebase;

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //
    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// msg.sender can be an allowed operator if his allowance equal or exceed the balance of the user 'from'.
    modifier allowed(address from) virtual {
        if (
            from != msg.sender && allowance[from][msg.sender] <= balanceOf[from]
        ) {
            revert NotApproved(from, msg.sender);
        }
        _;
    }

    modifier notPaused() {
        require(!paused, "SGL: paused");
        _;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent(address from) {
        _;
        require(_isSolvent(from, exchangeRate), "SGL: insolvent");
    }

    bool private initialized;
    modifier onlyOnce() {
        require(!initialized, "SGL: initialized");
        _;
        initialized = true;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice Return the amount of collateral for a `user` to be solvent, min TVL and max TVL. Returns 0 if user already solvent.
    /// @dev We use a `CLOSED_COLLATERIZATION_RATE` that is a safety buffer when making the user solvent again,
    ///      To prevent from being liquidated. This function is valid only if user is not solvent by `_isSolvent()`.
    /// @param user The user to check solvency.
    /// @param _exchangeRate The exchange rate asset/collateral.
    /// @return amountToSolvency The amount of collateral to be solvent.
    function computeTVLInfo(
        address user,
        uint256 _exchangeRate
    )
        public
        view
        returns (uint256 amountToSolvency, uint256 minTVL, uint256 maxTVL)
    {
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return (0, 0, 0);
        uint256 collateralShare = userCollateralShare[user];

        Rebase memory _totalBorrow = totalBorrow;

        uint256 collateralAmountInAsset = yieldBox.toAmount(
            collateralId,
            (collateralShare *
                (EXCHANGE_RATE_PRECISION / COLLATERALIZATION_RATE_PRECISION) *
                lqCollateralizationRate),
            false
        ) / _exchangeRate;
        borrowPart = (borrowPart * _totalBorrow.elastic) / _totalBorrow.base;

        amountToSolvency = borrowPart >= collateralAmountInAsset
            ? borrowPart - collateralAmountInAsset
            : 0;

        (minTVL, maxTVL) = _computeMaxAndMinLTVInAsset(
            collateralShare,
            _exchangeRate
        );
    }

    /// @notice Return the maximum liquidatable amount for user
    function computeClosingFactor(
        address user,
        uint256 _exchangeRate
    ) public view returns (uint256) {
        if (_isSolvent(user, _exchangeRate)) return 0;

        (uint256 amountToSolvency, , uint256 maxTVL) = computeTVLInfo(
            user,
            _exchangeRate
        );
        uint256 borrowed = userBorrowPart[user];
        if (borrowed >= maxTVL) return borrowed;

        return
            amountToSolvency +
            ((liquidationBonusAmount * borrowed) / FEE_PRECISION);
    }

    function computeLiquidatorReward(
        address user,
        uint256 _exchangeRate
    ) public view returns (uint256) {
        (uint256 minTVL, uint256 maxTVL) = _computeMaxAndMinLTVInAsset(
            userCollateralShare[user],
            _exchangeRate
        );
        return _getCallerReward(userBorrowPart[user], minTVL, maxTVL);
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        ISingularity.AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            // If there are no borrows, reset the interest rate
            if (_accrueInfo.interestPerSecond != STARTING_INTEREST_PER_SECOND) {
                _accrueInfo.interestPerSecond = STARTING_INTEREST_PER_SECOND;
                emit LogAccrue(0, 0, STARTING_INTEREST_PER_SECOND, 0);
            }
            accrueInfo = _accrueInfo;
            return;
        }

        uint256 extraAmount = 0;
        uint256 feeFraction = 0;
        Rebase memory _totalAsset = totalAsset;

        // Accrue interest
        extraAmount =
            (uint256(_totalBorrow.elastic) *
                _accrueInfo.interestPerSecond *
                elapsedTime) /
            1e18;
        _totalBorrow.elastic += uint128(extraAmount);
        uint256 fullAssetAmount = yieldBox.toAmount(
            assetId,
            _totalAsset.elastic,
            false
        ) + _totalBorrow.elastic;

        uint256 feeAmount = (extraAmount * protocolFee) / FEE_PRECISION; // % of interest paid goes to fee
        feeFraction = (feeAmount * _totalAsset.base) / fullAssetAmount;
        _accrueInfo.feesEarnedFraction += uint128(feeFraction);
        totalAsset.base = _totalAsset.base + uint128(feeFraction);
        totalBorrow = _totalBorrow;

        // Update interest rate
        uint256 utilization = (uint256(_totalBorrow.elastic) *
            UTILIZATION_PRECISION) / fullAssetAmount;
        if (utilization < MINIMUM_TARGET_UTILIZATION) {
            uint256 underFactor = ((MINIMUM_TARGET_UTILIZATION - utilization) *
                FACTOR_PRECISION) / MINIMUM_TARGET_UTILIZATION;
            uint256 scale = INTEREST_ELASTICITY +
                (underFactor * underFactor * elapsedTime);
            _accrueInfo.interestPerSecond = uint64(
                (uint256(_accrueInfo.interestPerSecond) * INTEREST_ELASTICITY) /
                    scale
            );

            if (_accrueInfo.interestPerSecond < MINIMUM_INTEREST_PER_SECOND) {
                _accrueInfo.interestPerSecond = MINIMUM_INTEREST_PER_SECOND; // 0.25% APR minimum
            }
        } else if (utilization > MAXIMUM_TARGET_UTILIZATION) {
            uint256 overFactor = ((utilization - MAXIMUM_TARGET_UTILIZATION) *
                FACTOR_PRECISION) / FULL_UTILIZATION_MINUS_MAX;
            uint256 scale = INTEREST_ELASTICITY +
                (overFactor * overFactor * elapsedTime);
            uint256 newInterestPerSecond = (uint256(
                _accrueInfo.interestPerSecond
            ) * scale) / INTEREST_ELASTICITY;
            if (newInterestPerSecond > MAXIMUM_INTEREST_PER_SECOND) {
                newInterestPerSecond = MAXIMUM_INTEREST_PER_SECOND; // 1000% APR maximum
            }
            _accrueInfo.interestPerSecond = uint64(newInterestPerSecond);
        }

        emit LogAccrue(
            extraAmount,
            feeFraction,
            _accrueInfo.interestPerSecond,
            utilization
        );
        accrueInfo = _accrueInfo;
    }

    /// @notice Removes an asset from msg.sender and transfers it to `to`.
    /// @param from Account to debit Assets from.
    /// @param to The user that receives the removed assets.
    /// @param fraction The amount/fraction of assets held to remove.
    /// @return share The amount of shares transferred to `to`.
    function removeAsset(
        address from,
        address to,
        uint256 fraction
    ) public notPaused allowed(from) returns (uint256 share) {
        accrue();

        share = _removeAsset(from, to, fraction, true);
    }

    /// @notice Adds assets to the lending pair.
    /// @param from Address to add asset from.
    /// @param to The address of the user to receive the assets.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add.
    /// @return fraction Total fractions added.
    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) public notPaused allowed(from) returns (uint256 fraction) {
        accrue();
        fraction = _addAsset(from, to, skim, share);
    }

    // ************************** //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    /// @notice construct Uniswap path
    function _collateralToAssetSwapPath()
        internal
        view
        returns (address[] memory path)
    {
        path = new address[](2);
        path[0] = address(collateral);
        path[1] = address(asset);
    }

    function _assetToWethSwapPath()
        internal
        view
        returns (address[] memory path)
    {
        path = new address[](2);
        path[0] = address(asset);
        path[1] = address(penrose.wethToken());
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(
        address user,
        uint256 _exchangeRate
    ) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            yieldBox.toAmount(
                collateralId,
                collateralShare *
                    (EXCHANGE_RATE_PRECISION /
                        COLLATERALIZATION_RATE_PRECISION) *
                    closedCollateralizationRate,
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            (borrowPart * _totalBorrow.elastic * _exchangeRate) /
                _totalBorrow.base;
    }

    /// @dev Helper function to move tokens.
    /// @param from Account to debit tokens from, in `yieldBox`.
    /// @param _assetId The ERC-20 token asset ID in yieldBox.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    function _addTokens(
        address from,
        uint256 _assetId,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        _yieldBoxShares[from][_assetId] += share;

        if (skim) {
            require(
                share <= yieldBox.balanceOf(address(this), _assetId) - total,
                "SGL: too much"
            );
        } else {
            yieldBox.transfer(from, address(this), _assetId, share); // added a 'from' instead of 'msg.sender' -0xGAB
        }
    }

    /// @dev Concrete implementation of `addAsset`.
    function _addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) internal returns (uint256 fraction) {
        Rebase memory _totalAsset = totalAsset;
        uint256 totalAssetShare = _totalAsset.elastic;
        uint256 allShare = _totalAsset.elastic +
            yieldBox.toShare(assetId, totalBorrow.elastic, true);
        fraction = allShare == 0
            ? share
            : (share * _totalAsset.base) / allShare;
        if (_totalAsset.base + uint128(fraction) < 1000) {
            return 0;
        }
        totalAsset = _totalAsset.add(share, fraction);
        balanceOf[to] += fraction;
        emit Transfer(address(0), to, fraction);

        _addTokens(from, assetId, share, totalAssetShare, skim);
        emit LogAddAsset(skim ? address(yieldBox) : from, to, share, fraction);
    }

    /// @dev Concrete implementation of `removeAsset`.
    /// @param from The account to remove from. Should always be msg.sender except for `depositFeesToyieldBox()`.
    function _removeAsset(
        address from,
        address to,
        uint256 fraction,
        bool updateYieldBoxShares
    ) internal returns (uint256 share) {
        if (totalAsset.base == 0) {
            return 0;
        }
        Rebase memory _totalAsset = totalAsset;
        uint256 allShare = _totalAsset.elastic +
            yieldBox.toShare(assetId, totalBorrow.elastic, true);
        share = (fraction * allShare) / _totalAsset.base;
        balanceOf[from] -= fraction;
        emit Transfer(from, address(0), fraction);
        _totalAsset.elastic -= uint128(share);
        _totalAsset.base -= uint128(fraction);
        require(_totalAsset.base >= 1000, "SGL: min limit");
        totalAsset = _totalAsset;
        emit LogRemoveAsset(from, to, share, fraction);
        yieldBox.transfer(address(this), to, assetId, share);
        if (updateYieldBoxShares) {
            if (share > _yieldBoxShares[from][assetId]) {
                _yieldBoxShares[from][assetId] = 0; //some assets accrue in time
            } else {
                _yieldBoxShares[from][assetId] -= share;
            }
        }
    }

    /// @dev Return the equivalent of collateral borrow part in asset amount.
    function _getAmountForBorrowPart(
        uint256 borrowPart
    ) internal view returns (uint256) {
        return totalBorrow.toElastic(borrowPart, false);
    }

    /// @notice Returns the min and max LTV for user in asset price
    function _computeMaxAndMinLTVInAsset(
        uint256 collateralShare,
        uint256 _exchangeRate
    ) internal view returns (uint256 min, uint256 max) {
        uint256 collateralAmount = yieldBox.toAmount(
            collateralId,
            collateralShare,
            false
        );

        max = (collateralAmount * EXCHANGE_RATE_PRECISION) / _exchangeRate;
        min =
            (max * closedCollateralizationRate) /
            COLLATERALIZATION_RATE_PRECISION;
    }

    function _getCallerReward(
        uint256 borrowed,
        uint256 startTVLInAsset,
        uint256 maxTVLInAsset
    ) internal view returns (uint256) {
        if (borrowed == 0) return 0;
        if (startTVLInAsset == 0) return 0;

        if (borrowed < startTVLInAsset) return 0;
        if (borrowed >= maxTVLInAsset) return minLiquidatorReward;

        uint256 rewardPercentage = ((borrowed - startTVLInAsset) *
            FEE_PRECISION) / (maxTVLInAsset - startTVLInAsset);

        int256 diff = int256(minLiquidatorReward) - int256(maxLiquidatorReward);
        int256 reward = (diff * int256(rewardPercentage)) /
            int256(FEE_PRECISION) +
            int256(maxLiquidatorReward);

        return uint256(reward);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./SGLCommon.sol";

contract SGLLendingBorrowing is SGLCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @param from Account to borrow for.
    /// @param to The receiver of borrowed tokens.
    /// @param amount Amount to borrow.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(
        address from,
        address to,
        uint256 amount
    )
        public
        notPaused
        solvent(from)
        allowed(from)
        returns (uint256 part, uint256 share)
    {
        updateExchangeRate();

        accrue();

        (part, share) = _borrow(from, to, amount);
    }

    /// @notice Repays a loan.
    /// @param from Address to repay from.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) public notPaused allowed(from) returns (uint256 amount) {
        updateExchangeRate();

        accrue();

        amount = _repay(from, to, skim, part);
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param from Account to transfer shares from.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) public notPaused allowed(from) {
        _addCollateral(from, to, skim, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param from Account to debit collateral from.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(
        address from,
        address to,
        uint256 share
    ) public notPaused solvent(from) allowed(from) {
        // accrue must be called because we check solvency
        accrue();

        _removeCollateral(from, to, share);
    }

    /// @notice Lever down: Sell collateral to repay debt; excess goes to YB
    /// @param from The user who sells
    /// @param share Collateral YieldBox-shares to sell
    /// @param minAmountOut Mininal proceeds required for the sale
    /// @param swapper Swapper to execute the sale
    /// @param dexData Additional data to pass to the swapper
    /// @param amountOut Actual asset amount received in the sale
    function sellCollateral(
        address from,
        uint256 share,
        uint256 minAmountOut,
        ISwapper swapper,
        bytes calldata dexData
    )
        external
        notPaused
        solvent(from)
        allowed(from)
        returns (uint256 amountOut)
    {
        require(penrose.swappers(swapper), "SGL: Invalid swapper");

        updateExchangeRate();
        accrue();

        _removeCollateral(from, address(swapper), share);
        uint256 shareOut;
        (amountOut, shareOut) = swapper.swap(
            collateralId,
            assetId,
            share,
            address(this),
            minAmountOut,
            dexData
        );

        // As long as the ratio is correct, we trust `amountOut` resp.
        // `shareOut`, because all money received by the swapper gets used up
        // one way or another, or the transaction will revert.
        require(amountOut >= minAmountOut, "SGL: not enough");

        uint256 partOwed = userBorrowPart[from];
        uint256 amountOwed = totalBorrow.toElastic(partOwed, true);
        uint256 shareOwed = yieldBox.toShare(assetId, amountOwed, true);
        if (shareOwed <= shareOut) {
            // Skim the repayment; the swapper left it in the YB
            _repay(from, from, true, partOwed);
            yieldBox.transfer(
                address(this),
                from,
                assetId,
                shareOut - shareOwed
            );
        } else {
            // Repay as much as we can.
            // TODO: Is this guaranteed to succeed? Fair amount of conversions..
            uint256 partOut = totalBorrow.toBase(amountOut, false);
            _repay(from, from, true, partOut);
        }
    }

    /// @notice Lever up: Borrow more and buy collateral with it.
    /// @param from The user who buys
    /// @param borrowAmount Amount of extra asset borrowed
    /// @param supplyAmount Amount of asset supplied (down payment)
    /// @param minAmountOut Mininal collateral amount to receive
    /// @param swapper Swapper to execute the purchase
    /// @param dexData Additional data to pass to the swapper
    /// @param amountOut Actual collateral amount purchased
    function buyCollateral(
        address from,
        uint256 borrowAmount,
        uint256 supplyAmount,
        uint256 minAmountOut,
        ISwapper swapper,
        bytes calldata dexData
    )
        external
        notPaused
        solvent(from)
        allowed(from)
        returns (uint256 amountOut)
    {
        require(penrose.swappers(swapper), "SGL: Invalid swapper");

        // Let this fail first to save gas:
        uint256 supplyShare = yieldBox.toShare(assetId, supplyAmount, true);
        if (supplyShare > 0) {
            yieldBox.transfer(from, address(swapper), assetId, supplyShare);
        }

        updateExchangeRate();
        accrue();

        uint256 borrowShare;
        (, borrowShare) = _borrow(from, address(swapper), borrowAmount);

        uint256 collateralShare;
        (amountOut, collateralShare) = swapper.swap(
            assetId,
            collateralId,
            supplyShare + borrowShare,
            address(this),
            minAmountOut,
            dexData
        );
        require(amountOut >= minAmountOut, "SGL: not enough");

        _addCollateral(from, from, true, collateralShare);
    }

    // ************************** //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    /// @dev Concrete implementation of `addCollateral`.
    function _addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) internal {
        userCollateralShare[to] += share;
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare + share;
        _addTokens(from, collateralId, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(yieldBox) : from, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(
        address from,
        address to,
        uint256 share
    ) internal {
        userCollateralShare[from] -= share;
        totalCollateralShare -= share;
        emit LogRemoveCollateral(from, to, share);
        yieldBox.transfer(address(this), to, collateralId, share);
        if (share > _yieldBoxShares[from][collateralId]) {
            _yieldBoxShares[from][collateralId] = 0; //accrues in time
        } else {
            _yieldBoxShares[from][collateralId] -= share;
        }
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = (amount * borrowOpeningFee) / FEE_PRECISION; // A flat % fee is charged for any borrow

        (totalBorrow, part) = totalBorrow.add(amount + feeAmount, true);
        require(
            totalBorrowCap == 0 || totalBorrow.base <= totalBorrowCap,
            "SGL: borrow cap reached"
        );
        userBorrowPart[from] += part;
        emit LogBorrow(from, to, amount, feeAmount, part);

        share = yieldBox.toShare(assetId, amount, false);
        Rebase memory _totalAsset = totalAsset;
        require(_totalAsset.base >= 1000, "SGL: min limit");
        _totalAsset.elastic -= uint128(share);
        totalAsset = _totalAsset;

        yieldBox.transfer(address(this), to, assetId, share);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);

        userBorrowPart[to] -= part;

        uint256 share = yieldBox.toShare(assetId, amount, true);
        uint128 totalShare = totalAsset.elastic;
        _addTokens(from, assetId, share, uint256(totalShare), skim);
        totalAsset.elastic = totalShare + uint128(share);
        emit LogRepay(skim ? address(yieldBox) : from, to, amount, part);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./SGLCommon.sol";

// solhint-disable max-line-length

contract SGLLiquidation is SGLCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Entry point for liquidations.
    /// @dev Will call `closedLiquidation()` if not LQ exists or no LQ bid avail exists. Otherwise use LQ.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    ///        Ignore for `orderBookLiquidation()`
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    ///        Ignore for `orderBookLiquidation()`
    /// @param collateralToAssetSwapData Extra swap data
    ///        Ignore for `orderBookLiquidation()`
    /// @param usdoToBorrowedSwapData Extra swap data
    ///        Ignore for `closedLiquidation()`
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        ISwapper swapper,
        bytes calldata collateralToAssetSwapData,
        bytes calldata usdoToBorrowedSwapData
    ) external notPaused {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        if (address(liquidationQueue) != address(0)) {
            (, bool bidAvail, uint256 bidAmount) = liquidationQueue
                .getNextAvailBidPool();
            if (bidAvail) {
                uint256 needed = 0;
                for (uint256 i = 0; i < maxBorrowParts.length; i++) {
                    needed += maxBorrowParts[i];
                }
                if (bidAmount >= needed) {
                    _orderBookLiquidation(
                        users,
                        _exchangeRate,
                        usdoToBorrowedSwapData
                    );
                    return;
                }
            }
        }
        _closedLiquidation(
            users,
            maxBorrowParts,
            swapper,
            _exchangeRate,
            collateralToAssetSwapData
        );
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _computeAssetAmountToSolvency(
        address user,
        uint256 _exchangeRate
    ) private view returns (uint256) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return 0;
        uint256 collateralShare = userCollateralShare[user];

        Rebase memory _totalBorrow = totalBorrow;

        uint256 collateralAmountInAsset = yieldBox.toAmount(
            collateralId,
            (collateralShare *
                (EXCHANGE_RATE_PRECISION / COLLATERALIZATION_RATE_PRECISION) *
                lqCollateralizationRate),
            false
        ) / _exchangeRate;
        // Obviously it's not `borrowPart` anymore but `borrowAmount`
        borrowPart = (borrowPart * _totalBorrow.elastic) / _totalBorrow.base;

        return
            borrowPart >= collateralAmountInAsset
                ? borrowPart - collateralAmountInAsset
                : 0;
    }

    function _orderBookLiquidation(
        address[] calldata users,
        uint256 _exchangeRate,
        bytes memory swapData
    ) private {
        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowAmount = _computeAssetAmountToSolvency(
                    user,
                    _exchangeRate
                );

                if (borrowAmount == 0) {
                    continue;
                }

                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = _totalBorrow.toBase(borrowAmount, false);
                    userBorrowPart[user] = availableBorrowPart - borrowPart;
                }
                uint256 collateralShare = yieldBox.toShare(
                    collateralId,
                    (borrowAmount * _exchangeRate * liquidationMultiplier) /
                        (EXCHANGE_RATE_PRECISION *
                            LIQUIDATION_MULTIPLIER_PRECISION),
                    false
                );
                userCollateralShare[user] -= collateralShare;
                emit LogRemoveCollateral(
                    user,
                    address(liquidationQueue),
                    collateralShare
                );
                emit LogRepay(
                    address(liquidationQueue),
                    user,
                    borrowAmount,
                    borrowPart
                );

                // Keep totals
                allCollateralShare += collateralShare;
                allBorrowAmount += borrowAmount;
                allBorrowPart += borrowPart;
            }
        }
        require(allBorrowAmount != 0, "SGL: solvent");

        _totalBorrow.elastic -= uint128(allBorrowAmount);
        _totalBorrow.base -= uint128(allBorrowPart);
        totalBorrow = _totalBorrow;
        totalCollateralShare -= allCollateralShare;

        uint256 allBorrowShare = yieldBox.toShare(
            assetId,
            allBorrowAmount,
            true
        );

        // Transfer collateral to be liquidated
        yieldBox.transfer(
            address(this),
            address(liquidationQueue),
            collateralId,
            allCollateralShare
        );

        // LiquidationQueue pay debt
        liquidationQueue.executeBids(
            yieldBox.toAmount(collateralId, allCollateralShare, true),
            swapData
        );

        uint256 returnedShare = yieldBox.balanceOf(address(this), assetId) -
            uint256(totalAsset.elastic);
        uint256 extraShare = returnedShare - allBorrowShare;
        uint256 callerShare = (extraShare * callerFee) / FEE_PRECISION; // 1% goes to caller

        yieldBox.transfer(address(this), msg.sender, assetId, callerShare);

        totalAsset.elastic += uint128(returnedShare - callerShare);
        emit LogAddAsset(
            address(liquidationQueue),
            address(this),
            returnedShare - callerShare,
            0
        );
    }

    function _updateBorrowAndCollateralShare(
        address user,
        uint256 maxBorrowPart,
        uint256 _exchangeRate
    )
        private
        returns (
            uint256 borrowAmount,
            uint256 borrowPart,
            uint256 collateralShare
        )
    {
        uint256 availableBorrowPart = computeClosingFactor(user, _exchangeRate);
        borrowPart = maxBorrowPart > availableBorrowPart
            ? availableBorrowPart
            : maxBorrowPart;

        userBorrowPart[user] = userBorrowPart[user] - borrowPart;

        borrowAmount = totalBorrow.toElastic(borrowPart, false);
        collateralShare = yieldBox.toShare(
            collateralId,
            (borrowAmount * liquidationMultiplier * _exchangeRate) /
                (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
            false
        );
        userCollateralShare[user] -= collateralShare;
        require(borrowAmount != 0, "SGL: solvent");

        totalBorrow.elastic -= uint128(borrowAmount);
        totalBorrow.base -= uint128(borrowPart);
    }

    function _extractLiquidationFees(
        uint256 borrowShare,
        uint256 callerReward,
        address swapper
    ) private {
        uint256 returnedShare = yieldBox.balanceOf(address(this), assetId) -
            uint256(totalAsset.elastic);
        uint256 extraShare = returnedShare - borrowShare;
        uint256 feeShare = (extraShare * protocolFee) / FEE_PRECISION; // x% of profit goes to fee.
        uint256 callerShare = (extraShare * callerReward) / FEE_PRECISION; //  y%  of profit goes to caller.

        yieldBox.transfer(address(this), penrose.feeTo(), assetId, feeShare);
        yieldBox.transfer(address(this), msg.sender, assetId, callerShare);

        totalAsset.elastic += uint128(returnedShare - feeShare - callerShare);

        emit LogAddAsset(
            swapper,
            address(this),
            extraShare - feeShare - callerShare,
            0
        );
    }

    function _liquidateUser(
        address user,
        uint256 maxBorrowPart,
        ISwapper swapper,
        uint256 _exchangeRate,
        bytes calldata swapData
    ) private {
        if (_isSolvent(user, _exchangeRate)) return;

        (
            uint256 startTVLInAsset,
            uint256 maxTVLInAsset
        ) = _computeMaxAndMinLTVInAsset(
                userCollateralShare[user],
                _exchangeRate
            );
        uint256 callerReward = _getCallerReward(
            userBorrowPart[user],
            startTVLInAsset,
            maxTVLInAsset
        );

        (
            uint256 borrowAmount,
            uint256 borrowPart,
            uint256 collateralShare
        ) = _updateBorrowAndCollateralShare(user, maxBorrowPart, _exchangeRate);
        emit LogRemoveCollateral(user, address(swapper), collateralShare);
        emit LogRepay(address(swapper), user, borrowAmount, borrowPart);

        uint256 borrowShare = yieldBox.toShare(assetId, borrowAmount, true);

        // Closed liquidation using a pre-approved swapper
        require(penrose.swappers(swapper), "SGL: Invalid swapper");

        // Swaps the users collateral for the borrowed asset
        yieldBox.transfer(
            address(this),
            address(swapper),
            collateralId,
            collateralShare
        );

        uint256 minAssetMount = 0;
        if (swapData.length > 0) {
            minAssetMount = abi.decode(swapData, (uint256));
        }
        swapper.swap(
            collateralId,
            assetId,
            collateralShare,
            address(this),
            minAssetMount,
            abi.encode(_collateralToAssetSwapPath())
        );

        _extractLiquidationFees(borrowShare, callerReward, address(swapper));
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @dev Closed liquidations Only, 90% of extra shares goes to caller and 10% to protocol
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    /// @param swapData Swap necessar data
    function _closedLiquidation(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        ISwapper swapper,
        uint256 _exchangeRate,
        bytes calldata swapData
    ) private {
        uint256 liquidatedCount = 0;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                liquidatedCount++;
                _liquidateUser(
                    user,
                    maxBorrowParts[i],
                    swapper,
                    _exchangeRate,
                    swapData
                );
            }
        }

        require(liquidatedCount > 0, "SGL: no users found");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

import "./interfaces/ISingularity.sol";
import "../swappers/ISwapper.sol";
import "../liquidationQueue/ILiquidationQueue.sol";
import "../interfaces/IPenrose.sol";
import "../interfaces/IOracle.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

// solhint-disable max-line-length

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

contract SGLStorage is BoringOwnable, ERC20 {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //

    ISingularity.AccrueInfo public accrueInfo;

    IPenrose public penrose;
    YieldBox public yieldBox;
    ILiquidationQueue public liquidationQueue;
    IERC20 public collateral;
    IERC20 public asset;
    uint256 public collateralId;
    uint256 public assetId;
    bool public paused;
    address public conservator;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalAsset; // elastic = yieldBox shares held by the Singularity, base = Total fractions held by asset suppliers
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
    uint256 public totalBorrowCap;
    mapping(address => mapping(uint256 => uint256)) internal _yieldBoxShares;

    // User balances
    mapping(address => uint256) public userCollateralShare;
    // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)
    mapping(address => uint256) public userBorrowPart;
    // map of operator approval
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    /// Asset -> collateral = assetAmount * exchangeRate.
    uint256 public exchangeRate;

    IOracle public oracle;
    bytes public oracleData;

    // Fees
    uint256 public callerFee = 1000; //1%
    uint256 public protocolFee = 10000; //10%
    uint256 public borrowOpeningFee = 50; //0.05%

    //Liquidation
    uint256 public liquidationMultiplier = 112000; //12%
    uint256 public orderBookLiquidationMultiplier = 127000; //27%

    uint256 public closedCollateralizationRate = 75000; // 75%
    uint256 public lqCollateralizationRate = 25000; // 25%

    uint256 public minLiquidatorReward = 1e3; //1%
    uint256 public maxLiquidatorReward = 1e4; //10%
    uint256 public liquidationBonusAmount = 1e4; //10%

    //errors
    error NotApproved(address _from, address _operator);

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event LogExchangeRate(uint256 rate);
    event LogAccrue(
        uint256 accruedAmount,
        uint256 feeFraction,
        uint64 rate,
        uint256 utilization
    );
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogAddAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogRemoveCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogRemoveAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount,
        uint256 part
    );
    event LogRepay(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event LogYieldBoxFeesDeposit(uint256 feeShares, uint256 ethAmount);
    event LogApprovalForAll(
        address indexed _from,
        address indexed _operator,
        bool _approved
    );
    event LogBorrowCapUpdated(uint256 _oldVal, uint256 _newVal);
    event PausedUpdated(bool oldState, bool newState);
    event ConservatorUpdated(address indexed old, address indexed _new);

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    uint256 internal constant COLLATERALIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 internal constant MINIMUM_TARGET_UTILIZATION = 7e17; // 70%
    uint256 internal constant MAXIMUM_TARGET_UTILIZATION = 8e17; // 80%
    uint256 internal constant UTILIZATION_PRECISION = 1e18;
    uint256 internal constant FULL_UTILIZATION = 1e18;
    uint256 internal constant FULL_UTILIZATION_MINUS_MAX =
        FULL_UTILIZATION - MAXIMUM_TARGET_UTILIZATION;
    uint256 internal constant FACTOR_PRECISION = 1e18;

    uint64 internal constant STARTING_INTEREST_PER_SECOND = 317097920; // approx 1% APR
    uint64 internal constant MINIMUM_INTEREST_PER_SECOND = 79274480; // approx 0.25% APR
    uint64 internal constant MAXIMUM_INTEREST_PER_SECOND = 317097920000; // approx 1000% APR
    uint256 internal constant INTEREST_ELASTICITY = 28800e36; // Half or double in 28800 seconds (8 hours) if linear

    uint256 internal EXCHANGE_RATE_PRECISION = 1e18; //mutable but can only be set in the init method
    uint256 internal constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    // Fees
    uint256 internal constant FEE_PRECISION = 1e5;

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    function symbol() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "tm",
                    collateral.safeSymbol(),
                    "/",
                    asset.safeSymbol(),
                    "-",
                    oracle.symbol(oracleData)
                )
            );
    }

    function name() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Tapioca Singularity ",
                    collateral.safeName(),
                    "/",
                    asset.safeName(),
                    "-",
                    oracle.name(oracleData)
                )
            );
    }

    function decimals() external view returns (uint8) {
        return asset.safeDecimals();
    }

    // totalSupply for ERC20 compatibility
    // BalanceOf[user] represent a fraction
    function totalSupply() public view override returns (uint256) {
        return totalAsset.base;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./SGLCommon.sol";
import "./SGLLiquidation.sol";
import "./SGLLendingBorrowing.sol";

import "../interfaces/ISendFrom.sol";
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";

// solhint-disable max-line-length

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title Tapioca market
contract Singularity is SGLCommon {
    using RebaseLibrary for Rebase;

    // ************ //
    // *** VARS *** //
    // ************ //
    enum Module {
        Base,
        LendingBorrowing,
        Liquidation
    }
    /// @notice returns the liquidation module
    SGLLiquidation public liquidationModule;
    /// @notice returns the lending module
    SGLLendingBorrowing public lendingBorrowingModule;

    /// @notice The init function that acts as a constructor
    function init(bytes calldata data) external onlyOnce {
        (
            address _liquidationModule,
            address _lendingBorrowingModule,
            IPenrose tapiocaBar_,
            IERC20 _asset,
            uint256 _assetId,
            IERC20 _collateral,
            uint256 _collateralId,
            IOracle _oracle,
            uint256 _exchangeRatePrecision
        ) = abi.decode(
                data,
                (
                    address,
                    address,
                    IPenrose,
                    IERC20,
                    uint256,
                    IERC20,
                    uint256,
                    IOracle,
                    uint256
                )
            );

        liquidationModule = SGLLiquidation(_liquidationModule);
        lendingBorrowingModule = SGLLendingBorrowing(_lendingBorrowingModule);
        penrose = tapiocaBar_;
        yieldBox = YieldBox(tapiocaBar_.yieldBox());
        owner = address(penrose);

        require(
            address(_collateral) != address(0) &&
                address(_asset) != address(0) &&
                address(_oracle) != address(0),
            "SGL: bad pair"
        );
        asset = _asset;
        collateral = _collateral;
        assetId = _assetId;
        collateralId = _collateralId;
        oracle = _oracle;

        accrueInfo.interestPerSecond = uint64(STARTING_INTEREST_PER_SECOND); // 1% APR, with 1e18 being 100%

        updateExchangeRate();

        //default fees
        callerFee = 1000; // 1%
        protocolFee = 10000; // 10%
        borrowOpeningFee = 50; // 0.05%

        //liquidation
        liquidationMultiplier = 112000; //12%
        orderBookLiquidationMultiplier = 127000; //27%

        closedCollateralizationRate = 75000;
        lqCollateralizationRate = 25000;
        EXCHANGE_RATE_PRECISION = _exchangeRatePrecision > 0
            ? _exchangeRatePrecision
            : 1e18;

        minLiquidatorReward = 1e3;
        maxLiquidatorReward = 1e4;
        liquidationBonusAmount = 1e4;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns Total yieldBox shares for user
    /// @param _user The user to check shares for
    /// @param _assetId The asset id to check shares for
    function yieldBoxShares(
        address _user,
        uint256 _assetId
    ) external view returns (uint256) {
        return
            yieldBox.balanceOf(_user, _assetId) +
            _yieldBoxShares[_user][_assetId];
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Allows batched call to Singularity.
    /// @param calls An array encoded call data.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    function execute(
        bytes[] calldata calls,
        bool revertOnFail
    ) external returns (bool[] memory successes, string[] memory results) {
        successes = new bool[](calls.length);
        results = new string[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = _getRevertMsg(result);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param from Account to transfer shares from.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) public {
        _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                SGLLendingBorrowing.addCollateral.selector,
                from,
                to,
                skim,
                share
            )
        );
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param from Account to debit collateral from.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address from, address to, uint256 share) public {
        _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                SGLLendingBorrowing.removeCollateral.selector,
                from,
                to,
                share
            )
        );
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @param from Account to borrow for.
    /// @param to The receiver of borrowed tokens.
    /// @param amount Amount to borrow.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(
        address from,
        address to,
        uint256 amount
    ) public returns (uint256 part, uint256 share) {
        bytes memory result = _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                SGLLendingBorrowing.borrow.selector,
                from,
                to,
                amount
            )
        );
        (part, share) = abi.decode(result, (uint256, uint256));
    }

    /// @notice Repays a loan.
    /// @param from Address to repay from.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        bytes memory result = _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                SGLLendingBorrowing.repay.selector,
                from,
                to,
                skim,
                part
            )
        );
        amount = abi.decode(result, (uint256));
    }

    /// @notice Lever down: Sell collateral to repay debt; excess goes to YB
    /// @param from The user who sells
    /// @param share Collateral YieldBox-shares to sell
    /// @param minAmountOut Mininal proceeds required for the sale
    /// @param swapper Swapper to execute the sale
    /// @param dexData Additional data to pass to the swapper
    /// @param amountOut Actual asset amount received in the sale
    function sellCollateral(
        address from,
        uint256 share,
        uint256 minAmountOut,
        ISwapper swapper,
        bytes calldata dexData
    ) external returns (uint256 amountOut) {
        bytes memory result = _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                SGLLendingBorrowing.sellCollateral.selector,
                from,
                share,
                minAmountOut,
                swapper,
                dexData
            )
        );
        amountOut = abi.decode(result, (uint256));
    }

    /// @notice Lever up: Borrow more and buy collateral with it.
    /// @param from The user who buys
    /// @param borrowAmount Amount of extra asset borrowed
    /// @param supplyAmount Amount of asset supplied (down payment)
    /// @param minAmountOut Mininal collateral amount to receive
    /// @param swapper Swapper to execute the purchase
    /// @param dexData Additional data to pass to the swapper
    /// @param amountOut Actual collateral amount purchased
    function buyCollateral(
        address from,
        uint256 borrowAmount,
        uint256 supplyAmount,
        uint256 minAmountOut,
        ISwapper swapper,
        bytes calldata dexData
    ) external returns (uint256 amountOut) {
        bytes memory result = _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                SGLLendingBorrowing.buyCollateral.selector,
                from,
                borrowAmount,
                supplyAmount,
                minAmountOut,
                swapper,
                dexData
            )
        );
        amountOut = abi.decode(result, (uint256));
    }

    /// @notice Entry point for liquidations.
    /// @dev Will call `closedLiquidation()` if not LQ exists or no LQ bid avail exists. Otherwise use LQ.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    ///        Ignore for `orderBookLiquidation()`
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    ///        Ignore for `orderBookLiquidation()`
    /// @param collateralToAssetSwapData Extra swap data
    ///        Ignore for `orderBookLiquidation()`
    /// @param usdoToBorrowedSwapData Extra swap data
    ///        Ignore for `closedLiquidation()`
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        ISwapper swapper,
        bytes calldata collateralToAssetSwapData,
        bytes calldata usdoToBorrowedSwapData
    ) external {
        _executeModule(
            Module.Liquidation,
            abi.encodeWithSelector(
                SGLLiquidation.liquidate.selector,
                users,
                maxBorrowParts,
                swapper,
                collateralToAssetSwapData,
                usdoToBorrowedSwapData
            )
        );
    }

    /// @notice Withdraw the fees accumulated in `accrueInfo.feesEarnedFraction` to the balance of `feeTo`.
    function withdrawFeesEarned() public {
        accrue();
        address _feeTo = penrose.feeTo();
        uint256 _feesEarnedFraction = accrueInfo.feesEarnedFraction;
        balanceOf[_feeTo] += _feesEarnedFraction;
        emit Transfer(address(0), _feeTo, _feesEarnedFraction);
        accrueInfo.feesEarnedFraction = 0;
        emit LogWithdrawFees(_feeTo, _feesEarnedFraction);
    }

    /// @notice Withdraw the balance of `feeTo`, swap asset into TAP and deposit it to yieldBox of `feeTo`
    function depositFeesToYieldBox(
        ISwapper swapper,
        IPenrose.SwapData calldata swapData
    ) public {
        if (accrueInfo.feesEarnedFraction > 0) {
            withdrawFeesEarned();
        }
        require(penrose.swappers(swapper), "SGL: Invalid swapper");
        address _feeTo = penrose.feeTo();

        uint256 feeShares = _removeAsset(
            _feeTo,
            address(this),
            balanceOf[_feeTo],
            false
        );
        if (feeShares == 0) return;

        uint256 wethAssetId = penrose.wethAssetId();
        uint256 amount = 0;
        if (assetId != wethAssetId) {
            yieldBox.transfer(
                address(this),
                address(swapper),
                assetId,
                feeShares
            );

            (amount, ) = swapper.swap(
                assetId,
                penrose.wethAssetId(),
                feeShares,
                _feeTo,
                swapData.minAssetAmount,
                abi.encode(_assetToWethSwapPath())
            );
        } else {
            yieldBox.transfer(address(this), _feeTo, assetId, feeShares);
        }

        emit LogYieldBoxFeesDeposit(feeShares, amount);
    }

    /// @notice Withdraw to another layer
    /// @dev if `dstChainId` is 0, withdraw happens on the same chain
    function withdrawTo(
        address from,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        bytes calldata adapterParams,
        address payable refundAddress
    ) public payable allowed(from) {
        if (dstChainId == 0) {
            yieldBox.withdraw(
                assetId,
                from,
                LzLib.bytes32ToAddress(receiver),
                amount,
                0
            );
            return;
        }
        try
            IERC165(address(asset)).supportsInterface(
                type(ISendFrom).interfaceId
            )
        {} catch {
            return;
        }

        require(
            yieldBox.toAmount(
                assetId,
                yieldBox.balanceOf(from, assetId),
                false
            ) >= amount,
            "SGL: not available"
        );

        yieldBox.withdraw(assetId, from, address(this), amount, 0);
        ISendFrom.LzCallParams memory callParams = ISendFrom.LzCallParams({
            refundAddress: msg.value > 0 ? refundAddress : payable(this),
            zroPaymentAddress: address(0),
            adapterParams: adapterParams
        });
        ISendFrom(address(asset)).sendFrom{
            value: msg.value > 0 ? msg.value : address(this).balance
        }(address(this), dstChainId, receiver, amount, callParams);
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice Set the bonus amount a liquidator can make use of, on top of the amount needed to make the user solvent
    /// @param _val the new value
    function setLiquidationBonusAmount(uint256 _val) external onlyOwner {
        require(_val < FEE_PRECISION, "SGL: not valid");
        liquidationBonusAmount = _val;
    }

    /// @notice Set the liquidator min reward
    /// @param _val the new value
    function setMinLiquidatorReward(uint256 _val) external onlyOwner {
        require(_val < FEE_PRECISION, "SGL: not valid");
        require(_val < maxLiquidatorReward, "SGL: not valid");
        minLiquidatorReward = _val;
    }

    /// @notice Set the liquidator max reward
    /// @param _val the new value
    function setMaxLiquidatorReward(uint256 _val) external onlyOwner {
        require(_val < FEE_PRECISION, "SGL: not valid");
        require(_val > minLiquidatorReward, "SGL: not valid");
        maxLiquidatorReward = _val;
    }

    /// @notice Set the Conservator address
    /// @dev Conservator can pause the contract
    /// @param _conservator The new address
    function setConservator(address _conservator) external onlyOwner {
        require(_conservator != address(0), "SGL: address not valid");
        emit ConservatorUpdated(conservator, _conservator);
        conservator = _conservator;
    }

    /// @notice updates the pause state of the contract
    /// @param val the new value
    function updatePause(bool val) external {
        require(msg.sender == conservator, "SGL: unauthorized");
        require(val != paused, "SGL: same state");
        emit PausedUpdated(paused, val);
        paused = val;
    }

    /// @notice sets the collateralization rate used for LiquidationQueue type liquidations
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setLqCollateralizationRate(uint256 _val) external onlyOwner {
        require(_val <= COLLATERALIZATION_RATE_PRECISION, "SGL: not valid");
        lqCollateralizationRate = _val;
    }

    /// @notice sets closed collateralization rate
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setClosedCollateralizationRate(uint256 _val) external onlyOwner {
        require(_val <= COLLATERALIZATION_RATE_PRECISION, "SGL: not valid");
        closedCollateralizationRate = _val;
    }

    /// @notice sets the liquidation multiplier
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setLiquidationMultiplier(uint256 _val) external onlyOwner {
        liquidationMultiplier = _val;
    }

    /// @notice sets the order book multiplier
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setOrderBookLiquidationMultiplier(
        uint256 _val
    ) external onlyOwner {
        orderBookLiquidationMultiplier = _val;
    }

    /// @notice sets the borrowing opening fee
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setBorrowOpeningFee(uint256 _val) external onlyOwner {
        require(_val <= FEE_PRECISION, "SGL: not valid");
        borrowOpeningFee = _val;
    }

    /// @notice sets the liquidator fee
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setCallerFee(uint256 _val) external onlyOwner {
        require(_val <= FEE_PRECISION, "SGL: not valid");
        callerFee = _val;
    }

    /// @notice sets the protocol fee
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setProtocolFee(uint256 _val) external onlyOwner {
        require(_val <= FEE_PRECISION, "SGL: not valid");
        protocolFee = _val;
    }

    /// @notice Set a new LiquidationQueue.
    /// @param _liquidationQueue The address of the new LiquidationQueue contract.
    function setLiquidationQueue(
        ILiquidationQueue _liquidationQueue
    ) public onlyOwner {
        require(_liquidationQueue.onlyOnce(), "SGL: LQ not initalized");
        liquidationQueue = _liquidationQueue;
    }

    /// @notice Execute an only owner function inside of the LiquidationQueue
    function updateLQExecutionSwapper(address _swapper) external onlyOwner {
        liquidationQueue.setBidExecutionSwapper(_swapper);
    }

    /// @notice Execute an only owner function inside of the LiquidationQueue
    function updateLQUsdoSwapper(address _swapper) external onlyOwner {
        liquidationQueue.setUsdoSwapper(_swapper);
    }

    /// @notice sets max borrowable amount
    function setBorrowCap(uint256 _cap) external notPaused onlyOwner {
        emit LogBorrowCapUpdated(totalBorrowCap, _cap);
        totalBorrowCap = _cap;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //

    function _getRevertMsg(
        bytes memory _returnData
    ) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "SGL: no return data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _extractModule(Module _module) private view returns (address) {
        address module;
        if (_module == Module.LendingBorrowing) {
            module = address(lendingBorrowingModule);
        } else if (_module == Module.Liquidation) {
            module = address(liquidationModule);
        }
        if (module == address(0)) {
            revert("SGL: module not set");
        }

        return module;
    }

    function _executeModule(
        Module _module,
        bytes memory _data
    ) private returns (bytes memory returnData) {
        bool success = true;
        address module = _extractModule(_module);

        (success, returnData) = module.delegatecall(_data);
        if (!success) {
            revert(_getRevertMsg(returnData));
        }
    }

    function _executeViewModule(
        Module _module,
        bytes memory _data
    ) private view returns (bytes memory returnData) {
        bool success = true;
        address module = _extractModule(_module);

        (success, returnData) = module.staticcall(_data);
        if (!success) {
            revert(_getRevertMsg(returnData));
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "./ISwapper.sol";
import "../interfaces/IPenrose.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

import "../libraries/ICurvePool.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title Curve pool swapper
contract CurveSwapper is ISwapper {
    using BoringERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //
    ICurvePool public curvePool;

    YieldBox private immutable yieldBox;

    /// @notice creates a new CurveSwapper contract
    /// @param _curvePool CurvePool address
    /// @param _bar Penrose address
    constructor(ICurvePool _curvePool, IPenrose _bar) {
        curvePool = _curvePool;
        yieldBox = YieldBox(_bar.yieldBox());
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns the possible output amount for input share
    /// @param tokenInId YieldBox asset id
    /// @param shareIn Shares to get the amount for
    /// @param dexData Custom DEX data for query execution
    function getOutputAmount(
        uint256 tokenInId,
        uint256 shareIn,
        bytes calldata dexData
    ) external view override returns (uint256 amountOut) {
        uint256[] memory tokenIndexes = abi.decode(dexData, (uint256[]));
        uint256 amountIn = yieldBox.toAmount(tokenInId, shareIn, false);
        amountOut = curvePool.get_dy(
            int128(int256(tokenIndexes[0])),
            int128(int256(tokenIndexes[1])),
            amountIn
        );
    }

    function getInputAmount(
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (uint256) {
        revert("Not implemented");
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice swaps token in with token out
    /// @dev returns both amount and shares
    /// @param tokenInId YieldBox asset id
    /// @param tokenOutId YieldBox asset id
    /// @param shareIn Shares to be swapped
    /// @param to Receiver address
    /// @param amountOutMin Minimum amount to be received
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for Curve, it should contain uint256[] tokenIndexes
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 shareIn,
        address to,
        uint256 amountOutMin,
        bytes calldata dexData
    ) external override returns (uint256 amountOut, uint256 shareOut) {
        uint256[] memory tokenIndexes = abi.decode(dexData, (uint256[]));

        (uint256 amountIn, ) = yieldBox.withdraw(
            tokenInId,
            address(this),
            address(this),
            0,
            shareIn
        );

        amountOut = _swapTokensForTokens(
            int128(int256(tokenIndexes[0])),
            int128(int256(tokenIndexes[1])),
            amountIn,
            amountOutMin
        );

        (, address tokenOutAddress, , ) = yieldBox.assets(tokenOutId);
        IERC20(tokenOutAddress).approve(address(yieldBox), amountOut);
        (, shareOut) = yieldBox.depositAsset(
            tokenOutId,
            address(this),
            to,
            amountOut,
            0
        );
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _swapTokensForTokens(
        int128 i,
        int128 j,
        uint256 amountIn,
        uint256 amountOutMin
    ) private returns (uint256) {
        address tokenOut = curvePool.coins(uint256(uint128(j)));

        uint256 outputAmount = curvePool.get_dy(i, j, amountIn);
        require(outputAmount >= amountOutMin, "insufficient-amount-out");

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        curvePool.exchange(i, j, amountIn, amountOutMin);
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "swap failed");

        return balanceAfter - balanceBefore;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ISwapper {
    /// @notice returns the possible output amount for input share
    /// @param tokenInId YieldBox asset id
    /// @param shareIn Shares to get the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for Curve, it should contain uint256[] tokenIndexes
    function getOutputAmount(
        uint256 tokenInId,
        uint256 shareIn,
        bytes calldata dexData
    ) external view returns (uint256 amountOut);

    /// @notice returns necessary input amount for a fixed output amount
    /// @param tokenOutId YieldBox asset id
    /// @param shareOut Shares out to compute the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    function getInputAmount(
        uint256 tokenOutId,
        uint256 shareOut,
        bytes calldata dexData
    ) external view returns (uint256 amountIn);

    /// @notice swaps token in with token out
    /// @dev returns both amount and shares
    /// @param tokenInId YieldBox asset id
    /// @param tokenOutId YieldBox asset id
    /// @param shareIn Shares to be swapped
    /// @param to Receiver address
    /// @param amountOutMin Minimum amount to be received
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for Curve, it should contain uint256[] tokenIndexes
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 shareIn,
        address to,
        uint256 amountOutMin,
        bytes calldata dexData
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import "./FullMath.sol";
import "./TickMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(
        address pool,
        uint32 secondsAgo
    )
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[
                1
            ] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / int32(secondsAgo));
        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % int32(secondsAgo) != 0)
        ) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(
            secondsAgoX160 /
                (uint192(secondsPerLiquidityCumulativesDelta) << 32)
        );
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(
                sqrtRatioX96,
                sqrtRatioX96,
                1 << 64
            );
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(
        address pool
    ) internal view returns (uint32 secondsAgo) {
        (
            ,
            ,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, "NI");

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(
            pool
        ).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(
        address pool
    ) internal view returns (int24, uint128) {
        (
            ,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, "NEO");

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) +
            observationCardinality -
            1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, "ONI");

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - prevTickCumulative) / int32(delta));
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(
                    secondsPerLiquidityCumulativeX128 -
                        prevSecondsPerLiquidityCumulativeX128
                ) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(
        WeightedTickData[] memory weightedTickData
    ) internal pure returns (int24 weightedArithmeticMeanTick) {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator +=
                weightedTickData[i].tick *
                int256(uint256(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0))
            weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(
        address[] memory tokens,
        int24[] memory ticks
    ) internal pure returns (int256 syntheticTick) {
        require(tokens.length - 1 == ticks.length, "DL");
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i]
                ? syntheticTick += ticks[i - 1]
                : syntheticTick -= ticks[i - 1];
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(
        int24 tick
    ) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(
        uint160 sqrtPriceX96
    ) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
            "R"
        );
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24(
            (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
        );
        int24 tickHi = int24(
            (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
        );

        tick = tickLow == tickHi
            ? tickLow
            : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "./ISwapper.sol";
import "../interfaces/IPenrose.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

import "../libraries/IUniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/IUniswapV2Pair.sol";

/// Modified from https://github.com/sushiswap/kashi-lending/blob/master/contracts/swappers/SushiSwapMultiSwapper.sol
contract MultiSwapper is ISwapper {
    using BoringERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //
    address private immutable factory;
    YieldBox private immutable yieldBox;
    bytes32 private immutable pairCodeHash;

    /// @notice creates a new MultiSwapper contract
    /// @param _factory UniswapV2Factory address
    /// @param _tapiocaBar Penrose address
    /// @param _pairCodeHash UniswapV2 pair code hash
    constructor(address _factory, IPenrose _tapiocaBar, bytes32 _pairCodeHash) {
        factory = _factory;
        yieldBox = YieldBox(_tapiocaBar.yieldBox());
        pairCodeHash = _pairCodeHash;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns the possible output amount for input share
    /// @param tokenInId YieldBox asset id
    /// @param shareIn Shares to get the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    function getOutputAmount(
        uint256 tokenInId,
        uint256 shareIn,
        bytes calldata dexData
    ) external view override returns (uint256 amountOut) {
        address[] memory path = abi.decode(dexData, (address[]));
        uint256 amountIn = yieldBox.toAmount(tokenInId, shareIn, false);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
    }

    /// @notice returns necessary input amount for a fixed output amount
    /// @param tokenOutId YieldBox asset id
    /// @param shareOut Shares out to compute the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    function getInputAmount(
        uint256 tokenOutId,
        uint256 shareOut,
        bytes calldata dexData
    ) external view override returns (uint256 amountIn) {
        address[] memory path = abi.decode(dexData, (address[]));
        uint256 amountOut = yieldBox.toAmount(tokenOutId, shareOut, false);
        uint256[] memory amounts = UniswapV2Library.getAmountsIn(
            factory,
            amountOut,
            path,
            pairCodeHash
        );
        amountIn = amounts[0];
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice swaps token in with token out
    /// @dev returns both amount and shares
    /// @param tokenInId YieldBox asset id
    /// @param tokenOutId YieldBox asset id
    /// @param shareIn Shares to be swapped
    /// @param to Receiver address
    /// @param amountOutMin Minimum amount to be received
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 shareIn,
        address to,
        uint256 amountOutMin,
        bytes calldata dexData
    ) external override returns (uint256 amountOut, uint256 shareOut) {
        address[] memory path = abi.decode(dexData, (address[]));
        (uint256 amountIn, ) = yieldBox.withdraw(
            tokenInId,
            address(this),
            address(this),
            0,
            shareIn
        );

        amountOut = _swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this)
        );

        IERC20(path[path.length - 1]).approve(address(yieldBox), amountOut);
        (, shareOut) = yieldBox.depositAsset(
            tokenOutId,
            address(this),
            to,
            amountOut,
            0
        );
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    // Swaps an exact amount of tokens for another token through the path passed as an argument
    // Returns the amount of the final token
    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountOutMin, "insufficient-amount-out");
        // Required for the next step
        IERC20(path[0]).safeTransfer(
            UniswapV2Library.pairFor(factory, path[0], path[1], pairCodeHash),
            amountIn
        );
        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairCodeHash
                )
                : _to;

            IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output, pairCodeHash)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "../libraries/IUniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/IUniswapV2Pair.sol";

/// Modified from https://github.com/sushiswap/kashi-lending/blob/master/contracts/swappers/SushiSwapMultiSwapper.sol

contract NonYieldBoxMultiSwapper {
    using BoringERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //
    address private immutable factory;
    bytes32 private immutable pairCodeHash;

    /// @notice creates a new MultiSwapper contract
    /// @param _factory UniswapV2Factory address
    /// @param _pairCodeHash UniswapV2 pair code hash
    constructor(address _factory, bytes32 _pairCodeHash) {
        factory = _factory;
        pairCodeHash = _pairCodeHash;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    function getOutputAmount(
        address[] calldata path,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
    }

    function getInputAmount(
        address[] calldata path,
        uint256 amountOut
    ) external view returns (uint256 amountIn) {
        uint256[] memory amounts = UniswapV2Library.getAmountsIn(
            factory,
            amountOut,
            path,
            pairCodeHash
        );
        amountIn = amounts[0];
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountMinOut,
        address to,
        address[] calldata path,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        amountOut = _swapExactTokensForTokens(
            amountIn,
            amountMinOut,
            path,
            address(this)
        );

        IERC20(tokenOut).safeTransfer(to, amountOut);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    // Swaps an exact amount of tokens for another token through the path passed as an argument
    // Returns the amount of the final token
    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountOutMin, "insufficient-amount-out");
        // Required for the next step
        IERC20(path[0]).safeTransfer(
            UniswapV2Library.pairFor(factory, path[0], path[1], pairCodeHash),
            amountIn
        );
        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairCodeHash
                )
                : _to;

            IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output, pairCodeHash)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

import "./ISwapper.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IYieldBox.sol";
import "./libraries/OracleLibrary.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__
*/

/// @title UniswapV3 swapper contract
contract UniswapV3Swapper is ISwapper {
    // ************ //
    // *** VARS *** //
    // ************ //
    IYieldBox private immutable yieldBox;
    ISwapRouter public immutable swapRouter;
    IUniswapV3Factory public immutable factory;
    address public owner;

    uint24 public poolFee = 3000;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event PoolFee(uint256 _old, uint256 _new);

    /// @notice creates a new UniswapV3Swapper contract
    constructor(
        IYieldBox _yieldBox,
        ISwapRouter _swapRouter,
        IUniswapV3Factory _factory
    ) {
        yieldBox = _yieldBox;
        swapRouter = _swapRouter;
        factory = _factory;
        owner = msg.sender;
    }

    /// @notice sets a new pool fee
    /// @param _newFee the new value
    function setPoolFee(uint24 _newFee) external {
        require(msg.sender == owner, "UniswapV3Swapper: not authorized");
        emit PoolFee(poolFee, _newFee);
        poolFee = _newFee;
    }

    /// @notice returns the possible output amount for input share
    /// @param tokenInId YieldBox asset id
    /// @param shareIn Shares to get the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for Curve, it should contain uint256[] tokenIndexes
    ///     - for UniV3, it should contain uint256 tokenOutId
    function getOutputAmount(
        uint256 tokenInId,
        uint256 shareIn,
        bytes calldata dexData
    ) external view override returns (uint256 amountOut) {
        uint256 tokenOutId = abi.decode(dexData, (uint256));

        (, address tokenIn, , ) = yieldBox.assets(tokenInId);
        (, address tokenOut, , ) = yieldBox.assets(tokenOutId);

        uint256 amountIn = yieldBox.toAmount(tokenInId, shareIn, false);

        address pool = factory.getPool(tokenIn, tokenOut, poolFee);
        (int24 tick, ) = OracleLibrary.consult(pool, 60);

        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(amountIn),
            tokenIn,
            tokenOut
        );
    }

    /// @notice returns necessary input amount for a fixed output amount
    /// @param tokenOutId YieldBox asset id
    /// @param shareOut Shares out to compute the amount for
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for UniV3, it should contain uint256 tokenInId
    function getInputAmount(
        uint256 tokenOutId,
        uint256 shareOut,
        bytes calldata dexData
    ) external view override returns (uint256 amountIn) {
        uint256 tokenInId = abi.decode(dexData, (uint256));

        (, address tokenIn, , ) = yieldBox.assets(tokenInId);
        (, address tokenOut, , ) = yieldBox.assets(tokenOutId);

        uint256 amountOut = yieldBox.toAmount(tokenOutId, shareOut, false);

        address pool = factory.getPool(tokenIn, tokenOut, poolFee);

        (int24 tick, ) = OracleLibrary.consult(pool, 60);
        amountIn = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(amountOut),
            tokenOut,
            tokenIn
        );
    }

    /// @notice swaps token in with token out
    /// @dev returns both amount and shares
    /// @param tokenInId YieldBox asset id
    /// @param tokenOutId YieldBox asset id
    /// @param shareIn Shares to be swapped
    /// @param to Receiver address
    /// @param amountOutMin Minimum amount to be received
    /// @param dexData Custom DEX data for query execution
    /// @dev dexData examples:
    ///     - for UniV2, it should contain address[] swapPath
    ///     - for Curve, it should contain uint256[] tokenIndexes
    ///     - for UniV3, it should contain uint256 deadline
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 shareIn,
        address to,
        uint256 amountOutMin,
        bytes calldata dexData
    ) external override returns (uint256 amountOut, uint256 shareOut) {
        (, address tokenIn, , ) = yieldBox.assets(tokenInId);
        (, address tokenOut, , ) = yieldBox.assets(tokenOutId);

        (uint256 amountIn, ) = yieldBox.withdraw(
            tokenInId,
            address(this),
            address(this),
            0,
            shareIn
        );

        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        uint256 deadline = abi.decode(dexData, (uint256));
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        IERC20(tokenOut).approve(address(yieldBox), amountOut);
        (, shareOut) = yieldBox.depositAsset(
            tokenOutId,
            address(this),
            to,
            amountOut,
            0
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";
import "tapioca-sdk/dist/contracts/token/oft/v2/OFTV2.sol";
import "./interfaces/IYieldBox.sol";

//
//                 .(%%%%%%%%%%%%*       *
//             #%%%%%%%%%%%%%%%%%%%%*  ####*
//          #%%%%%%%%%%%%%%%%%%%%%#  /####
//       ,%%%%%%%%%%%%%%%%%%%%%%%   ####.  %
//                                #####
//                              #####
//   #####%#####              *####*  ####%#####*
//  (#########(              #####     ##########.
//  ##########             #####.      .##########
//                       ,####/
//                      #####
//  %%%%%%%%%%        (####.           *%%%%%%%%%#
//  .%%%%%%%%%%     *####(            .%%%%%%%%%%
//   *%%%%%%%%%%   #####             #%%%%%%%%%%
//               (####.
//      ,((((  ,####(          /(((((((((((((
//        *,  #####  ,(((((((((((((((((((((
//          (####   ((((((((((((((((((((/
//         ####*  (((((((((((((((((((
//                     ,**//*,.

abstract contract BaseOFT is OFTV2 {
    using SafeERC20 for IERC20;
    using BytesLib for bytes;

    /// @notice The YieldBox address.
    IYieldBox public immutable yieldBox;

    uint16 public constant PT_YB_SEND_STRAT = 770;
    uint16 public constant PT_YB_RETRIEVE_STRAT = 771;
    uint16 public constant PT_YB_DEPOSIT = 772;
    uint16 public constant PT_YB_WITHDRAW = 773;

    /// ==========================
    /// ========== Errors ========
    /// ==========================
    /// @notice Error while depositing ETH assets to YieldBox.
    error TOFT_YB_ETHDeposit();

    /// ==========================
    /// ========== Events ========
    /// ==========================
    event YieldBoxDeposit(uint256 _amount);
    event YieldBoxRetrieval(uint256 _amount);

    constructor(IYieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    receive() external payable {}

    // ==========================
    // ========== LZ ============
    // ==========================
    function sendToYB(
        uint256 amount,
        uint256 assetId,
        uint16 lzDstChainId,
        uint256 extraGasLimit,
        address zroPaymentAddress,
        bool strategyDeposit
    ) external payable {
        bytes32 toAddress = LzLib.addressToBytes32(msg.sender);
        _debitFrom(msg.sender, lzEndpoint.getChainId(), toAddress, amount);

        bytes memory lzPayload = abi.encode(
            strategyDeposit ? PT_YB_SEND_STRAT : PT_YB_DEPOSIT,
            LzLib.addressToBytes32(msg.sender),
            toAddress,
            amount,
            assetId
        );
        bytes memory adapterParam = LzLib.buildDefaultAdapterParams(
            extraGasLimit
        );
        _lzSend(
            lzDstChainId,
            lzPayload,
            payable(msg.sender),
            zroPaymentAddress,
            adapterParam,
            msg.value
        );
        emit SendToChain(lzDstChainId, msg.sender, toAddress, amount);
    }

    function retrieveFromYB(
        uint256 amount,
        uint256 assetId,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        bytes memory airdropAdapterParam,
        bool strategyWithdrawal
    ) external payable {
        bytes32 toAddress = LzLib.addressToBytes32(msg.sender);

        bytes memory lzPayload = abi.encode(
            strategyWithdrawal ? PT_YB_RETRIEVE_STRAT : PT_YB_WITHDRAW,
            LzLib.addressToBytes32(msg.sender),
            toAddress,
            amount,
            0,
            assetId,
            zroPaymentAddress
        );
        _lzSend(
            lzDstChainId,
            lzPayload,
            payable(msg.sender),
            zroPaymentAddress,
            airdropAdapterParam,
            msg.value
        );
        emit SendToChain(lzDstChainId, msg.sender, toAddress, amount);
    }

    // ================================
    // ========== YieldBox ============
    // ================================

    function _ybDeposit(
        uint16 _srcChainId,
        bytes memory _payload,
        IERC20 _erc20,
        bool _strategyDeposit
    ) internal virtual {
        (
            ,
            bytes32 fromAddressBytes, //from
            ,
            uint256 amount,
            uint256 assetId
        ) = abi.decode(_payload, (uint16, bytes32, bytes32, uint256, uint256));

        address onBehalfOf = _strategyDeposit
            ? address(this)
            : LzLib.bytes32ToAddress(fromAddressBytes);
        _creditTo(_srcChainId, address(this), amount);
        _depositToYieldbox(assetId, amount, _erc20, address(this), onBehalfOf);

        emit ReceiveFromChain(_srcChainId, onBehalfOf, amount);
    }

    function _ybWithdraw(
        uint16 _srcChainId,
        bytes memory _payload,
        bool _strategyWithdrawal
    ) internal virtual {
        (
            ,
            bytes32 from,
            ,
            uint256 _amount,
            uint256 _share,
            uint256 _assetId,
            address _zroPaymentAddress
        ) = abi.decode(
                _payload,
                (uint16, bytes32, bytes32, uint256, uint256, uint256, address)
            );

        address _from = LzLib.bytes32ToAddress(from);
        _retrieveFromYieldBox(
            _assetId,
            _amount,
            _share,
            _strategyWithdrawal ? address(this) : _from,
            address(this)
        );

        _debitFrom(
            address(this),
            lzEndpoint.getChainId(),
            LzLib.addressToBytes32(address(this)),
            _amount
        );
        bytes memory lzSendBackPayload = _encodeSendPayload(
            from,
            _ld2sd(_amount)
        );
        _lzSend(
            _srcChainId,
            lzSendBackPayload,
            payable(this),
            _zroPaymentAddress,
            "",
            address(this).balance
        );
        emit SendToChain(
            _srcChainId,
            _from,
            LzLib.addressToBytes32(address(this)),
            _amount
        );

        emit ReceiveFromChain(_srcChainId, _from, _amount);
    }

    /// @notice Receive an inter-chain transaction to execute a deposit inside YieldBox.
    function _depositToYieldbox(
        uint256 _assetId,
        uint256 _amount,
        IERC20 _erc20,
        address _from,
        address _to
    ) private {
        _erc20.approve(address(yieldBox), _amount);
        yieldBox.depositAsset(_assetId, _from, _to, _amount, 0);

        emit YieldBoxDeposit(_amount);
    }

    /// @notice Receive an inter-chain transaction to execute a deposit inside YieldBox.
    function _retrieveFromYieldBox(
        uint256 _assetId,
        uint256 _amount,
        uint256 _share,
        address _from,
        address _to
    ) private {
        yieldBox.withdraw(_assetId, _from, _to, _amount, _share);

        emit YieldBoxRetrieval(_amount);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        uint256 packetType = _payload.toUint256(0); //because we are not using encodePacked

        if (packetType == PT_YB_SEND_STRAT) {
            _ybDeposit(_srcChainId, _payload, IERC20(address(this)), true);
        } else if (packetType == PT_YB_RETRIEVE_STRAT) {
            _ybWithdraw(_srcChainId, _payload, true);
        } else if (packetType == PT_YB_DEPOSIT) {
            _ybDeposit(_srcChainId, _payload, IERC20(address(this)), false);
        } else if (packetType == PT_YB_WITHDRAW) {
            _ybWithdraw(_srcChainId, _payload, false);
        } else {
            packetType = _payload.toUint8(0); //LZ uses encodePacked for payload
            if (packetType == PT_SEND) {
                _sendAck(_srcChainId, _srcAddress, _nonce, _payload);
            } else if (packetType == PT_SEND_AND_CALL) {
                _sendAndCallAck(_srcChainId, _srcAddress, _nonce, _payload);
            } else {
                revert("OFTCoreV2: unknown packet type");
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "../swappers/ISwapper.sol";
import "./interfaces/IBigBang.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IPenrose.sol";
import "../interfaces/ISendFrom.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

// solhint-disable max-line-length
/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

contract BigBang is BoringOwnable {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************ //
    // *** VARS *** //
    // ************ //
    mapping(address => mapping(address => bool)) public operators;

    IBigBang.AccrueInfo public accrueInfo;

    IPenrose public penrose;
    YieldBox public yieldBox;
    IERC20 public collateral;
    IUSDO public asset;
    uint256 public collateralId;
    uint256 public assetId;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
    uint256 public totalBorrowCap;

    // User balances
    mapping(address => uint256) public userCollateralShare;
    // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)

    mapping(address => uint256) public userBorrowPart;

    // map of operator approval
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    /// Asset -> collateral = assetAmount * exchangeRate.
    uint256 public exchangeRate;
    uint256 public borrowingFee;

    IOracle oracle;
    bytes public oracleData;

    uint256 public callerFee; // 90%
    uint256 public protocolFee; // 10%
    uint256 public collateralizationRate; // 75%
    uint256 public totalFees;

    bool public paused;
    address public conservator;

    bool private _isEthMarket;
    uint256 public maxDebtRate;
    uint256 public minDebtRate;
    uint256 public debtRateAgainstEthMarket;
    uint256 public debtStartPoint;
    uint256 private constant DEBT_PRECISION = 1e18;

    uint256 public minLiquidatorReward = 1e3; //1%
    uint256 public maxLiquidatorReward = 1e4; //10%
    uint256 public liquidationBonusAmount = 1e4; //10%

    //errors
    error NotApproved(address _from, address _operator);

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint256 accruedAmount, uint64 rate);
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogRemoveCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount,
        uint256 part
    );
    event LogRepay(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarned);
    event LogYieldBoxFeesDeposit(uint256 feeShares, uint256 tapAmount);
    event LogApprovalForAll(
        address indexed _from,
        address indexed _operator,
        bool _approved
    );
    event LogBorrowCapUpdated(uint256 _oldVal, uint256 _newVal);
    event LogStabilityFee(uint256 _oldFee, uint256 _newFee);
    event LogBorrowingFee(uint256 _oldVal, uint256 _newVal);
    event ConservatorUpdated(address indexed old, address indexed _new);
    event PausedUpdated(bool oldState, bool newState);

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    uint256 private constant LIQUIDATION_MULTIPLIER = 112000; // add 12%

    uint256 private constant MAX_BORROWING_FEE = 8e4; //at 80% for testing; TODO
    uint256 private constant MAX_STABILITY_FEE = 8e17; //at 80% for testing; TODO

    uint256 private constant FEE_PRECISION = 1e5;
    uint256 private EXCHANGE_RATE_PRECISION; //not costant, but can only be set in the 'init' method
    uint256 private constant COLLATERALIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //
    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    modifier allowed(address from) virtual {
        if (from != msg.sender && !operators[from][msg.sender]) {
            revert NotApproved(from, msg.sender);
        }
        _;
    }
    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent(address from) {
        _;
        require(_isSolvent(from, exchangeRate), "BigBang: insolvent");
    }

    modifier notPaused() {
        require(!paused, "BigBang: paused");
        _;
    }

    bool private initialized;
    modifier onlyOnce() {
        require(!initialized, "BigBang: initialized");
        _;
        initialized = true;
    }

    /// @notice The init function that acts as a constructor
    function init(bytes calldata data) external onlyOnce {
        (
            IPenrose tapiocaBar_,
            IERC20 _collateral,
            uint256 _collateralId,
            IOracle _oracle,
            uint256 _exchangeRatePrecision,
            uint256 _debtRateAgainstEth,
            uint256 _debtRateMin,
            uint256 _debtRateMax,
            uint256 _debtStartPoint
        ) = abi.decode(
                data,
                (
                    IPenrose,
                    IERC20,
                    uint256,
                    IOracle,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256
                )
            );

        penrose = tapiocaBar_;
        yieldBox = YieldBox(tapiocaBar_.yieldBox());
        owner = address(penrose);

        address _asset = penrose.usdoToken();

        require(
            address(_collateral) != address(0) &&
                address(_asset) != address(0) &&
                address(_oracle) != address(0),
            "BigBang: bad pair"
        );

        asset = IUSDO(_asset);
        assetId = penrose.usdoAssetId();
        collateral = _collateral;
        collateralId = _collateralId;
        oracle = _oracle;

        updateExchangeRate();

        callerFee = 90000; // 90%
        protocolFee = 10000; // 10%
        collateralizationRate = 75000; // 75%

        EXCHANGE_RATE_PRECISION = _exchangeRatePrecision;

        _isEthMarket = collateralId == penrose.wethAssetId();
        if (!_isEthMarket) {
            debtRateAgainstEthMarket = _debtRateAgainstEth;
            maxDebtRate = _debtRateMax;
            minDebtRate = _debtRateMin;
            debtStartPoint = _debtStartPoint;
        }

        minLiquidatorReward = 1e3;
        maxLiquidatorReward = 1e4;
        liquidationBonusAmount = 1e4;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice Return the amount of collateral for a `user` to be solvent, min TVL and max TVL. Returns 0 if user already solvent.
    /// @dev We use a `CLOSED_COLLATERIZATION_RATE` that is a safety buffer when making the user solvent again,
    ///      To prevent from being liquidated. This function is valid only if user is not solvent by `_isSolvent()`.
    /// @param user The user to check solvency.
    /// @param _exchangeRate The exchange rate asset/collateral.
    /// @return amountToSolvency The amount of collateral to be solvent.
    function computeTVLInfo(
        address user,
        uint256 _exchangeRate
    )
        public
        view
        returns (uint256 amountToSolvency, uint256 minTVL, uint256 maxTVL)
    {
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return (0, 0, 0);
        uint256 collateralShare = userCollateralShare[user];

        Rebase memory _totalBorrow = totalBorrow;

        uint256 collateralAmountInAsset = yieldBox.toAmount(
            collateralId,
            (collateralShare *
                (EXCHANGE_RATE_PRECISION / COLLATERALIZATION_RATE_PRECISION) *
                collateralizationRate),
            false
        ) / _exchangeRate;
        borrowPart = (borrowPart * _totalBorrow.elastic) / _totalBorrow.base;

        amountToSolvency = borrowPart >= collateralAmountInAsset
            ? borrowPart - collateralAmountInAsset
            : 0;

        (minTVL, maxTVL) = _computeMaxAndMinLTVInAsset(
            collateralShare,
            _exchangeRate
        );
    }

    /// @notice Return the maximum liquidatable amount for user
    function computeClosingFactor(
        address user,
        uint256 _exchangeRate
    ) public view returns (uint256) {
        if (_isSolvent(user, _exchangeRate)) return 0;

        (uint256 amountToSolvency, , uint256 maxTVL) = computeTVLInfo(
            user,
            _exchangeRate
        );
        uint256 borrowed = userBorrowPart[user];
        if (borrowed >= maxTVL) return borrowed;

        return
            amountToSolvency +
            ((liquidationBonusAmount * borrowed) / FEE_PRECISION);
    }

    function computeLiquidatorReward(
        address user,
        uint256 _exchangeRate
    ) public view returns (uint256) {
        (uint256 minTVL, uint256 maxTVL) = _computeMaxAndMinLTVInAsset(
            userCollateralShare[user],
            _exchangeRate
        );
        return _getCallerReward(userBorrowPart[user], minTVL, maxTVL);
    }

    /// @notice returns total market debt
    function getTotalDebt() external view returns (uint256) {
        return totalBorrow.elastic;
    }

    /// @notice returns the current debt rate
    function getDebtRate() public view returns (uint256) {
        if (_isEthMarket) return penrose.bigBangEthDebtRate(); // default 0.5%
        if (totalBorrow.elastic == 0) return minDebtRate;

        uint256 _ethMarketTotalDebt = BigBang(penrose.bigBangEthMarket())
            .getTotalDebt();
        uint256 _currentDebt = totalBorrow.elastic;
        uint256 _maxDebtPoint = (_ethMarketTotalDebt *
            debtRateAgainstEthMarket) / 1e18;

        if (_currentDebt >= _maxDebtPoint) return maxDebtRate;

        uint256 debtPercentage = ((_currentDebt - debtStartPoint) *
            DEBT_PRECISION) / (_maxDebtPoint - debtStartPoint);
        uint256 debt = ((maxDebtRate - minDebtRate) * debtPercentage) /
            DEBT_PRECISION +
            minDebtRate;

        return debt;
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Allows batched call to BingBang.
    /// @param calls An array encoded call data.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    function execute(
        bytes[] calldata calls,
        bool revertOnFail
    ) external returns (bool[] memory successes, string[] memory results) {
        successes = new bool[](calls.length);
        results = new string[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = _getRevertMsg(result);
        }
    }

    /// @notice allows 'operator' to act on behalf of the sender
    /// @param status true/false
    function updateOperator(address operator, bool status) external {
        operators[msg.sender][operator] = status;
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// @dev This function is supposed to be invoked if needed because Oracle queries can be expensive.
    ///      Oracle should consider USDO at 1$
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get("");

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        IBigBang.AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        //update debt rate
        uint256 annumDebtRate = getDebtRate();
        _accrueInfo.debtRate = uint64(annumDebtRate / 31536000); //per second

        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;

        uint256 extraAmount = 0;

        // Calculate fees
        extraAmount =
            (uint256(_totalBorrow.elastic) *
                _accrueInfo.debtRate *
                elapsedTime) /
            1e18;
        _totalBorrow.elastic += uint128(extraAmount);

        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount, _accrueInfo.debtRate);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @param from Account to borrow for.
    /// @param to The receiver of borrowed tokens.
    /// @param amount Amount to borrow.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(
        address from,
        address to,
        uint256 amount
    )
        public
        notPaused
        solvent(from)
        allowed(from)
        returns (uint256 part, uint256 share)
    {
        updateExchangeRate();

        accrue();

        (part, share) = _borrow(from, to, amount);
    }

    /// @notice Repays a loan.
    /// @dev The bool param is not used but we added it to respect the ISingularity interface for MarketsHelper compatibility
    /// @param from Address to repay from.
    /// @param to Address of the user this payment should go.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address from,
        address to,
        bool,
        uint256 part
    ) public notPaused allowed(from) returns (uint256 amount) {
        updateExchangeRate();

        accrue();

        amount = _repay(from, to, part);
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param from Account to transfer shares from.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) public notPaused allowed(from) {
        userCollateralShare[to] += share;
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare + share;
        _addTokens(from, collateralId, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(yieldBox) : from, to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param from Account to debit collateral from.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(
        address from,
        address to,
        uint256 share
    ) public notPaused solvent(from) allowed(from) {
        updateExchangeRate();

        // accrue must be called because we check solvency
        accrue();

        _removeCollateral(from, to, share);
    }

    /// @notice Withdraw the balance of `feeTo`, swap asset into TAP and deposit it to yieldBox of `feeTo`
    function depositFeesToYieldBox(
        ISwapper swapper,
        IPenrose.SwapData calldata swapData
    ) public notPaused {
        require(penrose.swappers(swapper), "BigBang: Invalid swapper");

        uint256 balance = asset.balanceOf(address(this));
        totalFees += balance;

        emit LogWithdrawFees(penrose.feeTo(), balance);

        address _feeTo = penrose.feeTo();
        if (totalFees > 0) {
            uint256 feeShares = yieldBox.toShare(assetId, totalFees, false);

            asset.approve(address(yieldBox), totalFees);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                totalFees,
                0
            );

            totalFees = 0;
            yieldBox.transfer(
                address(this),
                address(swapper),
                assetId,
                feeShares
            );
            (uint256 colAmount, ) = swapper.swap(
                assetId,
                penrose.wethAssetId(),
                feeShares,
                _feeTo,
                swapData.minAssetAmount,
                abi.encode(_assetToWethSwapPath())
            );

            emit LogYieldBoxFeesDeposit(feeShares, colAmount);
        }
    }

    /// @notice Entry point for liquidations.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    /// @param collateralToAssetSwapData Extra swap data
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        ISwapper swapper,
        bytes calldata collateralToAssetSwapData
    ) external notPaused {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        _closedLiquidation(
            users,
            maxBorrowParts,
            swapper,
            _exchangeRate,
            collateralToAssetSwapData
        );
    }

    /// @notice Withdraw to another layer
    function withdrawTo(
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        bytes calldata adapterParams,
        address payable refundAddress
    ) public payable {
        try
            IERC165(address(asset)).supportsInterface(
                type(ISendFrom).interfaceId
            )
        {} catch {
            return;
        }

        uint256 available = yieldBox.toAmount(
            assetId,
            yieldBox.balanceOf(msg.sender, assetId),
            false
        );
        require(available >= amount, "BigBang: not available");

        yieldBox.withdraw(assetId, msg.sender, address(this), amount, 0);

        ISendFrom.LzCallParams memory callParams = ISendFrom.LzCallParams({
            refundAddress: refundAddress,
            zroPaymentAddress: address(0),
            adapterParams: adapterParams
        });

        ISendFrom(address(asset)).sendFrom{value: msg.value}(
            address(this),
            dstChainId,
            receiver,
            amount,
            callParams
        );
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice Set the bonus amount a liquidator can make use of, on top of the amount needed to make the user solvent
    /// @param _val the new value
    function setLiquidationBonusAmount(uint256 _val) external onlyOwner {
        require(_val < FEE_PRECISION, "BigBang: not valid");
        liquidationBonusAmount = _val;
    }

    /// @notice Set the liquidator min reward
    /// @param _val the new value
    function setMinLiquidatorReward(uint256 _val) external onlyOwner {
        require(_val < FEE_PRECISION, "BigBang: not valid");
        require(_val < maxLiquidatorReward, "BigBang: not valid");
        minLiquidatorReward = _val;
    }

    /// @notice Set the liquidator max reward
    /// @param _val the new value
    function setMaxLiquidatorReward(uint256 _val) external onlyOwner {
        require(_val < FEE_PRECISION, "BigBang: not valid");
        require(_val > minLiquidatorReward, "BigBang: not valid");
        maxLiquidatorReward = _val;
    }

    /// @notice Set the Conservator address
    /// @dev Conservator can pause the contract
    /// @param _conservator The new address
    function setConservator(address _conservator) external onlyOwner {
        require(_conservator != address(0), "BigBang: address not valid");
        emit ConservatorUpdated(conservator, _conservator);
        conservator = _conservator;
    }

    /// @notice updates the pause state of the contract
    /// @param val the new value
    function updatePause(bool val) external {
        require(msg.sender == conservator, "BigBang: unauthorized");
        require(val != paused, "BigBang: same state");
        emit PausedUpdated(paused, val);
        paused = val;
    }

    /// @notice sets the protocol fee
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setProtocolFee(uint256 _val) external onlyOwner {
        require(_val <= FEE_PRECISION, "BigBang: not valid");
        protocolFee = _val;
    }

    /// @notice sets the caller fee
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setCallerFee(uint256 _val) external onlyOwner {
        require(_val <= FEE_PRECISION, "BigBang: not valid");
        callerFee = _val;
    }

    /// @notice sets the collateralization rate
    /// @dev can only be called by the owner
    /// @param _val the new value
    function setCollateralizationRate(uint256 _val) external onlyOwner {
        require(_val <= COLLATERALIZATION_RATE_PRECISION, "BigBang: not valid");
        collateralizationRate = _val;
    }

    /// @notice sets max borrowable amount
    function setBorrowCap(uint256 _cap) external onlyOwner notPaused {
        emit LogBorrowCapUpdated(totalBorrowCap, _cap);
        totalBorrowCap = _cap;
    }

    /// @notice Updates the variable debt ratio
    /// @dev has to be called before accrue
    function updateDebt() private {}

    /// @notice Updates the borrowing fee
    /// @param _borrowingFee the new value
    function updateBorrowingFee(uint256 _borrowingFee) external onlyOwner {
        require(_borrowingFee <= MAX_BORROWING_FEE, "BigBang: value not valid");
        emit LogBorrowingFee(borrowingFee, _borrowingFee);
        borrowingFee = _borrowingFee;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _getRevertMsg(
        bytes memory _returnData
    ) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "BingBang: no return data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice construct Uniswap path
    function _collateralToAssetSwapPath()
        private
        view
        returns (address[] memory path)
    {
        path = new address[](2);
        path[0] = address(collateral);
        path[1] = address(asset);
    }

    function _assetToWethSwapPath()
        internal
        view
        returns (address[] memory path)
    {
        path = new address[](2);
        path[0] = address(asset);
        path[1] = address(penrose.wethToken());
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(
        address user,
        uint256 _exchangeRate
    ) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];

        Rebase memory _totalBorrow = totalBorrow;

        return
            yieldBox.toAmount(
                collateralId,
                collateralShare *
                    (EXCHANGE_RATE_PRECISION /
                        COLLATERALIZATION_RATE_PRECISION) *
                    collateralizationRate,
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            (borrowPart * _totalBorrow.elastic * _exchangeRate) /
                _totalBorrow.base;
    }

    function _liquidateUser(
        address user,
        uint256 maxBorrowPart,
        ISwapper swapper,
        uint256 _exchangeRate,
        bytes calldata swapData
    ) private {
        if (_isSolvent(user, _exchangeRate)) return;

        (
            uint256 startTVLInAsset,
            uint256 maxTVLInAsset
        ) = _computeMaxAndMinLTVInAsset(
                userCollateralShare[user],
                _exchangeRate
            );
        uint256 callerReward = _getCallerReward(
            userBorrowPart[user],
            startTVLInAsset,
            maxTVLInAsset
        );

        (
            uint256 borrowAmount,
            uint256 borrowPart,
            uint256 collateralShare
        ) = _updateBorrowAndCollateralShare(user, maxBorrowPart, _exchangeRate);
        emit LogRemoveCollateral(user, address(swapper), collateralShare);
        emit LogRepay(address(swapper), user, borrowAmount, borrowPart);

        uint256 borrowShare = yieldBox.toShare(assetId, borrowAmount, true);

        // Closed liquidation using a pre-approved swapper
        require(penrose.swappers(swapper), "BigBang: Invalid swapper");

        // Swaps the users collateral for the borrowed asset
        yieldBox.transfer(
            address(this),
            address(swapper),
            collateralId,
            collateralShare
        );

        uint256 minAssetMount = 0;
        if (swapData.length > 0) {
            minAssetMount = abi.decode(swapData, (uint256));
        }

        uint256 balanceBefore = yieldBox.balanceOf(address(this), assetId);
        swapper.swap(
            collateralId,
            assetId,
            collateralShare,
            address(this),
            minAssetMount,
            abi.encode(_collateralToAssetSwapPath())
        );
        uint256 balanceAfter = yieldBox.balanceOf(address(this), assetId);

        uint256 returnedShare = balanceAfter - balanceBefore;
        _extractLiquidationFees(returnedShare, borrowShare, callerReward);
    }

    function _extractLiquidationFees(
        uint256 returnedShare,
        uint256 borrowShare,
        uint256 callerReward
    ) private {
        uint256 extraShare = returnedShare - borrowShare;
        uint256 feeShare = (extraShare * protocolFee) / FEE_PRECISION; // x% of profit goes to fee.
        uint256 callerShare = (extraShare * callerReward) / FEE_PRECISION; //  y%  of profit goes to caller.

        yieldBox.transfer(address(this), penrose.feeTo(), assetId, feeShare);
        yieldBox.transfer(address(this), msg.sender, assetId, callerShare);
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @dev Closed liquidations Only, 90% of extra shares goes to caller and 10% to protocol
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    /// @param swapData Swap necessar data
    function _closedLiquidation(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        ISwapper swapper,
        uint256 _exchangeRate,
        bytes calldata swapData
    ) private {
        uint256 liquidatedCount = 0;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                liquidatedCount++;
                _liquidateUser(
                    user,
                    maxBorrowParts[i],
                    swapper,
                    _exchangeRate,
                    swapData
                );
            }
        }

        require(liquidatedCount > 0, "SGL: no users found");
    }

    /// @dev Helper function to move tokens.
    /// @param from Account to debit tokens from, in `yieldBox`.
    /// @param _tokenId The ERC-20 token asset ID in yieldBox.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    function _addTokens(
        address from,
        uint256 _tokenId,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(
                share <= yieldBox.balanceOf(address(this), _tokenId) - total,
                "BigBang: too much"
            );
        } else {
            yieldBox.transfer(from, address(this), _tokenId, share);
        }
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(
        address from,
        address to,
        uint256 share
    ) internal {
        userCollateralShare[from] -= share;
        totalCollateralShare -= share;
        emit LogRemoveCollateral(from, to, share);
        yieldBox.transfer(address(this), to, collateralId, share);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address from,
        address to,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);

        userBorrowPart[to] -= part;

        uint256 toWithdraw = (amount - part); //acrrued
        uint256 toBurn = amount - toWithdraw;
        yieldBox.withdraw(assetId, from, address(this), amount, 0);
        //burn USDO
        if (toBurn > 0) {
            asset.burn(address(this), toBurn);
        }

        emit LogRepay(from, to, amount, part);
    }

    //TODO: accrue fees when re-borrowing
    /// @dev Concrete implementation of `borrow`.
    function _borrow(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = (amount * borrowingFee) / FEE_PRECISION; // A flat % fee is charged for any borrow

        (totalBorrow, part) = totalBorrow.add(amount + feeAmount, true);
        require(
            totalBorrowCap == 0 || totalBorrow.elastic <= totalBorrowCap,
            "BigBang: borrow cap reached"
        );

        userBorrowPart[from] += part;

        //mint USDO
        asset.mint(address(this), amount);

        //deposit borrowed amount to user
        asset.approve(address(yieldBox), amount);
        yieldBox.depositAsset(assetId, address(this), to, amount, 0);

        share = yieldBox.toShare(assetId, amount, false);

        emit LogBorrow(from, to, amount, feeAmount, part);
    }

    /// @notice Returns the min and max LTV for user in asset price
    function _computeMaxAndMinLTVInAsset(
        uint256 collateralShare,
        uint256 _exchangeRate
    ) internal view returns (uint256 min, uint256 max) {
        uint256 collateralAmount = yieldBox.toAmount(
            collateralId,
            collateralShare,
            false
        );

        max = (collateralAmount * EXCHANGE_RATE_PRECISION) / _exchangeRate;
        min = (max * collateralizationRate) / COLLATERALIZATION_RATE_PRECISION;
    }

    function _getCallerReward(
        uint256 borrowed,
        uint256 startTVLInAsset,
        uint256 maxTVLInAsset
    ) internal view returns (uint256) {
        if (borrowed == 0) return 0;
        if (startTVLInAsset == 0) return 0;

        if (borrowed < startTVLInAsset) return 0;
        if (borrowed >= maxTVLInAsset) return minLiquidatorReward;

        uint256 rewardPercentage = ((borrowed - startTVLInAsset) *
            FEE_PRECISION) / (maxTVLInAsset - startTVLInAsset);

        int256 diff = int256(minLiquidatorReward) - int256(maxLiquidatorReward);
        int256 reward = (diff * int256(rewardPercentage)) /
            int256(FEE_PRECISION) +
            int256(maxLiquidatorReward);

        return uint256(reward);
    }

    function _updateBorrowAndCollateralShare(
        address user,
        uint256 maxBorrowPart,
        uint256 _exchangeRate
    )
        private
        returns (
            uint256 borrowAmount,
            uint256 borrowPart,
            uint256 collateralShare
        )
    {
        uint256 availableBorrowPart = computeClosingFactor(user, _exchangeRate);
        borrowPart = maxBorrowPart > availableBorrowPart
            ? availableBorrowPart
            : maxBorrowPart;

        userBorrowPart[user] = userBorrowPart[user] - borrowPart;

        borrowAmount = totalBorrow.toElastic(borrowPart, false);
        collateralShare = yieldBox.toShare(
            collateralId,
            (borrowAmount * LIQUIDATION_MULTIPLIER * _exchangeRate) /
                (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
            false
        );
        userCollateralShare[user] -= collateralShare;
        require(borrowAmount != 0, "SGL: solvent");

        totalBorrow.elastic -= uint128(borrowAmount);
        totalBorrow.base -= uint128(borrowPart);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IBigBang {
    struct AccrueInfo {
        uint64 debtRate;
        uint64 lastAccrued;
    }

    function accrueInfo()
        external
        view
        returns (uint64 debtRate, uint64 lastAccrued);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);

    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
pragma experimental ABIEncoderV2;

// solhint-disable max-line-length

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}

interface IYieldBox {
    function wrappedNative() external view returns (address wrappedNative);

    function assets(
        uint256 assetId
    )
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function nativeTokens(
        uint256 assetId
    )
        external
        view
        returns (string memory name, string memory symbol, uint8 decimals);

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(
        uint256 assetId
    ) external view returns (uint256 totalSupply);

    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) external;

    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) external;

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IUSDO is IStrictERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";

contract FlashMaliciousBorrowerMock is IERC3156FlashBorrower {
    using BoringERC20 for IERC20;
    IERC3156FlashLender lender;

    constructor(IERC3156FlashLender _lender) {
        lender = _lender;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes32) {
        require(msg.sender == address(lender), "FlashBorrower: untrusted");
        require(initiator == address(this), "FlashBorrower: not the initiator");
        //do stuff here
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function flashBorrow(address token, uint256 amount) public {
        //missing approve for repayment
        lender.flashLoan(this, token, amount, "");
    }
}

contract FlashBorrowerMock is IERC3156FlashBorrower {
    using BoringERC20 for IERC20;
    IERC3156FlashLender lender;

    constructor(IERC3156FlashLender _lender) {
        lender = _lender;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes32) {
        require(msg.sender == address(lender), "FlashBorrower: untrusted");
        require(initiator == address(this), "FlashBorrower: not the initiator");
        //do stuff here
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function flashBorrow(address token, uint256 amount) public {
        approveRepayment(token, amount);
        lender.flashLoan(this, token, amount, "");
    }

    function approveRepayment(address token, uint256 amount) public {
        uint256 _allowance = IERC20(token).allowance(
            address(this),
            address(lender)
        );
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.18;
pragma abicoder v2;

import "tapioca-sdk/dist/contracts/interfaces/ILayerZeroReceiver.sol";
import "tapioca-sdk/dist/contracts/interfaces/ILayerZeroEndpoint.sol";
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";

/*
like a real LayerZero endpoint but can be mocked, which handle message transmission, verification, and receipt.
- blocking: LayerZero provides ordered delivery of messages from a given sender to a destination chain.
- non-reentrancy: endpoint has a non-reentrancy guard for both the send() and receive(), respectively.
- adapter parameters: allows UAs to add arbitrary transaction params in the send() function, like airdrop on destination chain.
unlike a real LayerZero endpoint, it is
- no messaging library versioning
- send() will short circuit to lzReceive()
- no user application configuration
*/
contract LZEndpointMock is ILayerZeroEndpoint {
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;

    mapping(address => address) public lzEndpointLookup;

    uint16 public mockChainId;
    bool public nextMsgBlocked;

    // fee config
    RelayerFeeConfig public relayerFeeConfig;
    ProtocolFeeConfig public protocolFeeConfig;
    uint256 public oracleFee;
    bytes public defaultAdapterParams;

    // path = remote addrss + local address
    // inboundNonce = [srcChainId][path].
    mapping(uint16 => mapping(bytes => uint64)) public inboundNonce;
    //todo: this is a hack
    // outboundNonce = [dstChainId][srcAddress]
    mapping(uint16 => mapping(address => uint64)) public outboundNonce;
    //    // outboundNonce = [dstChainId][path].
    //    mapping(uint16 => mapping(bytes => uint64)) public outboundNonce;
    // storedPayload = [srcChainId][path]
    mapping(uint16 => mapping(bytes => StoredPayload)) public storedPayload;
    // msgToDeliver = [srcChainId][path]
    mapping(uint16 => mapping(bytes => QueuedPayload[])) public msgsToDeliver;

    // reentrancy guard
    uint8 internal _send_entered_state = 1;
    uint8 internal _receive_entered_state = 1;

    struct ProtocolFeeConfig {
        uint256 zroFee;
        uint256 nativeBP;
    }

    struct RelayerFeeConfig {
        uint128 dstPriceRatio; // 10^10
        uint128 dstGasPriceInWei;
        uint128 dstNativeAmtCap;
        uint64 baseGas;
        uint64 gasPerByte;
    }

    struct StoredPayload {
        uint64 payloadLength;
        address dstAddress;
        bytes32 payloadHash;
    }

    struct QueuedPayload {
        address dstAddress;
        uint64 nonce;
        bytes payload;
    }

    modifier sendNonReentrant() {
        require(
            _send_entered_state == _NOT_ENTERED,
            "LayerZeroMock: no send reentrancy"
        );
        _send_entered_state = _ENTERED;
        _;
        _send_entered_state = _NOT_ENTERED;
    }

    modifier receiveNonReentrant() {
        require(
            _receive_entered_state == _NOT_ENTERED,
            "LayerZeroMock: no receive reentrancy"
        );
        _receive_entered_state = _ENTERED;
        _;
        _receive_entered_state = _NOT_ENTERED;
    }

    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    event PayloadCleared(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        address dstAddress
    );
    event PayloadStored(
        uint16 srcChainId,
        bytes srcAddress,
        address dstAddress,
        uint64 nonce,
        bytes payload,
        bytes reason
    );
    event ValueTransferFailed(address indexed to, uint256 indexed quantity);

    constructor(uint16 _chainId) {
        mockChainId = _chainId;

        // init config
        relayerFeeConfig = RelayerFeeConfig({
            dstPriceRatio: 1e10, // 1:1, same chain, same native coin
            dstGasPriceInWei: 1e10,
            dstNativeAmtCap: 1e19,
            baseGas: 100,
            gasPerByte: 1
        });
        protocolFeeConfig = ProtocolFeeConfig({zroFee: 1e18, nativeBP: 1000}); // BP 0.1
        oracleFee = 1e16;
        defaultAdapterParams = LzLib.buildDefaultAdapterParams(200000);
    }

    // ------------------------------ ILayerZeroEndpoint Functions ------------------------------
    function send(
        uint16 _chainId,
        bytes memory _path,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable override sendNonReentrant {
        require(
            _path.length == 40,
            "LayerZeroMock: incorrect remote address size"
        ); // only support evm chains

        address dstAddr;
        assembly {
            dstAddr := mload(add(_path, 20))
        }

        address lzEndpoint = lzEndpointLookup[dstAddr];
        require(
            lzEndpoint != address(0),
            "LayerZeroMock: destination LayerZero Endpoint not found"
        );

        // not handle zro token
        bytes memory adapterParams = _adapterParams.length > 0
            ? _adapterParams
            : defaultAdapterParams;
        (uint256 nativeFee, ) = estimateFees(
            _chainId,
            msg.sender,
            _payload,
            _zroPaymentAddress != address(0x0),
            adapterParams
        );
        require(
            msg.value >= nativeFee,
            "LayerZeroMock: not enough native for fees"
        );

        uint64 nonce = ++outboundNonce[_chainId][msg.sender];

        // refund if they send too much
        uint256 amount = msg.value - nativeFee;
        if (amount > 0) {
            (bool success, ) = _refundAddress.call{value: amount}("");
            require(success, "LayerZeroMock: failed to refund");
        }

        // Mock the process of receiving msg on dst chain
        // Mock the relayer paying the dstNativeAddr the amount of extra native token
        (
            ,
            uint256 extraGas,
            uint256 dstNativeAmt,
            address payable dstNativeAddr
        ) = LzLib.decodeAdapterParams(adapterParams);
        if (dstNativeAmt > 0) {
            (bool success, ) = dstNativeAddr.call{value: dstNativeAmt}("");
            if (!success) {
                emit ValueTransferFailed(dstNativeAddr, dstNativeAmt);
            }
        }

        bytes memory srcUaAddress = abi.encodePacked(msg.sender, dstAddr); // cast this address to bytes
        bytes memory payload = _payload;
        LZEndpointMock(lzEndpoint).receivePayload(
            mockChainId,
            srcUaAddress,
            dstAddr,
            nonce,
            extraGas,
            payload
        );
    }

    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _path,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external override receiveNonReentrant {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];

        // assert and increment the nonce. no message shuffling
        require(
            _nonce == ++inboundNonce[_srcChainId][_path],
            "LayerZeroMock: wrong nonce"
        );

        // queue the following msgs inside of a stack to simulate a successful send on src, but not fully delivered on dst
        if (sp.payloadHash != bytes32(0)) {
            QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];
            QueuedPayload memory newMsg = QueuedPayload(
                _dstAddress,
                _nonce,
                _payload
            );

            // warning, might run into gas issues trying to forward through a bunch of queued msgs
            // shift all the msgs over so we can treat this like a fifo via array.pop()
            if (msgs.length > 0) {
                // extend the array
                msgs.push(newMsg);

                // shift all the indexes up for pop()
                for (uint256 i = 0; i < msgs.length - 1; i++) {
                    msgs[i + 1] = msgs[i];
                }

                // put the newMsg at the bottom of the stack
                msgs[0] = newMsg;
            } else {
                msgs.push(newMsg);
            }
        } else if (nextMsgBlocked) {
            storedPayload[_srcChainId][_path] = StoredPayload(
                uint64(_payload.length),
                _dstAddress,
                keccak256(_payload)
            );
            emit PayloadStored(
                _srcChainId,
                _path,
                _dstAddress,
                _nonce,
                _payload,
                bytes("")
            );
            // ensure the next msgs that go through are no longer blocked
            nextMsgBlocked = false;
        } else {
            try
                ILayerZeroReceiver(_dstAddress).lzReceive{gas: _gasLimit}(
                    _srcChainId,
                    _path,
                    _nonce,
                    _payload
                )
            {} catch (bytes memory reason) {
                storedPayload[_srcChainId][_path] = StoredPayload(
                    uint64(_payload.length),
                    _dstAddress,
                    keccak256(_payload)
                );
                emit PayloadStored(
                    _srcChainId,
                    _path,
                    _dstAddress,
                    _nonce,
                    _payload,
                    reason
                );
                // ensure the next msgs that go through are no longer blocked
                nextMsgBlocked = false;
            }
        }
    }

    function getInboundNonce(
        uint16 _chainID,
        bytes calldata _path
    ) external view override returns (uint64) {
        return inboundNonce[_chainID][_path];
    }

    function getOutboundNonce(
        uint16 _chainID,
        address _srcAddress
    ) external view override returns (uint64) {
        return outboundNonce[_chainID][_srcAddress];
    }

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes memory _payload,
        bool _payInZRO,
        bytes memory _adapterParams
    ) public view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory adapterParams = _adapterParams.length > 0
            ? _adapterParams
            : defaultAdapterParams;

        // Relayer Fee
        uint256 relayerFee = _getRelayerFee(
            _dstChainId,
            1,
            _userApplication,
            _payload.length,
            adapterParams
        );

        // LayerZero Fee
        uint256 protocolFee = _getProtocolFees(
            _payInZRO,
            relayerFee,
            oracleFee
        );
        _payInZRO ? zroFee = protocolFee : nativeFee = protocolFee;

        // return the sum of fees
        nativeFee = nativeFee + relayerFee + oracleFee;
    }

    function getChainId() external view override returns (uint16) {
        return mockChainId;
    }

    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _path,
        bytes calldata _payload
    ) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        require(
            sp.payloadHash != bytes32(0),
            "LayerZeroMock: no stored payload"
        );
        require(
            _payload.length == sp.payloadLength &&
                keccak256(_payload) == sp.payloadHash,
            "LayerZeroMock: invalid payload"
        );

        address dstAddress = sp.dstAddress;
        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = inboundNonce[_srcChainId][_path];

        ILayerZeroReceiver(dstAddress).lzReceive(
            _srcChainId,
            _path,
            nonce,
            _payload
        );
        emit PayloadCleared(_srcChainId, _path, nonce, dstAddress);
    }

    function hasStoredPayload(
        uint16 _srcChainId,
        bytes calldata _path
    ) external view override returns (bool) {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        return sp.payloadHash != bytes32(0);
    }

    function getSendLibraryAddress(
        address
    ) external view override returns (address) {
        return address(this);
    }

    function getReceiveLibraryAddress(
        address
    ) external view override returns (address) {
        return address(this);
    }

    function isSendingPayload() external view override returns (bool) {
        return _send_entered_state == _ENTERED;
    }

    function isReceivingPayload() external view override returns (bool) {
        return _receive_entered_state == _ENTERED;
    }

    function getConfig(
        uint16 /*_version*/,
        uint16 /*_chainId*/,
        address /*_ua*/,
        uint256 /*_configType*/
    ) external pure override returns (bytes memory) {
        return "";
    }

    function getSendVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function getReceiveVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function setConfig(
        uint16 /*_version*/,
        uint16 /*_chainId*/,
        uint256 /*_configType*/,
        bytes memory /*_config*/
    ) external override {}

    function setSendVersion(uint16 /*version*/) external override {}

    function setReceiveVersion(uint16 /*version*/) external override {}

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _path
    ) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        // revert if no messages are cached. safeguard malicious UA behaviour
        require(
            sp.payloadHash != bytes32(0),
            "LayerZeroMock: no stored payload"
        );
        require(sp.dstAddress == msg.sender, "LayerZeroMock: invalid caller");

        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        emit UaForceResumeReceive(_srcChainId, _path);

        // resume the receiving of msgs after we force clear the "stuck" msg
        _clearMsgQue(_srcChainId, _path);
    }

    // ------------------------------ Other Public/External Functions --------------------------------------------------

    function getLengthOfQueue(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (uint256) {
        return msgsToDeliver[_srcChainId][_srcAddress].length;
    }

    // used to simulate messages received get stored as a payload
    function blockNextMsg() external {
        nextMsgBlocked = true;
    }

    function setDestLzEndpoint(
        address destAddr,
        address lzEndpointAddr
    ) external {
        lzEndpointLookup[destAddr] = lzEndpointAddr;
    }

    function setRelayerPrice(
        uint128 _dstPriceRatio,
        uint128 _dstGasPriceInWei,
        uint128 _dstNativeAmtCap,
        uint64 _baseGas,
        uint64 _gasPerByte
    ) external {
        relayerFeeConfig.dstPriceRatio = _dstPriceRatio;
        relayerFeeConfig.dstGasPriceInWei = _dstGasPriceInWei;
        relayerFeeConfig.dstNativeAmtCap = _dstNativeAmtCap;
        relayerFeeConfig.baseGas = _baseGas;
        relayerFeeConfig.gasPerByte = _gasPerByte;
    }

    function setProtocolFee(uint256 _zroFee, uint256 _nativeBP) external {
        protocolFeeConfig.zroFee = _zroFee;
        protocolFeeConfig.nativeBP = _nativeBP;
    }

    function setOracleFee(uint256 _oracleFee) external {
        oracleFee = _oracleFee;
    }

    function setDefaultAdapterParams(bytes memory _adapterParams) external {
        defaultAdapterParams = _adapterParams;
    }

    // --------------------- Internal Functions ---------------------
    // simulates the relayer pushing through the rest of the msgs that got delayed due to the stored payload
    function _clearMsgQue(uint16 _srcChainId, bytes calldata _path) internal {
        QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];

        // warning, might run into gas issues trying to forward through a bunch of queued msgs
        while (msgs.length > 0) {
            QueuedPayload memory payload = msgs[msgs.length - 1];
            ILayerZeroReceiver(payload.dstAddress).lzReceive(
                _srcChainId,
                _path,
                payload.nonce,
                payload.payload
            );
            msgs.pop();
        }
    }

    function _getProtocolFees(
        bool _payInZro,
        uint256 _relayerFee,
        uint256 _oracleFee
    ) internal view returns (uint256) {
        if (_payInZro) {
            return protocolFeeConfig.zroFee;
        } else {
            return
                ((_relayerFee + _oracleFee) * protocolFeeConfig.nativeBP) /
                10000;
        }
    }

    function _getRelayerFee(
        uint16 /* _dstChainId */,
        uint16 /* _outboundProofType */,
        address /* _userApplication */,
        uint256 _payloadSize,
        bytes memory _adapterParams
    ) internal view returns (uint256) {
        (uint16 txType, uint256 extraGas, uint256 dstNativeAmt, ) = LzLib
            .decodeAdapterParams(_adapterParams);
        uint256 totalRemoteToken; // = baseGas + extraGas + requiredNativeAmount
        if (txType == 2) {
            require(
                relayerFeeConfig.dstNativeAmtCap >= dstNativeAmt,
                "LayerZeroMock: dstNativeAmt too large "
            );
            totalRemoteToken += dstNativeAmt;
        }
        // remoteGasTotal = dstGasPriceInWei * (baseGas + extraGas)
        uint256 remoteGasTotal = relayerFeeConfig.dstGasPriceInWei *
            (relayerFeeConfig.baseGas + extraGas);
        totalRemoteToken += remoteGasTotal;

        // tokenConversionRate = dstPrice / localPrice
        // basePrice = totalRemoteToken * tokenConversionRate
        uint256 basePrice = (totalRemoteToken *
            relayerFeeConfig.dstPriceRatio) / 10 ** 10;

        // pricePerByte = (dstGasPriceInWei * gasPerBytes) * tokenConversionRate
        uint256 pricePerByte = (relayerFeeConfig.dstGasPriceInWei *
            relayerFeeConfig.gasPerByte *
            relayerFeeConfig.dstPriceRatio) / 10 ** 10;

        return basePrice + _payloadSize * pricePerByte;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "tapioca-sdk/dist/contracts/interfaces/ILayerZeroEndpoint.sol";
import "./BaseOFT.sol";
import "./interfaces/IERC3156FlashLender.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title USDO OFT contract
contract USDO is BaseOFT, IERC3156FlashLender {
    // ************ //
    // *** VARS *** //
    // ************ //
    /// @notice returns the Conservator address
    address public conservator;
    /// @notice addresses allowed to mint USDO
    /// @dev chainId>address>status
    mapping(uint256 => mapping(address => bool)) public allowedMinter;
    /// @notice addresses allowed to burn USDO
    /// @dev chainId>address>status
    mapping(uint256 => mapping(address => bool)) public allowedBurner;
    /// @notice returns the pause state of the contract
    bool public paused;

    /// @notice returns the flash mint fee
    uint256 public flashMintFee;
    /// @notice returns the maximum amount of USDO that can be minted through the EIP-3156 flow
    uint256 public maxFlashMint;

    uint256 constant FLASH_MINT_FEE_PRECISION = 1e6;
    bytes32 constant FLASH_MINT_CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event Minted(address indexed _for, uint256 _amount);
    event Burned(address indexed _from, uint256 _amount);
    event SetMinterStatus(address indexed _for, bool _status);
    event SetBurnerStatus(address indexed _for, bool _status);
    event ConservatorUpdated(address indexed old, address indexed _new);
    event PausedUpdated(bool oldState, bool newState);
    event FlashMintFeeUpdated(uint256 _old, uint256 _new);
    event MaxFlashMintUpdated(uint256 _old, uint256 _new);

    modifier notPaused() {
        require(!paused, "USDO: paused");
        _;
    }

    /// @notice creates a new USDO0 OFT contract
    /// @param _lzEndpoint LayerZero endpoint
    constructor(
        address _lzEndpoint,
        IYieldBox _yieldBox,
        address _owner
    ) OFTV2("USDO", "USDO", 8, _lzEndpoint) BaseOFT(_yieldBox) {
        uint256 chain = _getChainId();
        allowedMinter[chain][msg.sender] = true;
        allowedBurner[chain][msg.sender] = true;
        flashMintFee = 10; // 0.001%
        maxFlashMint = 100_000 * 1e18; // 100k USDO

        mintLimit = 1_000_000_000 * 1e18;

        transferOwnership(_owner);
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns token's decimals
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /// @notice returns the maximum amount of tokens available for a flash mint
    function maxFlashLoan(address) public view override returns (uint256) {
        return maxFlashMint;
    }

    /// @notice returns the flash mint fee
    function flashFee(
        address token,
        uint256 amount
    ) public view override returns (uint256) {
        require(token == address(this), "USDO: token not valid");
        return (amount * flashMintFee) / FLASH_MINT_FEE_PRECISION;
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override notPaused returns (bool) {
        require(token == address(this), "USDO: token not valid");
        require(maxFlashLoan(token) >= amount, "USDO: amount too big");
        require(amount > 0, "USDO: amount not valid");
        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);

        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) ==
                FLASH_MINT_CALLBACK_SUCCESS,
            "USDO: failed"
        );

        uint256 _allowance = allowance(address(receiver), address(this));
        require(_allowance >= (amount + fee), "USDO: repay not approved");
        _approve(address(receiver), address(this), _allowance - (amount + fee));
        _burn(address(receiver), amount + fee);
        return true;
    }

    /// @notice mints USDO
    /// @param _to receiver address
    /// @param _amount the amount to mint
    function mint(address _to, uint256 _amount) external notPaused {
        require(allowedMinter[_getChainId()][msg.sender], "USDO: unauthorized");
        _mint(_to, _amount);
        emit Minted(_to, _amount);
    }

    /// @notice burns USDO
    /// @param _from address to burn from
    /// @param _amount the amount to burn
    function burn(address _from, uint256 _amount) external notPaused {
        require(allowedBurner[_getChainId()][msg.sender], "USDO: unauthorized");
        _burn(_from, _amount);
        emit Burned(_from, _amount);
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //

    /// @notice set the max allowed USDO mintable through flashloan
    /// @param _val the new amount
    function setMaxFlashMintable(uint256 _val) external onlyOwner {
        emit MaxFlashMintUpdated(maxFlashMint, _val);
        maxFlashMint = _val;
    }

    /// @notice set the flashloan fee
    /// @param _val the new fee
    function setFlashMintFee(uint256 _val) external onlyOwner {
        require(_val < FLASH_MINT_FEE_PRECISION, "USDO: fee too big");
        emit FlashMintFeeUpdated(flashMintFee, _val);
        flashMintFee = _val;
    }

    /// @notice Set the Conservator address
    /// @dev Conservator can pause the contract
    /// @param _conservator The new address
    function setConservator(address _conservator) external onlyOwner {
        require(_conservator != address(0), "USDO: address not valid");
        emit ConservatorUpdated(conservator, _conservator);
        conservator = _conservator;
    }

    /// @notice updates the pause state of the contract
    /// @param val the new value
    function updatePause(bool val) external {
        require(msg.sender == conservator, "USDO: unauthorized");
        require(val != paused, "USDO: same state");
        emit PausedUpdated(paused, val);
        paused = val;
    }

    /// @notice sets/unsets address as minter
    /// @param _for role receiver
    /// @param _status true/false
    function setMinterStatus(address _for, bool _status) external onlyOwner {
        allowedMinter[_getChainId()][_for] = _status;
        emit SetMinterStatus(_for, _status);
    }

    /// @notice sets/unsets address as burner
    /// @param _for role receiver
    /// @param _status true/false
    function setBurnerStatus(address _for, bool _status) external onlyOwner {
        allowedBurner[_getChainId()][_for] = _status;
        emit SetBurnerStatus(_for, _status);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    /// @notice Return the current Layer-Zero "chain ID", not the actual `chainId` OPCODE output.
    /// @dev Useful for testing.
    function _getChainId() private view returns (uint256) {
        return ILayerZeroEndpoint(lzEndpoint).getChainId();
    }

    // ************************* //
    // ************************* //
    // ************************* //
    // ************************* //
    //TODO: to be removed
    // ************************* //
    // *** TESTNET FUNCTIONS *** //
    // ************************* //
    mapping(address => uint256) public mintedAt;
    uint256 public constant MINT_WINDOW = 24 hours;
    uint256 public mintLimit;

    function setMintLimit(uint256 _val) external onlyOwner {
        mintLimit = _val;
    }

    function freeMint(uint256 _val) external {
        require(_val <= mintLimit, "USDO: amount too big");
        require(
            mintedAt[msg.sender] + MINT_WINDOW <= block.timestamp,
            "USDO: too early"
        );

        mintedAt[msg.sender] = block.timestamp;

        _mint(msg.sender, _val);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.8.0;

//Based on BaseBoringBatchable
contract MulticallWithReason {
    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    error BatchError(bytes innerError);

    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert BatchError(_returnData);

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    /// @notice Aggregate calls, ensuring each returns success
    /// @param calls An array of Call3 structs
    /// @return returnData An array of Result structs
    function multicall(
        Call3[] calldata calls
    ) public payable returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);

        Call3 calldata calli;

        for (uint256 i = 0; i < length; ) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(
                calli.callData
            );

            if (!result.success) {
                _getRevertMsg(result.returnData);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Aggregate calls, ensuring each returns success
    /// @param calls An array of Call3 structs
    /// @return returnData An array of Result structs
    function multicallValue(
        Call3Value[] calldata calls
    ) public payable returns (Result[] memory returnData) {
        uint256 valAccumulator;
        uint256 length = calls.length;
        returnData = new Result[](length);

        Call3Value calldata calli;

        for (uint256 i = 0; i < length; ) {
            Result memory result = returnData[i];
            calli = calls[i];
            uint256 val = calli.value;
            unchecked {
                valAccumulator += val;
            }
            (result.success, result.returnData) = calli.target.call{value: val}(
                calli.callData
            );

            if (!result.success) {
                _getRevertMsg(result.returnData);
            }

            unchecked {
                ++i;
            }
        }

        // Finally, make sure the msg.value = SUM(call[0...i].value)
        require(
            msg.value == valAccumulator,
            "MulticallWithReason: value mismatch"
        );
    }

    /// @notice Returns the block hash for the given block number
    /// @param blockNumber The block number
    function getBlockHash(
        uint256 blockNumber
    ) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /// @notice Returns the block number
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /// @notice Returns the block coinbase
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /// @notice Returns the block difficulty
    function getCurrentBlockDifficulty()
        public
        view
        returns (uint256 difficulty)
    {
        difficulty = block.prevrandao;
    }

    /// @notice Returns the block gas limit
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /// @notice Returns the block timestamp
    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    /// @notice Returns the (ETH) balance of a given address
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @notice Returns the block hash of the last block
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        unchecked {
            blockHash = blockhash(block.number - 1);
        }
    }

    /// @notice Gets the base fee of the given block
    /// @notice Can revert if the BASEFEE opcode is not implemented by the given chain
    function getBasefee() public view returns (uint256 basefee) {
        basefee = block.basefee;
    }

    /// @notice Returns the chain id
    function getChainId() public view returns (uint256 chainid) {
        chainid = block.chainid;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

library LzLib {
    // LayerZero communication
    struct CallParams {
        address payable refundAddress;
        address zroPaymentAddress;
    }

    //---------------------------------------------------------------------------
    // Address type handling

    struct AirdropParams {
        uint airdropAmount;
        bytes32 airdropAddress;
    }

    function buildAdapterParams(LzLib.AirdropParams memory _airdropParams, uint _uaGasLimit) internal pure returns (bytes memory adapterParams) {
        if (_airdropParams.airdropAmount == 0 && _airdropParams.airdropAddress == bytes32(0x0)) {
            adapterParams = buildDefaultAdapterParams(_uaGasLimit);
        } else {
            adapterParams = buildAirdropAdapterParams(_uaGasLimit, _airdropParams);
        }
    }

    // Build Adapter Params
    function buildDefaultAdapterParams(uint _uaGas) internal pure returns (bytes memory) {
        // txType 1
        // bytes  [2       32      ]
        // fields [txType  extraGas]
        return abi.encodePacked(uint16(1), _uaGas);
    }

    function buildAirdropAdapterParams(uint _uaGas, AirdropParams memory _params) internal pure returns (bytes memory) {
        require(_params.airdropAmount > 0, "Airdrop amount must be greater than 0");
        require(_params.airdropAddress != bytes32(0x0), "Airdrop address must be set");

        // txType 2
        // bytes  [2       32        32            bytes[]         ]
        // fields [txType  extraGas  dstNativeAmt  dstNativeAddress]
        return abi.encodePacked(uint16(2), _uaGas, _params.airdropAmount, _params.airdropAddress);
    }

    function getGasLimit(bytes memory _adapterParams) internal pure returns (uint gasLimit) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    // Decode Adapter Params
    function decodeAdapterParams(bytes memory _adapterParams) internal pure returns (uint16 txType, uint uaGas, uint airdropAmount, address payable airdropAddress) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            txType := mload(add(_adapterParams, 2))
            uaGas := mload(add(_adapterParams, 34))
        }
        require(txType == 1 || txType == 2, "Unsupported txType");
        require(uaGas > 0, "Gas too low");

        if (txType == 2) {
            assembly {
                airdropAmount := mload(add(_adapterParams, 66))
                airdropAddress := mload(add(_adapterParams, 86))
            }
        }
    }

    //---------------------------------------------------------------------------
    // Address type handling
    function bytes32ToAddress(bytes32 _bytes32Address) internal pure returns (address _address) {
        return address(uint160(uint(_bytes32Address)));
    }

    function addressToBytes32(address _address) internal pure returns (bytes32 _bytes32Address) {
        return bytes32(uint(uint160(_address)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint _extraGas) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) { // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload, bytes memory _reason) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OFTCoreV2.sol";
import "./IOFTV2.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BaseOFTV2 is OFTCoreV2, ERC165, IOFTV2 {

    constructor(uint8 _sharedDecimals, address _lzEndpoint) OFTCoreV2(_sharedDecimals, _lzEndpoint) {
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, LzCallParams calldata _callParams) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _amount, _callParams.refundAddress, _callParams.zroPaymentAddress, _callParams.adapterParams);
    }

    function sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, LzCallParams calldata _callParams) public payable virtual override {
        _sendAndCall(_from, _dstChainId, _toAddress, _amount, _payload, _dstGasForCall, _callParams.refundAddress, _callParams.zroPaymentAddress, _callParams.adapterParams);
    }

    /************************************************************************
    * public view functions
    ************************************************************************/
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOFTV2).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        return _estimateSendFee(_dstChainId, _toAddress, _amount, _useZro, _adapterParams);
    }

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        return _estimateSendAndCallFee(_dstChainId, _toAddress, _amount, _payload, _dstGasForCall, _useZro, _adapterParams);
    }

    function circulatingSupply() public view virtual override returns (uint);

    function token() public view virtual override returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface ICommonOFT is IERC165 {

    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface IOFTReceiverV2 {
    /**
     * @dev Called by the OFT contract when tokens are received from source chain.
     * @param _srcChainId The chain id of the source chain.
     * @param _srcAddress The address of the OFT token contract on the source chain.
     * @param _nonce The nonce of the transaction on the source chain.
     * @param _from The address of the account who calls the sendAndCall() on the source chain.
     * @param _amount The amount of tokens to transfer.
     * @param _payload Additional data with no specified format.
     */
    function onOFTReceived(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes32 _from, uint _amount, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ICommonOFT.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTV2 is ICommonOFT {

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, LzCallParams calldata _callParams) external payable;

    function sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, LzCallParams calldata _callParams) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../lzApp/NonblockingLzApp.sol";
import "../../../util/ExcessivelySafeCall.sol";
import "./ICommonOFT.sol";
import "./IOFTReceiverV2.sol";

abstract contract OFTCoreV2 is NonblockingLzApp {
    using BytesLib for bytes;
    using ExcessivelySafeCall for address;

    uint public constant NO_EXTRA_GAS = 0;

    // packet type
    uint8 public constant PT_SEND = 0;
    uint8 public constant PT_SEND_AND_CALL = 1;

    uint8 public immutable sharedDecimals;

    bool public useCustomAdapterParams;
    mapping(uint16 => mapping(bytes => mapping(uint64 => bool))) public creditedPackets;

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes32 indexed _toAddress, uint _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    event CallOFTReceivedSuccess(uint16 indexed _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _hash);

    event NonContractAddress(address _address);

    // _sharedDecimals should be the minimum decimals on all chains
    constructor(uint8 _sharedDecimals, address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {
        sharedDecimals = _sharedDecimals;
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function callOnOFTReceived(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes32 _from, address _to, uint _amount, bytes calldata _payload, uint _gasForCall) public virtual {
        require(_msgSender() == address(this), "OFTCore: caller must be OFTCore");

        // send
        _amount = _transferFrom(address(this), _to, _amount);
        emit ReceiveFromChain(_srcChainId, _to, _amount);

        // call
        IOFTReceiverV2(_to).onOFTReceived{gas: _gasForCall}(_srcChainId, _srcAddress, _nonce, _from, _amount, _payload);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) public virtual onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    /************************************************************************
    * internal functions
    ************************************************************************/
    function _estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes memory _adapterParams) internal view virtual returns (uint nativeFee, uint zroFee) {
        // mock the payload for sendFrom()
        bytes memory payload = _encodeSendPayload(_toAddress, _ld2sd(_amount));
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function _estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes memory _payload, uint64 _dstGasForCall, bool _useZro, bytes memory _adapterParams) internal view virtual returns (uint nativeFee, uint zroFee) {
        // mock the payload for sendAndCall()
        bytes memory payload = _encodeSendAndCallPayload(msg.sender, _toAddress, _ld2sd(_amount), _payload, _dstGasForCall);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        uint8 packetType = _payload.toUint8(0);

        if (packetType == PT_SEND) {
            _sendAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else if (packetType == PT_SEND_AND_CALL) {
            _sendAndCallAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else {
            revert("OFTCore: unknown packet type");
        }
    }

    function _send(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual returns (uint amount) {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        (amount,) = _removeDust(_amount);
        amount = _debitFrom(_from, _dstChainId, _toAddress, amount); // amount returned should not have dust
        require(amount > 0, "OFTCore: amount too small");

        bytes memory lzPayload = _encodeSendPayload(_toAddress, _ld2sd(amount));
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAck(uint16 _srcChainId, bytes memory, uint64, bytes memory _payload) internal virtual {
        (address to, uint64 amountSD) = _decodeSendPayload(_payload);
        if (to == address(0)) {
            to = address(0xdead);
        }

        uint amount = _sd2ld(amountSD);
        amount = _creditTo(_srcChainId, to, amount);

        emit ReceiveFromChain(_srcChainId, to, amount);
    }

    function _sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes memory _payload, uint64 _dstGasForCall, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual returns (uint amount) {
        _checkAdapterParams(_dstChainId, PT_SEND_AND_CALL, _adapterParams, _dstGasForCall);

        (amount,) = _removeDust(_amount);
        amount = _debitFrom(_from, _dstChainId, _toAddress, amount);
        require(amount > 0, "OFTCore: amount too small");

        // encode the msg.sender into the payload instead of _from
        bytes memory lzPayload = _encodeSendAndCallPayload(msg.sender, _toAddress, _ld2sd(amount), _payload, _dstGasForCall);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAndCallAck(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual {
        (bytes32 from, address to, uint64 amountSD, bytes memory payloadForCall, uint64 gasForCall) = _decodeSendAndCallPayload(_payload);

        bool credited = creditedPackets[_srcChainId][_srcAddress][_nonce];
        uint amount = _sd2ld(amountSD);

        // credit to this contract first, and then transfer to receiver only if callOnOFTReceived() succeeds
        if (!credited) {
            amount = _creditTo(_srcChainId, address(this), amount);
            creditedPackets[_srcChainId][_srcAddress][_nonce] = true;
        }

        if (!_isContract(to)) {
            emit NonContractAddress(to);
            return;
        }

        // workaround for stack too deep
        uint16 srcChainId = _srcChainId;
        bytes memory srcAddress = _srcAddress;
        uint64 nonce = _nonce;
        bytes memory payload = _payload;
        bytes32 from_ = from;
        address to_ = to;
        uint amount_ = amount;
        bytes memory payloadForCall_ = payloadForCall;

        // no gas limit for the call if retry
        uint gas = credited ? gasleft() : gasForCall;
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.callOnOFTReceived.selector, srcChainId, srcAddress, nonce, from_, to_, amount_, payloadForCall_, gas));

        if (success) {
            bytes32 hash = keccak256(payload);
            emit CallOFTReceivedSuccess(srcChainId, srcAddress, nonce, hash);
        } else {
            // store the failed message into the nonblockingLzApp
            _storeFailedMessage(srcChainId, srcAddress, nonce, payload, reason);
        }
    }

    function _isContract(address _account) internal view returns (bool) {
        return _account.code.length > 0;
    }

    function _checkAdapterParams(uint16 _dstChainId, uint16 _pkType, bytes memory _adapterParams, uint _extraGas) internal virtual {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            require(_adapterParams.length == 0, "OFTCore: _adapterParams must be empty.");
        }
    }

    function _ld2sd(uint _amount) internal virtual view returns (uint64) {
        uint amountSD = _amount / _ld2sdRate();
        require(amountSD <= type(uint64).max, "OFTCore: amountSD overflow");
        return uint64(amountSD);
    }

    function _sd2ld(uint64 _amountSD) internal virtual view returns (uint) {
        return _amountSD * _ld2sdRate();
    }

    function _removeDust(uint _amount) internal virtual view returns (uint amountAfter, uint dust) {
        dust = _amount % _ld2sdRate();
        amountAfter = _amount - dust;
    }

    function _encodeSendPayload(bytes32 _toAddress, uint64 _amountSD) internal virtual view returns (bytes memory) {
        return abi.encodePacked(PT_SEND, _toAddress, _amountSD);
    }

    function _decodeSendPayload(bytes memory _payload) internal virtual view returns (address to, uint64 amountSD) {
        require(_payload.toUint8(0) == PT_SEND && _payload.length == 41, "OFTCore: invalid payload");

        to = _payload.toAddress(13); // drop the first 12 bytes of bytes32
        amountSD = _payload.toUint64(33);
    }

    function _encodeSendAndCallPayload(address _from, bytes32 _toAddress, uint64 _amountSD, bytes memory _payload, uint64 _dstGasForCall) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            PT_SEND_AND_CALL,
            _toAddress,
            _amountSD,
            _addressToBytes32(_from),
            _dstGasForCall,
            _payload
        );
    }

    function _decodeSendAndCallPayload(bytes memory _payload) internal virtual view returns (bytes32 from, address to, uint64 amountSD, bytes memory payload, uint64 dstGasForCall) {
        require(_payload.toUint8(0) == PT_SEND_AND_CALL, "OFTCore: invalid payload");

        to = _payload.toAddress(13); // drop the first 12 bytes of bytes32
        amountSD = _payload.toUint64(33);
        from = _payload.toBytes32(41);
        dstGasForCall = _payload.toUint64(73);
        payload = _payload.slice(81, _payload.length - 81);
    }

    function _addressToBytes32(address _address) internal pure virtual returns (bytes32) {
        return bytes32(uint(uint160(_address)));
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount) internal virtual returns (uint);

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _amount) internal virtual returns (uint);

    function _transferFrom(address _from, address _to, uint _amount) internal virtual returns (uint);

    function _ld2sdRate() internal view virtual returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BaseOFTV2.sol";

contract OFTV2 is BaseOFTV2, ERC20 {

    uint internal immutable ld2sdRate;

    constructor(string memory _name, string memory _symbol, uint8 _sharedDecimals, address _lzEndpoint) ERC20(_name, _symbol) BaseOFTV2(_sharedDecimals, _lzEndpoint) {
        uint8 decimals = decimals();
        require(_sharedDecimals <= decimals, "OFT: sharedDecimals must be <= decimals");
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    /************************************************************************
    * internal functions
    ************************************************************************/
    function _debitFrom(address _from, uint16, bytes32, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns (uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes.slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    internal
    view
    returns (bool)
    {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "./ERC1155.sol";

// An asset is a token + a strategy
struct Asset {
    TokenType tokenType;
    address contractAddress;
    IStrategy strategy;
    uint256 tokenId;
}

contract AssetRegister is ERC1155 {
    using BoringAddress for address;

    mapping(address => mapping(address => mapping(uint256 => bool))) public isApprovedForAsset;

    event AssetRegistered(
        TokenType indexed tokenType,
        address indexed contractAddress,
        IStrategy strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );
    event ApprovalForAsset(address indexed sender, address indexed operator, uint256 assetId, bool approved);

    // ids start at 1 so that id 0 means it's not yet registered
    mapping(TokenType => mapping(address => mapping(IStrategy => mapping(uint256 => uint256)))) public ids;
    Asset[] public assets;

    constructor() {
        assets.push(Asset(TokenType.None, address(0), NO_STRATEGY, 0));
    }

    function assetCount() public view returns (uint256) {
        return assets.length;
    }

    function _registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) internal returns (uint256 assetId) {
        // Checks
        assetId = ids[tokenType][contractAddress][strategy][tokenId];

        // If assetId is 0, this is a new asset that needs to be registered
        if (assetId == 0) {
            // Only do these checks if a new asset needs to be created
            require(tokenId == 0 || tokenType != TokenType.ERC20, "YieldBox: No tokenId for ERC20");
            require(
                tokenType == TokenType.Native ||
                    (tokenType == strategy.tokenType() && contractAddress == strategy.contractAddress() && tokenId == strategy.tokenId()),
                "YieldBox: Strategy mismatch"
            );
            // If a new token gets added, the isContract checks that this is a deployed contract. Needed for security.
            // Prevents getting shares for a future token whose address is known in advance. For instance a token that will be deployed with CREATE2 in the future or while the contract creation is
            // in the mempool
            require((tokenType == TokenType.Native && contractAddress == address(0)) || contractAddress.isContract(), "YieldBox: Not a token");

            // Effects
            assetId = assets.length;
            assets.push(Asset(tokenType, contractAddress, strategy, tokenId));
            ids[tokenType][contractAddress][strategy][tokenId] = assetId;

            // The actual URI isn't emitted here as per EIP1155, because that would make this call super expensive.
            emit URI("", assetId);
            emit AssetRegistered(tokenType, contractAddress, strategy, tokenId, assetId);
        }
    }

    function registerAsset(TokenType tokenType, address contractAddress, IStrategy strategy, uint256 tokenId) public returns (uint256 assetId) {
        // Native assets can only be added internally by the NativeTokenFactory
        require(
            tokenType == TokenType.ERC20 || tokenType == TokenType.ERC721 || tokenType == TokenType.ERC1155,
            "AssetManager: cannot add Native"
        );
        assetId = _registerAsset(tokenType, contractAddress, strategy, tokenId);
    }

    function setApprovalForAsset(address operator, uint256 assetId, bool approved) external virtual {
        require(assetId < assetCount(), "AssetManager: asset not valid");
        isApprovedForAsset[msg.sender][operator][assetId] = approved;

        emit ApprovalForAsset(msg.sender, operator, assetId, approved);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library BoringMath {
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function muldiv(
        uint256 value,
        uint256 mul,
        uint256 div,
        bool roundUp
    ) internal pure returns (uint256 result) {
        result = (value * mul) / div;
        if (roundUp && (result * div) / mul < value) {
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";

// Written by OreNoMochi (https://github.com/OreNoMochii), BoringCrypto

contract ERC1155 is IERC1155 {
    using BoringAddress for address;

    // mappings

    mapping(address => mapping(address => bool)) public override isApprovedForAll; // map of operator approval
    mapping(address => mapping(uint256 => uint256)) public override balanceOf; // map of tokens owned by
    mapping(uint256 => uint256) public totalSupply; // totalSupply per token

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0xd9b67a26 || // ERC-1155
            interfaceID == 0x0e89341c; // EIP-1155 Metadata
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view override returns (uint256[] memory balances) {
        uint256 len = owners.length;
        require(len == ids.length, "ERC1155: Length mismatch");

        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    function _mint(address to, uint256 id, uint256 value) internal {
        require(to != address(0), "No 0 address");

        balanceOf[to][id] += value;
        totalSupply[id] += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function _burn(address from, uint256 id, uint256 value) internal {
        require(from != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        totalSupply[id] -= value;

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _transferSingle(address from, address to, uint256 id, uint256 value) internal {
        require(to != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function _transferBatch(address from, address to, uint256[] calldata ids, uint256[] calldata values) internal {
        require(to != address(0), "No 0 address");

        uint256 len = ids.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];
            balanceOf[from][id] -= value;
            balanceOf[to][id] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function _requireTransferAllowed(address _from, bool _approved) internal view virtual {
        require(_from == msg.sender || _approved || isApprovedForAll[_from][msg.sender] == true, "Transfer not allowed");
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external override {
        _requireTransferAllowed(from, false);

        _transferSingle(from, to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) ==
                    bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")),
                "Wrong return value"
            );
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "ERC1155: Length mismatch");
        _requireTransferAllowed(from, false);

        _transferBatch(from, to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) ==
                    bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")),
                "Wrong return value"
            );
        }
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function uri(uint256 /*assetId*/) external view virtual returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";

contract ERC1155TokenReceiver is IERC1155TokenReceiver {
    // ERC1155 receivers that simple accept the transfer
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81; //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC721TokenReceiver.sol";

contract ERC721TokenReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return 0x150b7a02; //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";
import "./IYieldBox.sol";

interface IStrategy {
    /// Each strategy only works with a single asset. This should help make implementations simpler and more readable.
    /// To safe gas a proxy pattern (YieldBox factory) could be used to deploy the same strategy for multiple tokens.

    /// It is recommended that strategies keep a small amount of funds uninvested (like 5%) to handle small withdrawals
    /// and deposits without triggering costly investing/divesting logic.

    /// #########################
    /// ### Basic Information ###
    /// #########################

    /// Returns the address of the yieldBox that this strategy is for
    function yieldBox() external view returns (IYieldBox yieldBox_);

    /// Returns a name for this strategy
    function name() external view returns (string memory name_);

    /// Returns a description for this strategy
    function description() external view returns (string memory description_);

    /// #######################
    /// ### Supported Token ###
    /// #######################

    /// Returns the standard that this strategy works with
    function tokenType() external view returns (TokenType tokenType_);

    /// Returns the contract address that this strategy works with
    function contractAddress() external view returns (address contractAddress_);

    /// Returns the tokenId that this strategy works with (for EIP1155)
    /// This is always 0 for EIP20 tokens
    function tokenId() external view returns (uint256 tokenId_);

    /// ###########################
    /// ### Balance Information ###
    /// ###########################

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but MUST NOT return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view returns (uint256 amount);

    /// ##########################
    /// ### YieldBox Functions ###
    /// ##########################

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// If the strategy handles native tokens (ETH) it will receive it directly (not wrapped). It will be
    /// up to the strategy to wrap it if needed.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external;

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// If the strategy handles native tokens (ETH) it should send this, not a wrapped version.
    /// With some strategies it might be hard to withdraw exactly the correct amount.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external;
}

IStrategy constant NO_STRATEGY = IStrategy(address(0));

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IWrappedNative is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";

interface IYieldBox {
    function wrappedNative() external view returns (address wrappedNative);

    function assets(uint256 assetId)
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function nativeTokens(uint256 assetId)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint8 decimals
        );

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(uint256 assetId) external view returns (uint256 totalSupply);

    function setApprovalForAsset(
        address operator,
        uint256 assetId,
        bool approved
    ) external;

    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) external;

    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) external;

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./AssetRegister.sol";
import "./BoringMath.sol";

struct NativeToken {
    string name;
    string symbol;
    uint8 decimals;
    string uri;
}

/// @title NativeTokenFactory
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The NativeTokenFactory is a token factory to create ERC1155 tokens. This is used by YieldBox to create
/// native tokens in YieldBox. These have many benefits:
/// - low and predictable gas usage
/// - simplified approval
/// - no hidden features, all these tokens behave the same

contract NativeTokenFactory is AssetRegister {
    using BoringMath for uint256;

    mapping(uint256 => NativeToken) public nativeTokens;
    mapping(uint256 => address) public owner;
    mapping(uint256 => address) public pendingOwner;

    event TokenCreated(address indexed creator, string name, string symbol, uint8 decimals, uint256 tokenId);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    modifier allowed(address _from, uint256 _id) {
        _requireTransferAllowed(_from, isApprovedForAsset[_from][msg.sender][_id]);
        _;
    }

    /// @notice Only allows the `owner` to execute the function.
    /// @param tokenId The `tokenId` that the sender has to be owner of.
    modifier onlyOwner(uint256 tokenId) {
        require(msg.sender == owner[tokenId], "NTF: caller is not the owner");
        _;
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param tokenId The `tokenId` of the token that ownership whose ownership will be transferred/renounced.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(uint256 tokenId, address newOwner, bool direct, bool renounce) public onlyOwner(tokenId) {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "NTF: zero address");

            // Effects
            emit OwnershipTransferred(tokenId, owner[tokenId], newOwner);
            owner[tokenId] = newOwner;
            pendingOwner[tokenId] = address(0);
        } else {
            // Effects
            pendingOwner[tokenId] = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    /// @param tokenId The `tokenId` of the token that ownership is claimed for.
    function claimOwnership(uint256 tokenId) public {
        address _pendingOwner = pendingOwner[tokenId];

        // Checks
        require(msg.sender == _pendingOwner, "NTF: caller != pending owner");

        // Effects
        emit OwnershipTransferred(tokenId, owner[tokenId], _pendingOwner);
        owner[tokenId] = _pendingOwner;
        pendingOwner[tokenId] = address(0);
    }

    /// @notice Create a new native token. This will be an ERC1155 token. If later it's needed as an ERC20 token it can
    /// be wrapped into an ERC20 token. Native support for ERC1155 tokens is growing though.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param decimals The number of decimals of the token (this is just for display purposes). Should be set to 18 in normal cases.
    function createToken(string calldata name, string calldata symbol, uint8 decimals, string calldata uri) public returns (uint32 tokenId) {
        // To keep each Token unique in the AssetRegister, we use the assetId as the tokenId. So for native assets, the tokenId is always equal to the assetId.
        tokenId = assets.length.to32();
        _registerAsset(TokenType.Native, address(0), NO_STRATEGY, tokenId);
        // Initial supply is 0, use owner can mint. For a fixed supply the owner can mint and revoke ownership.
        // The msg.sender is the initial owner, can be changed after.
        nativeTokens[tokenId] = NativeToken(name, symbol, decimals, uri);
        owner[tokenId] = msg.sender;

        emit TokenCreated(msg.sender, name, symbol, decimals, tokenId);
        emit TransferSingle(msg.sender, address(0), address(0), tokenId, 0);
        emit OwnershipTransferred(tokenId, address(0), msg.sender);
    }

    /// @notice The `owner` can mint tokens. If a fixed supply is needed, the `owner` should mint the totalSupply and renounce ownership.
    /// @param tokenId The token to be minted.
    /// @param to The account to transfer the minted tokens to.
    /// @param amount The amount of tokens to mint.
    /// @dev For security reasons, operators are not allowed to mint. Only the actual owner can do this. Of course the owner can be a contract.
    function mint(uint256 tokenId, address to, uint256 amount) public onlyOwner(tokenId) {
        _mint(to, tokenId, amount);
    }

    /// @notice Burns tokens. Only the holder of tokens can burn them or an approved operator.
    /// @param tokenId The token to be burned.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 tokenId, address from, uint256 amount) public allowed(from, tokenId) {
        require(assets[tokenId].tokenType == TokenType.Native, "NTF: Not native");
        _burn(from, tokenId, amount);
    }

    /// @notice The `owner` can mint tokens. If a fixed supply is needed, the `owner` should mint the totalSupply and renounce ownership.
    /// @param tokenId The token to be minted.
    /// @param tos The accounts to transfer the minted tokens to.
    /// @param amounts The amounts of tokens to mint.
    /// @dev If the tos array is longer than the amounts array there will be an out of bounds error. If the amounts array is longer, the extra amounts are simply ignored.
    /// @dev For security reasons, operators are not allowed to mint. Only the actual owner can do this. Of course the owner can be a contract.
    function batchMint(uint256 tokenId, address[] calldata tos, uint256[] calldata amounts) public onlyOwner(tokenId) {
        uint256 len = tos.length;
        for (uint256 i = 0; i < len; i++) {
            _mint(tos[i], tokenId, amounts[i]);
        }
    }

    /// @notice Burns tokens. This is only useful to be used by an operator.
    /// @param tokenId The token to be burned.
    /// @param froms The accounts to burn tokens from.
    /// @param amounts The amounts of tokens to burn.
    function batchBurn(uint256 tokenId, address[] calldata froms, uint256[] calldata amounts) public {
        require(assets[tokenId].tokenType == TokenType.Native, "NTF: Not native");
        uint256 len = froms.length;
        for (uint256 i = 0; i < len; i++) {
            _requireTransferAllowed(froms[i], isApprovedForAsset[froms[i]][msg.sender][tokenId]);
            _burn(froms[i], tokenId, amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../enums/YieldBoxTokenType.sol";
import "../interfaces/IStrategy.sol";

// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

abstract contract BaseStrategy is IStrategy {
    IYieldBox public immutable yieldBox;

    constructor(IYieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    function _currentBalance() internal view virtual returns (uint256 amount);

    function currentBalance() public view virtual returns (uint256 amount) {
        return _currentBalance();
    }

    function withdrawable() external view virtual returns (uint256 amount) {
        return _currentBalance();
    }

    function cheapWithdrawable() external view virtual returns (uint256 amount) {
        return _currentBalance();
    }

    function _deposited(uint256 amount) internal virtual;

    function deposited(uint256 amount) external {
        require(msg.sender == address(yieldBox), "Not YieldBox");
        _deposited(amount);
    }

    function _withdraw(address to, uint256 amount) internal virtual;

    function withdraw(address to, uint256 amount) external {
        require(msg.sender == address(yieldBox), "Not YieldBox");
        _withdraw(to, amount);
    }
}

abstract contract BaseERC20Strategy is BaseStrategy {
    TokenType public constant tokenType = TokenType.ERC20;
    uint256 public constant tokenId = 0;
    address public immutable contractAddress;

    constructor(IYieldBox _yieldBox, address _contractAddress) BaseStrategy(_yieldBox) {
        contractAddress = _contractAddress;
    }
}

abstract contract BaseERC1155Strategy is BaseStrategy {
    TokenType public constant tokenType = TokenType.ERC1155;
    uint256 public immutable tokenId;
    address public immutable contractAddress;

    constructor(IYieldBox _yieldBox, address _contractAddress, uint256 _tokenId) BaseStrategy(_yieldBox) {
        contractAddress = _contractAddress;
        tokenId = _tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../enums/YieldBoxTokenType.sol";
import "../BoringMath.sol";
import "./BaseStrategy.sol";

// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

contract ERC20WithoutStrategy is BaseERC20Strategy {
    using BoringERC20 for IERC20;

    constructor(IYieldBox _yieldBox, IERC20 token) BaseERC20Strategy(_yieldBox, address(token)) {}

    string public constant override name = "No strategy";
    string public constant override description = "No strategy";

    function _currentBalance() internal view override returns (uint256 amount) {
        return IERC20(contractAddress).safeBalanceOf(address(this));
    }

    function _deposited(uint256 amount) internal override {}

    function _withdraw(address to, uint256 amount) internal override {
        IERC20(contractAddress).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

// The YieldBox
// The original BentoBox is owned by the Sushi team to set strategies for each token. Abracadabra wanted different strategies, which led to
// them launching their own DegenBox. The YieldBox solves this by allowing an unlimited number of strategies for each token in a fully
// permissionless manner. The YieldBox has no owner and operates fully permissionless.

// Other improvements:
// Better system to make sure the token to share ratio doesn't reset.
// Full support for rebasing tokens.

// This contract stores funds, handles their transfers, approvals and strategies.

// Copyright (c) 2021, 2022 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Since the contract is permissionless, only one deployment per chain is needed. If it's not yet deployed
// on a chain or if you want to make a derivative work, contact @BoringCrypto. The core of YieldBox is
// copyrighted. Most of the contracts that it builds on are open source though.

// BEWARE: Still under active development
// Security review not done yet

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IWrappedNative.sol";
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC721.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC721TokenReceiver.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AssetRegister.sol";
import "./NativeTokenFactory.sol";
import "./YieldBoxRebase.sol";
import "./YieldBoxURIBuilder.sol";
import "./YieldBoxPermit.sol";

// solhint-disable no-empty-blocks

/// @title YieldBox
/// @author BoringCrypto, Keno
/// @notice The YieldBox is a vault for tokens. The stored tokens can assigned to strategies.
/// Yield from this will go to the token depositors.
/// Any funds transfered directly onto the YieldBox will be lost, use the deposit function instead.
contract YieldBox is YieldBoxPermit, BoringBatchable, NativeTokenFactory, ERC721TokenReceiver, ERC1155TokenReceiver {
    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //
    using BoringAddress for address;
    using BoringERC20 for IERC20;
    using BoringERC20 for IWrappedNative;
    using YieldBoxRebase for uint256;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event Deposited(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut,
        bool isNFT
    );

    event Withdraw(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut
    );

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //
    IWrappedNative public immutable wrappedNative;
    YieldBoxURIBuilder public immutable uriBuilder;

    constructor(IWrappedNative wrappedNative_, YieldBoxURIBuilder uriBuilder_) YieldBoxPermit("YieldBox") {
        wrappedNative = wrappedNative_;
        uriBuilder = uriBuilder_;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    /// @dev Returns the total balance of `token` the strategy contract holds,
    /// plus the total amount this contract thinks the strategy holds.
    function _tokenBalanceOf(Asset storage asset) internal view returns (uint256 amount) {
        return asset.strategy.currentBalance();
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from, assetId) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native && asset.tokenType != TokenType.ERC721, "YieldBox: can't deposit type");

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share may be lower than the amount due to rounding, that's ok
            share = amount._toShares(totalSupply[assetId], totalAmount, false);
        } else {
            // amount may be lower than the value of share due to rounding, in that case, add 1 to amount (Always round up)
            amount = share._toAmount(totalSupply[assetId], totalAmount, true);
        }

        _mint(to, assetId, share);

        // Interactions
        if (asset.tokenType == TokenType.ERC20) {
            // For ERC20 tokens, use the safe helper function to deal with broken ERC20 implementations. This actually calls transferFrom on the ERC20 contract.
            IERC20(asset.contractAddress).safeTransferFrom(from, address(asset.strategy), amount);
        } else {
            // ERC1155
            // When depositing yieldBox tokens into the yieldBox, things can be simplified
            if (asset.contractAddress == address(this)) {
                _transferSingle(from, address(asset.strategy), asset.tokenId, amount);
            } else {
                IERC1155(asset.contractAddress).safeTransferFrom(from, address(asset.strategy), asset.tokenId, amount, "");
            }
        }

        asset.strategy.deposited(amount);

        emit Deposited(msg.sender, from, to, assetId, amount, share, amountOut, shareOut, false);

        return (amount, share);
    }

    /// @notice Deposit an NFT asset
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositNFTAsset(
        uint256 assetId,
        address from,
        address to
    ) public allowed(from, assetId) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC721, "YieldBox: not ERC721");

        // Effects
        _mint(to, assetId, 1);

        // Interactions
        IERC721(asset.contractAddress).safeTransferFrom(from, address(asset.strategy), asset.tokenId);

        asset.strategy.deposited(1);

        emit Deposited(msg.sender, from, to, assetId, 1, 1, 1, 1, true);

        return (1, 1);
    }

    /// @notice Deposit ETH asset
    /// @param assetId The id of the asset.
    /// @param to which account to push the tokens.
    /// @param amount ETH amount to deposit.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositETHAsset(
        uint256 assetId,
        address to,
        uint256 amount
    ) public payable returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC20 && asset.contractAddress == address(wrappedNative), "YieldBox: not wrappedNative");

        // Effects
        uint256 share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(asset), false);

        _mint(to, assetId, share);

        // Interactions
        wrappedNative.deposit{ value: amount }();
        // Strategies always receive wrappedNative (supporting both wrapped and raw native tokens adds too much complexity)
        wrappedNative.safeTransfer(address(asset.strategy), amount);
        asset.strategy.deposited(amount);

        emit Deposited(msg.sender, msg.sender, to, assetId, amount, share, amountOut, shareOut, false);

        return (amount, share);
    }

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from, assetId) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native, "YieldBox: can't withdraw Native");

        // Handle ERC721 separately
        if (asset.tokenType == TokenType.ERC721) {
            return _withdrawNFT(asset, assetId, from, to);
        }

        return _withdrawFungible(asset, assetId, from, to, amount, share);
    }

    /// @notice Handles burning and withdrawal of ERC20 and 1155 tokens.
    /// @param asset The asset to withdraw.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    function _withdrawNFT(
        Asset storage asset,
        uint256 assetId,
        address from,
        address to
    ) internal returns (uint256 amountOut, uint256 shareOut) {
        _burn(from, assetId, 1);

        // Interactions
        asset.strategy.withdraw(to, 1);

        emit Withdraw(msg.sender, from, to, assetId, 1, 1, 1, 1);

        return (1, 1);
    }

    /// @notice Handles burning and withdrawal of ERC20 and 1155 tokens.
    /// @param asset The asset to withdraw.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function _withdrawFungible(
        Asset storage asset,
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) internal returns (uint256 amountOut, uint256 shareOut) {
        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share paid could be lower than the amount paid due to rounding, in that case, add a share (Always round up)
            share = amount._toShares(totalSupply[assetId], totalAmount, true);
        } else {
            // amount may be lower than the value of share due to rounding, that's ok
            amount = share._toAmount(totalSupply[assetId], totalAmount, false);
        }

        _burn(from, assetId, share);

        // Interactions
        asset.strategy.withdraw(to, amount);

        emit Withdraw(msg.sender, from, to, assetId, amount, share, amountOut, shareOut);

        return (amount, share);
    }

    /// @notice Transfer shares from a user account to another one.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param assetId The id of the asset.
    /// @param share The amount of `token` in shares.
    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) public allowed(from, assetId) {
        _transferSingle(from, to, assetId, share);
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) public allowed(from, type(uint256).max) {
        _transferBatch(from, to, assetIds_, shares_);
    }

    /// @notice Transfer shares from a user account to multiple other ones.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param tos The receivers of the tokens.
    /// @param shares The amount of `token` in shares for each receiver in `tos`.
    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) public allowed(from, type(uint256).max) {
        // Checks
        uint256 len = tos.length;
        for (uint256 i = 0; i < len; i++) {
            require(tos[i] != address(0), "YieldBox: to not set"); // To avoid a bad UI from burning funds
        }

        // Effects
        uint256 totalAmount;
        for (uint256 i = 0; i < len; i++) {
            address to = tos[i];
            uint256 share_ = shares[i];
            balanceOf[to][assetId] += share_;
            totalAmount += share_;
            emit TransferSingle(msg.sender, from, to, assetId, share_);
        }
        balanceOf[from][assetId] -= totalAmount;
    }

    /// @notice Update approval status for an operator
    /// @param operator The address approved to perform actions on your behalf
    /// @param approved True/False
    function setApprovalForAll(address operator, bool approved) external override {
        // Checks
        require(operator != address(0), "YieldBox: operator not set"); // Important for security
        require(operator != address(this), "YieldBox: can't approve yieldBox");

        // Effects
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Update approval status for an operator
    /// @param _owner The YieldBox account owner
    /// @param operator The address approved to perform actions on your behalf
    /// @param approved True/False
    function _setApprovalForAll(
        address _owner,
        address operator,
        bool approved
    ) internal override{
        isApprovedForAll[_owner][operator] = approved;
        emit ApprovalForAll(_owner, operator, approved);
    }

    /// @notice Update approval status for an operator and for a specific asset
    /// @param operator The address approved to perform actions on your behalf
    /// @param assetId The asset id  to update approval status for
    /// @param approved True/False
    function setApprovalForAsset(
        address operator,
        uint256 assetId,
        bool approved
    ) external override {
        // Checks
        require(operator != address(0), "YieldBox: operator not set"); // Important for security
        require(operator != address(this), "YieldBox: can't approve yieldBox");
        require(assetId < assetCount(), "YieldBox: asset not valid");

        // Effects
        _setApprovalForAsset(msg.sender, operator, assetId, approved);
    }

    /// @notice Update approval status for an operator and for a specific asset
    /// @param _owner The owner of the asset
    /// @param operator The address approved to perform actions on your behalf
    /// @param assetId The asset id  to update approval status for
    /// @param approved True/False
    function _setApprovalForAsset(
        address _owner,
        address operator,
        uint256 assetId,
        bool approved
    ) internal override {
        isApprovedForAsset[_owner][operator][assetId] = approved;
        emit ApprovalForAsset(_owner, operator, assetId, approved);
    }

    // This functionality has been split off into a separate contract. This is only a view function, so gas usage isn't a huge issue.
    // This keeps the YieldBox contract smaller, so it can be optimized more.
    function uri(uint256 assetId) external view override returns (string memory) {
        return uriBuilder.uri(assets[assetId], nativeTokens[assetId], totalSupply[assetId], owner[assetId]);
    }

    function name(uint256 assetId) external view returns (string memory) {
        return uriBuilder.name(assets[assetId], nativeTokens[assetId].name);
    }

    function symbol(uint256 assetId) external view returns (string memory) {
        return uriBuilder.symbol(assets[assetId], nativeTokens[assetId].symbol);
    }

    function decimals(uint256 assetId) external view returns (uint8) {
        return uriBuilder.decimals(assets[assetId], nativeTokens[assetId].decimals);
    }

    // Helper functions

    /// @notice Helper function to return totals for an asset
    /// @param assetId The regierestered asset id
    /// @return totalShare The total amount for asset represented in shares
    /// @return totalAmount The total amount for asset
    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount) {
        totalShare = totalSupply[assetId];
        totalAmount = _tokenBalanceOf(assets[assetId]);
    }

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param assetId The id of the asset.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            share = amount;
        } else {
            share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent shares back into the `token` amount.
    /// @param assetId The id of the asset.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = share;
        } else {
            amount = share._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent the balance in `token` amount for a `user` for an `asset`.
    /// @param user The `user` to get the amount for.
    /// @param assetId The id of the asset.
    function amountOf(address user, uint256 assetId) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = balanceOf[user][assetId];
        } else {
            amount = balanceOf[user][assetId]._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), false);
        }
    }

    /// @notice Helper function to register & deposit an asset
    /// @param tokenType Registration token type.
    /// @param contractAddress Token address.
    /// @param strategy Asset's strategy address.
    /// @param tokenId Registration token id.
    /// @param from which user to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount amount to deposit.
    /// @param share amount to deposit represented in shares.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public returns (uint256 amountOut, uint256 shareOut) {
        if (tokenType == TokenType.Native) {
            // If native token, register it as an ERC1155 asset (as that's what it is)
            return depositAsset(registerAsset(TokenType.ERC1155, address(this), strategy, tokenId), from, to, amount, share);
        } else {
            return depositAsset(registerAsset(tokenType, contractAddress, strategy, tokenId), from, to, amount, share);
        }
    }

    /// @notice Helper function to register & deposit ETH
    /// @param strategy Asset's strategy address.
    /// @param amount amount to deposit.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositETH(
        IStrategy strategy,
        address to,
        uint256 amount
    ) public payable returns (uint256 amountOut, uint256 shareOut) {
        return depositETHAsset(registerAsset(TokenType.ERC20, address(wrappedNative), strategy, 0), to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IYieldBox.sol";

/**
 * Modification of the OpenZeppelin ERC20Permit contract to support ERC721 tokens.
 * OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol).
 *
 * @dev Implementation of the ERC-4494 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-4494[EIP-4494].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract YieldBoxPermit is EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;


    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 assetId,uint256 nonce,uint256 deadline)");
    

    bytes32 private constant _PERMIT_ALL_TYPEHASH =
        keccak256("PermitAll(address owner,address spender,uint256 nonce,uint256 deadline)");
    

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC721 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    function permit(
        address owner,
        address spender,
        uint256 assetId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "YieldBoxPermit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, assetId, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "YieldBoxPermit: invalid signature");

        _setApprovalForAsset(owner, spender, assetId, true);
    }


    function _setApprovalForAsset(
        address owner,
        address spender,
        uint256 assetId,
        bool approved
    ) internal virtual;


    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "YieldBoxPermit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_ALL_TYPEHASH, owner, spender, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "YieldBoxPermit: invalid signature");

        _setApprovalForAll(owner, spender, true);
    }

    function _setApprovalForAll(
        address _owner,
        address operator,
        bool approved
    ) internal virtual;
    
    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

library YieldBoxRebase {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function _toShares(
        uint256 amount,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 share) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the shares using te current amount to share ratio
        share = (amount * totalShares_) / totalAmount;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (share * totalAmount) / totalShares_ < amount) {
            share++;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function _toAmount(
        uint256 share,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the amount using te current amount to share ratio
        amount = (share * totalAmount) / totalShares_;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (amount * totalShares_) / totalAmount < share) {
            amount++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "./interfaces/IYieldBox.sol";
import "./NativeTokenFactory.sol";

// solhint-disable quotes

contract YieldBoxURIBuilder {
    using BoringERC20 for IERC20;
    using Strings for uint256;
    using Base64 for bytes;

    struct AssetDetails {
        string tokenType;
        string name;
        string symbol;
        uint256 decimals;
    }

    function name(Asset calldata asset, string calldata nativeName) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            return nativeName;
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeName(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(
                        abi.encodePacked(
                            string(
                                abi.encodePacked(
                                    "ERC1155:",
                                    uint256(uint160(asset.contractAddress)).toHexString(20),
                                    "/",
                                    asset.tokenId.toString()
                                )
                            ),
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else {
                return string(abi.encodePacked(nativeName, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function symbol(Asset calldata asset, string calldata nativeSymbol) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            return nativeSymbol;
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeSymbol(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return string(abi.encodePacked("ERC1155", " (", asset.strategy.name(), ")"));
            } else {
                return string(abi.encodePacked(nativeSymbol, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function decimals(Asset calldata asset, uint8 nativeDecimals) external view returns (uint8) {
        if (asset.tokenType == TokenType.ERC1155) {
            return 0;
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            return token.safeDecimals();
        } else {
            return nativeDecimals;
        }
    }

    function uri(
        Asset calldata asset,
        NativeToken calldata nativeToken,
        uint256 totalSupply,
        address owner
    ) external view returns (string memory) {
        AssetDetails memory details;
        if (asset.tokenType == TokenType.ERC1155) {
            // Contracts can't retrieve URIs, so the details are out of reach
            details.tokenType = "ERC1155";
            details.name = string(
                abi.encodePacked("ERC1155:", uint256(uint160(asset.contractAddress)).toHexString(20), "/", asset.tokenId.toString())
            );
            details.symbol = "ERC1155";
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            details = AssetDetails("ERC20", token.safeName(), token.safeSymbol(), token.safeDecimals());
        } else {
            // Native
            details.tokenType = "Native";
            details.name = nativeToken.name;
            details.symbol = nativeToken.symbol;
            details.decimals = nativeToken.decimals;
        }

        string memory properties = string(
            asset.tokenType != TokenType.Native
                ? abi.encodePacked(',"tokenAddress":"', uint256(uint160(asset.contractAddress)).toHexString(20), '"')
                : abi.encodePacked(',"totalSupply":', totalSupply.toString(), ',"fixedSupply":', owner == address(0) ? "true" : "false")
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    abi
                        .encodePacked(
                            '{"name":"',
                            details.name,
                            '","symbol":"',
                            details.symbol,
                            '"',
                            asset.tokenType == TokenType.ERC1155 ? "" : ',"decimals":',
                            asset.tokenType == TokenType.ERC1155 ? "" : details.decimals.toString(),
                            ',"properties":{"strategy":"',
                            uint256(uint160(address(asset.strategy))).toHexString(20),
                            '","tokenType":"',
                            details.tokenType,
                            '"',
                            properties,
                            asset.tokenType == TokenType.ERC1155 ? string(abi.encodePacked(',"tokenId":', asset.tokenId.toString())) : "",
                            "}}"
                        )
                        .encode()
                )
            );
    }
}