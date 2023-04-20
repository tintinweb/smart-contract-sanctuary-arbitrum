/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

// SPDX-License-Identifier: MIT
// File: contract/interfaces/IReferralProgram.sol


pragma solidity ^0.8.0;

interface IReferralProgram {
    function registerCode(bytes32 _code) external;
    function setReferralCode(address _account, bytes32 _code) external;
    function setReferralCodeByUser(bytes32 _code) external;
    function getReferralInfo(address _account) external view returns (bytes32, address, bytes32, uint256);
    function isRefCodeExist(bytes32 _code) external view returns (bool);
}

// File: contract/access/Governable.sol



pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}
// File: contract/ReferralProgram.sol



pragma solidity ^0.8.0;



contract ReferralProgram is Governable, IReferralProgram {
    uint256 public activeUsers;
    mapping (address => bool) public isHandler;
    mapping (address => bytes32) public refCodes;
    mapping (address => uint256) public refCounts;
    mapping (bytes32 => address) public refCodeOwners;
    mapping (address => bytes32) public beRefCodes;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event RegisterCode(address account, bytes32 code);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralProgram: forbidden");
        _;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setReferralCode(address _account, bytes32 _code) external override onlyHandler {
        _setReferralCode(_account, _code);
    }

    function setReferralCodeByUser(bytes32 _code) external override{
        _setReferralCode(msg.sender, _code);
    }

    function _setReferralCode(address _account, bytes32 _code) private {
        require(_code != bytes32(0), "ReferralProgram: invalid _code");
        require(beRefCodes[_account] == bytes32(0), "ReferralProgram: already exists");
        address codeOwner = refCodeOwners[_code];
        require(codeOwner != address(0), "ReferralProgram: code not exists");
        require(codeOwner != _account, "ReferralProgram: forbidden do self-ref");

        uint256 refCount = refCounts[codeOwner];
        beRefCodes[_account] = _code;
        refCounts[codeOwner] = refCount + 1;
        require(refCount == refCounts[codeOwner] - 1, "ReferralProgram: nonReentrant");
        activeUsers++;
        emit SetTraderReferralCode(_account, _code);
    }

    function registerCode(bytes32 _code) external override{
        require(_code != bytes32(0), "ReferralProgram: invalid _code");
        require(refCodes[msg.sender] == bytes32(0), "ReferralProgram: already registered");
        require(refCodeOwners[_code] == address(0), "ReferralProgram: code already exists");
        refCodes[msg.sender] = _code;
        refCodeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function getReferralInfo(address _account) external override view returns (bytes32, address, bytes32, uint256) {
        bytes32 beRefCode = beRefCodes[_account];
        address beRef;
        if (beRefCode != bytes32(0)) {
            beRef = refCodeOwners[beRefCode];
        }
        bytes32 refCode = refCodes[_account];
        uint256 refCount = refCounts[_account];
        return (beRefCode, beRef, refCode, refCount);
    }

    function isRefCodeExist(bytes32 _code) external override view returns (bool) {
        return refCodeOwners[_code] != address(0);
    }

}