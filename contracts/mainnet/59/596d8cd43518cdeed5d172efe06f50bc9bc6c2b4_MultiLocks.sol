// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

 /**
 * MultiLocks allows you to create a pool for locking tokens.
 * Important! Tokens with taxes and fees do not work. It is required to include the pool as an exception for taxes.
 * Do Your Own Research (DYOR).
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./MultiLockPool.sol";
import "./Wallet.sol";
import "./TaxCreationBlock.sol";
import "./TokenInfo.sol";

interface iMLPool {
    function initPool(address _aToken, uint256 _nMLPool, address _aMLs, uint256 _typeToken) external returns (bool);
    function getMLPoolDataArr(address _aOwner, uint256 _key, uint256 _n) external view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory);
    function getMLPoolDataArrByLockID(uint256 LockID, uint256 _n) external view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory);
}

contract MultiLocks is Wallet, TaxCreationBlock, TokenInfo {

    event NewContractMLDeployed(address indexed newAContract, uint256 indexed nMLPool);

    uint256 public version=1;
    uint256 public nPools = 0;
    uint256 public nType = 0;
    uint256 public nTypeLP = 0;

    // mMLPools[aToken] = nMLPool
    mapping(address => uint256) public mMLPools;

    // mMLPoolsContracts[aPool] = nMLPool
    mapping(address => uint256) public mMLPoolsContracts;

    // mMLPoolsTypeToken[_key] = nMLPool
    mapping(uint256 => uint256) public mMLPoolsTypeToken;

    // mMLPoolsTypeLPToken[_key] = nMLPool
    mapping(uint256 => uint256) public mMLPoolsTypeLPToken;

    struct MLPoolData {
        uint256 nMLPool;
        address aPool;
        address aToken;
        uint256 typeToken;
        uint256 cTime;
        //address addressOwner;
    }
    // mPData[nMLPool] = MLPoolData
    mapping(uint256 => MLPoolData) public mPData;

    function getVersion() public view returns (uint256) {
        return version;
    }

    function getMLPoolAllData(uint256 _nMLPool, address _aOwner, uint256 _key, uint256 _n) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256[] memory nArr = new uint256[](50);
        address[] memory aArr = new address[](50);
        bool[] memory bArr = new bool[](50);
        string[] memory sArr = new string[](50);

        if(mPData[_nMLPool].nMLPool==0){
            return (nArr, aArr, bArr, sArr);
        }

        (nArr, aArr, bArr, sArr) = iMLPool(mPData[_nMLPool].aPool).getMLPoolDataArr(_aOwner, _key, _n);

        nArr[40] = version;
        nArr[41] = mPData[_nMLPool].cTime;

        return (nArr, aArr, bArr, sArr);
    }

    function getMLPoolAllDataByLockID(uint256 _nMLPool, uint256 _LockID, uint256 _n) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256[] memory nArr = new uint256[](50);
        address[] memory aArr = new address[](50);
        bool[] memory bArr = new bool[](50);
        string[] memory sArr = new string[](50);

        if(mPData[_nMLPool].nMLPool==0){
            return (nArr, aArr, bArr, sArr);
        }

        (nArr, aArr, bArr, sArr) = iMLPool(mPData[_nMLPool].aPool).getMLPoolDataArrByLockID(_LockID, _n);

        nArr[40] = version;
        nArr[41] = mPData[_nMLPool].cTime;

        return (nArr, aArr, bArr, sArr);
    }

    function getMLPoolAllDataByContract(address _aMLPool, address _aOwner, uint256 _key, uint256 _n) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256 _nMLPool = mMLPoolsContracts[_aMLPool];
        return getMLPoolAllData(_nMLPool, _aOwner, _key, _n);
    }

    function getMLPoolAllDataByTokens(address _aToken, address _aOwner, uint256 _key, uint256 _n) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256 _nMLPool = mMLPools[_aToken];
        return getMLPoolAllData(_nMLPool, _aOwner, _key, _n);
    }

    function getMLPoolAllDataByTypeToken(uint256 _typeToken, uint256 _keyTypeToken, address _aOwner, uint256 _key, uint256 _n) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256 _nMLPool = 0;
        if(_typeToken==1){
            _nMLPool = mMLPoolsTypeLPToken[_keyTypeToken];
        } else {
            _nMLPool = mMLPoolsTypeToken[_keyTypeToken];
        }
        return getMLPoolAllData(_nMLPool, _aOwner, _key, _n);
    }

    function deployContractMLPool(address aToken) public {
        require(mMLPools[aToken] == 0, "exists");

        uint256 _typeToken = 0;
        if(isLiquidityPool(aToken)){
            _typeToken = 1;
        }

        nPools++;

        MultiLockPool MLPool1 = new MultiLockPool();
        address aPool = address(MLPool1);

        iMLPool(aPool).initPool(aToken, nPools, address(this), _typeToken);

        mMLPools[aToken] = nPools;
        mMLPoolsContracts[aPool] = nPools;

        mPData[nPools].nMLPool = nPools;
        mPData[nPools].aPool = aPool;
        mPData[nPools].aToken = aToken;
        mPData[nPools].typeToken = _typeToken;
        mPData[nPools].cTime = block.timestamp;

        if(_typeToken==1){
            nTypeLP++;
            mMLPoolsTypeLPToken[nTypeLP] = nPools;
        } else {
            nType++;
            mMLPoolsTypeToken[nType] = nPools;
        }

        emit NewContractMLDeployed(aPool, nPools);
    }
}

// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

pragma solidity >=0.8.0;

import "./IERC20.sol";

contract TokenInfo {

    constructor () {}

    // _nameMethod = "owner()"
    function hasMethod(address _cAddress, string memory _nameMethod) public view returns (bool) {
        (bool success, ) = _cAddress.staticcall(abi.encodeWithSignature(_nameMethod));
        return success;
    }

    function isLiquidityPool(address _aToken) public view returns (bool) {
        if(!hasMethod(_aToken, "price1CumulativeLast()")){ return false; }
        return true;
    }

    function tOwner(address _aToken) public view returns (address) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature("owner()"));

        if (success && result.length > 0) {
            return abi.decode(result, (address));
        } else {
            return address(0);
        }
    }

    function getFunStr(address _aToken, string memory nameFun) public view returns (string memory) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature(nameFun));

        if (success && result.length > 0) {
            return abi.decode(result, (string));
        } else {
            return '';
        }
    }

    function getFunNum(address _aToken, string memory nameFun) public view returns (uint256) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature(nameFun));

        if (success && result.length > 0) {
            return abi.decode(result, (uint256));
        } else {
            return 0;
        }
    }

    function getFunAddr(address _aToken, string memory nameFun) public view returns (address) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature(nameFun));

        if (success && result.length > 0) {
            return abi.decode(result, (address));
        } else {
            return address(0);
        }
    }

    function tName(address _aToken) public view returns (string memory) {
        return getFunStr(_aToken, "name()");
    }

    function tSymbol(address _aToken) public view returns (string memory) {
        return getFunStr(_aToken, "symbol()");
    }

    function tDecimals(address _aToken) public view returns (uint256) {
        return getFunNum(_aToken, "decimals()");
    }

    function tTotalSupply(address _aToken) public view returns (uint256) {
        return getFunNum(_aToken, "totalSupply()");
    }

    function tBalanceOf(address _aToken, address _aAccount) public view returns (uint256) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature("balanceOf(address)", _aAccount));

        if (success && result.length > 0) {
            return abi.decode(result, (uint256));
        } else {
            return 0;
        }
    }

    function tAllowance(address _aToken, address _aAccount, address _aSpender) public view returns (uint256) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature("allowance(address,address)", _aAccount, _aSpender));

        if (success && result.length > 0) {
            return abi.decode(result, (uint256));
        } else {
            return 0;
        }
    }

    function getPairFactory(address _aToken) public view returns (address) {
        return getFunAddr(_aToken, "factory()");
    }

    function getPairToken0(address _aToken) public view returns (address) {
        return getFunAddr(_aToken, "token0()");
    }

    function getPairToken1(address _aToken) public view returns (address) {
        return getFunAddr(_aToken, "token1()");
    }

}

// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";

contract TaxCreationBlock is Ownable {
    uint256 public taxCreation = 10000000000000000; // 0.01
    address public taxCreationAddress = address(this); // 0.01

    function setTaxCreation(uint256 _amountTax) public onlyOwner {
        taxCreation = _amountTax;
        return;
    }

    function setTaxCreationAddress(address _addressTax) public onlyOwner {
        taxCreationAddress = _addressTax;
        return;
    }

    function sendTaxCreation() payable public {
        require(msg.value >= taxCreation, "taxCreation error");
        if(taxCreationAddress!=address(this)){
            payable(taxCreationAddress).transfer(taxCreation);
        }
        return;
    }
}

// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Wallet is Ownable {
    receive() external payable {}
    fallback() external payable {}

    // Transfer Eth
    function transferEth(address _to, uint256 _amount) public onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // Transfer Tokens
    function transferTokens(address addressToken, address _to, uint256 _amount) public onlyOwner {
        IERC20 contractToken = IERC20(addressToken);
        contractToken.transfer(_to, _amount);
    }

}

// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

/**
 * The pool was created for locking tokens.
 * This smart contract allows you to deposit tokens and set the time for their unlocking.
 * The smart contract supports vesting period.
 * The smart contract supports multi-locking from multiple locks.
 * Methods for creating locks: addMultiLock and addVesting
 * Methods for claiming tokens: claimTokens and claimTokensV
 * Important! Tokens with taxes and fees do not work. It is required to include the this pool as an exception for taxes.
 * Do Your Own Research (DYOR).
 */

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./TokenInfo.sol";

