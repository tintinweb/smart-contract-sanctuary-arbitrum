// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {VestingTerms} from "../VestingTerms.sol";

import {AccessHelper} from "../../utils/AccessHelper.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ADMIN_ROLE} from "../../utils/constants.sol";

import {MarketPlaceEvents} from "./utils/MarketPlaceEvents.sol";
import "./utils/MarketPlaceStructs.sol";

contract MarketPlaceV2 is AccessHelper, ReentrancyGuard, MarketPlaceEvents {
    uint256 public platformFee;
    address public feeRecipient;

    uint256 private contractCounter = 0;

    mapping(address => bool) private payableToken;
    address[] private payableTokens;

    using SafeERC20 for IERC20;

    mapping(uint256 => FundingTermsContractInfo)
        public fundingTermsSupportedContracts;

    // user => token => number of orders
    mapping(address => mapping(address => uint256)) public userAsksCounter;
    mapping(address => mapping(address => uint256)) public userBidsCounter;

    // user => token => number of active orders
    mapping(address => mapping(address => uint256))
        public userActiveAsksCounter;
    mapping(address => mapping(address => uint256))
        public userActiveBidsCounter;

    // token =>  saleId => list struct
    mapping(address => mapping(uint256 => Order)) public askOrders;
    mapping(address => mapping(uint256 => Order)) public bidOrders;

    // token => tokens sales info struct
    mapping(address => TokenAsksInfo) private tokenAsksInfo;
    mapping(address => TokenBidsInfo) private tokenBidsInfo;

    mapping(address => bool) private vestingContractsAddresses;

    // function initialize(address _admin) public initializer {
    //     _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    //     _grantRole(ADMIN_ROLE, _admin);
    // }

    uint256 public constant TOKEN_DECIMALS = 18;
    uint256 public constant MAX_FEE_RATE = 1000;

    constructor(
        uint256 _platformFee,
        address _feeRecipient,
        address _payableToken
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        require(
            _platformFee <= MAX_FEE_RATE,
            "platform fee can't be more than 10 percent"
        );
        require(_feeRecipient != address(0), "fee recipient not valid address");
        require(
            _payableToken != address(0),
            "payable token is not valid address"
        );

        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
        payableToken[_payableToken] = true;
        payableTokens.push(_payableToken);
    }

    function addSupportedFundingContractAddress(
        uint256 internalId,
        address _fundingTerms,
        string calldata _logoUrl,
        string calldata _symbol,
        address _tokenAddress
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(
            vestingContractsAddresses[_fundingTerms] == false,
            "Vesting Contract already exists"
        );

        uint256 id = contractCounter;
        contractCounter++;

        fundingTermsSupportedContracts[id] = FundingTermsContractInfo({
            internalId: internalId,
            fundingTermsAddress: _fundingTerms,
            logoUrl: _logoUrl,
            symbol: _symbol,
            tokenAddress: _tokenAddress
        });

        vestingContractsAddresses[_fundingTerms] = true;
    }

    function listSupportedTokens()
        public
        view
        returns (FundingTermsContractInfo[] memory)
    {
        FundingTermsContractInfo[]
            memory result = new FundingTermsContractInfo[](contractCounter);
        for (uint256 i = 0; i < contractCounter; i++) {
            result[i] = fundingTermsSupportedContracts[i];
        }
        return result;
    }

    function listAvailableTokensForSale(
        address _user
    ) public view returns (UserAvailableTokensForSale[] memory) {
        address sender = _user;

        UserAvailableTokensForSale[]
            memory result = new UserAvailableTokensForSale[](contractCounter);

        for (uint256 i = 0; i < contractCounter; i++) {
            FundingTermsContractInfo
                memory contractInfo = fundingTermsSupportedContracts[i];

            VestingTerms fundingTerms = VestingTerms(
                contractInfo.fundingTermsAddress
            );

            uint256 availableTokensAmount = fundingTerms.getAvailableTokens(
                sender
            );

            result[i] = UserAvailableTokensForSale({
                internalId: contractInfo.internalId,
                fundingTermsAddress: contractInfo.fundingTermsAddress,
                logoUrl: contractInfo.logoUrl,
                symbol: contractInfo.symbol,
                tokenAddress: contractInfo.tokenAddress,
                availableTokensForSale: availableTokensAmount
            });
        }
        return result;
    }

    function createBid(
        address _fundingTermsAddress,
        uint256 _quantity,
        uint256 _fullPrice,
        address _payToken
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            vestingContractsAddresses[_fundingTermsAddress] == true,
            "Vesting Contract not supported"
        );

        require(_payToken != address(0), "invalid pay token address");
        require(
            payableToken[_payToken],
            "pay token not supported for this sale"
        );

        uint256 payTokenDecimals = ERC20(_payToken).decimals();

        uint256 pricePerToken = getPricePerToken(
            _quantity,
            _fullPrice,
            payTokenDecimals,
            TOKEN_DECIMALS
        );

        require(pricePerToken != 0, "price per token gt 0");

        require(_quantity > 0, "quantaty cannot be 0");
        require(_fullPrice > 0, "_fullPrice cannot be 0");

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);
        bool distributingStarted = fundingTerms.distributingStarted();
        require(
            distributingStarted == false,
            "cannot create bid while distributing"
        );

        address sender = msg.sender;
        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();

        IERC20(_payToken).safeTransferFrom(sender, address(this), _fullPrice);

        TokenBidsInfo memory bidsInfo = tokenBidsInfo[tokenForSaleAddress];

        tokenBidsInfo[tokenForSaleAddress].activeBids = bidsInfo.activeBids + 1;
        tokenBidsInfo[tokenForSaleAddress].incrementalId =
            bidsInfo.incrementalId +
            1;

        userBidsCounter[sender][tokenForSaleAddress] += 1;
        userActiveBidsCounter[sender][tokenForSaleAddress] += 1;

        Order memory bidOrder = Order({
            id: bidsInfo.incrementalId,
            fullPrice: _fullPrice,
            pricePerToken: pricePerToken,
            quantity: _quantity,
            sold: false,
            buyer: sender,
            seller: address(0),
            createdAt: block.timestamp,
            fulfilledAt: 0,
            fundingTermsAddress: _fundingTermsAddress,
            orderType: "BID",
            payToken: _payToken
        });

        bidOrders[tokenForSaleAddress][bidsInfo.incrementalId] = bidOrder;

        emit BidCreated(bidsInfo.incrementalId, tokenForSaleAddress, bidOrder);
    }

    function createAsk(
        address _fundingTermsAddress,
        uint256 _quantity,
        uint256 _fullPrice,
        address _payToken
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            vestingContractsAddresses[_fundingTermsAddress] == true,
            "Vesting Contract not supported"
        );

        require(_quantity > 0, "quantity must be greater than 0");
        require(_fullPrice > 0, "price must be greater than 0");
        require(_payToken != address(0), "invalid pay token address");
        require(
            payableToken[_payToken],
            "pay token not supported for this sale"
        );

        uint256 payTokenDecimals = ERC20(_payToken).decimals();

        uint256 pricePerToken = getPricePerToken(
            _quantity,
            _fullPrice,
            payTokenDecimals,
            TOKEN_DECIMALS
        );

        require(pricePerToken != 0, "price per token gt 0");

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);
        bool distributingStarted = fundingTerms.distributingStarted();
        require(
            distributingStarted == false,
            "cannot create ask while distributing"
        );

        address sender = msg.sender;

        uint256 availableTokensAmount = fundingTerms.getAvailableTokens(sender);

        require(
            _quantity <= availableTokensAmount,
            "quantity is higher than available amount"
        );

        fundingTerms.lockTokens(sender, _quantity);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();

        userAsksCounter[sender][tokenForSaleAddress] += 1;
        userActiveAsksCounter[sender][tokenForSaleAddress] += 1;

        TokenAsksInfo memory asksInfo = tokenAsksInfo[tokenForSaleAddress];

        tokenAsksInfo[tokenForSaleAddress].activeAsks = asksInfo.activeAsks + 1;
        tokenAsksInfo[tokenForSaleAddress].incrementalId =
            asksInfo.incrementalId +
            1;

        Order memory askOrder = Order({
            id: asksInfo.incrementalId,
            fullPrice: _fullPrice,
            pricePerToken: pricePerToken,
            quantity: _quantity,
            sold: false,
            seller: sender,
            buyer: address(0),
            createdAt: block.timestamp,
            fulfilledAt: 0,
            fundingTermsAddress: _fundingTermsAddress,
            orderType: "ASK",
            payToken: _payToken
        });

        askOrders[tokenForSaleAddress][asksInfo.incrementalId] = askOrder;

        emit AskCreated(asksInfo.incrementalId, tokenForSaleAddress, askOrder);
    }

    function listAskOrdersPerToken(
        address _tokenForSaleAddress
    ) public view returns (Order[] memory) {
        Order[] memory result = new Order[](
            tokenAsksInfo[_tokenForSaleAddress].activeAsks
        );
        if (tokenAsksInfo[_tokenForSaleAddress].activeAsks == 0) {
            return result;
        }

        uint256 resultCounter = 0;
        uint256 asksLength = tokenAsksInfo[_tokenForSaleAddress].incrementalId;

        for (uint256 i = 0; i < asksLength; i++) {
            Order memory token = askOrders[_tokenForSaleAddress][i];

            if (token.sold == false && token.seller != address(0)) {
                result[resultCounter] = token;
                resultCounter = resultCounter + 1;
            }
        }

        return result;
    }

    function listBidOrdersPerToken(
        address _tokenForSaleAddress
    ) public view returns (Order[] memory) {
        Order[] memory result = new Order[](
            tokenBidsInfo[_tokenForSaleAddress].activeBids
        );
        if (tokenBidsInfo[_tokenForSaleAddress].activeBids == 0) {
            return result;
        }

        uint256 resultCounter = 0;
        uint256 bidsLength = tokenBidsInfo[_tokenForSaleAddress].incrementalId;

        for (uint256 i = 0; i < bidsLength; i++) {
            Order memory bid = bidOrders[_tokenForSaleAddress][i];

            if (bid.sold == false && bid.buyer != address(0)) {
                result[resultCounter] = bid;
                resultCounter = resultCounter + 1;
            }
        }

        return result;
    }

    function cancelAskOrder(
        address _fundingTermsAddress,
        uint256 _saleId
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            vestingContractsAddresses[_fundingTermsAddress] == true,
            "Vesting Contract not supported"
        );

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order memory listedToken = askOrders[tokenForSaleAddress][_saleId];

        require(listedToken.seller == sender, "not ask owner");
        require(listedToken.sold == false, "order already sold");

        userAsksCounter[sender][tokenForSaleAddress] -= 1;
        userActiveAsksCounter[sender][tokenForSaleAddress] -= 1;

        tokenAsksInfo[tokenForSaleAddress].activeAsks -= 1;

        fundingTerms.unlockTokens(sender, listedToken.quantity);

        delete askOrders[tokenForSaleAddress][_saleId];
    }

    function cancelBidOrder(
        address _fundingTermsAddress,
        uint256 _bidId
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            vestingContractsAddresses[_fundingTermsAddress] == true,
            "Vesting Contract not supported"
        );

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order memory bid = bidOrders[tokenForSaleAddress][_bidId];

        require(bid.buyer == sender, "not bid owner");
        require(bid.sold == false, "order already sold");

        IERC20(bid.payToken).safeTransfer(sender, bid.fullPrice);

        tokenBidsInfo[tokenForSaleAddress].activeBids -= 1;

        userBidsCounter[sender][tokenForSaleAddress] -= 1;

        userActiveBidsCounter[sender][tokenForSaleAddress] -= 1;

        delete bidOrders[tokenForSaleAddress][_bidId];
    }

    function buy(
        address _fundingTermsAddress,
        uint256 _saleId,
        address _payToken,
        uint256 _price
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            vestingContractsAddresses[_fundingTermsAddress] == true,
            "Vesting Contract not supported"
        );

        require(_payToken != address(0), "invalid pay token address");
        require(
            payableToken[_payToken],
            "pay token not supported for this sale"
        );

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order storage listedToken = askOrders[tokenForSaleAddress][_saleId];

        require(listedToken.payToken == _payToken, "paytoken is different");
        require(listedToken.seller != address(0), "seller is not valid");
        require(_price == listedToken.fullPrice, "price is not correct");
        require(_saleId == listedToken.id, "id is not correct");
        require(listedToken.sold == false, "order already sold");

        listedToken.sold = true;
        listedToken.buyer = sender;
        listedToken.fulfilledAt = block.timestamp;
        uint256 totalPrice = _price;
        uint256 platformFeeTotal = calculatePlatformFee(_price);

        IERC20(_payToken).safeTransferFrom(
            sender,
            feeRecipient,
            platformFeeTotal
        );

        IERC20(_payToken).safeTransferFrom(
            sender,
            listedToken.seller,
            totalPrice - platformFeeTotal
        );

        fundingTerms.marketAskOrderFulFilled(
            listedToken.seller,
            sender,
            listedToken.quantity
        );

        address seller = listedToken.seller;

        tokenAsksInfo[tokenForSaleAddress].activeAsks -= 1;

        userActiveAsksCounter[seller][tokenForSaleAddress] -= 1;

        emit OrderAccepted(listedToken.id, tokenForSaleAddress, listedToken);
    }

    function sell(
        address _fundingTermsAddress,
        uint256 _bidId,
        address _payToken,
        uint256 _fullPrice
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            vestingContractsAddresses[_fundingTermsAddress] == true,
            "Vesting Contract not supported"
        );

        require(_payToken != address(0), "invalid pay token address");
        require(
            payableToken[_payToken],
            "pay token not supported for this sale"
        );

        require(_fullPrice != 0, "price cannot be 0");

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order storage bid = bidOrders[tokenForSaleAddress][_bidId];

        require(bid.payToken == _payToken, "paytoken is different");
        require(bid.fullPrice == _fullPrice, "price is not correct");
        require(_bidId == bid.id, "bid id is not correct");
        require(bid.sold == false, "order already sold");

        uint256 availableTokensAmount = fundingTerms.getAvailableTokens(sender);

        require(
            bid.quantity <= availableTokensAmount,
            "quantity is higher than available amount"
        );

        bid.sold = true;
        bid.seller = sender;
        bid.fulfilledAt = block.timestamp;
        uint256 totalPrice = _fullPrice;
        uint256 platformFeeTotal = calculatePlatformFee(totalPrice);

        IERC20(_payToken).safeTransfer(feeRecipient, platformFeeTotal);
        IERC20(_payToken).safeTransfer(sender, totalPrice - platformFeeTotal);

        fundingTerms.marketBidOrderFulFilled(sender, bid.buyer, bid.quantity);

        tokenBidsInfo[tokenForSaleAddress].activeBids -= 1;

        address buyer = bid.buyer;

        userActiveBidsCounter[buyer][tokenForSaleAddress] -= 1;

        emit OrderAccepted(bid.id, tokenForSaleAddress, bid);
    }

    function getActiveOrders(
        address _user,
        address _tokenForSaleAddress
    ) public view returns (Order[] memory) {
        uint256 numActiveAsks = userActiveAsksCounter[_user][
            _tokenForSaleAddress
        ];
        uint256 numActiveBids = userActiveBidsCounter[_user][
            _tokenForSaleAddress
        ];
        uint256 totalOrders = numActiveAsks + numActiveBids;
        Order[] memory userOrders = new Order[](totalOrders);

        uint256 orderIndex = 0;

        if (
            tokenAsksInfo[_tokenForSaleAddress].activeAsks == 0 &&
            tokenBidsInfo[_tokenForSaleAddress].activeBids == 0
        ) {
            return userOrders;
        }

        uint256 asksLength = tokenAsksInfo[_tokenForSaleAddress].incrementalId;
        uint256 bidsLength = tokenBidsInfo[_tokenForSaleAddress].incrementalId;

        for (uint256 i = 0; i < asksLength; i++) {
            Order memory ask = askOrders[_tokenForSaleAddress][i];
            if (ask.seller == _user && ask.sold == false) {
                userOrders[orderIndex] = ask;
                orderIndex = orderIndex + 1;
            }
        }

        for (uint256 i = 0; i < bidsLength; i++) {
            Order memory bid = bidOrders[_tokenForSaleAddress][i];
            if (bid.buyer == _user && bid.sold == false) {
                userOrders[orderIndex] = bid;
                orderIndex = orderIndex + 1;
            }
        }

        return userOrders;
    }

    function listOrderHistoryPerToken(
        address _tokenForSaleAddress
    ) public view returns (Order[] memory) {
        require(_tokenForSaleAddress != address(0), "invalid address");

        uint256 orderFullfiledCount = 0;
        uint256 asksLength = tokenAsksInfo[_tokenForSaleAddress].incrementalId;
        uint256 bidsLength = tokenBidsInfo[_tokenForSaleAddress].incrementalId;

        for (uint256 i = 0; i < asksLength; i++) {
            Order memory ask = askOrders[_tokenForSaleAddress][i];
            if (ask.sold == true) {
                orderFullfiledCount++;
            }
        }

        for (uint256 i = 0; i < bidsLength; i++) {
            Order memory bid = bidOrders[_tokenForSaleAddress][i];
            if (bid.sold == true) {
                orderFullfiledCount++;
            }
        }

        if (orderFullfiledCount == 0) {
            Order[] memory userOrders = new Order[](0);
            return userOrders;
        }

        Order[] memory orderHistory = new Order[](orderFullfiledCount);
        uint256 orderHistoryIndex = 0;

        for (uint256 i = 0; i < asksLength; i++) {
            Order memory ask = askOrders[_tokenForSaleAddress][i];
            if (ask.sold == true) {
                orderHistory[orderHistoryIndex] = ask;
                orderHistoryIndex = orderHistoryIndex + 1;
            }
        }

        for (uint256 i = 0; i < bidsLength; i++) {
            Order memory bid = bidOrders[_tokenForSaleAddress][i];
            if (bid.sold == true) {
                orderHistory[orderHistoryIndex] = bid;
                orderHistoryIndex = orderHistoryIndex + 1;
            }
        }

        return orderHistory;
    }

    function getPricePerToken(
        uint256 _amount,
        uint256 _price,
        uint256 _payableTokenDecimals,
        uint256 _tokenDecimals
    ) internal pure returns (uint256) {
        uint256 decimals = _tokenDecimals - _payableTokenDecimals;
        uint256 normalizedPrice = _price * (10 ** decimals) * 1e18;

        uint256 pricePerToken = normalizedPrice / _amount;

        return pricePerToken / (10 ** decimals);
    }

    function updatePlatformFee(
        uint256 _platformFee
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(_platformFee <= MAX_FEE_RATE, "can't more than 10 percent");
        platformFee = _platformFee;
    }

    function updateFeeRecipient(
        address _address
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(_address != address(0), "invalid address");
        feeRecipient = _address;
    }

    function addPayableToken(
        address _token
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(_token != address(0), "invalid address");
        require(payableToken[_token] == false, "already payable token");
        payableToken[_token] = true;
        payableTokens.push(_token);
    }

    function getPayableTokens() external view returns (address[] memory) {
        return payableTokens;
    }

    function checkIsPayableToken(
        address _payableToken
    ) external view returns (bool) {
        return payableToken[_payableToken];
    }

    function calculatePlatformFee(
        uint256 _price
    ) public view returns (uint256) {
        return (_price * platformFee) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessHelper} from "../utils/AccessHelper.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ADMIN_ROLE, MARKET_ROLE} from "../utils/constants.sol";

