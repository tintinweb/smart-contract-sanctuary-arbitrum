/**
 *Submitted for verification at Arbiscan on 2022-05-19
*/

pragma solidity ^0.5.17;

contract ERC20
{
    function approve(address _spender, uint _amount)
        public
        returns (bool);
    function transferFrom(address _sender, address _receiver, uint _amount)
        public
        returns (bool);
}

contract BucketSale
{
    function tokenSoldFor()
        public
        returns (ERC20);

    function agreeToTermsAndConditionsListedInThisContractAndEnterSale(
        address _buyer,
        uint _bucketId,
        uint _amount,
        address _referrer)
    public;
}

interface KyberNetworkInterface
{
    function swapTokenToToken(
            ERC20 src,
            uint srcAmount,
            ERC20 dest,
            uint minConversionRate)
        external
        returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate)
        external
        payable
        returns(uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint _srcQty)
        external
        view
        returns (uint expectedRate, uint slippageRate);
}

contract KyberTrader
{
    address public constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    KyberNetworkInterface public kyberNetworkProxy;
    ERC20 public mcdDai;

    function swapEtherToToken()
        public
        payable
        returns (uint _receivedAmount)
    {
        (, uint minRate) = kyberNetworkProxy.getExpectedRate(ERC20(ETH_TOKEN_ADDRESS), mcdDai, msg.value);
        uint result = kyberNetworkProxy.swapEtherToToken.value(msg.value)(mcdDai, minRate);
        return result;
    }

    function swapTokenToToken(
            ERC20 _srcToken,
            uint _srcQty)
        public
        returns (uint _receivedAmount)
    {
        // getExpectedRate returns expected rate and slippage rate
        // We use the slippage rate as the minRate
        (, uint minRate) = kyberNetworkProxy.getExpectedRate(_srcToken, mcdDai, _srcQty);

        // Check that the token transferFrom has succeeded
        require(_srcToken.transferFrom(msg.sender, address(this), _srcQty), "Transfer of incoming ERC20 failed");

        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
        require(_srcToken.approve(address(kyberNetworkProxy), 0), "Could not reset incoming ERC20 allowance");

        // Approve tokens so network can take them during the swap
        _srcToken.approve(address(kyberNetworkProxy), _srcQty);

        // Perform the swap
        uint result = kyberNetworkProxy.swapTokenToToken(_srcToken, _srcQty, mcdDai, minRate);
        return result;
    }
}

contract EntryBot is KyberTrader
{
    BucketSale bucketSale;

    constructor(BucketSale _bucketSale, KyberNetworkInterface _kyberNetworkProxy)
        public
    {
        bucketSale = _bucketSale;
        mcdDai = bucketSale.tokenSoldFor();
        kyberNetworkProxy = _kyberNetworkProxy;
        bucketSale.tokenSoldFor().approve(address(bucketSale), uint(-1));
    }

    function agreeToTermsAndConditionsListedInThisBucketSaleContractAndEnterSaleWithEther(
            address _buyer,
            uint _bucketId,
            uint _numberOfBuckets,
            address _referrer)
        public
        payable
    {
        uint receivedDai = swapEtherToToken();
        _enterSale(
            _buyer,
            _bucketId,
            receivedDai,
            _numberOfBuckets,
            _referrer);
    }

    function agreeToTermsAndConditionsListedInThisBucketSaleContractAndEnterSaleWithErc20(
            address _buyer,
            uint _bucketId,
            ERC20 _Erc20,
            uint _totalBuyAmount,
            uint _numberOfBuckets,
            address _referrer)
        public
    {
        uint receivedDai = swapTokenToToken(_Erc20, _totalBuyAmount);
        _enterSale(
            _buyer,
            _bucketId,
            receivedDai,
            _numberOfBuckets,
            _referrer);
    }

    function agreeToTermsAndConditionsListedInThisBucketSaleContractAndEnterSaleWithDai(
            address _buyer,
            uint _bucketId,
            uint _totalBuyAmount,
            uint _numberOfBuckets,
            address _referrer)
        public
    {
        bucketSale.tokenSoldFor().transferFrom(msg.sender, address(this), _totalBuyAmount);
        _enterSale(_buyer, _bucketId, _totalBuyAmount, _numberOfBuckets, _referrer);
    }

    function _enterSale(
            address _buyer,
            uint _bucketId,
            uint _totalBuyAmount,
            uint _numberOfBuckets,
            address _referrer)
        private
    {
        uint amountPerBucket = _totalBuyAmount / _numberOfBuckets;

        for(uint i = 0; i < _numberOfBuckets; i++)
        {
            bucketSale.agreeToTermsAndConditionsListedInThisContractAndEnterSale(
                _buyer,
                _bucketId + i,
                amountPerBucket,
                _referrer
            );
        }
    }
}

contract EntryBotMainNet is EntryBot
{
    constructor()
    EntryBot(BucketSale(0x30076fF7436aE82207b9c03AbdF7CB056310A95A), KyberNetworkInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755))
        public
    {}
}