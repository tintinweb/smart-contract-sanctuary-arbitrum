/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor()  {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "e3");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
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

interface structItem {
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

}

interface p {
    struct allStakingItem {
        address pool;
        uint256 stakingNum;
        uint256[] stakingList;
    }
}

interface IgoManager is p {
    function getAllStakingNum(address _user) external view returns (uint256 num);

    function massGetStaking(address _user) external view returns (allStakingItem[] memory allStakingList, uint256[] memory tokenIdList);
}


contract IGOPoolV2 is Ownable, ReentrancyGuard, structItem, p {
    using SafeMath for uint256;
    address payable public feeAddress;
    address payable public teamAddress;
    address public IGOPoolFactory;
    address public swapPool;
    bool public useSwapPool = false;
    IgoManager public igoManager = IgoManager(0x360c35Af6429Ab4B6322eaa77E284fBd58877cd5);
    mapping(address => mapping(uint256 => bool)) public CanBuyBackList;
    mapping(address => uint256[]) public UserIgoTokenIdList;
    mapping(address => uint256) public UserIgoTokenIdListNum;
    mapping(uint256 => tokenIdInfo) public TokenIdSwapStatusStatusList;
    uint256 public stakingIgoNum;

    mapping(address => bool) public whiteList;

    struct multi_item {
        uint256 stakingTotal;
        uint256 whiteListTotal;
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

    orderItem_1 public fk1;
    orderItem_2 public fk2;

    event igoEvent(address _buyer, uint256 _idoNum, uint256[] _idoIdList, uint256 _amount, uint256 _time, uint256 _cosoID);

    constructor(
        IERC721Enumerable _Coso,
        address _feeAddress,
        address _teamAddress,
        IERC20 _ETH,
        uint256 orderId,
        IERC721Enumerable _nftToken,
        uint256 _igoAmount,
        address _erc20Token,
        uint256 _price,
        uint256 _swapRate) {
        IGOPoolFactory = msg.sender;
        feeAddress = payable(_feeAddress);
        teamAddress = payable(_teamAddress);
        fk2.CosoNFT = _Coso;
        fk2.ETH = _ETH;
        fk1.cosoQuote = 1;
        fk1.orderId = orderId;
        fk1.orderStatus = true;
        fk1.nftToken = _nftToken;
        fk1.igoTotalAmount = _igoAmount;
        fk1.erc20Token = _erc20Token;
        fk1.price = _price;
        fk1.igoOkAmount = 0;
        fk2.swapFee = _swapRate;
        fk2.igoMaxAmount = 0;
    }

    modifier onlyIGOPoolFactory() {
        require(msg.sender == IGOPoolFactory, "e00");
        _;
    }

    function setIgoManager(IgoManager _igoManager) external onlyOwner {
        igoManager = _igoManager;
    }

    function enableIgo() external onlyOwner {
        fk1.orderStatus = true;
    }

    function disableIgo() external onlyOwner {
        fk1.orderStatus = false;
    }

    function setIgo(address payable _feeAddress, uint256 _fee, IERC721Enumerable _CosoNft, IERC721Enumerable _nftToken) external onlyIGOPoolFactory {
        feeAddress = _feeAddress;
        fk2.swapFee = _fee;
        fk2.CosoNFT = _CosoNft;
        fk1.nftToken = _nftToken;
    }

    function setOrderId(uint256 _orderId) external onlyOwner {
        fk1.orderId = _orderId;
    }

    function setTeamAddress(address payable _teamAddress) external onlyOwner {
        require(_teamAddress != address(0), "e01");
        teamAddress = _teamAddress;
    }

    function setIgoTotalAmount(uint256 _igoTotalAmount) external onlyOwner {
        fk1.igoTotalAmount = _igoTotalAmount;
    }

    function setErc20token(address _token, uint256 _price) external onlyOwner {
        fk1.erc20Token = _token;
        fk1.price = _price;
    }

    function updateBuybackFee(uint256 _swapFee) external onlyOwner {
        fk2.swapFee = _swapFee;
    }

    function setNftToken(IERC721Enumerable _nftToken) external onlyOwner {
        fk1.nftToken = _nftToken;
    }

    function setTaskType(uint256 _igoMaxAmount, bool _useWhiteList, bool _useWhiteListCheck, bool _useStakingCoso, uint256 _CosoQuote, bool _useSwapPool) external onlyOwner {
        fk2.igoMaxAmount = _igoMaxAmount;
        fk1.useWhiteListCheck = _useWhiteListCheck;
        fk2.useWhiteList = _useWhiteList;
        fk2.useStakingCoso = _useStakingCoso;
        fk1.cosoQuote = _CosoQuote;
        useSwapPool = _useSwapPool;
    }

    function setSwapPool(address _swapPool) external onlyOwner {
        require(_swapPool != address(0));
        swapPool = _swapPool;
    }

    function setSwapTokenPrice(IERC20 _swapToken, uint256 _swapPrice) external onlyOwner {
        require(block.timestamp <= fk1.endBlock || address(fk2.swapToken) == address(0), "e06");
        fk2.swapToken = _swapToken;
        fk2.swapPrice = _swapPrice;
    }

    function setTimeLines(uint256 _startBlock, uint256 _endBlock, uint256 _buyBackEndBlock) external onlyOwner {
        require(_buyBackEndBlock > _endBlock && _endBlock > _startBlock, "e07");
        fk1.startBlock = _startBlock;
        fk1.endBlock = _endBlock;
        fk2.buyBackEndBlock = _buyBackEndBlock;
    }

    function getStakingNum(address _user) external view returns (uint256 stakingNum, uint256 igoMaxAmount) {
        stakingNum = igoManager.getAllStakingNum(_user);
        igoMaxAmount = fk2.igoMaxAmount;
    }

    function getStaking(address _user) external view returns (uint256[] memory idTokenList, uint256 idTokenListNum, nftInfo[] memory nftInfolist2, uint256 igoQuota, uint256 maxIgoNum) {
        (, idTokenList) = igoManager.massGetStaking(_user);
        idTokenListNum = idTokenList.length;
        nftInfolist2 = massGetNftInfo(fk2.CosoNFT, idTokenList);
        igoQuota = (idTokenList.length).sub(UserIgoTokenIdListNum[_user]);
        maxIgoNum = fk2.igoMaxAmount;
    }

    function igo(uint256 idoNum, uint256 _cosoID) external payable nonReentrant {
        address _user = msg.sender;
        require(idoNum > 0, "e13");
        require(fk1.nftToken.MinerList(address(this)), "e14");
        require(fk1.orderStatus, "e15");
        require(block.timestamp >= fk1.startBlock && block.timestamp <= fk1.endBlock, "e16");
        require(fk1.igoOkAmount.add(idoNum) <= fk1.igoTotalAmount, "e17");
        uint256 cocoID = _cosoID;
        require(UserIgoTokenIdListNum[_user].add(idoNum) <= fk2.igoMaxAmount, "e18");
        if (!fk2.useWhiteList && !fk1.useWhiteListCheck && fk2.useStakingCoso) {
            cocoID = 0;
            require(UserIgoTokenIdListNum[_user].add(idoNum) <= igoManager.getAllStakingNum(_user));
            stakingIgoNum = stakingIgoNum.add(idoNum);
        }
        if (fk2.useWhiteList && fk1.useWhiteListCheck && !fk2.useStakingCoso) {
            cocoID = 0;
            require(whiteList[_user], "e20");
        }
        uint256 allAmount = (fk1.price).mul(idoNum);
        uint256 fee = allAmount.mul(fk2.swapFee).div(100);
        uint256 toTeam = allAmount.sub(fee);
        if (fk1.erc20Token == address(0))
        {
            require(msg.value == allAmount, "e21");
            teamAddress.transfer(toTeam);
        } else {
            require(IERC20(fk1.erc20Token).balanceOf(_user) >= allAmount, "e22");
            IERC20(fk1.erc20Token).transferFrom(_user, teamAddress, toTeam);
        }
        if (fee > 0) {
            if (fk1.erc20Token == address(0)) {
                feeAddress.transfer(fee);
            } else {
                IERC20(fk1.erc20Token).transferFrom(_user, feeAddress, fee);
            }
        }
        uint256[] memory idoIdList = new uint256[](idoNum);
        for (uint256 i = 0; i < idoNum; i++) {
            (bool mintStatus,uint256 _token_id) = fk1.nftToken.mintForMiner(_user);
            require(mintStatus && _token_id > 0, "e23");
            TokenIdSwapStatusStatusList[_token_id].mintStatus = true;
            CanBuyBackList[_user][_token_id] = true;
            UserIgoTokenIdList[_user].push(_token_id);
            fk1.igoOkAmount = fk1.igoOkAmount.add(1);
            UserIgoTokenIdListNum[_user] = UserIgoTokenIdListNum[_user].add(1);
            idoIdList[i] = _token_id;
        }
        emit igoEvent(msg.sender, idoNum, idoIdList, allAmount, block.timestamp, cocoID);
    }

    function buyback(uint256[] memory _tokenIdList) external nonReentrant {
        require(block.timestamp > fk1.endBlock && block.timestamp < fk2.buyBackEndBlock, "e26");
        uint256 buybackNum = _tokenIdList.length;
        uint256 leftrate = uint256(100).sub(fk2.swapFee);
        uint256 allAmount = (fk1.price).mul(leftrate).mul(buybackNum).div(100);
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            require(CanBuyBackList[msg.sender][_tokenIdList[i]], "e27");
        }
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            fk1.nftToken.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenIdList[i]);
            CanBuyBackList[msg.sender][_tokenIdList[i]] = false;
            fk2.buyBackNum = fk2.buyBackNum.add(1);
            TokenIdSwapStatusStatusList[_tokenIdList[i]].buybackStatus = true;
        }
        if (fk1.erc20Token != address(0)) {
            IERC20(fk1.erc20Token).transfer(msg.sender, allAmount);
        } else {
            payable(msg.sender).transfer(allAmount);
        }
    }

    function takeTokens(address _token) external onlyOwner returns (bool){
        if (_token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
            return true;
        } else {
            IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
            return true;
        }
    }

    function getTimeStatus(uint256 _time) external view returns (bool canStaking, bool canIgo, bool canBuyBack, bool canWithDraw, bool canSwapToken) {
        if (_time < fk1.startBlock) {
            return (true, false, false, false, false);
        } else if (fk1.startBlock <= _time && _time <= fk1.endBlock) {
            return (false, true, false, false, true);
        } else if (fk1.endBlock < _time && _time <= fk2.buyBackEndBlock) {
            return (false, false, true, true, true);
        } else if (_time > fk2.buyBackEndBlock) {
            return (false, false, false, true, true);
        }
    }

    function getTokenInfoByIndex() external view returns (orderItem_1 memory orderItem1, orderItem_2 memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2, string memory nftName, string memory nftSymbol){
        orderItem1 = fk1;
        orderItem2 = fk2;
        if (orderItem1.erc20Token == address(0)) {
            name2 = fk2.ETH.name();
            symbol2 = fk2.ETH.symbol();
            decimals2 = fk2.ETH.decimals();
        } else {
            name2 = IERC20(orderItem1.erc20Token).name();
            symbol2 = IERC20(orderItem1.erc20Token).symbol();
            decimals2 = IERC20(orderItem1.erc20Token).decimals();
        }
        price2 = orderItem1.price.mul(1e18).div(10 ** decimals2);
        nftName = orderItem1.nftToken.name();
        nftSymbol = orderItem1.nftToken.symbol();
    }

    function getUserIdoTokenIdList(address _address) external view returns (uint256[] memory) {
        return UserIgoTokenIdList[_address];
    }

    function getNftInfo(IERC721Enumerable _nftToken, uint256 _tokenId) public view returns (nftInfo memory nftInfo2) {
        nftInfo2 = nftInfo(_nftToken.name(), _nftToken.symbol(), _nftToken.tokenURI(_tokenId), _nftToken.ownerOf(_tokenId), TokenIdSwapStatusStatusList[_tokenId]);
    }

    function massGetNftInfo(IERC721Enumerable _nftToken, uint256[] memory _tokenIdList) public view returns (nftInfo[] memory nftInfolist2) {
        nftInfolist2 = new nftInfo[](_tokenIdList.length);
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            nftInfolist2[i] = getNftInfo(_nftToken, _tokenIdList[i]);
        }
    }

    receive() payable external {}
}