contract VestingTerms is AccessHelper, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 private tokenForSaleContract;

    address public tokenForSaleAddress;
    bool public distributingStarted = false;

    struct UserInfo {
        uint256 tokenBalance;
        uint256 lockedTokens;
        uint256 tokenReleased;
        address userAddress;
    }

    mapping(address => UserInfo) public userBalances;
    address[] public userAddresses;
    mapping(address => bool) private addressExists;

    uint256 public immutable vestingPeriod;
    uint256 public immutable vestingMonths;
    uint8 public immutable startVestingPercentage;
    uint256 public vestingStartTime;

    uint256 public constant VESTING_STEP = 30 days;

    address public treasuryAddress;

    constructor(
        address _adminAddress,
        address _tokenForSaleAddress,
        uint256 _vestingMonths,
        uint8 _startVestingPercentage,
        address _marketAddress,
        address _treasuryAddress
    ) {
        require(_tokenForSaleAddress != address(0), "Address cannot be 0");
        require(_vestingMonths != 0, "Vesting period cannot be 0");
        require(_treasuryAddress != address(0), "Treasury Address cannot be 0");

        tokenForSaleAddress = _tokenForSaleAddress;
        vestingPeriod = _vestingMonths * 30 * 24 * 60 * 60;
        vestingMonths = _vestingMonths;
        startVestingPercentage = _startVestingPercentage;

        tokenForSaleContract = IERC20(_tokenForSaleAddress);
        treasuryAddress = _treasuryAddress;

        _grantRole(ADMIN_ROLE, _adminAddress);
        _grantRole(MARKET_ROLE, _marketAddress);
    }

    function startDistributing() external onlyAuthorized(ADMIN_ROLE) {
        require(distributingStarted == false, "distributing already started");
        vestingStartTime = block.timestamp;
        distributingStarted = true;
    }

    function calculateVestedAmount(
        uint256 elapsedTime,
        uint256 vestedAmount,
        uint256 releasedTokens,
        uint256 lockedTokens
    ) internal view returns (uint256) {
        if (elapsedTime >= vestingPeriod) {
            return vestedAmount - releasedTokens - lockedTokens;
        }

        uint256 availableAmount = vestedAmount - lockedTokens;
        uint256 startAmount = (availableAmount * startVestingPercentage) / 100;
        uint256 elapsedMonths = elapsedTime / VESTING_STEP;

        uint256 postStartAvailableAmount = availableAmount - startAmount;

        uint256 currentVestedAmount = (postStartAvailableAmount *
            elapsedMonths) / vestingMonths;

        return currentVestedAmount + startAmount - releasedTokens;
    }

    function getAvailableBalance(address _user) public view returns (uint256) {
        if (distributingStarted == false) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - vestingStartTime;

        UserInfo memory memUserInfo = userBalances[_user];

        return
            calculateVestedAmount(
                elapsedTime,
                memUserInfo.tokenBalance,
                memUserInfo.tokenReleased,
                memUserInfo.lockedTokens
            );
    }

    function redeem(uint256 _amount) external nonReentrant {
        require(distributingStarted == true, "distributing has not started");
        address sender = msg.sender;

        uint256 elapsedTime = block.timestamp - vestingStartTime;

        UserInfo memory memUserInfo = userBalances[sender];

        uint256 availableBalance = calculateVestedAmount(
            elapsedTime,
            memUserInfo.tokenBalance,
            memUserInfo.tokenReleased,
            memUserInfo.lockedTokens
        );

        require(
            _amount <= availableBalance,
            "The requested amount exceeds the available balance"
        );

        UserInfo storage userInfo = userBalances[sender];

        userInfo.tokenReleased += _amount;

        tokenForSaleContract.safeTransfer(sender, _amount);
    }

    function getAvailableTokens(address _user) public view returns (uint256) {
        require(_user != address(0), "address cannot be null address");

        UserInfo memory memUserInfo = userBalances[_user];
        uint256 availableTokensAmount = 0;

        if (
            (memUserInfo.tokenBalance -
                memUserInfo.lockedTokens -
                memUserInfo.tokenReleased) > 0
        ) {
            availableTokensAmount =
                memUserInfo.tokenBalance -
                memUserInfo.lockedTokens -
                memUserInfo.tokenReleased;
        }

        return availableTokensAmount;
    }

    function lockTokens(
        address _user,
        uint256 _quantity
    ) external onlyAuthorized(MARKET_ROLE) {
        require(distributingStarted == false, "cannot lock while distributing");

        uint256 availableTokensAmount = getAvailableTokens(_user);

        require(
            _quantity <= availableTokensAmount,
            "quantity is higher than available amount"
        );

        UserInfo storage userInfo = userBalances[_user];
        userInfo.lockedTokens += _quantity;
    }

    function unlockTokens(
        address _user,
        uint256 _quantity
    ) external onlyAuthorized(MARKET_ROLE) {
        uint256 userLockedTokens = userBalances[_user].lockedTokens;

        require(
            _quantity <= userLockedTokens,
            "quantity to unlock is higher than locked tokens"
        );

        UserInfo storage userInfo = userBalances[_user];
        userInfo.lockedTokens -= _quantity;
    }

    function marketAskOrderFulFilled(
        address _seller,
        address _buyer,
        uint256 _amount
    ) external onlyAuthorized(MARKET_ROLE) {
        require(_seller != address(0), "from address not valid");
        require(_buyer != address(0), "_to address not valid");
        require(_amount > 0, "amount must be higher than 0");

        UserInfo memory memUserInfo = userBalances[_seller];

        require(
            _amount <= memUserInfo.lockedTokens,
            "amount is greater than locked tokens"
        );
        require(
            _amount <= memUserInfo.tokenBalance,
            "mount is greater than total from balance"
        );

        UserInfo storage fromUserInfo = userBalances[_seller];
        fromUserInfo.lockedTokens -= _amount;
        fromUserInfo.tokenBalance -= _amount;

        UserInfo storage toUserInfo = userBalances[_buyer];
        toUserInfo.tokenBalance += _amount;

        if (!addressExists[_buyer]) {
            userAddresses.push(_buyer);
            addressExists[_buyer] = true;
            toUserInfo.userAddress = _buyer;
        }
    }

    function marketBidOrderFulFilled(
        address _seller,
        address _buyer,
        uint256 _amount
    ) external onlyAuthorized(MARKET_ROLE) {
        require(_seller != address(0), "from address not valid");
        require(_buyer != address(0), "_to address not valid");
        require(_amount > 0, "amount must be higher than 0");

        uint256 availableTokensAmount = getAvailableTokens(_seller);

        require(
            _amount <= availableTokensAmount,
            "amount is greater than available tokens"
        );

        UserInfo storage fromUserInfo = userBalances[_seller];
        fromUserInfo.tokenBalance -= _amount;

        UserInfo storage toUserInfo = userBalances[_buyer];
        toUserInfo.tokenBalance += _amount;

        if (!addressExists[_buyer]) {
            userAddresses.push(_buyer);
            addressExists[_buyer] = true;
            toUserInfo.userAddress = _buyer;
        }
    }

    function updateUserBalances(
        UserInfo[] calldata usersInfo
    ) public onlyAuthorized(ADMIN_ROLE) {
        require(
            distributingStarted == false,
            "cannot update balances while distributing"
        );

        for (uint256 i = 0; i < usersInfo.length; i++) {
            UserInfo memory info = usersInfo[i];
            UserInfo storage user = userBalances[info.userAddress];

            user.tokenBalance = info.tokenBalance;
            user.lockedTokens = 0;
            user.tokenReleased = 0;
            user.userAddress = info.userAddress;

            if (!addressExists[info.userAddress]) {
                userAddresses.push(info.userAddress);
                addressExists[info.userAddress] = true;
            }
        }
    }

    function getTotalUsers() public view returns (uint256) {
        return userAddresses.length;
    }

    function getUsers(
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (address[] memory) {
        require(
            startIndex < endIndex,
            "Invalid index: startIndex must be less than endIndex"
        );
        require(endIndex <= userAddresses.length, "Index out of bounds");

        uint256 length = endIndex - startIndex;
        address[] memory usersInfo = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            usersInfo[i] = userAddresses[startIndex + i];
        }

        return usersInfo;
    }

    function releaseTokens() external onlyAuthorized(ADMIN_ROLE) {
        require(
            distributingStarted == false,
            "cannot release tokens while distributing"
        );
        tokenForSaleContract.transfer(
            treasuryAddress,
            tokenForSaleContract.balanceOf(address(this))
        );
    }

    function isVestingFinished() public view returns (bool) {
        return (block.timestamp - vestingStartTime) >= vestingPeriod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract AccessHelper is AccessControlEnumerable {
    modifier onlyAuthorized(bytes32 role) {
        _checkAuthorization(role);
        _;
    }

    function _checkAuthorization(bytes32 role) internal view {
        if (!hasRole(role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// access roles

bytes32 constant TOKEN_PROVIDER_ROLE = keccak256("TOKEN_PROVIDER_ROLE");
bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 constant MARKET_ROLE = keccak256("MARKET_ROLE");


//test 
bytes32 constant GREETER_ROLE = keccak256("GREETER_ROLE");

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct FundingTermsContractInfo {
    uint256 internalId;
    address fundingTermsAddress;
    string logoUrl;
    string symbol;
    address tokenAddress;
}

struct UserAvailableTokensForSale {
    uint256 internalId;
    address fundingTermsAddress;
    string logoUrl;
    string symbol;
    address tokenAddress;
    uint256 availableTokensForSale;
}

struct Order {
    uint256 id;
    uint256 quantity;
    uint256 fullPrice;
    uint256 pricePerToken;
    bool sold;
    address seller;
    address buyer;
    address fundingTermsAddress;
    uint256 createdAt;
    uint256 fulfilledAt;
    string orderType;
    address payToken;
}

struct TokenAsksInfo {
    uint256 activeAsks;
    uint256 incrementalId;
}

struct TokenBidsInfo {
    uint256 activeBids;
    uint256 incrementalId;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MarketPlaceStructs.sol";

abstract contract MarketPlaceEvents {
    event AskCreated(
        uint256 indexed id,
        address indexed tokenAddress,
        Order askOrder
    );

    event BidCreated(
        uint256 indexed id,
        address indexed tokenAddress,
        Order bidOrder
    );

    event OrderAccepted(
        uint256 indexed id,
        address indexed tokenAddress,
        Order askOrder
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}