interface iMultiLocks {
    function sendTaxCreation() payable external;
}

contract MultiLockPool is TokenInfo {

    using SafeMath for uint256;

    uint256 public typeToken; // 0 - simpleToken, 1 - LP Token
    address public aMultiLocks;
    uint256 public nMLPool;
    address public aMLToken;

    constructor() {}

    bool public initializePool = false;
    function initPool(address _aToken, uint256 _nMLPool, address _aMultiLocks, uint256 _typeToken) public returns (bool) {
        require(initializePool == false, "initialized");
        initializePool = true;

        typeToken = _typeToken;
        aMultiLocks = _aMultiLocks;
        nMLPool = _nMLPool;
        aMLToken = _aToken;

        return true;
    }

    // ExtData info
    struct structExtData {
        uint256 lastID;
        uint256 totalUsers;
        uint256 totalAmount;
        uint256 sentAmount;
    }

    structExtData public ExtData;

    // Owner info
    struct OwnerInfo {
        uint256 lastKey;
        uint256 totalAmount;
        uint256 sentAmount;
    }
    // mOwnI[aOwner] = OwnerInfo
    mapping(address => OwnerInfo) public mOwnI;

    // Lock data
    struct LockData {
        address aOwner;
        uint256 keyOwner;
        uint256 amount;
        uint256 sTime;
        uint256 fTime;
        uint256 returnedTime;
        uint256 vPeriod;
        uint256 vPerc;
        bool returned;
        string sTextData;
    }

    // mLD[LockID] = LockData
    mapping(uint256 => LockData) public mLD;

    // mappingLockVesting[LockID][_n] = returnedTime;
    mapping(uint256 => mapping(uint256 => uint256)) public mLockVesting;

    // mOwn[aOwner][_key] = LockID
    mapping(address => mapping(uint256 => uint256)) public mOwn;

    // add MultiLock data
    function addMultiLockData(
        address[] memory _aOwnerArr,
        uint256[] memory _nArr,
        uint256[] memory _fTimeArr,
        string memory _sTextData
    ) internal {
        require(_aOwnerArr.length == _fTimeArr.length, "_aOwnerArr, _fTimeArr");
        require(_aOwnerArr.length == _nArr.length, "_aOwnerArr, _nArr");

        uint256 bBefore = tBalanceOf(aMLToken, address(this));
        uint256 SumTokens = 0;
        for (uint i; i < _aOwnerArr.length; i++) {
            SumTokens = SumTokens.add(_nArr[i]);

            ExtData.lastID++;

            mOwnI[_aOwnerArr[i]].lastKey = mOwnI[_aOwnerArr[i]].lastKey+1;
            mOwnI[_aOwnerArr[i]].totalAmount = mOwnI[_aOwnerArr[i]].totalAmount.add(_nArr[i]);

            mOwn[_aOwnerArr[i]][mOwnI[_aOwnerArr[i]].lastKey] = ExtData.lastID;

            mLD[ExtData.lastID].aOwner = _aOwnerArr[i];
            mLD[ExtData.lastID].keyOwner = mOwnI[_aOwnerArr[i]].lastKey;
            mLD[ExtData.lastID].amount = _nArr[i];
            mLD[ExtData.lastID].sTime = block.timestamp;
            mLD[ExtData.lastID].fTime = _fTimeArr[i];
            mLD[ExtData.lastID].returnedTime = 0;
            mLD[ExtData.lastID].returned = false;
            mLD[ExtData.lastID].sTextData = _sTextData;

            if(mOwnI[_aOwnerArr[i]].lastKey==1){
                ExtData.totalUsers = ExtData.totalUsers.add(1);
            }
            ExtData.totalAmount = ExtData.totalAmount.add(_nArr[i]);
        }

        require(IERC20(aMLToken).transferFrom(msg.sender, address(this), SumTokens), "TransferFrom");
        require(bBefore.add(SumTokens) >= tBalanceOf(aMLToken, address(this)), "Balance");
    }

        // add Vesting data
    function addVestingData(address _aOwner, uint256 _nTokens, uint256 _sTime, uint256 _vPeriod, uint256 _vPerc, string memory _sTextData) internal {
        require(_vPeriod > 0, "vPeriod");
        require(100 % _vPerc == 0, "vPerc: 1,2,4,5,10,20,25,50,100");
        require(_vPerc < 100, "_vPerc");

        address[] memory _aOwnerArr = new address[](1);
        _aOwnerArr[0] = _aOwner;
        uint256[] memory _nArr = new uint256[](1);
        _nArr[0] = _nTokens;
        uint256[] memory _fTimeArr = new uint256[](1);
        _fTimeArr[0] = _sTime;
        addMultiLockData(_aOwnerArr, _nArr, _fTimeArr, _sTextData);

        mLD[ExtData.lastID].vPeriod = _vPeriod;
        mLD[ExtData.lastID].vPerc = _vPerc;
    }

    /**
     * Add MultiLock
     * _nArr - amount Arr
     * _fTimeArr - finish Time Arr
     */
    function addMultiLock(
        address[] memory _aOwnerArr,
        uint256[] memory _nArr,
        uint256[] memory _fTimeArr, 
        string memory _sTextData
    ) public payable returns (bool) {
        iMultiLocks(aMultiLocks).sendTaxCreation{value: msg.value}();
        addMultiLockData(_aOwnerArr, _nArr, _fTimeArr, _sTextData);
        return true;
    }

    /**
     * Add Vesting
     */
    function addVesting(
        address _aOwner,
        uint256 _nTokens,
        uint256 _sTime,
        uint256 _vPeriod,
        uint256 _vPerc, 
        string memory _sTextData
    ) public payable returns (bool) {
        iMultiLocks(aMultiLocks).sendTaxCreation{value: msg.value}();
        addVestingData(_aOwner, _nTokens, _sTime, _vPeriod, _vPerc, _sTextData);
        return true;
    }

    // Show current timestamp
    function showTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    // Send Owner
    function sendOwner(address _aOwner, uint256 _key) internal {
        require(mOwnI[_aOwner].lastKey >= _key, "_key not found");
        uint256 LockID = mOwn[_aOwner][_key];

        require(mLD[LockID].vPeriod == 0, "is vesting");

        require(!mLD[LockID].returned, "already returned");
        require(block.timestamp > mLD[LockID].fTime, "token is locked");

        ExtData.sentAmount = ExtData.sentAmount.add(mLD[LockID].amount);
        mOwnI[_aOwner].sentAmount = mOwnI[_aOwner].sentAmount.add(mLD[LockID].amount);
        mLD[LockID].returned = true;
        mLD[LockID].returnedTime = block.timestamp;

        require(IERC20(aMLToken).transfer(_aOwner, mLD[LockID].amount), "Transfer");
    }

    function nPerc(uint256 _n, uint256 _p) public pure returns (uint256) {
        return _n.mul(_p).div(100);
    }

    // Send Owner Vesting
    function sendOwnerV(address _aOwner, uint256 _key, uint256 _n) internal {
        require(mOwnI[_aOwner].lastKey >= _key, "_key not found");
        uint256 LockID = mOwn[_aOwner][_key];

        require(mLD[LockID].vPeriod > 0, "not vesting");

        require(mLockVesting[LockID][_n] == 0, "already returned");
        uint256 _nMax = 100/mLD[LockID].vPerc;
        require(_n > 0 && _n <= _nMax, "_n");

        uint256 UnTime = mLD[LockID].fTime.add(mLD[LockID].vPeriod.mul(60).mul(_n));
        require(block.timestamp > UnTime, "token is locked");

        uint256 TokensSent = nPerc(mLD[LockID].amount, mLD[LockID].vPerc);

        ExtData.sentAmount = ExtData.sentAmount.add(TokensSent);
        mOwnI[_aOwner].sentAmount = mOwnI[_aOwner].sentAmount.add(TokensSent);

        mLockVesting[LockID][_n] = block.timestamp;

        require(IERC20(aMLToken).transfer(_aOwner, TokensSent), "Transfer");
    }

    function claimTokens(uint256 _key) public returns (bool) {
        sendOwner(msg.sender, _key);
        return true;
    }

    function claimTokensV(uint256 _key, uint256 _n) public returns (bool) {
        sendOwnerV(msg.sender, _key, _n);
        return true;
    }

    function getMLPoolDataArrByLockID(uint256 LockID, uint256 _n) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        return getMLPoolDataArr(mLD[LockID].aOwner, mLD[LockID].keyOwner, _n);
    }

    function getMLPoolDataArr(address _aOwner, uint256 _key, uint256 _n) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        address[] memory aArr = new address[](50);
        aArr[0] = address(this);
        aArr[1] = aMLToken;
        aArr[2] = _aOwner;

        if(typeToken==1){ // LP
            aArr[11] = getPairFactory(aMLToken);
            aArr[12] = getPairToken0(aMLToken);
            aArr[13] = getPairToken1(aMLToken);

            aArr[14] = tOwner(aArr[12]);
            aArr[15] = tOwner(aArr[13]);
        } else {
            aArr[10] = tOwner(aMLToken);
        }
        
        uint256[] memory nArr = new uint256[](50);
        nArr[0] = nMLPool;
        nArr[1] = _key;
        nArr[2] = mOwnI[_aOwner].lastKey;
        nArr[3] = mOwnI[_aOwner].totalAmount;
        nArr[4] = mOwnI[_aOwner].sentAmount;

        uint256 LockID = mOwn[_aOwner][_key];

        nArr[5] = mLD[LockID].amount;
        nArr[6] = mLD[LockID].sTime;
        nArr[7] = mLD[LockID].fTime;
        nArr[8] = mLD[LockID].returnedTime;

        nArr[10] = tDecimals(aMLToken);
        nArr[11] = tTotalSupply(aMLToken);

        nArr[12] = tBalanceOf(aMLToken, _aOwner);
        nArr[13] = tAllowance(aMLToken, _aOwner, address(this));

        nArr[14] = ExtData.lastID;
        nArr[15] = ExtData.totalUsers;
        nArr[16] = ExtData.totalAmount;
        nArr[17] = ExtData.sentAmount;

        nArr[18] = typeToken;

        if(typeToken==1){ // LP
            nArr[20] = tDecimals(aArr[12]);
            nArr[21] = tTotalSupply(aArr[12]);

            nArr[22] = tBalanceOf(aArr[12], _aOwner);
            nArr[23] = tAllowance(aArr[12], _aOwner, address(this));

            nArr[24] = tDecimals(aArr[13]);
            nArr[25] = tTotalSupply(aArr[13]);

            nArr[26] = tBalanceOf(aArr[13], _aOwner);
            nArr[27] = tAllowance(aArr[13], _aOwner, address(this));
        }

        nArr[28] = mLD[LockID].vPeriod;
        nArr[29] = mLD[LockID].vPerc;
        nArr[30] = mLockVesting[LockID][_n];

        bool[] memory bArr = new bool[](50);
        bArr[0] = mLD[LockID].returned;

        // sArr
        string[] memory sArr = new string[](50);
        sArr[0] = tName(aMLToken);
        sArr[1] = tSymbol(aMLToken);
        
        if(typeToken==1){ // LP
            sArr[2] = tName(aArr[12]);
            sArr[3] = tSymbol(aArr[12]);

            sArr[4] = tName(aArr[13]);
            sArr[5] = tSymbol(aArr[13]);
        }

        sArr[10] = mLD[LockID].sTextData;

        return (nArr, aArr, bArr, sArr);
    }

}

// SPDX-License-Identifier: MIT

/**
 * contract Ownable
 */

pragma solidity >=0.8.0;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "onlyOwner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

/**
 * interface IERC20
 */

pragma solidity >=0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function owner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    //event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

/**
 * abstract contract Context
 */

pragma solidity >=0.8.0;

abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    //constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

/**
 * Library for mathematical operations
 */

pragma solidity >=0.8.0;

// @dev Wrappers over Solidity's arithmetic operations with added overflow * checks.
library SafeMath {
    // Counterpart to Solidity's `+` operator.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    // Counterpart to Solidity's `*` operator.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}