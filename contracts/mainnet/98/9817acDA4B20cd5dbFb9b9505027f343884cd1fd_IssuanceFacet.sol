// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {IIssuanceFacet} from "../interfaces/internal/IIssuanceFacet.sol";
contract IssuanceFacet is IIssuanceFacet{
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.IssuanceFacet.diamond.storage");
    struct IssuanceSetting{
           //0 default 1 normal  2 proxy  3 both
           mapping(address => IssueMode) issueMode;
           mapping(address => address) issuer;
           mapping(address => mapping(address=> bool)) proxyIssueWhiteList;
    }

    function diamondStorage() internal pure returns (IssuanceSetting storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function getIssueMode(address _vault) external view returns(IssueMode){
        IssuanceSetting storage ds = diamondStorage();  
        return ds.issueMode[_vault];
    }
    function setIssueMode(address _vault,IssueMode _mode) external {
        IssuanceSetting storage ds = diamondStorage();   
        if(ds.issueMode[_vault] !=_mode){
            ds.issueMode[_vault]=_mode;
            emit SetIssueMode(_vault,_mode);
        }     
    }
    function getIssuer(address _vault) external view returns(address){
        IssuanceSetting storage ds = diamondStorage();   
        return ds.issuer[_vault];
    }

    function setIssuer(address _vault,address _issuer) external {
        IssuanceSetting storage ds = diamondStorage(); 
        if(_issuer == address(0)){
            delete  ds.issuer[_vault];
        }else{
            ds.issuer[_vault]=_issuer;
        } 
        emit SetIssuer(_vault,_issuer);
    }

    function setProxyIssueWhiteList(address _vault,address _issuer,bool _status) external{
        IssuanceSetting storage ds = diamondStorage(); 
        if(_status){
            ds.proxyIssueWhiteList[_vault][_issuer]=_status;
        }else{
            delete ds.proxyIssueWhiteList[_vault][_issuer];
        }
        emit SetProxyIssueWhiteList(_vault,_issuer,_status);
    }

    function getProxyIssueWhiteList(address _vault,address _issuer) external view returns(bool){
        IssuanceSetting storage ds = diamondStorage(); 
        return  ds.proxyIssueWhiteList[_vault][_issuer];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface IIssuanceFacet{
    enum IssueMode{
        Default,
        Normal,
        Proxy
    }
    event SetIssueMode(address _vault,IssueMode _mode);
    event SetIssuer(address _vault,address _issuer);
    event SetProxyIssueWhiteList(address _vault,address _issuer,bool _status);
    function getIssueMode(address _vault) external view returns(IssueMode);
    function setIssueMode(address _vault,IssueMode _mode) external; 
    function getIssuer(address _vault) external view returns(address);
    function setIssuer(address _vault,address _issuer) external;
    function setProxyIssueWhiteList(address _vault,address _issuer,bool _status) external;
    function getProxyIssueWhiteList(address _vault,address _issuer) external view returns(bool);
}