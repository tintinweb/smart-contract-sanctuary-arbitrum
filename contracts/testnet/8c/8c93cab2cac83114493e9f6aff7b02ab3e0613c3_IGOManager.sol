/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "e3");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ow1");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ow2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "e4");
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

interface IERC721Enumerable {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintForMiner(address _to) external returns (bool, uint256);

    function MinerList(address _address) external returns (bool);
}


interface k {
    struct nftInfo {
        string name;
        string symbol;
        string tokenURI;
        address ownerOf;
        tokenIdInfo statusList;
    }

    struct tokenIdInfo {
        bool mintStatus;
        bool buybackStatus;
        bool swapStatus;
    }

    struct orderItem_1 {
        uint256 orderId;
        IERC721Enumerable nftToken;
        uint256 igoTotalAmount;
        address erc20Token;
        uint256 price;
        bool orderStatus;
        uint256 igoOkAmount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 cosoQuote;
        bool useWhiteListCheck;
    }

    struct orderItem_2 {
        IERC20 swapToken;
        uint256 swapPrice;
        uint256 buyBackEndBlock;
        uint256 buyBackNum;
        uint256 swapFee;
        uint256 igoMaxAmount;
        IERC721Enumerable CosoNFT;
        bool useStakingCoso;
        bool useWhiteList;
        IERC20 ETH;
    }
}

interface s {
    struct claimiItem {
        uint256 tokenId;
        bool hasClaim;
    }
}

interface IGOPool is k {
    function useSwapPool() external view returns (bool);

    function IGOPoolFactory() external view returns (address);

    function swapPool() external view returns (address);

    function fk1() external view returns (orderItem_1 memory);

    function fk2() external view returns (orderItem_2 memory);

    function UserIgoTokenIdListNum(address _user) external view returns (uint256);

    function UserIgoTokenIdList(address _user, uint256 _index) external view returns (uint256);

    function getTokenInfoByIndex() external view returns (orderItem_1 memory orderItem1, orderItem_2 memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2, string memory nftName, string memory nftSymbol);

    function getUserIdoTokenIdList(address _address) external view returns (uint256[] memory);

    function massGetNftInfo(IERC721Enumerable _nftToken, uint256[] memory _tokenIdList) external view returns (nftInfo[] memory nftInfolist2);

    function getStaking(address _user) external view returns (uint256[] memory idTokenList, uint256 idTokenListNum, nftInfo[] memory nftInfolist2, uint256 igoQuota, uint256 maxIgoNum);
}


interface SwapPool is s {
    function claimTimes() external view returns(uint256);

    function swapToken() external view returns (IERC20);

    function swapPrice() external view returns (uint256);

    function SwapNFT() external view returns (IERC721Enumerable);

    function userTokenIdList(address _user, uint256 _time) external view returns (uint256);

    function canClaimBlockNumList(uint256 _time) external view returns (uint256);

    function canClaimAmountList(uint256 _time) external view returns (uint256);

    function canClaimAmount(address _user, uint256 _time) external view returns (uint256);

    function userClaimList(address _address, uint256 _tokenId, uint256 _time) external view returns (claimiItem memory);

    function getUserTokenIdList(address _address) external view returns (uint256[] memory);
}


interface StakingPool {
    function userStakingTokenIdList(address _user, uint256 _index) external view returns (uint256);

    function userStakingNumList(address _user) external view returns (uint256);

    function getuserStakingTokenIdList(address _user) external view returns (uint256[] memory stakingList);
}

