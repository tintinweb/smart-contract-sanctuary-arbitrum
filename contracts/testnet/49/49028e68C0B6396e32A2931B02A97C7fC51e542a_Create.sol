// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.22;

import {IDiamond} from "./interfaces/IDiamond.sol";

import {DiamondBase} from "./utils/DiamondBase.sol";
import {DiamondAuth} from "./utils/DiamondAuth.sol";
import {DiamondLoupe} from "./utils/DiamondLoupe.sol";

import {DiamondManager} from "./DiamondManager.sol";

interface IDiamondContract {
    function facet(bytes32, bytes4) external view returns (address);
}

abstract contract DiamondFacade is DiamondAuth, DiamondLoupe {
    using DiamondManager for bytes32;

    constructor(
        string memory _key,
        address _diamond
    ) payable DiamondBase(_key) DiamondAuth(false) DiamondLoupe(false) {
        _this.diamond().addr = payable(_diamond);
    }

    fallback() external payable virtual override {
        address f = IDiamondContract(_this.diamond().addr).facet(
            _this,
            msg.sig
        );
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
pragma solidity ^0.8.22;

import {IDiamond} from "./interfaces/IDiamond.sol";

library DiamondManager {
    using DiamondManager for bytes32;
    using DiamondManager for DiamondManager.Data;

    bytes32 constant base = keccak256("diamond");

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
        mapping(address => uint16) index;
        mapping(address => Facet) facet;
        mapping(bytes4 => Funct) funct;
        mapping(bytes4 => bool) interfaces;
        mapping(address => bool) access;
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
        $.access[_owner] = true;
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

    /* Access */

    function setAccess(bytes32 _key, address _owner, bool _access) internal {
        _key.checkAccess(msg.sender);
        diamond(_key).access[_owner] = _access;
    }

    function checkAccess(
        bytes32 _key,
        address _owner
    ) internal view returns (bool check) {
        Data storage $ = diamond(_key);
        check = $.access[_owner];
        if (!check) revert IDiamond.AccessDenied(_owner);
        return check;
    }

    /* Loupe */

    function functs(
        bytes32 _key,
        address _facet
    ) internal view returns (bytes4[] memory _functs) {
        _functs = diamond(_key).facet[_facet].functs;
        return
            _functs.length == 0 ? diamond(base).facet[_facet].functs : _functs;
    }

    function facet(
        bytes32 _key,
        bytes4 _funct
    ) internal view returns (address _facet) {
        _facet = diamond(_key).funct[_funct].facet;
        return
            _facet == address(0) ? diamond(base).funct[_funct].facet : _facet;
    }

    function facets(
        bytes32 _key
    ) internal view returns (address[] memory _facets) {
        address[] memory f = diamond(_key).facets;
        uint l = f.length;
        if (f.length > 0)
            for (uint i; i < l; ++i) {
                _facets[i] = f[i];
            }
        f = diamond(base).facets;
        if (f.length > 0)
            for (uint i; i < f.length; ++i) {
                _facets[i + l] = f[i];
            }
    }

    function getFacets(
        bytes32 _key
    ) internal view returns (Facet[] memory facets_) {
        Data storage $ = diamond(_key);
        uint length = $.facets.length;
        facets_ = new Facet[](length + 1);
        for (uint i; i < length; ++i) {
            address facet_ = $.facets[i];
            facets_[i] = Facet(facet_, $.facet[facet_].functs);
        }
        facets_[length] = Facet(
            address(this),
            diamond(base).facet[address(this)].functs
        );
    }

    function setInterface(
        bytes32 _key,
        bytes32 _service,
        bytes4 _interface,
        bool _state
    ) internal {
        _key.checkAccess(msg.sender);
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

    function internalCut(
        bytes4[] memory _functs,
        bytes memory _calldata
    ) internal {
        diamond(base)._addFunctions(address(this), _functs, true);
        IDiamond.Data[] memory _cut = new IDiamond.Data[](1);
        _cut[0] = IDiamond.Data(address(this), IDiamond.Action.Add, _functs);
        emit DiamondCut(_cut, address(this), _calldata);
    }

    function _addFunctions(
        Data storage $,
        address _facet,
        bytes4[] memory _functs,
        bool _internal
    ) internal {
        uint16 position = uint16($.facet[_facet].functs.length);
        if (position == 0) {
            $.index[_facet] = uint16($.facets.length);
            $.facets.push(_facet);
        }
        for (uint i; i < _functs.length; ++i) {
            if ($.funct[_functs[i]].facet != address(0)) {
                if (!_internal)
                    revert IDiamond.CannotAddFunctionToDiamondThatAlreadyExists(
                        _functs[i]
                    );
            } else {
                $.facet[_facet].functs.push(_functs[i]);
                $.funct[_functs[i]] = Funct(_facet, position);
                ++position;
            }
        }
    }

    function addFunctions(
        Data storage $,
        address _facet,
        bytes4[] memory _functs
    ) internal {
        if (_facet == address(0))
            revert IDiamond.CannotAddSelectorsToZeroAddress(_functs);
        enforcedFacetHasCode(_facet, "DiamondCut: Add facet has no code");
        $._addFunctions(_facet, _functs, false);
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
        uint16 position = uint16($.facet[_facet].functs.length);
        for (uint i; i < _functs.length; ++i) {
            bytes4 funct_ = _functs[i];
            Funct memory old = $.funct[funct_];
            if (old.facet == _facet)
                revert IDiamond
                    .CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
                        funct_
                    );
            if (old.facet == address(0))
                revert IDiamond.CannotReplaceFunctionThatDoesNotExists(funct_);
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (old.facet == address(this))
                revert IDiamond.CannotReplaceImmutableFunction(funct_);

            // delete old functions
            if ($.facet[old.facet].functs.length > 1) {
                uint last = $.facet[old.facet].functs.length - 1;
                $.facet[old.facet].functs[old.position] = $
                    .facet[old.facet]
                    .functs[last];
                $.facet[old.facet].functs.pop();
            } else {
                $.facets[$.index[old.facet]] = $.facets[$.facets.length - 1];
                $.facets.pop();
                delete $.facet[old.facet];
                delete $.index[old.facet];
            }

            // regist new functions
            $.funct[funct_].facet = _facet;
            $.funct[funct_].position = position;
            $.facet[_facet].functs.push(funct_);
            ++position;
        }
        $.facets.push(_facet);
    }

    function removeFunctions(
        Data storage $,
        address _facet,
        bytes4[] memory _functs
    ) internal {
        uint position = $.facet[_facet].functs.length;
        if (position == 0)
            revert IDiamond
                .CannotRemoveFunctionFromFacetAddressThatDoesNotExist(_facet);
        if (_facet == address(0))
            revert IDiamond.RemoveFacetAddressNotFound(_facet);
        for (uint i; i < _functs.length; ++i) {
            bytes4 funct_ = _functs[i];
            Funct memory old = $.funct[funct_];
            if (old.facet == address(0))
                revert IDiamond.CannotRemoveFunctionThatDoesNotExist(funct_);
            // can't remove immutable functions -- functions defined directly in the diamond
            if (old.facet == address(this))
                revert IDiamond.CannotRemoveImmutableFunction(funct_);
            // replace funct with last funct
            if ($.facet[_facet].functs.length > 1) {
                --position;
                if (old.position != position) {
                    bytes4 last = $.facet[_facet].functs[position];
                    $.facet[_facet].functs[old.position] = last;
                    $.funct[last].position = old.position;
                }
                // delete last funct
                $.facet[_facet].functs.pop();
                delete $.funct[funct_];
            } else {
                $.facets[$.index[old.facet]] = $.facets[$.facets.length];
                $.facets.pop();
                delete $.facet[old.facet];
                delete $.index[old.facet];
            }
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
pragma solidity ^0.8.22;

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

    function diamondCut(Cut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    error NoSelectorsGivenToAdd();
    error AccessDenied(address _sender);
    error NotContractOwner(address _user, address _contractOwner);
    error NoSelectorsProvidedForFacetForCut(address _facetAddress);
    error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
    error NoBytecodeAtAddress(address _contractAddress, string _message);
    error FunctionNotFound(bytes4 _functionSelector);
    error IncorrectFacetCutAction(uint8 _action);
    error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
    error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
    error CannotReplaceImmutableFunction(bytes4 _selector);
    error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
    error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
    error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
    error RemoveFacetAddressNotFound(address _facetAddress);
    error Connot(bytes4 _selector);
    error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
    error CannotRemoveFunctionFromFacetAddressThatDoesNotExist(address _facetAddress);
    error CannotRemoveImmutableFunction(bytes4 _selector);
    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.22;

import {DiamondBase} from "./DiamondBase.sol";
import {DiamondManager} from "../DiamondManager.sol";

abstract contract DiamondAuth is DiamondBase {
    using DiamondManager for bytes32;
    using DiamondManager for DiamondManager.Data;

    constructor(bool _diamond) {
        if (_diamond) {
            bytes4[] memory f = new bytes4[](4);
            f[0] = 0x466a0146;
            f[1] = 0x8da5cb5b;
            f[2] = 0xb84614a5;
            f[3] = 0x13af4035;
            DiamondManager.internalCut(f, "auth");
        }
    }

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

    function setAccess(address _owner, bool _access) public virtual {
        address payable diamond = _this.diamond().addr;
        diamond == address(this)
            ? _this.setAccess(_owner, _access)
            : DiamondAuth(diamond).setAccess(_owner, _access);
    }

    function checkAccess(address _owner) public view virtual returns (bool) {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.checkAccess(_owner)
                : DiamondAuth(diamond).checkAccess(_owner);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.22;

import {IDiamond} from "../interfaces/IDiamond.sol";
import {DiamondManager} from "../DiamondManager.sol";

abstract contract DiamondBase {
    using DiamondManager for bytes32;
    using DiamondManager for DiamondManager.Data;

    bytes32 immutable _this;

    constructor(string memory _key) payable {
        _this = keccak256(abi.encodePacked(_key));
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
pragma solidity ^0.8.22;

import {DiamondBase} from "./DiamondBase.sol";
import {DiamondManager} from "../DiamondManager.sol";

abstract contract DiamondLoupe is DiamondBase {
    using DiamondManager for bytes32;
    using DiamondManager for DiamondManager.Data;

    constructor(bool _diamond) {
        if (_diamond) {
            bytes4[] memory f = new bytes4[](12);
            f[0] = 0x82431dab;
            f[1] = 0xcdffacc6;
            f[2] = 0x52ef6b2c;
            f[3] = 0xf69f473c;
            f[4] = 0xadfca15e;
            f[5] = 0xf28401a9;
            f[6] = 0x59d96799;
            f[7] = 0x7a0ed627;
            f[8] = 0x8257735f;
            f[9] = 0xc0a43a7c;
            f[10] = 0x01ffc9a7;
            f[11] = 0xc33470d3;
            DiamondManager.internalCut(f, "loupe");
        }
    }

    function facets()
        public
        view
        virtual
        returns (DiamondManager.Facet[] memory)
    {
        address payable diamond = _this.diamond().addr;
        return
            diamond == address(this)
                ? _this.getFacets()
                : DiamondLoupe(diamond).facets(_this);
    }

    function facets(
        bytes32 _contract
    ) public view virtual returns (DiamondManager.Facet[] memory) {
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

interface IKingdom {
    function state() external view returns (bool);

    function setState(bool _state) external;

    function getGame(string memory _title) external view returns (uint);

    function reserve() external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { DiamondFacade } from 'contracts/layout/DiamondFacade.sol';
import { IDiamond } from 'contracts/layout/interfaces/IDiamond.sol';
import { DiamondManager } from 'contracts/layout/DiamondManager.sol';
import { Data } from './shared/Data.sol';

// Fascade factory
contract Kingdom is DiamondFacade {
    using DiamondManager for bytes32;
    using Data for Data.Storage;
    Data.Storage internal $;

    constructor(
        string memory _name,
        address _owner,
        address _reserve,
        address _rToken,
        address _diamond
    ) DiamondFacade('WHOISTHEKING.KINGDOM', _diamond) {
        $.name = _name;
        $.owner = _owner;
        $.foundationDay = block.timestamp;
        $.state = true;
        $.world = _this.diamond().addr;
        $.gcounts = 0;
        $.reserve = _reserve;
        $.rToken = _rToken;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

library Data {
    struct Storage {
        string name; //왕국 이름
        address owner; // 왕국의 주인
        address world; //월드 주소
        address reserve; // reserve 주소
        uint foundationDay; // 건국일
        bool state; // 왕국 상태
        mapping(uint => address) games; // 게임정보
        uint gcounts; // 게임index
        address rToken;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Modifier } from '../shared/Modifier.sol';
import { Type } from 'contracts/types/Type.sol';
import { Kingdom } from 'contracts/services/kingdom/Kingdom.sol';
import { IKingdom } from 'contracts/services/kingdom/IKingdom.sol';
import { IERC20 } from 'contracts/interfaces/IERC20.sol';
import { Errors } from 'contracts/types/Errors.sol';
import { Events } from '../shared/Events.sol';

contract Create is Modifier {
    // 이벤트 오픈
    function openWorldEvent(uint _amount, uint _start, uint _duration) public isOperate permission {
        $.wevents.push(Type.WorldEvent($.wevents.length, _amount, _start, _duration, Type.State.START));
    }

    // 왕국 건설
    function createCastle(string memory _name) public payable {
        if (IERC20($.mainToken).balanceOf(msg.sender) < $.minAmount) revert Errors.INSUFFICIENT_AMOUNT();

        address kingdom = address(new Kingdom(_name, msg.sender, $.reserve, $.mainToken, address(this)));
        $.kingdoms[$.kcounts] = kingdom;
        $.kcounts++;

        IERC20($.mainToken).transferFrom(msg.sender, $.reserve, $.minAmount);
        emit Events.createCastle(block.timestamp, msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Type } from 'contracts/types/Type.sol';

library Data {
    struct Storage {
        mapping(address => bool) permission;
        mapping(uint => mapping(address => bool)) playingKingdom; // 게임에 참여한 왕국 상태
        mapping(uint => uint) playingKingdomCount; // 게임에 참여한 왕국 index,
        mapping(uint => Type.KingdomList[]) playingKingdomList; // 게임에 참여한 왕국 정보
        mapping(uint => address) kingdoms; // 건국된 왕국 정보
        bool operate;
        Type.WorldEvent[] wevents; // 이벤트들
        uint kcounts; // 왕국 갯수
        uint gcounts; // 게임갯수
        uint minAmount; // 건국 토큰 갯수
        address mainToken;
        address reserve;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

interface Events {
    event createCastle(uint indexed _start, address indexed _foundationDay);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import {Data} from "./Data.sol";
import {Errors} from "contracts/types/Errors.sol";

abstract contract Modifier {
    using Data for Data.Storage;
    Data.Storage internal $;

    modifier permission() {
        if (!$.permission[msg.sender]) revert Errors.NO_PERMISSION(msg.sender);
        _;
    }

    modifier isOperate() {
        if (!$.operate) revert Errors.NOT_POSSIBLE();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

interface Errors {
    error NO_PERMISSION(address);
    error NOT_POSSIBLE();
    error INSUFFICIENT_AMOUNT();
    error LOW_VALUE(uint);
    error WRONG_VALUE(uint);
    error ALREADY_REGISTERED();
    error ALREADY_UNSTKAIN();
    error ALREADY_HARVESTED();
    error NOT_AVAILABLE(address);
    error EVENT_STATE(bool);
    error MISMATCH_OWNER();
    error REENTRANCY(bool);
    error NOT_FOUNDED();
    error NOT_YET();
    error WAS_LOOTED();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

// import {Type} from "modules/history/types/Type.sol";

interface Type {
    enum State {
        START,
        END
    }

    struct WorldEvent {
        uint index; // 식별 번호
        uint amount; // 뿌릴양
        uint start; // 시작 시간
        uint duration; // 이벤트 기간
        State state; // 이벤트 상태
        //uint totalCounts; // 왕국 해시 통합 카운트
    }

    // 참여중인 게임 정보
    struct KingdomList {
        address kingdom;
        uint count;
        bool state;
    }

    // 번호
    struct Checker {
        address owner;
        bool state;
    }

    struct Staker {
        uint amount;
        bool staking; // true : staking, false : unstaking
        uint claimTime; // 언스 예정일
        uint claimAmount; // 언스 양
    }
}