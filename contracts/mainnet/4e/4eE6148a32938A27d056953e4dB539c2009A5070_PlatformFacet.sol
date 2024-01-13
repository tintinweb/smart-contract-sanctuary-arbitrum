// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IPlatformFacet} from "../interfaces/internal/IPlatformFacet.sol";
contract PlatformFacet  is IPlatformFacet{
      bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.Platform.diamond.storage");
      struct Platform{
           //eth
           address eth;
           //weth
           address weth;
           //module whiteList  
           mapping(address=>bool)  moduleStatus;  
           address[]  modules;
           
           //protocol Platform
           ProtocolAndA[] protocols;
           //module=>protocol name=>protocol address
           mapping (address=>mapping(string=>address)) moduleToProtocolA; 
           
           address[] tokens;
           //assetList 1 normal 2 aave asset 3 compound asset 4gmx  5 lido asset  6 nft asset
           mapping(address=>uint256) tokenTypes; //asset type

   
 
           //factory use  wallet->vault
           mapping(address=>address[])   walletToVault;
           mapping(address=>uint256)  vaultToSalt;
           mapping(address=>bool)  isVault;

           //vaultImplementation
           address vaultImplementation;
           
           //proxy code
           mapping(bytes32=>bool)  proxyCodeHash;   
      }

      function diamondStorage() internal pure returns (Platform storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
      }
      //set modules  
      function setModules(address[] memory _modules,bool[] memory _status)  external {
                  Platform storage ds = diamondStorage();  
                  for(uint256 i=0;i<_modules.length;i++){       
                  require(_modules[i]!=address(0),"address is zero");   
                  //add module
                  if(_status[i] && !ds.moduleStatus[_modules[i]]){         
                        ds.moduleStatus[_modules[i]]=true;
                        ds.modules.push(_modules[i]);
                  }
                  //delete module   
                  if(!_status[i] && ds.moduleStatus[_modules[i]]){   
                        delete ds.moduleStatus[_modules[i]];
                        uint256 count=ds.modules.length;
                        for(uint256 j=0;j<count;j++){
                        if(ds.modules[j]==_modules[i]){
                              ds.modules[j]=ds.modules[count-1];
                              ds.modules.pop();   
                        }
                        }
                  }
                  }
                  emit SetModules(_modules,_status);
      }

      function getAllModules() external view returns(address[] memory){
            Platform storage ds = diamondStorage();  
            return ds.modules;
      }
      function getModuleStatus(address _module) external view returns(bool){
             Platform storage ds = diamondStorage();  
             return ds.moduleStatus[_module];
      }
      //set protocol
      function setProtocols(address _module,string[] memory _protocols,address[] memory _protocolAddrs)  external {
            Platform storage ds = diamondStorage();
            for(uint256 i=0;i<_protocols.length;i++){       
                //add protocol 
                if(_protocolAddrs[i] != address(0) && ds.moduleToProtocolA[_module][_protocols[i]]== address(0)){
                  ds.moduleToProtocolA[_module][_protocols[i]]=_protocolAddrs[i];
                  ProtocolAndA memory p=ProtocolAndA({
                        addr:_protocolAddrs[i],
                        module:_module,
                        protocol:_protocols[i]
                  });
                  ds.protocols.push(p);
                }
                //delete protocol
                if(_protocolAddrs[i] == address(0)  && ds.moduleToProtocolA[_module][_protocols[i]] != address(0)){        
                  delete ds.moduleToProtocolA[_module][_protocols[i]];    
                  uint256 count=ds.protocols.length;
                  for(uint256 j=0;j<count;j++){             
                       if(keccak256(abi.encodePacked(ds.protocols[j].protocol))==keccak256(abi.encodePacked(_protocols[i]))){
                           ds.protocols[j]=ds.protocols[count-1];
                           ds.protocols.pop();   
                       }
                  }
                }
            }   
            emit SetProtocols(_module,_protocols,_protocolAddrs); 
      }
    
      function getProtocols()  external view returns(ProtocolAndA[] memory){
            Platform storage ds = diamondStorage();  
            return ds.protocols;  
      }

      function getModuleToProtocolA(address _module,string memory _protocol) external view returns(address){
            Platform storage ds = diamondStorage();  
            return ds.moduleToProtocolA[_module][_protocol];
      }

      //set token
      function setTokens(address[] memory _tokens,uint256[] memory _tokenTypes)  external {
            Platform storage ds = diamondStorage();
            for(uint256 i=0;i<_tokens.length;i++){       
                require(_tokens[i]!=address(0),"address is zero");   
                //add token
                if(_tokenTypes[i] !=0 && ds.tokenTypes[_tokens[i]]==0){
                  ds.tokens.push(_tokens[i]);
                  ds.tokenTypes[_tokens[i]]=_tokenTypes[i];
                } 

                //remove token
                if(_tokenTypes[i] ==0 && ds.tokenTypes[_tokens[i]] !=0) {
                  delete ds.tokenTypes[_tokens[i]];
                  uint256 count=ds.tokens.length;
                  for(uint256 j=0;j<count;j++){
                       if(ds.tokens[j]==_tokens[i]){
                           ds.tokens[j]=ds.tokens[count-1];
                           ds.tokens.pop();   
                       }
                  }
                }
            }
            emit SetTokens(_tokens,_tokenTypes);
      }
      function getTokens()  external view returns(address[] memory){
            Platform storage ds = diamondStorage();  
            return ds.tokens;  
      }
      function getTokenType(address _token) external view returns(uint256){
            Platform storage ds = diamondStorage();  
            return ds.tokenTypes[_token];              
      }

      //vaultfactory
    
      function addWalletToVault(address _wallet,address _vault,uint256 _salt) external {
            Platform storage ds = diamondStorage();
            ds.walletToVault[_wallet].push(_vault);
            ds.vaultToSalt[_vault]=_salt;
            ds.isVault[_vault]=true;
            emit AddWalletToVault(_wallet,_vault,_salt);
      }
     
      function removeWalletToVault(address _wallet,address[] memory _vaults) external {
            Platform storage ds = diamondStorage();
            address[] memory vaultList=ds.walletToVault[_wallet];
            uint256 count=vaultList.length;
            for(uint256 i=0;i<_vaults.length;i++){
                 for(uint256 j=0;j<vaultList.length;j++){
                    if(_vaults[i]==vaultList[j]){
                         delete ds.isVault[_vaults[i]];
                         delete ds.vaultToSalt[_vaults[i]];
                         ds.walletToVault[_wallet][j]=ds.walletToVault[_wallet][count-1];
                         ds.walletToVault[_wallet].pop();
                         count--;
                    }
                 } 
            }
            emit RemoveWalletToVault(_wallet,_vaults);

      }
      function getAllVaultByWallet(address _wallet) external view returns(address[] memory) {
            Platform storage ds = diamondStorage();
            return ds.walletToVault[_wallet];
      }
      function getVaultToSalt(address _vault) external view returns(uint256){
            Platform storage ds = diamondStorage();
            return ds.vaultToSalt[_vault];
      }
      function getIsVault(address _vault) external view returns(bool){
            Platform storage ds = diamondStorage();
            return ds.isVault[_vault]; 
      }
     
      function setWeth(address _weth) external{
            Platform storage ds = diamondStorage();
            ds.weth=_weth; 
            emit SetWeth(_weth);
      }

      function getWeth() external view returns(address){
            Platform storage ds = diamondStorage();
            return ds.weth;
      }

      function setEth(address _eth) external {
            Platform storage ds = diamondStorage();
            ds.eth=_eth;
            emit SetEth(_eth);
      }

      function getEth() external view returns(address){
            Platform storage ds = diamondStorage();
            return ds.eth;
      }

      function getVaultImplementation() external view returns(address){
            Platform storage ds=diamondStorage();
            return ds.vaultImplementation;
      }
      
      function setVaultImplementation(address _implementation) external{
            Platform storage ds=diamondStorage();
            ds.vaultImplementation=_implementation;
            emit SetVaultImplementation(_implementation);
      }
      /**
        _option:
           true:add option
           false:delete option      
       */
      function setProxyCodeHash(address _proxy,bool _option) external{
             Platform storage ds=diamondStorage();
             bytes32  hashCode=keccak256(_proxy.code);
             ds.proxyCodeHash[hashCode]=_option;
             emit SetProxyCodeHash(_proxy,_option);
      }

      function getProxyCodeHash(address _proxy) external view returns(bool){
             Platform storage ds=diamondStorage();
             bytes32  hashCode=keccak256(_proxy.code);
             return  ds.proxyCodeHash[hashCode];
      }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IPlatformFacet{
    struct ProtocolAndA{
        address addr;
        address module;
        string  protocol;      
    }
    event SetModules(address[]  _modules,bool[]  _status);
    event SetProtocols(address _module,string[]  _protocols,address[]  _protocolAddrs);
    event SetTokens(address[]  _tokens,uint256[]  _tokenTypes);
    event AddWalletToVault(address _wallet,address _vault,uint256 _salt);
    event RemoveWalletToVault(address _wallet,address[]  _vaults);
    event SetWeth(address _weth);
    event SetEth(address _eth);
    event SetVaultImplementation(address _implementation);
    event SetProxyCodeHash(address _proxy,bool _option);

    function setModules(address[] memory _modules,bool[] memory _status)  external;
    function getAllModules()  external view returns(address[] memory);
    function getModuleStatus(address _module) external view returns(bool);   


    function setProtocols(address _module,string[] memory _protocols,address[] memory _protocolAddrs) external;
    function getProtocols()  external view returns(ProtocolAndA[] memory);
    function getModuleToProtocolA(address _module,string memory _protocol) external view returns(address);


    function setTokens(address[] memory _tokens,uint256[] memory _tokenTypes)  external;
    function getTokens()  external view returns(address[] memory);  
    function getTokenType(address _token) external view returns(uint256);


    function addWalletToVault(address _wallet,address _vault,uint256 _salt) external;
    function removeWalletToVault(address _wallet,address[] memory _vaults) external;
    function getAllVaultByWallet(address _wallet) external view returns(address[] memory);
    function getVaultToSalt(address _vault) external view returns(uint256);
    function getIsVault(address _vault) external view returns(bool);

    function setWeth(address _weth) external;
    function getWeth() external view returns(address);

    function setEth(address _eth) external;
    function getEth() external view returns(address);

    function getVaultImplementation() external view returns(address);
    function setVaultImplementation(address _implementation) external; 
    function setProxyCodeHash(address _proxy,bool _option) external;  
    function getProxyCodeHash(address _proxy) external view returns(bool);
}