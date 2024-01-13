// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IVaultFacet} from "../interfaces/internal/IVaultFacet.sol";

contract VaultFacet is IVaultFacet {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.vault.diamond.storage");
    struct Vault {
        bool lock;
        //1 main  2 loaner  3 debtor  4 follow  5 mirror  6  lender  7 borrower 8 leveragelender 9 leverage borrower
        uint256 vaultType;
        //platform 1  otherVault 2
        uint256 sourceType;
        uint256 time;
        address masterToken;
        address[] modules;
        mapping(address => bool) moduleStatus;
        address[] tokens;
        mapping(address => uint256) tokenTypes;
        address[] protocols;
        mapping(address => bool) protocolStatus;
        mapping(bytes32 => Position) positions;
        mapping(uint16 => bytes32[]) positionKey;
        mapping(bytes4 => bool) funcWhiteList;
        mapping(bytes4 => bool) funcBlackList;
    }

    struct VaultInfo {
        mapping(address => Vault) vaultInfo;
    }

    function diamondStorage() internal pure returns (VaultInfo storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setVaultType(address _vault, uint256 _vaultType) external {
        VaultInfo storage ds = diamondStorage();
        ds.vaultInfo[_vault].vaultType = _vaultType;
        emit SetVaultType(_vault, _vaultType);
    }

    function getVaultType(address _vault) external view returns (uint256) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].vaultType;
    }

    function setSourceType(address _vault, uint256 _sourceType) external {
        VaultInfo storage ds = diamondStorage();
        ds.vaultInfo[_vault].sourceType = _sourceType;
        emit SetSourceType(_vault, _sourceType);
    }

    function getSourceType(address _vault) external view returns (uint256) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].sourceType;
    }

    function setVaultMasterToken(
        address _vault,
        address _masterToken
    ) external {
        VaultInfo storage ds = diamondStorage();
        ds.vaultInfo[_vault].masterToken = _masterToken;
        emit SetVaultMasterToken(_vault, _masterToken);
    }

    function getVaultMasterToken(
        address _vault
    ) external view returns (address) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].masterToken;
    }

    function setVaultLock(address _vault, bool _lock) external {
        VaultInfo storage ds = diamondStorage();
        ds.vaultInfo[_vault].lock = _lock;
        emit SetVaultLock(_vault, _lock);
    }

    function getVaultLock(address _vault) external view returns (bool) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].lock;
    }

    function setVaultTime(address _vault, uint256 _time) external {
        VaultInfo storage ds = diamondStorage();
        ds.vaultInfo[_vault].time = _time;
        emit SetVaultTime(_vault, _time);
    }

    function getVaulTime(address _vault) external view returns (uint256) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].time;
    }

    //module

    function setVaultModules(
        address _vault,
        address[] memory _modules,
        bool[] memory _status
    ) external {
        VaultInfo storage ds = diamondStorage();
        for (uint i; i < _modules.length; i++) {
            require(_modules[i] != address(0), "invalid address");
            //add
            if (_status[i] && !ds.vaultInfo[_vault].moduleStatus[_modules[i]]) {
                ds.vaultInfo[_vault].moduleStatus[_modules[i]] = true;
                ds.vaultInfo[_vault].modules.push(_modules[i]);
            }
            //delete
            if (!_status[i] && ds.vaultInfo[_vault].moduleStatus[_modules[i]]) {
                delete ds.vaultInfo[_vault].moduleStatus[_modules[i]];
                address[] memory temp = ds.vaultInfo[_vault].modules;
                for (uint j; j < temp.length; j++) {
                    if (temp[j] == _modules[i]) {
                        ds.vaultInfo[_vault].modules[j] = ds
                            .vaultInfo[_vault]
                            .modules[temp.length - 1];
                        ds.vaultInfo[_vault].modules.pop();
                    }
                }
            }
        }
        emit SetVaultModules(_vault, _modules, _status);
    }

    function getVaultAllModules(
        address _vault
    ) external view returns (address[] memory) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].modules;
    }

    function getVaultModuleStatus(
        address _vault,
        address _module
    ) external view returns (bool) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].moduleStatus[_module];
    }

    //asset

    function setVaultTokens(
        address _vault,
        address[] memory _tokens,
        uint256[] memory _types
    ) external {
        VaultInfo storage ds = diamondStorage();
        for (uint i; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "invalid address");
            //add
            if (
                _types[i] != 0 &&
                ds.vaultInfo[_vault].tokenTypes[_tokens[i]] == 0
            ) {
                ds.vaultInfo[_vault].tokenTypes[_tokens[i]] = _types[i];
                ds.vaultInfo[_vault].tokens.push(_tokens[i]);
            }
            //delete
            if (
                _types[i] == 0 &&
                ds.vaultInfo[_vault].tokenTypes[_tokens[i]] != 0
            ) {
                delete ds.vaultInfo[_vault].tokenTypes[_tokens[i]];
                address[] memory temp = ds.vaultInfo[_vault].tokens;
                for (uint j; j < temp.length; j++) {
                    if (temp[j] == _tokens[i]) {
                        ds.vaultInfo[_vault].tokens[j] = ds
                            .vaultInfo[_vault]
                            .tokens[temp.length - 1];
                        ds.vaultInfo[_vault].tokens.pop();
                    }
                }
            }
        }
        emit SetVaultTokens(_vault, _tokens, _types);
    }

    function getVaultAllTokens(
        address _vault
    ) external view returns (address[] memory) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].tokens;
    }

    function getVaultTokenType(
        address _vault,
        address _token
    ) external view returns (uint256) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].tokenTypes[_token];
    }

    //prtotcol

    function setVaultProtocol(
        address _vault,
        address[] memory _protocols,
        bool[] memory _status
    ) external {
        VaultInfo storage ds = diamondStorage();
        for (uint i; i < _protocols.length; i++) {
            require(_protocols[i] != address(0), "invalid address");
            //add
            if (
                _status[i] &&
                !ds.vaultInfo[_vault].protocolStatus[_protocols[i]]
            ) {
                ds.vaultInfo[_vault].protocolStatus[_protocols[i]] = true;
                ds.vaultInfo[_vault].protocols.push(_protocols[i]);
            }
            //delete
            if (
                !_status[i] &&
                ds.vaultInfo[_vault].protocolStatus[_protocols[i]]
            ) {
                delete ds.vaultInfo[_vault].protocolStatus[_protocols[i]];
                address[] memory temp = ds.vaultInfo[_vault].protocols;
                for (uint j; j < temp.length; j++) {
                    if (temp[j] == _protocols[i]) {
                        ds.vaultInfo[_vault].protocols[j] = ds
                            .vaultInfo[_vault]
                            .protocols[temp.length - 1];
                        ds.vaultInfo[_vault].protocols.pop();
                    }
                }
            }
        }
        emit SetVaultProtocol(_vault, _protocols, _status);
    }

    function getVaultAllProtocol(
        address _vault
    ) external view returns (address[] memory) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].protocols;
    }

    function getVaultProtocolStatus(
        address _vault,
        address _protocol
    ) external view returns (bool) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].protocolStatus[_protocol];
    }

    /**
        uint16[3] memory _append    
           0:positionType
           1:debtType   
              -normal 0
              -debt  1
           2:option  
              -0  delete
              -1  add
       */

    function setVaultPosition(
        address _vault,
        address _component,
        uint16[3] memory _append
    ) external {
        VaultInfo storage ds = diamondStorage();
        bytes32 key = getPositionKey(_component, uint256(_append[0]));
        uint16 positionType = ds.vaultInfo[_vault].positions[key].positionType;
        uint16 ableUse = ds.vaultInfo[_vault].positions[key].ableUse;
        //delete position
        if (_append[2] == 0 && ableUse == 1) {
            ds.vaultInfo[_vault].positions[key].ableUse = 0;
        }
        //add position(real add)
        if (_append[2] == 1 && positionType == 0) {
            ds.vaultInfo[_vault].positions[key].ableUse = 1;
            ds.vaultInfo[_vault].positions[key].positionType = _append[0];
            ds.vaultInfo[_vault].positions[key].debtType = _append[1];
            ds.vaultInfo[_vault].positions[key].component = _component;
            ds.vaultInfo[_vault].positionKey[_append[0]].push(key);
            // uint16[3] memory a1=[uint16(1),uint16(2),uint16(3)];
        }
        //add postion(edit add)
        if (_append[2] == 1 && positionType != 0 && ableUse == 0) {
            ds.vaultInfo[_vault].positions[key].ableUse = 1;
        }
        emit SetVaultPosition(_vault, _component, _append);
    }

    function setVaultPositionData(
        address _vault,
        address _component,
        uint256 _positionType,
        bytes memory _data
    ) external {
        VaultInfo storage ds = diamondStorage();
        bytes32 key = getPositionKey(_component, _positionType);
        ds.vaultInfo[_vault].positions[key].data = _data;
        emit SetVaultPositionData(_vault, _component, _positionType, _data);
    }

    function setVaultPositionBalance(
        address _vault,
        address _component,
        uint256 _positionType,
        uint256 _balance
    ) external {
        VaultInfo storage ds = diamondStorage();
        bytes32 key = getPositionKey(_component, _positionType);
        ds.vaultInfo[_vault].positions[key].balance = _balance;
        emit SetVaultPositionBalance(
            _vault,
            _component,
            _positionType,
            _balance
        );
    }

    function getVaultAllPosition(
        address _vault,
        uint16[] memory _positionTypes
    ) external view returns (Position[] memory positions) {
        VaultInfo storage ds = diamondStorage();
        uint256 len;
        //get length
        for (uint256 i; i < _positionTypes.length; i++) {
            len += ds.vaultInfo[_vault].positionKey[_positionTypes[i]].length;
        }
        //get data
        positions = new Position[](len);
        len = 0;
        for (uint i; i < _positionTypes.length; i++) {
            uint256 tempLen = ds
                .vaultInfo[_vault]
                .positionKey[_positionTypes[i]]
                .length;
            for (uint j; j < tempLen; j++) {
                bytes32 key = ds.vaultInfo[_vault].positionKey[
                    _positionTypes[i]
                ][j];
                positions[len] = ds.vaultInfo[_vault].positions[key];
                len++;
            }
        }
    }

    function getVaultProtocolPosition(
        address _vault,
        uint16 _positionType
    ) external view returns (Position[] memory positions) {
        VaultInfo storage ds = diamondStorage();
        uint256 len = ds.vaultInfo[_vault].positionKey[_positionType].length;
        positions = new Position[](len);
        for (uint i; i < len; i++) {
            bytes32 key = ds.vaultInfo[_vault].positionKey[_positionType][i];
            positions[i] = ds.vaultInfo[_vault].positions[key];
        }
    }

    function getVaultPosition(
        address _vault,
        address _component,
        uint256 _positionType
    ) external view returns (Position memory position) {
        VaultInfo storage ds = diamondStorage();
        bytes32 key = getPositionKey(_component, _positionType);
        position = ds.vaultInfo[_vault].positions[key];
    }

    function getPositionKey(
        address _asset,
        uint256 _debtType
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_asset, _debtType));
    }

    function setFuncWhiteList(
        address _vault,
        bytes4 _func,
        bool _type
    ) external {
        require(_func != bytes4(0), "VaultFacet:invalid func");
        VaultInfo storage ds = diamondStorage();
        if (_type) {
            ds.vaultInfo[_vault].funcWhiteList[_func] = true;
        } else {
            delete ds.vaultInfo[_vault].funcWhiteList[_func];
        }
        emit SetFuncWhiteList(_vault, _func, _type);
    }

    function getFuncWhiteList(
        address _vault,
        bytes4 _func
    ) external view returns (bool) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].funcWhiteList[_func];
    }

    function setFuncBlackList(
        address _vault,
        bytes4 _func,
        bool _type
    ) external {
        require(_func != bytes4(0), "VaultFacet:invalid func");
        VaultInfo storage ds = diamondStorage();
        if (_type) {
            ds.vaultInfo[_vault].funcBlackList[_func] = true;
        } else {
            delete ds.vaultInfo[_vault].funcBlackList[_func];
        }
        emit SetFuncBlackList(_vault, _func, _type);
    }

    function getFuncBlackList(
        address _vault,
        bytes4 _func
    ) external view returns (bool) {
        VaultInfo storage ds = diamondStorage();
        return ds.vaultInfo[_vault].funcBlackList[_func];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IVaultFacet{
      struct Position{  
           uint16  positionType;  //1 normal 2 aave asset 3 compound asset 4gmx  asset  5 lido asset  6 nft asset
           uint16  debtType;   // 0 normal    1  debt           
           uint16 ableUse;   // 0 unused   1 used
           address component; 
           uint256 balance;
           bytes data; 
      }
     event SetVaultType(address _vault,uint256 _vaultType);
     event SetSourceType(address _vault,uint256 _sourceType);
     event SetVaultMasterToken(address _vault,address _masterToken);
     event SetVaultLock(address _vault,bool _lock);
     event SetVaultTime(address _vault,uint256 _time);
     event SetVaultModules(address _vault,address[]  _modules,bool[]  _status);
     event SetVaultTokens(address _vault,address[] _tokens,uint256[]  _types);
     event SetVaultProtocol(address _vault,address[]  _protocols,bool[]  _status);
     event SetVaultPosition(address _vault,address _component,uint16[3]  _append);
     event SetVaultPositionData(address _vault,address _component,uint256 _positionType,bytes  _data);
     event SetVaultPositionBalance(address _vault,address _component,uint256 _positionType,uint256 _balance);  
    
     event SetFuncWhiteList(address _vault,bytes4 _func,bool _type);
     event SetFuncBlackList(address _vault,bytes4 _func,bool _type);



     function setVaultType(address _vault,uint256 _vaultType) external;
     function getVaultType(address _vault) external view returns(uint256);
     function setSourceType(address _vault,uint256 _sourceType) external;
     function getSourceType(address _vault) external view returns(uint256);
     
     function setVaultMasterToken(address _vault,address _masterToken) external;
     function getVaultMasterToken(address _vault) external view returns(address);
     
     function setVaultLock(address _vault,bool _lock) external;
     function getVaultLock(address _vault) external view returns(bool);
     function setVaultTime(address _vault,uint256 _time) external;
     function getVaulTime(address _vault) external view returns(uint256);


     function setVaultModules(address _vault,address[] memory _modules,bool[] memory _status) external; 
     function getVaultAllModules(address _vault) external view returns(address[] memory);
     function getVaultModuleStatus(address _vault,address _module) external view returns(bool);

     function setVaultTokens(address _vault,address[] memory _tokens,uint256[] memory _status) external;
     function getVaultAllTokens(address _vault) external view returns(address[] memory);
     function getVaultTokenType(address _vault,address _token) external view returns(uint256);

     function setVaultProtocol(address _vault,address[] memory _protocols,bool[] memory _status) external;
     function getVaultAllProtocol(address _vault) external view returns(address[] memory);
     function getVaultProtocolStatus(address _vault,address  _protocol) external view returns(bool);

     function setVaultPosition(address _vault,address _component,uint16[3] memory _append) external;
     function setVaultPositionData(address _vault,address _component,uint256 _positionType,bytes memory _data) external;
     function getVaultAllPosition(address _vault,uint16[] memory _positionTypes) external view returns(Position[] memory positions);
     function getVaultProtocolPosition(address _vault,uint16 _positionType) external view returns(Position[] memory positions);
     function getVaultPosition(address _vault,address _component, uint256 _positionType) external view returns(Position memory position);
    
     function setFuncWhiteList(address _vault,bytes4 _func,bool _type) external;
     function getFuncWhiteList(address _vault,bytes4 _func) external view returns(bool);
     function setFuncBlackList(address _vault,bytes4 _func,bool _type) external;
     function getFuncBlackList(address _vault,bytes4 _func) external view returns(bool);
}