// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

// import "./base/Multicall.sol";
import "./dex/ISwapRouter.sol";
import "./interfaces/INFT.sol";
import "./interfaces/ISubscription.sol";
import "./interfaces/IPost.sol";

import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Operator is Ownable{
    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public immutable WETH9;

    AggregatorV3Interface public priceFeed;

    /// @dev payment accepted usd ERC20 (USDC|USDT)
    mapping(address => bool) public usdTokens;

    /// @dev  nft contract
    address public subscriptionNft;
    address public postNft;
    /// @dev
    address public feeTo;

    uint256 public FEE_SUBSCRIBE = 80; //8%
    //uint256 public FEE_SUBSCRIBE_TX = 30;//
    uint256 public ROYALTY = 25; //2.5%
    uint256 public FEE_TX = 30;

    bool public mintPause;
    bool public locked;
    bool private _swapSwitch;
    //first indexed sender
    event MintSubscription(
        address indexed sender,
        address author,
        uint256 tokenId,
        uint128 start,
        uint128 expire,
        uint256 price
    );
    event MintSubscriptionETH(
        address indexed sender,
        address author,
        uint256 tokenId,
        uint128 start,
        uint128 expire,
        uint256 price,
        uint256 priceETH
    );
    event BuySubscription(
        address indexed sender,
        address oldOwner,
        uint256 tokenId,
        uint256 amountIn
    );
    event BuySubscriptionETH(
        address indexed sender,
        address oldOwner,
        uint256 tokenId,
        uint256 priceETH
    );
    event MintPost(
        address indexed sender,
        uint256 tokenId,
        uint128 postId,
        uint256 price
    );
    event BuyPost(address indexed sender, address oldOwner, uint256 tokenId,uint256 amountIn);
    event BuyPostETH(address indexed sender, address oldOwner, uint256 tokenId,uint256 priceETH);
    event SendTips(address indexed sender, address to,uint256 fromId, uint256 tipsAmount);
    event SendTipsETH(address indexed sender, address to,uint256 fromId, uint256 tipsAmount,uint256 value);
 

    modifier mintAble() {
        require(!mintPause, "!mint"); //mint pause
        _;
    }
    modifier swapSwitch() {
        _swapSwitch = true;
        _;
        _swapSwitch = false;
    }

    modifier lock() {
        require(!locked, "lock");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _WETH) {
        WETH9 = _WETH;
    }
 
   /*eth decimals 18*/
    function getOutputETHAmount(uint256 priceUsd) public view returns (uint256) {
        //price decimals 8
        /*uint80 roundID int price uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
        (,int price ,,,) = priceFeed.latestRoundData();
        //1e8*(18 -priceUsd decimals) => 1e8*1e12 = 1e20
        return (priceUsd * 1e20)/uint256(price);
    }

    function setSubscriptionNft(address _subscription) external onlyOwner {
        subscriptionNft = _subscription;
    }
 
    function setPostNft(address _postNft) external onlyOwner {
        postNft = _postNft;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function setPriceFee(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function setFeeTx(uint256 feeTx) external onlyOwner {
        FEE_TX = feeTx;
    }

    function setRoyalty(uint256 _royalty) external onlyOwner {
        ROYALTY = _royalty;
    }

    function setAcceptedUsdTokens(
        address _token,
        bool accepted
    ) external onlyOwner {
        usdTokens[_token] = accepted;

        // Approve the router to spend _token.
        TransferHelper.approve(_token, address(swapRouter), type(uint256).max);
    }

    //
    function approveSwapRouterToken(
        address _token,
        uint256 amount
    ) external onlyOwner {
         
        // Approve the router to spend _token.
        TransferHelper.approve(_token, address(swapRouter), amount);
    }

    function setFeeSubscribe(uint256 _percent) external onlyOwner {
        FEE_SUBSCRIBE = _percent;
    }

    function setMintAble(bool _pause) external onlyOwner {
        mintPause = _pause;
    }

    /// fee
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    ///subscribe pay with eth
    /// Called only when the user sets the payment method to ETH
    function mintSubscriptionETH(
        address to,
        address author,
        uint256 priceUsd,
        uint128 startAt,
        uint128 expireAt
    ) external payable mintAble returns (uint256 tokenId) {
        ///validate pay,
        // require(priceUsd >= 1e6, "p<1"); //price lt 1
        uint256 requireETH = getOutputETHAmount(priceUsd);
        require(requireETH <= msg.value, "eth insufficient"); 

        /// collect fee
        /// send to author
        (uint256 feeAmount, uint256 afterFeeAmount) = _feeSubscribeCalc(msg.value);
        payable(feeTo).transfer(feeAmount);
        payable(author).transfer(afterFeeAmount);

        tokenId = ISubscription(subscriptionNft).mint(
            to,
            author,
            startAt,
            expireAt
        );

        emit MintSubscriptionETH(to, author, tokenId, startAt, expireAt, priceUsd,msg.value);
    }

    ///should use multicall transfer eth to usd if necessary
    /// amountIn=price In usd 6 dicements
    /// tokenIn = USDC | USDT
    function mintSubscription(
        address to,
        address author,
        address tokenIn,
        uint256 price,
        uint128 startAt,
        uint128 expireAt
    ) external mintAble returns (uint256 tokenId) {
        if(price > 0){//0,free mint accepted

            ///validate pay,
            //require(price >= 1e6, "p<1"); //price lt 1
            require(usdTokens[tokenIn], "!usd"); //tokenIn not accepte
            //require(author!=msg.sender, "s=a");//sub-self occur erc20 transfrom STF,caller should check this

            /// collect fee
            /// direct transfer to author
            (uint256 feeAmount, uint256 afterFeeAmount) = _feeSubscribeCalc(price);
            TransferHelper.transferFrom(tokenIn, msg.sender, feeTo, feeAmount);
            TransferHelper.transferFrom(
                tokenIn,
                msg.sender,
                author,
                afterFeeAmount
            );
        }

        tokenId = ISubscription(subscriptionNft).mint(to, author, startAt, expireAt);

        emit MintSubscription(to, author, tokenId, startAt, expireAt, price);
    }

 

    /// must approve to spend the tokenIn,or transfer in the amount of tokenIn
    // must approval tokenId
    // check tokenId is for sale,price>0 ;set price 0 after buy
    // check amountIn >= price that retrieved  by tokenId
    // collect fee
    // transfer the left of tokenIn to owner,
    // transfer nft to sender
    function buySubscription(
        address to,
        address tokenIn,
        uint256 amountIn,
        uint256 tokenId
    ) external {
        //
        require(usdTokens[tokenIn], "!usd"); //tokenIn not accepted
        uint256 price = INFT(subscriptionNft).prices(tokenId);
        require(price > 0, "!sale"); //not for sale
        require(amountIn >= price, "amountIn insufficient");
        // no neccessary, if the amount insufficient occur transfer error 'stfc'
        //require(IERC20(tokenIn).balanceOf(msg.sender) >= amountIn,'balance insufficient');

        address owner = IERC721(subscriptionNft).ownerOf(tokenId);
        //
        (uint256 feeTx, uint256 afterFeeAmount) = _feeTxCalc(amountIn);

        TransferHelper.transferFrom(tokenIn, msg.sender, feeTo, feeTx);
        TransferHelper.transferFrom(tokenIn, msg.sender, owner, afterFeeAmount);

        _transferNFT(subscriptionNft, to, owner, tokenId);

        INFT(subscriptionNft).setPrice(tokenId, 0); //Take off the shelves

        emit BuySubscription(to, owner, tokenId,amountIn);
    }

 
    function buySubscriptionETH(address to,uint256 tokenId) external payable{
        //
        uint256 price = INFT(subscriptionNft).prices(tokenId);
        require(price > 0, "!sale"); //not for sale,or not exsist
        uint256 requireETH = getOutputETHAmount(price);
        require(msg.value >= requireETH, "eth insufficient"); //amountIn insufficient
        

        address owner = IERC721(subscriptionNft).ownerOf(tokenId);
        //
        (uint256 feeTx, uint256 afterFeeAmount) = _feeTxCalc(msg.value);
        payable(feeTo).transfer(feeTx);
        payable(owner).transfer(afterFeeAmount);


        _transferNFT(subscriptionNft, to, owner, tokenId);

        INFT(subscriptionNft).setPrice(tokenId, 0); //Take off the shelves

        emit BuySubscriptionETH(to, owner, tokenId,msg.value);
    }

    /// must approve to spend the tokenIn,or transfer in the amount of tokenIn
    // must approval tokenId
    // check amountIn >= price that retrieved  by tokenId
    // pay tax to author and collect fee
    // transfer the left of tokenIn to owner,
    // transfer nft to sender
    // take off the shelves
    function buyPost(
        address to,
        address tokenIn,
        uint256 amountIn,
        uint256 tokenId
    ) external lock {
        //
        require(usdTokens[tokenIn], "!usd"); //tokenIn not accepted
        // IPost.Meta memory meta = IPost(postNft).getMeta(tokenId);
        (address author,,) = IPost(postNft).metas(tokenId);
        uint256 price = INFT(postNft).prices(tokenId);
        require(price > 0, "!sale"); //not for sale
        require(amountIn >= price, "amountIn insufficient"); //
        //
        address owner = IERC721(postNft).ownerOf(tokenId);

        (uint256 royalty, uint256 taxTx, uint256 afterTaxAmount) = _taxCalc(
            amountIn
        );
        TransferHelper.transferFrom(
            tokenIn,
            msg.sender,
            author,
            royalty
        );
        TransferHelper.transferFrom(tokenIn, msg.sender, feeTo, taxTx);
        TransferHelper.transferFrom(tokenIn, msg.sender, owner, afterTaxAmount);

        _transferNFT(postNft, to, owner, tokenId);
        INFT(postNft).setPrice(tokenId, 0); //Take off the shelves

        emit BuyPost(to, owner, tokenId,amountIn);
    }


    function buyPostETH(uint256 tokenId) external payable lock {
                
        uint256 priceUsd = INFT(postNft).prices(tokenId);
        require(priceUsd > 0, "!sale"); //not for sale or not exists
        
        uint256 requireETH = getOutputETHAmount(priceUsd);
        require(requireETH <= msg.value, "eth insufficient"); 
        
        address owner = IERC721(postNft).ownerOf(tokenId);
        (address author,,) = IPost(postNft).metas(tokenId);

        (uint256 royalty, uint256 feeTx, uint256 afterTaxAmount) = _taxCalc(msg.value);
        payable(author).transfer(royalty);
        payable(feeTo).transfer(feeTx);
        payable(owner).transfer(afterTaxAmount);

        _transferNFT(postNft, msg.sender, owner, tokenId);
        INFT(postNft).setPrice(tokenId, 0); //Take off the shelves

        emit BuyPostETH(msg.sender, owner, tokenId,msg.value);
    }

    /// anyone can mint ,but only the author verification
    function mintPost(
        uint256 price,
        uint128 postId
    ) external mintAble returns (uint256 tokenId) {
        require(price >= 1e6, "p<1"); //usd lt 1

        tokenId = IPost(postNft).mint(msg.sender, postId, price);

        //a post mint that means up for sale ,so approval
        //INFT(postNft).operatorApprovalForAll(msg.sender);

        emit MintPost(msg.sender, tokenId, postId, price);
    }

    /// must approve to spend the tokenIn,or transfer in the amount of tokenIn
    // collect fee
    // transfer the left of tokenIn to toAccount
    function sendTips(
        address tokenIn,
        address to,
        uint256 fromId,
        uint256 tipsAmount
    ) external {
        require(tipsAmount>0, "tipsAmount=0"); 
        require(usdTokens[tokenIn], "!usd"); //tokenIn not accepted

        (uint256 feeTx, uint256 afterFeeAmount) = _feeTxCalc(tipsAmount);
        TransferHelper.transferFrom(tokenIn, msg.sender, feeTo, feeTx);
        TransferHelper.transferFrom(
            tokenIn,
            msg.sender,
            to,
            afterFeeAmount
        );
        //msg.sender might be this,by swapAndCall/multicall
        emit SendTips(tx.origin, to,fromId ,tipsAmount);
    }

    function sendTipsETH(address to,uint256 fromId,uint256 tipsAmount) external payable{
        //
        require(msg.value>0, "eth0");  
        uint256 requireETH = getOutputETHAmount(tipsAmount);
        require(requireETH <= msg.value, "eth insufficient"); 

        (uint256 feeAmount, uint256 afterFeeAmount) = _feeTxCalc(msg.value);
        payable(feeTo).transfer(feeAmount);
        payable(to).transfer(afterFeeAmount);
 

        emit SendTipsETH(tx.origin, to,fromId,tipsAmount, msg.value);
    }

    function _taxCalc(uint256 amountIn)
        private
        view
        returns (uint256 _royalty, uint256 feeTx, uint256 afterTaxAmount)
    {
        _royalty = (ROYALTY * amountIn) / 1000;
        feeTx = (FEE_TX * amountIn) / 1000;
        afterTaxAmount = amountIn - _royalty - feeTx;
    }

    function _feeTxCalc(
        uint256 amountIn
    ) private view returns (uint256 feeTx, uint256 afterFeeAmount) {
        feeTx = (FEE_TX * amountIn) / 1000;
        afterFeeAmount = amountIn - feeTx;
    }

    function _feeSubscribeCalc(
        uint256 amountIn
    ) private view returns (uint256 feeAmount, uint256 afterFeeAmount) {
        feeAmount = (FEE_SUBSCRIBE * amountIn) / 1000;
        afterFeeAmount = amountIn - feeAmount;
    }

    //swap recipient -> payment sender
    function _tokenSender() private view returns (address sender) {
        sender = _swapSwitch ? address(this) : msg.sender;
    }

    function _transferNFT(
        address nft,
        address to,
        address owner,
        uint256 tokenId
    ) private {
        INFT(nft).operatorApprovalForAll(owner);
        IERC721(nft).transferFrom(owner, to, tokenId);
    }

    ///  uint24 feeAmount = 10000;3000;500
    /// tokenIn tokenOut fee => pool
    /// tokenOut = usdERC20
    /// we dont use multicall from frontend to swap,so the user dont have to approve the usdERC20,ux better
    ///swap uniswap list token to usd by tokenIn/tokenOut(usd) pool,then mintXXX
    function swapAndCall(
        address tokenIn,
        address tokenOut,
        uint256 amountInMax,
        uint256 amountOut,
        uint24 feeAmount,
        bytes memory callData
    ) external payable {
      
        bool inputIsWETH9 =tokenIn == WETH9;

        if (inputIsWETH9) {
            require(msg.value > 0, "eth0");
            amountInMax = msg.value;
        }else{
            require(IERC20(tokenIn).balanceOf(msg.sender)>=amountInMax, "balance insufficient");
            TransferHelper.transferFrom(tokenIn, msg.sender, address(this), amountInMax);
            //TransferHelper.approve(tokenIn, swapRouter, amountInMax);
        }

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: feeAmount,
                recipient: address(this), //msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMax,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        //amountIn = swapRouter.exactOutputSingle(params);
        uint256 amountIn = swapRouter.exactOutputSingle{value: msg.value}(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        uint256 diffIn = amountInMax - amountIn;
        if (diffIn > 0) {
            if(inputIsWETH9){
                swapRouter.refundETH();
                // // refund leftover ETH to user
                TransferHelper.transferETH(msg.sender, diffIn); //msg.sender
            }else{
                TransferHelper.safeTransfer(tokenIn, msg.sender,  diffIn);
            }
        }

        (bool success, bytes memory result) = address(this).call(callData);

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

    }

    ///swap any uniswap list token to usd by tokenIn/middleToken../tokenOut pool,then mintXXX
    //tokenIn can't be WETH9
    // tokenOut is usdTokens
    // tokenIn = path.toAddress(0);
    function swapMultiAndCall(
        bytes memory path,
        address tokenIn,
        uint256 amountInMaximum,
        uint256 amountOut,
        bytes memory callData
    ) external {
        require(IERC20(tokenIn).balanceOf(msg.sender)>=amountInMaximum, "balance insufficient");
        TransferHelper.transferFrom(tokenIn, msg.sender, address(this), amountInMaximum);
        //TransferHelper.approve(tokenIn, swapRouter, amountInMax);
 
        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path:path,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum:amountInMaximum
            });

    
        uint256 amountIn = swapRouter.exactOutput(params);

        uint256 diffIn = amountInMaximum - amountIn;
        if (diffIn > 0) {
            TransferHelper.safeTransfer(tokenIn, msg.sender,  diffIn);
        }

        (bool success, bytes memory result) = address(this).call(callData);

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

    }

    //refundETH
    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.15;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function refundETH() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

interface INFT {
    event PriceChange(address indexed sender,uint256 tokenId,uint256 price,uint256 prePrice);

    function operatorApprovalForAll(address owner) external ;
    function prices(uint256 tokenId) external returns(uint256 price);
    function setPrice(uint256 tokenId,uint256 price) external;
    function setOperator(address _operator) external;
    // function mint(address to) external returns(uint256 tokenId);
    function currentId() external view returns (uint256) ;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

interface ISubscription {
    struct Meta {
        address author;
        uint128 start;
        uint128 expire;
    }

    // mapping(uint256 => Meta) public metas;
    function metas(uint256 tokenId) external view returns ( address author,uint128 start,uint128 expire);

    function mint(
        address to,
        address _author,
        uint128 _startAt,
        uint128 _expireAt
    ) external returns (uint256 tokenId);


}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

interface IPost {
    struct Meta {
        address author;
        uint128 postId;
        uint128 nonce;//transfer counter
    }

    // mapping(uint256 => Meta) public metas;
    function metas(uint256 tokenId) external view returns ( address author,uint128 postId,uint128 nonce);

    function mint(
        address _author,
        uint128 postId,
        uint256 price
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (from == address(this)) {
            (bool success, ) = token.call(
                abi.encodeWithSelector(IERC20.transfer.selector, to, value)
            );
            require(success, "TH1");
        } else {
            (bool success, ) = token.call(
                abi.encodeWithSelector(
                    IERC20.transferFrom.selector,
                    from,
                    to,
                    value
                )
            );
            require(success, "TH2");
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TH3"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TH4"
        );
    }

    function approve(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success,) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success ,
            "TH5"
        );
    }

    function transferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TH6");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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