contract IGOManager is Ownable, k,s {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    uint256 public orderNum = 0;
    mapping(uint256 => IGOPool) public orderItemInfo;
    uint256 public oldStakingPoolNum = 0;
    uint256 public shareStakingPoolNum = 0;
    uint256 public swapPoolNum = 0;
    mapping(uint256 => IGOPool) public oldStakingPoolList;
    mapping(uint256 => StakingPool) public shareStakingPoolList;
    mapping(uint256 => SwapPool) public swapPoolList;
    //mapping(SwapPool => bool) public swapPoolInList;


    struct StakingPoolItem {
        uint256 StakingNum;
        uint256[] stakingList;
    }

    struct swapPoolItem {
        IERC721Enumerable SwapNFT;
        IERC20 swapToken;
        uint256 swapPrice;
    }

    //append mode
    function addSwapPool (SwapPool[] memory _swapPoolList) external onlyOwner returns(swapPoolItem[] memory swapPoolItems) {
        swapPoolItems = new swapPoolItem[](_swapPoolList.length);
        for (uint256 i=0;i<_swapPoolList.length;i++) {
            swapPoolList[swapPoolNum] = _swapPoolList[i];
            swapPoolNum = swapPoolNum.add(1);
            swapPoolItems[i] = swapPoolItem(_swapPoolList[i].SwapNFT(),_swapPoolList[i].swapToken(),_swapPoolList[i].swapPrice());
        }
    }

    //reset mode
    function resetSwapPool (SwapPool[] memory _swapPoolList) external onlyOwner returns(swapPoolItem[] memory swapPoolItems) {
        swapPoolNum = 0;
        swapPoolItems = new swapPoolItem[](_swapPoolList.length);
        for (uint256 i=0;i<_swapPoolList.length;i++) {
            swapPoolList[swapPoolNum] = _swapPoolList[i];
            swapPoolNum = swapPoolNum.add(1);
            swapPoolItems[i] = swapPoolItem(_swapPoolList[i].SwapNFT(),_swapPoolList[i].swapToken(),_swapPoolList[i].swapPrice());
        }
    }

    function addOldStakingPool(IGOPool[] memory _stakingList) external onlyOwner {
        for (uint256 i=0;i<_stakingList.length;i++) {
            oldStakingPoolList[oldStakingPoolNum] = _stakingList[i];
            oldStakingPoolNum = oldStakingPoolNum.add(1);
        }
    }

    //append mode
    function addShareStakingPool(StakingPool[] memory _stakingList) external onlyOwner {
        for (uint256 i=0;i<_stakingList.length;i++) {
            shareStakingPoolList[shareStakingPoolNum] = _stakingList[i];
            shareStakingPoolNum = shareStakingPoolNum.add(1);
        }
    }

    //reset mode
    function resetOldStakingPool(IGOPool[] memory _stakingList) external onlyOwner {
        oldStakingPoolNum = 0;
        for (uint256 i=0;i<_stakingList.length;i++) {
            oldStakingPoolList[oldStakingPoolNum] = _stakingList[i];
            oldStakingPoolNum = oldStakingPoolNum.add(1);
        }
    }

    //reset mode
    function resetShareStakingPool(StakingPool[] memory _stakingList) external onlyOwner {
        shareStakingPoolNum = 0;
        for (uint256 i=0;i<_stakingList.length;i++) {
            shareStakingPoolList[shareStakingPoolNum] = _stakingList[i];
            shareStakingPoolNum = shareStakingPoolNum.add(1);
        }
    }


    function getAllStakingNum(address _user) public view returns (uint256 num) {
        num = 0;
        for (uint256 i = 0; i < shareStakingPoolNum; i++) {
            num = num.add(shareStakingPoolList[i].userStakingNumList(_user));
        }
        for (uint256 i = 0; i < oldStakingPoolNum; i++) {
            (, uint256 idTokenListNum,,,) = oldStakingPoolList[i].getStaking(_user);
            num = num.add(idTokenListNum);
        }
    }

    //append mode
    function addIGOPooList(IGOPool[] memory _IGOPoolList) external onlyOwner returns (orderItem_3[] memory returnIgoInfoList){
        returnIgoInfoList = new orderItem_3[](_IGOPoolList.length);
        for (uint256 i = 0; i < _IGOPoolList.length; i++)
        {
            orderItemInfo[orderNum] = _IGOPoolList[i];
            returnIgoInfoList[i] = getIgoInfo(orderNum);
            orderNum = orderNum.add(1);
        }
    }

    function resetIGOPooList(IGOPool[] memory _IGOPoolList) external onlyOwner returns (orderItem_3[] memory returnIgoInfoList){
        returnIgoInfoList = new orderItem_3[](_IGOPoolList.length);
        orderNum = 0;
        for (uint256 i = 0; i < _IGOPoolList.length; i++)
        {
            orderItemInfo[orderNum] = _IGOPoolList[i];
            returnIgoInfoList[i] = getIgoInfo(orderNum);
            orderNum = orderNum.add(1);
        }
    }

    struct orderItem_3 {
        orderItem_1 x1;
        orderItem_2 x2;
        string name2;
        string symbol2;
        uint256 decimals2;
        uint256 price2;
        string nftName;
        string nftSymbol;
        IGOPool igoAddress;
    }

    struct stakingInfoItem {
        uint256[] idTokenList;
        uint256 idTokenListNum;
        nftInfo[] nftInfolist2;
        uint256 igoQuota;
        uint256 maxIgoNum;
    }

    struct IgoIdListItem {
        IGOPool IGO;
        IERC721Enumerable nftToken;
        uint256[] TokenIdList;
        uint256 TokenIdListNum;
    }

    function getIgoInfo(uint256 _index) public view returns (orderItem_3 memory returnIgoInfo) {
        returnIgoInfo.igoAddress = orderItemInfo[_index];
        {
            orderItem_1 memory orderItem_1 = orderItemInfo[_index].fk1();
            returnIgoInfo.x1 = orderItem_1;
        }
        {
            orderItem_2 memory orderItem_2 = orderItemInfo[_index].fk2();
            returnIgoInfo.x2 = orderItem_2;
        }
        {
            (,,string memory name2, string memory symbol2, uint256 decimals2, uint256 price2,string memory nftName,string memory nftSymbol) = orderItemInfo[_index].getTokenInfoByIndex();
            returnIgoInfo.name2 = name2;
            returnIgoInfo.symbol2 = symbol2;
            returnIgoInfo.decimals2 = decimals2;
            returnIgoInfo.price2 = price2;
            returnIgoInfo.nftName = nftName;
            returnIgoInfo.nftSymbol = nftSymbol;
        }
    }

    function getIgoInfo(IGOPool _igoAddress) public view returns (orderItem_3 memory returnIgoInfo) {
        returnIgoInfo.igoAddress = _igoAddress;
        {
            orderItem_1 memory orderItem_1 = _igoAddress.fk1();
            returnIgoInfo.x1 = orderItem_1;
        }
        {
            orderItem_2 memory orderItem_2 = _igoAddress.fk2();
            returnIgoInfo.x2 = orderItem_2;
        }
        {
            (,,string memory name2, string memory symbol2, uint256 decimals2, uint256 price2,string memory nftName,string memory nftSymbol) = _igoAddress.getTokenInfoByIndex();
            returnIgoInfo.name2 = name2;
            returnIgoInfo.symbol2 = symbol2;
            returnIgoInfo.decimals2 = decimals2;
            returnIgoInfo.price2 = price2;
            returnIgoInfo.nftName = nftName;
            returnIgoInfo.nftSymbol = nftSymbol;
        }
    }

    function massGetIgoInfo(uint256[] memory index_list) external view returns (orderItem_3[] memory returnIgoInfoList) {
        returnIgoInfoList = new orderItem_3[](index_list.length);
        for (uint256 i = 0; i < index_list.length; i++) {
            returnIgoInfoList[i] = getIgoInfo(index_list[i]);
        }
    }

    function massGetIgoInfo() external view returns (orderItem_3[] memory returnIgoInfoList) {
        returnIgoInfoList = new orderItem_3[](orderNum);
        for (uint256 i = 0; i < orderNum; i++) {
            returnIgoInfoList[i] = getIgoInfo(i);
        }
    }

    struct allStakingItem {
        address pool;
        uint256 stakingNum;
        uint256[] stakingList;
    }

    function massGetStaking(address _user) external view returns (allStakingItem[] memory allStakingList,uint256[] memory tokenIdList) {
        uint256 allNum = getAllStakingNum(_user);
        tokenIdList = new uint256[](allNum);
        uint256 num = oldStakingPoolNum.add(shareStakingPoolNum);
        allStakingList = new allStakingItem[](num);
        uint256 num0;
        uint256 num1;
        for (uint256 i = 0; i < shareStakingPoolNum; i++) {
            StakingPool x = shareStakingPoolList[i];
            uint256 StakingNum = x.userStakingNumList(_user);
            uint256[] memory stakingList = new uint256[](StakingNum);
            for (uint256 h = 0; h < StakingNum; h++) {
                stakingList[h] = x.userStakingTokenIdList(_user, h);
                tokenIdList[num1] = x.userStakingTokenIdList(_user, h);
                num1 = num1.add(1);
            }
            allStakingList[num0] = allStakingItem(address(x), StakingNum, stakingList);
            num0 = num0.add(1);
        }
        for (uint256 i = 0; i < oldStakingPoolNum; i++) {
            IGOPool y = oldStakingPoolList[i];
            (uint256[] memory stakingList,uint256 StakingNum,,,) = y.getStaking(_user);
            for (uint256 p=0;p<stakingList.length;p++) {
                tokenIdList[num1] = stakingList[p];
                num1 = num1.add(1);
            }
            allStakingList[num0] = allStakingItem(address(y), StakingNum, stakingList);
            num0 = num0.add(1);
        }
    }

    function massGetIgoTokenIdList(address _user, uint256[] memory index_list) external view returns (IgoIdListItem[] memory IgoIdList) {
        IgoIdList = new IgoIdListItem[](index_list.length);
        for (uint256 i = 0; i < index_list.length; i++) {
            IGOPool x = orderItemInfo[index_list[i]];
            IERC721Enumerable y = x.fk1().nftToken;
            uint256 z = x.UserIgoTokenIdListNum(_user);
            uint256[] memory list = new uint256[](z);
            for (uint256 t = 0; t < z; t++) {
                list[t] = x.UserIgoTokenIdList(_user, t);
            }
            IgoIdList[i] = IgoIdListItem(x, y, list, z);
        }
    }

    function massGetIgoTokenIdList(address _user) external view returns (IgoIdListItem[] memory IgoIdList) {
        IgoIdList = new IgoIdListItem[](orderNum);
        for (uint256 i = 0; i < orderNum; i++) {
            IGOPool x = orderItemInfo[i];
            IERC721Enumerable y = x.fk1().nftToken;
            uint256 z = x.UserIgoTokenIdListNum(_user);
            uint256[] memory list = new uint256[](z);
            for (uint256 t = 0; t < z; t++) {
                list[t] = x.UserIgoTokenIdList(_user, t);
            }
            IgoIdList[i] = IgoIdListItem(x, y, list, z);
        }
    }

    struct SwapPoolInfoItem {
        uint256 tokenId;
        bool hasClaim;
        uint256 blockNum;
        uint256 amount;
    }

    struct SwapPoolInfoListItem2 {
        SwapPoolInfoItem[] SwapPoolInfo;
    }

    struct SwapPoolInfoListItem3 {
        uint256 swapPrice;
        IERC20 swapToken;
        IERC721Enumerable SwapNFT;
        SwapPoolInfoListItem2[] list;
    }

    function GetSwapPoolInfo(address _user,SwapPool _SwapPool,uint256 _tokenId) public view returns (SwapPoolInfoItem[] memory SwapPoolInfoList) {
        uint256 times = _SwapPool.claimTimes();
        SwapPoolInfoList = new SwapPoolInfoItem[](times);
        for (uint256 j=0;j<times;j++) {
            claimiItem memory y = _SwapPool.userClaimList(_user,_tokenId,j);
            uint256 blockNum = _SwapPool.canClaimBlockNumList(j);
            uint256 amount = _SwapPool.canClaimAmountList(j);
            SwapPoolInfoList[j] = SwapPoolInfoItem(_tokenId,y.hasClaim,blockNum,amount);
        }
    }

    function MassGetSwapPoolInfo(address _user,SwapPool _SwapPool) public view returns (SwapPoolInfoListItem3 memory info) {
        info.swapPrice = _SwapPool.swapPrice();
        info.swapToken = _SwapPool.swapToken();
        info.SwapNFT = _SwapPool.SwapNFT();
        uint256[] memory idList = _SwapPool.getUserTokenIdList(_user);
        SwapPoolInfoListItem2[] memory SwapPoolInfoList = new SwapPoolInfoListItem2[](idList.length);
        for (uint256 i=0;i<idList.length;i++) {
            SwapPoolInfoList[i] = SwapPoolInfoListItem2(GetSwapPoolInfo(_user,_SwapPool,idList[i]));
        }
        info.list = SwapPoolInfoList;
    }

    function MassGetSwapPoolInfo(address _user)  public view returns (SwapPoolInfoListItem3[] memory infoList) {
        infoList = new SwapPoolInfoListItem3[](swapPoolNum);
        for (uint256 i=0;i<swapPoolNum;i++) {
            infoList[i] = MassGetSwapPoolInfo(_user,swapPoolList[i]);
        }
    }
}