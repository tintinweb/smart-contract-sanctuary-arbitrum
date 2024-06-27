/**
 *Submitted for verification at Arbiscan.io on 2024-06-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
pragma abicoder v2;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


interface IVELAV2_PriceManager{
    function setPrice(uint256 _assetId, uint256 _price, uint256 _ts) external; //11+assetId PriceManager
    function getLastPrice(uint256 _assetId) external view returns (uint256);
}

interface IVELAV2_LiquidateVault{
    function liquidatePosition(uint256 _posId) external; //1 LiquidateVault
}

struct Position {
    address owner;
    address refer;
    bool isLong;
    uint256 tokenId;
    uint256 averagePrice;
    uint256 collateral;
    int256 fundingIndex;
    uint256 lastIncreasedTime;
    uint256 size;
    uint256 accruedBorrowFee;
}
interface IVELAV2_PositionVault{
    function getNumOfUnexecuted() external view returns (uint256);
    function executeOrders(uint256 numOfOrders) external;

    function getPosition(uint256 _posId) external view returns (Position memory);
    function queueIndex() external view returns(uint256);
    function queuePosIds(uint256) external view returns(uint256);
}

interface IVELAV2_OrderVault{
    function triggerForOpenOrders(uint256 _posId) external; //2 
    function triggerForTPSL(uint256 _posId) external; //3 
    function updateTrailingStop(uint256 _posId) external; //4
    function triggerForAddPositionTrigger(uint256 _addPositionTriggerId) external;
    function getPosAddPositionTriggerIds(
        uint256 _posId
    ) external view returns (uint256[] memory _addPositionTriggerIds);
}

interface IVELAV2_Vault{
    function withdraw(address _token,uint256 _amount) external payable;
    function forceClosePosition(uint256 _posId) external;
}

interface IVELAV2_SettingsManager{
    function feeManager() external view returns(address);
}

IVELAV2_PriceManager constant PriceManager = IVELAV2_PriceManager(0xC8e027C40B25C4Cd0c059763D042e79466D7bBB6);
IVELAV2_LiquidateVault constant LiquidateVault = IVELAV2_LiquidateVault(0x361A5F8fA6860B5f5C021A5Dd370C1180010A561);
IVELAV2_PositionVault constant PositionVault = IVELAV2_PositionVault(0x8B97E18eE706d056A5659947a717A7971003f524);
IVELAV2_OrderVault constant OrderVault = IVELAV2_OrderVault(0x52AC3eda13EB7959f918Df02a72d0f6c9C703523);
IVELAV2_Vault constant Vault = IVELAV2_Vault(0xC4ABADE3a15064F9E3596943c699032748b13352);
IVELAV2_SettingsManager constant SettingsManager = IVELAV2_SettingsManager(0x6F2c6010A438546242cAb29Bb755c1F0AfaCa5AA);
IERC20 constant vUSD = IERC20(0xAA0B397B0896A864714dE56AA33E3df471229268);
IERC20 constant USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);

uint8 constant MARKET = 0; //executeOpenMarketOrders, executeAddPositions, executeDecreasePositions
uint8 constant LIQUIDATE = 1; // 6 for posId length3
uint8 constant TOO = 2; //7
uint8 constant TPSL = 3; //8
uint8 constant TRAILING = 4; //9
uint8 constant FORCECLOSE = 5; //10
uint8 constant SETPRICE = 11;

interface IBot{
    function setPrice(uint256 assetId, uint256 ts, uint256 price) external;
    function work1(uint256 category, uint256 _posId) external; 
}
contract Reader {
    IBot BOT;
    constructor(){
        BOT = IBot(msg.sender);
    }
    function query(
        uint256 assetId, uint256 price_ts, uint256 price, //price is raw pyth price
        uint256[] calldata categories, uint256[] calldata posIds
    ) public returns (
        bool price_ok, 
        bool[] memory res
    ){
        require(msg.sender==address(0), "query only");
        try BOT.setPrice(uint8(assetId), uint32(price_ts), uint64(price)){ 
            try PriceManager.getLastPrice(assetId){
                price_ok = true;
            }catch(bytes memory){}
        }catch(bytes memory){}
        res = new bool[](posIds.length);
        for(uint i; i<posIds.length; i++){
            try BOT.work1(uint8(categories[i]), uint24(posIds[i])){
                res[i] = true;
            }catch(bytes memory){}
        }
    }
    mapping(uint256=>bool) seen; //only used temporarily
    uint256[] haveTokens; //only used temporarily
    function getPositionTokens() external  returns(uint256[] memory, uint256 queueFullLength){
        uint256[] memory posIds;
        return getPositionTokens(posIds);
    }
    function getPositionTokens(uint256[] memory posIds) public returns(uint256[] memory, uint256 queueFullLength){
        require(msg.sender==address(0), "query only");
        uint256 startIdx = PositionVault.queueIndex();
        (uint length) = PositionVault.getNumOfUnexecuted();
        if(length>0){
            for(uint i; i<length; i++){
                uint posId = PositionVault.queuePosIds(startIdx+i);
                posId = posId % 2**128;
                Position memory pos = PositionVault.getPosition(posId);
                if(!seen[pos.tokenId]){
                    seen[pos.tokenId] = true;
                    haveTokens.push(pos.tokenId);
                }
            }
        }
        for(uint i; i<posIds.length; i++){
            uint posId = posIds[i];
            Position memory pos = PositionVault.getPosition(posId);
            if(!seen[pos.tokenId]){
                seen[pos.tokenId] = true;
                haveTokens.push(pos.tokenId);
            }
        }
        return (haveTokens, startIdx+length);
    }
}
interface IReader{
    function query(
        uint256 tokenId, uint256 price_ts, uint256 price, 
        uint256[] calldata categories, uint256[] calldata posIds
    ) external view returns (
        bool price_ok, 
        bool[] memory res
    );
    function getPositionTokens() external  returns(uint256[] memory);
    function getPositionTokens(uint256[] calldata posIds) external view returns(address[] memory, uint256 queueFullLength);
}

interface IBot_Management{
    function transferOwnership(address newOwner) external;
    function addOperator(address op) external;
    function removeOperator(address op) external;
    function withdraw() external;
    function withdraw_eth() external;
    function setDecimal(uint256,uint256) external;

    function init() external;
    function fix() external;
    function setLogicContract(address _c) external;
}

contract A_VELAV2BOT_MAINNET {
    address private _owner;
    mapping(address=>bool) private isOperator;
    address[] private TOKENS; //not used anymore
    address READER;
    mapping(uint256=>uint256) private priceDecimals;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }*/
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    struct AddressSlot {
        address value;
    }
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function _transferOwnership(address newOwner) internal { //onlyOwner
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        getAddressSlot(_ADMIN_SLOT).value=newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /*modifier onlyOperator{
        require(isOperator[msg.sender], "not operator");
        _;
    }*/
    function _addOperator(address op) internal{ //onlyOwner
        isOperator[op] = true;
    }
    function _removeOperator(address op) internal{ //onlyOwner
        isOperator[op] = false;
    }

    function _init() internal { //only when init owner==0
        require(_owner==address(0), "!init");
        _owner = msg.sender;
        //owner should not be operator

        READER = address(new Reader());
        //generated by: print("\n".join([f"        priceDecimals[{id}]={decimals};" for id,_,_,decimals in getprices(sorted(assetId2asset.keys()))]))
        priceDecimals[1]=22;
        priceDecimals[2]=22;
        priceDecimals[3]=22;
        priceDecimals[4]=22;
        priceDecimals[5]=22;
        priceDecimals[6]=20;
        priceDecimals[7]=22;
        priceDecimals[8]=22;
        priceDecimals[9]=22;
        priceDecimals[10]=22;
        priceDecimals[11]=25;
        priceDecimals[12]=25;
        priceDecimals[13]=27;
        priceDecimals[14]=25;
        priceDecimals[15]=25;
        priceDecimals[16]=25;
        priceDecimals[17]=25;
        priceDecimals[18]=25;
        priceDecimals[19]=25;
        priceDecimals[20]=25;
        priceDecimals[21]=25;
        priceDecimals[22]=25;
        priceDecimals[23]=25;
        priceDecimals[24]=25;
        priceDecimals[25]=27;
        priceDecimals[26]=25;
        priceDecimals[27]=25;
        priceDecimals[28]=25;
        priceDecimals[29]=22;
        priceDecimals[30]=22;
        priceDecimals[31]=22;
        priceDecimals[32]=22;
        priceDecimals[33]=22;
    }
    function _fix() internal {
        READER = address(new Reader());
    }
    
    function _withdraw() internal{ //public
        uint256 bal = vUSD.balanceOf(address(this));
        if(bal>0){
            Vault.withdraw{value:msg.value}(address(USDC), bal);
        }
        bal = USDC.balanceOf(address(this));
        if(bal>0){
            USDC.transfer(SettingsManager.feeManager(), bal);
        }
    }
    function _withdraw_eth() internal{//onlyOwner
        payable(msg.sender).transfer(address(this).balance);
    }
    function _setDecimal(uint256 assetId, uint256 decimal) internal{//onlyOwner, operator can also init
        priceDecimals[assetId] = decimal;
    }

    function _setPrice(uint256 assetId, uint256 ts, uint256 price) internal{ //onlyOperator OR reader
        require(priceDecimals[assetId]!=0, "unknown asset");
        price *= 10**priceDecimals[assetId];
        PriceManager.setPrice(assetId, price, ts);
    }
    function _work1(uint256 category, uint256 posId) internal { //onlyOperator OR reader
        //emit LOG(category, account, indexToken, isLong, posId);
        if(category==LIQUIDATE){
            LiquidateVault.liquidatePosition(posId);
        }else if(category==TOO){
            uint256[] memory addPositionTriggerIds = OrderVault.getPosAddPositionTriggerIds(posId);
            if(addPositionTriggerIds.length > 0){
                bool anySucceed;
                for(uint i; i<addPositionTriggerIds.length; i++){
                    try OrderVault.triggerForAddPositionTrigger(addPositionTriggerIds[i]){
                        anySucceed = true;
                    }catch{}
                }
                if(!anySucceed) revert();
            }else{
                OrderVault.triggerForOpenOrders(posId);
            }
        }else if(category==TPSL){
            OrderVault.triggerForTPSL(posId);
        }else if(category==TRAILING){
            OrderVault.updateTrailingStop(posId);
        }else if(category==FORCECLOSE){
            Vault.forceClosePosition(posId);
        }else{
            revert("unknown category");
        }
    }
    function _setPrice_allowfail(uint256 assetId, uint256 ts, uint256 price) internal{
        price *= 10**priceDecimals[assetId];
        try PriceManager.setPrice(assetId, price, ts){
        }catch{}
    }
    function _work1_allowfail(uint256 category, uint256 posId) internal{
        if(category==LIQUIDATE){
            try LiquidateVault.liquidatePosition(posId){}
            catch{}
        }else if(category==TOO){
            uint256[] memory addPositionTriggerIds = OrderVault.getPosAddPositionTriggerIds(posId);
            if(addPositionTriggerIds.length > 0){
                for(uint i; i<addPositionTriggerIds.length; i++){
                    try OrderVault.triggerForAddPositionTrigger(addPositionTriggerIds[i]){
                    }catch{}
                }
            }else{
                try OrderVault.triggerForOpenOrders(posId){}
                catch{}
            }
        }else if(category==TPSL){
            try OrderVault.triggerForTPSL(posId){}
            catch{}
        }else if(category==TRAILING){
            try OrderVault.updateTrailingStop(posId){}
            catch{}
        }else if(category==FORCECLOSE){
            try Vault.forceClosePosition(posId){}
            catch{}
        }else{
            revert("unknown category");
        }
    }
    function _executeMarketOrders(uint256 queueFullLength) internal{
        uint256 startIdx = PositionVault.queueIndex();
        if(queueFullLength>startIdx){
            PositionVault.executeOrders(queueFullLength-startIdx);
        }
    }

    
    function calldataVal(uint startByte, uint length) private pure returns (uint) {
      unchecked{
        uint _retVal;
        assembly {
            _retVal := calldataload(startByte)
        }
        _retVal = _retVal >> (256-length*8);
        return _retVal;
      }
    }

    receive() external payable{}
    fallback() external payable{
      unchecked{
        if(isOperator[msg.sender]){
            uint256 calldatalen = msg.data.length;
            uint256 idx;
            while(idx<calldatalen){
                uint256 category = calldataVal(idx, 1);
                idx+=1;
                if(category>10){
                    if(category==255){
                        uint256 t = calldataVal(idx, 2);
                        uint256 tokenId = t>>8;
                        uint256 decimals = t% 2**8;
                        require(priceDecimals[tokenId]==0, "!setDecimal");
                        _setDecimal(tokenId, decimals);
                        idx += 2;
                    }else{
                        uint256 t = calldataVal(idx, 10);
                        uint256 ts = t >> 48; // calldataVal(idx, 4);
                        uint256 price = t % 2**48; // calldataVal(idx+4, 6);
                        _setPrice_allowfail(category-11, ts, price);
                        idx += 10;
                    }
                }else if(category==0){
                    uint256 fulllength = calldataVal(idx, 3);
                    _executeMarketOrders(fulllength);
                    idx += 3;
                }else if(category<6){
                    uint256 posId = calldataVal(idx, 2);
                    _work1_allowfail(category, posId);
                    idx += 2;
                }else{ //6 7 8 9 10 -> 1 2 3 4 5
                    uint256 posId = calldataVal(idx, 3);
                    _work1_allowfail(category-5, posId);
                    idx += 3;
                }
            }
        }else if(msg.sender == READER || msg.sender == address(this)){
            uint256 selector = calldataVal(0, 4);
            if(selector == 0xaa585d56){ //setPrice(uint256,uint256,uint256)
                (uint256 a, uint256 b, uint256 c) = abi.decode(msg.data[4:], (uint256,uint256, uint256));
                _setPrice(a,b,c);
            }else if(selector == 0x725ca3d6){ //work1(uint256,uint256)
                (uint256 a, uint256 b) = abi.decode(msg.data[4:], (uint256,uint256));
                _work1(a,b);
            }else{
                revert("unknown function");
            }
        }else if(msg.sender == _owner){
            // owner can also upgrade by calling `setLogicContract(address)`, see bot_proxy.sol
            uint256 selector = calldataVal(0, 4);
            if(selector == 0x3ccfd60b){ //withdraw()
                _withdraw();
            }else if(selector == 0xd6f8560d){ //withdraw_eth()
                _withdraw_eth();
            }else if(selector == 0xf2fde38b){ //transferOwnership(address)
                address a = abi.decode(msg.data[4:], (address));
                _transferOwnership(a);
            }else if(selector == 0x9870d7fe){ //addOperator(address)
                address a = abi.decode(msg.data[4:], (address));
                _addOperator(a);
            }else if(selector == 0xac8a584a){ //removeOperator(address)
                address a = abi.decode(msg.data[4:], (address));
                _removeOperator(a);
            }else if(selector == 0xa551878e){ //fix()
                _fix();
            }else if(selector == 0x72e319c2){ //setDecimal(uint256,uint256)
                // if we want to de-list an asset, set decimal to 0 to prevent bot updating price
                (uint256 a, uint256 b) = abi.decode(msg.data[4:], (uint256, uint256));
                _setDecimal(a, b);
            }else{
                revert("unknown function");
            }
        }else{
            uint256 selector = calldataVal(0, 4);
            if(selector == 0x3ccfd60b){ //withdraw()
                _withdraw();
            } else if(selector==0xe1c7392a){ //init()
                _init();
            }else{
                revert("unknown function");
            }
        }
      }
    }
}