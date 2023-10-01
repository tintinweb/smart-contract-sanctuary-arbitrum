// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* Modifier : Coinmeca Team <[email protected]>
* Lightweight version of EIP-2535 Diamonds
\******************************************************************************/

import {IDiamond} from "./interfaces/IDiamond.sol";

import {DiamondBase} from "./utils/DiamondBase.sol";
import {DiamondAuth} from "./utils/DiamondAuth.sol";
import {DiamondLoupe} from "./utils/DiamondLoupe.sol";

import {DiamondContractManager} from "./DiamondContractManager.sol";

abstract contract DiamondContract is DiamondAuth, DiamondLoupe {
    using DiamondContractManager for bytes32;
    using DiamondContractManager for DiamondContractManager.Data;

    constructor(
        string memory _key,
        IDiamond.Cut[] memory _diamondCut,
        IDiamond.Args memory _args
    ) payable DiamondBase(keccak256(abi.encodePacked(_key))) {
        _this.setOwner(_args.owner);
        _this.setPermission(address(this), true);
        _this.diamond().addr = payable(address(this));
        DiamondContractManager.diamondCut(
            _diamondCut,
            _args.init,
            _args.initCalldata
        );
    }

    function facet(bytes4 _funct) public virtual returns (address) {
        return _this.diamond().funct[_funct].facet;
    }

    function facet(
        bytes32 _contract,
        bytes4 _funct
    ) public virtual returns (address) {
        return _contract.diamond().funct[_funct].facet;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* Modifier : Coinmeca Team <[email protected]>
* Lightweight version of EIP-2535 Diamonds
\******************************************************************************/

import {IDiamond} from "./interfaces/IDiamond.sol";

library DiamondContractManager {
    using DiamondContractManager for bytes32;
    using DiamondContractManager for DiamondContractManager.Data;

    struct Facet {
        address addr;
        bytes4[] functs;
    }

    struct Funct {
        address facet;
        uint16 position;
    }

    struct Data {
        address payable addr;
        address owner;
        address[] facets;
        mapping(address => Facet) facet;
        mapping(bytes4 => Funct) funct;
        mapping(bytes4 => bool) interfaces;
        mapping(address => bool) permission;
    }

    function diamond(bytes32 _key) internal pure returns (Data storage $) {
        assembly {
            $.slot := _key
        }
    }

    /* Ownable */

    function setOwner(bytes32 _key, address _owner) internal {
        enforceIsContractOwner(_key);
        Data storage $ = diamond(_key);
        $.owner = _owner;
        $.permission[_owner] = true;
        emit OwnershipTransferred($.owner, _owner);
    }

    function owner(bytes32 _key) internal view returns (address _owner) {
        _owner = diamond(_key).owner;
    }

    function enforceIsContractOwner(bytes32 _key) internal view {
        Data storage $ = diamond(_key);
        if ($.owner != address(0))
            if (msg.sender != $.owner) {
                revert IDiamond.NotContractOwner(msg.sender, $.owner);
            }
    }

    /* Permission */

    function setPermission(
        bytes32 _key,
        address _owner,
        bool _permission
    ) internal {
        _key.checkPermission(msg.sender);
        diamond(_key).permission[_owner] = _permission;
    }

    function checkPermission(
        bytes32 _key,
        address _owner
    ) internal view returns (bool check) {
        Data storage $ = diamond(_key);
        check = $.permission[_owner];
        if (!check) revert IDiamond.PermissionDenied(_owner);
        return check;
    }

    /* Loupe */

    function functs(
        bytes32 _key,
        address _facet
    ) internal view returns (bytes4[] memory) {
        return diamond(_key).facet[_facet].functs;
    }

    function facet(
        bytes32 _key,
        bytes4 _funct
    ) internal view returns (address) {
        return diamond(_key).funct[_funct].facet;
    }

    function facets(bytes32 _key) internal view returns (address[] memory) {
        return diamond(_key).facets;
    }

    function getFacets(
        bytes32 _key
    ) internal view returns (Facet[] memory facets_) {
        Data storage $ = diamond(_key);
        uint length = $.facets.length;
        facets_ = new Facet[](length);
        for (uint i; i < length; ++i) {
            address facet_ = $.facets[i];
            facets_[i] = Facet(facet_, $.facet[facet_].functs);
        }
    }

    function setInterface(
        bytes32 _key,
        bytes32 _service,
        bytes4 _interface,
        bool _state
    ) internal {
        _key.checkPermission(msg.sender);
        diamond(_service).interfaces[_interface] = _state;
    }

    function checkInterface(
        bytes32 _service,
        bytes4 _interface
    ) internal view returns (bool) {
        return diamond(_service).interfaces[_interface];
    }

    /* DiamondCut */

    event DiamondCut(
        IDiamond.Data[] _diamondCut,
        address _init,
        bytes _calldata
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamond.Cut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint i; i < _diamondCut.length; ++i) {
            for (uint j; j < _diamondCut[i].data.length; ++j) {
                bytes4[] memory functs_ = _diamondCut[i]
                    .data[j]
                    .functionSelectors;
                address facet_ = _diamondCut[i].data[j].facetAddress;
                if (functs_.length == 0)
                    revert IDiamond.NoSelectorsProvidedForFacetForCut(facet_);
                IDiamond.Action action = _diamondCut[i].data[j].action;
                Data storage $ = diamond(
                    keccak256(abi.encodePacked(_diamondCut[i].key))
                );
                if (action == IDiamond.Action.Add)
                    $.addFunctions(facet_, functs_);
                else if (action == IDiamond.Action.Replace)
                    $.replaceFunctions(facet_, functs_);
                else if (action == IDiamond.Action.Remove)
                    $.removeFunctions(facet_, functs_);
                else revert IDiamond.IncorrectFacetCutAction(uint8(action));
            }
            emit DiamondCut(_diamondCut[i].data, _init, _calldata);
        }
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        Data storage $,
        address _facet,
        bytes4[] memory _functs
    ) internal {
        if (_facet == address(0))
            revert IDiamond.CannotAddSelectorsToZeroAddress(_functs);
        enforcedFacetHasCode(_facet, "DiamondCut: Add facet has no code");
        uint16 position = uint16($.facet[_facet].functs.length);
        for (uint i; i < _functs.length; ++i) {
            if ($.funct[_functs[i]].facet != address(0))
                revert IDiamond.CannotAddFunctionToDiamondThatAlreadyExists(
                    _functs[i]
                );
            $.facet[_facet].functs.push(_functs[i]);
            $.funct[_functs[i]] = Funct(_facet, position);
            ++position;
        }
        $.facets.push(_facet);
    }

    function replaceFunctions(
        Data storage $,
        address _facet,
        bytes4[] memory _functs
    ) internal {
        if (_facet == address(0))
            revert IDiamond.CannotReplaceFunctionsFromFacetWithZeroAddress(
                _functs
            );
        enforcedFacetHasCode(_facet, "DiamondCut: Replace facet has no code");
        for (uint i; i < _functs.length; ++i) {
            bytes4 funct_ = _functs[i];
            address facet_ = $.funct[funct_].facet;
            if (facet_ == _facet)
                revert IDiamond
                    .CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
                        funct_
                    );
            if (facet_ == address(0))
                revert IDiamond.CannotReplaceFunctionThatDoesNotExists(funct_);
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (facet_ == address(this))
                revert IDiamond.CannotReplaceImmutableFunction(funct_);
            // replace old facet address
            $.funct[funct_].facet = _facet;
        }
    }

    function removeFunctions(
        Data storage $,
        address _facet,
        bytes4[] memory _functs
    ) internal {
        uint position = $.facet[_facet].functs.length;
        if (_facet != address(0))
            revert IDiamond.RemoveFacetAddressMustBeZeroAddress(_facet);
        for (uint i; i < _functs.length; ++i) {
            bytes4 funct_ = _functs[i];
            Funct memory old = $.funct[funct_];
            if (old.facet == address(0))
                revert IDiamond.CannotRemoveFunctionThatDoesNotExist(funct_);
            // can't remove immutable functions -- functions defined directly in the diamond
            if (old.facet == address(this))
                revert IDiamond.CannotRemoveImmutableFunction(funct_);
            // replace funct with last funct
            --position;
            if (old.position != position) {
                bytes4 last = $.facet[_facet].functs[position];
                $.facet[_facet].functs[old.position] = last;
                $.funct[last].position = old.position;
            }
            // delete last funct
            $.facet[_facet].functs.pop();
            delete $.funct[funct_];
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) return;
        enforcedFacetHasCode(_init, "DiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success)
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert IDiamond.InitializationFunctionReverted(
                    _init,
                    _calldata
                );
            }
    }

    function enforcedFacetHasCode(
        address _facet,
        string memory _errorMessage
    ) internal view {
        uint size;
        assembly {
            size := extcodesize(_facet)
        }
        if (size == 0)
            revert IDiamond.NoBytecodeAtAddress(_facet, _errorMessage);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* Modifier : Coinmeca Team <[email protected]>
* Lightweight version of EIP-2535 Diamonds
\******************************************************************************/

import {IDiamond} from "./interfaces/IDiamond.sol";

import {DiamondBase} from "./utils/DiamondBase.sol";
import {DiamondAuth} from "./utils/DiamondAuth.sol";
import {DiamondLoupe} from "./utils/DiamondLoupe.sol";

import {DiamondContractManager} from "./DiamondContractManager.sol";
import {DiamondContract} from "./DiamondContract.sol";

abstract contract DiamondFacade is DiamondAuth, DiamondLoupe {
    using DiamondContractManager for bytes32;

    constructor(
        string memory _key,
        address _diamond
    ) payable DiamondBase(keccak256(abi.encodePacked(_key))) {
        _this.diamond().addr = payable(_diamond);
    }

    fallback() external payable virtual override {
        address f = DiamondContract(_this.diamond().addr).facet(_this, msg.sig);
        if (f == address(0)) revert IDiamond.FunctionNotFound(msg.sig);
        assembly {
            calldatacopy(0, 0, calldatasize())
            let r := delegatecall(gas(), f, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            switch r
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* Modifier : Coinmeca Team <[email protected]>
* Lightweight version of EIP-2535 Diamonds
\******************************************************************************/

interface IDiamond {
    enum Action {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct Cut {
        string key;
        Data[] data;
    }

    struct Data {
        address facetAddress;
        Action action;
        bytes4[] functionSelectors;
    }

    struct Args {
        address owner;
        address init;
        bytes initCalldata;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        Cut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    error NoSelectorsGivenToAdd();
    error PermissionDenied(address _sender);
    error NotContractOwner(address _user, address _contractOwner);
    error NoSelectorsProvidedForFacetForCut(address _facetAddress);
    error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
    error NoBytecodeAtAddress(address _contractAddress, string _message);
    error FunctionNotFound(bytes4 _functionSelector);
    error IncorrectFacetCutAction(uint8 _action);
    error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
    error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
    error CannotReplaceImmutableFunction(bytes4 _selector);
    error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
        bytes4 _selector
    );
    error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
    error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
    error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
    error CannotRemoveImmutableFunction(bytes4 _selector);
    error InitializationFunctionReverted(
        address _initializationContractAddress,
        bytes _calldata
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IEP 165 표준 인터페이스 https://eips.ethereum.org/EIPS/eip-165[EIP].
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "./IERC165.sol";

// ERC721 스탠다드 표준만
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "./IERC721.sol";

// 721 메타 데이터 인터페이스 표준
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 721 안전한 거래를 위한 필수 구현 인터페이스
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* Modifier : Coinmeca Team <[email protected]>
* Lightweight version of EIP-2535 Diamonds
\******************************************************************************/

import {DiamondContractManager} from "../DiamondContractManager.sol";
import {DiamondBase} from "./DiamondBase.sol";

abstract contract DiamondAuth is DiamondBase {
    using DiamondContractManager for bytes32;
    using DiamondContractManager for DiamondContractManager.Data;

    function owner() public virtual returns (address) {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.owner()
                : DiamondAuth(diamond).owner();
    }

    function setOwner(address _owner) public virtual {
        address payable diamond = _this.diamond().addr;
        diamond == address(this)
            ? _this.setOwner(_owner)
            : DiamondAuth(diamond).setOwner(_owner);
    }

    function setPermission(address _owner, bool _permission) public virtual {
        address payable diamond = _this.diamond().addr;
        diamond == address(this)
            ? _this.setPermission(_owner, _permission)
            : DiamondAuth(diamond).setPermission(_owner, _permission);
    }

    function checkPermission(
        address _owner
    ) public view virtual returns (bool) {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.checkPermission(_owner)
                : DiamondAuth(diamond).checkPermission(_owner);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* Modifier : Coinmeca Team <[email protected]>
* Lightweight version of EIP-2535 Diamonds
\******************************************************************************/

import {IDiamond} from "../interfaces/IDiamond.sol";

import {DiamondContract} from "../DiamondContract.sol";
import {DiamondContractManager} from "../DiamondContractManager.sol";

abstract contract DiamondBase {
    using DiamondContractManager for bytes32;
    using DiamondContractManager for DiamondContractManager.Data;

    bytes32 immutable _this;

    constructor(bytes32 _key) payable {
        _this = _key;
    }

    fallback() external payable virtual {
        address f = _this.diamond().funct[msg.sig].facet;
        if (f == address(0)) revert IDiamond.FunctionNotFound(msg.sig);
        assembly {
            calldatacopy(0, 0, calldatasize())
            let r := delegatecall(gas(), f, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            switch r
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable virtual {}
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* Modifier : Coinmeca Team <[email protected]>
* Lightweight version of EIP-2535 Diamonds
\******************************************************************************/

import {DiamondBase} from "./DiamondBase.sol";
import {DiamondContractManager} from "../DiamondContractManager.sol";

abstract contract DiamondLoupe is DiamondBase {
    using DiamondContractManager for bytes32;
    using DiamondContractManager for DiamondContractManager.Data;

    function facets()
        public
        view
        virtual
        returns (DiamondContractManager.Facet[] memory)
    {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.getFacets()
                : DiamondLoupe(diamond).facets(_this);
    }

    function facets(
        bytes32 _contract
    ) public view virtual returns (DiamondContractManager.Facet[] memory) {
        return _contract.getFacets();
    }

    function facetFunctionSelectors(
        address _facet
    ) public view virtual returns (bytes4[] memory) {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.functs(_facet)
                : DiamondLoupe(diamond).facetFunctionSelectors(_this, _facet);
    }

    function facetFunctionSelectors(
        bytes32 _contract,
        address _facet
    ) public view virtual returns (bytes4[] memory) {
        return _contract.functs(_facet);
    }

    function facetAddresses() public view virtual returns (address[] memory) {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.facets()
                : DiamondLoupe(diamond).facetAddresses(_this);
    }

    function facetAddresses(
        bytes32 _contract
    ) public view virtual returns (address[] memory) {
        return _contract.facets();
    }

    function facetAddress(bytes4 _funct) public view virtual returns (address) {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.facet(_funct)
                : DiamondLoupe(diamond).facetAddress(_this, _funct);
    }

    function facetAddress(
        bytes32 _contract,
        bytes4 _funct
    ) public view virtual returns (address) {
        return _contract.facet(_funct);
    }

    function supportsInterface(
        bytes4 _interface
    ) public view virtual returns (bool) {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.checkInterface(_interface)
                : DiamondLoupe(diamond).supportsInterface(_this, _interface);
    }

    function supportsInterface(
        bytes32 _contract,
        bytes4 _interface
    ) public view virtual returns (bool) {
        return _contract.checkInterface(_interface);
    }

    function setInterface(bytes4 _interface, bool _state) public virtual {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.setInterface(_this, _interface, _state)
                : DiamondLoupe(diamond).setInterface(_this, _interface, _state);
    }

    function setInterface(
        bytes32 _contract,
        bytes4 _interface,
        bool _state
    ) public virtual {
        return _this.setInterface(_contract, _interface, _state);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Errors} from './shared/Errors.sol';
import {IERC165} from '../../../modules/diamond/interfaces/IERC165.sol';
import {IERC721} from '../../../modules/diamond/interfaces/IERC721.sol';
import {IERC721Metadata} from '../../../modules/diamond/interfaces/IERC721Metadata.sol';
import {IERC721Receiver} from '../../../modules/diamond/interfaces/IERC721Receiver.sol';
import {Events} from '../../orderbook/nft/shared/Events.sol';

library Data2 {
    struct Storage {
        string name;
        string symbol;
        mapping(uint256 tokenId => address)  _owners;
        mapping(address owner => uint256)  _balances;
        mapping(uint256 tokenId => address)  _tokenApprovals;
        mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
    }

    function load() internal pure returns (Storage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// OrderNFT Facade Diamond
import {DiamondFacade} from "../../../modules/diamond/DiamondFacade.sol";
import {Data2} from "./Data2.sol";

//나중에 오더북이랑 합병 하시면 됩니다

contract OrderNFT is DiamondFacade {
    using Data2 for Data2.Storage;

    Data2.Storage internal $;

    constructor(
        string memory _name ,
        string memory _symbol,
        address _app
    ) DiamondFacade("orderNFT", _app) {
      $.name = _name;
      $.symbol = _symbol;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

library Errors {
    // Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
    // error 표준도 있는듯 
    error ERC721InvalidOwner(address owner);
    error ERC721InvalidReceiver(address receiver);
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
    error ERC721NonexistentToken(uint256 tokenId);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidSender(address sender);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidOperator(address operator);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}